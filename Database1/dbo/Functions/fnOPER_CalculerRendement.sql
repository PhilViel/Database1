/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnOPER_CalculerRendement
Nom du service		: TBLOPER_RENDEMENTS (Rechercher les taux de rendement)
But 				: Permet de calculer le rendement pour le mois traité
Description			: Cette fonction est appelée pour calculer un rendement pour le mois traité
Facette				: OPER
Référence			: Noyau-OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						mMontantTransaction			Montant de la transaction
						dTauxRendement				Taux du rendement mensuel
						tiNbrJrsMoisCalcul			Nombre de jours du mois du calcul
						tiJourOperation				Jour de l’opération

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						N/A							mRendement						Montant du rendement généré
	
Formule de calcul utilisé :
	mRendement = mMontantTransaction * dTauxRendement * ((tiNbrJrsMoisCalcul – tiJourOperation) / tiNbrJrsMoisCalcul)

Exemple d'appel :
		SELECT dbo.fnOPER_CalculerRendement(10000,3,31,7)

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-07-28		Jean-François Gauthier		Création de la fonction			1.4.5 dans le P171U - Services du noyau de la facette OPER - Opérations
		2009-07-29		Jean-François Gauthier		Ajout de la division par 100
		2009-11-03		Jean-François Gauthier		Modification pour decimal(10,3)
		2009-12-10		Jean-François Gauthier		Arrondissement de la valeur de retour à 2 décimales
		2013-01-09		Frédérick Thibault			Ajout du traitement par Fiducie et par délai de date RI estimée (FT1)
		2013-03-28		Frédérick Thibault			Ajout du traitement conventions individuelles issues d'un RIO ou RIM (FT2)
		2013-06-04		Frédérick Thibault			Exlusion des rendements 5 et 6 (TRI, RRI) de la validation Date RI (FT3)
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_CalculerRendement]
	(
		 @mMontantTransaction	MONEY
		,@dTauxRendement		DECIMAL(10,3)
		,@tiNbrJrsMoisCalcul	TINYINT
		,@tiJourOperation		TINYINT
		,@iIDTauxRendement		INT	-- FT1
		,@iIDConvention			INT	-- FT1
		,@iCheckDateRI			INT -- FT3
	)
RETURNS MONEY
AS
	BEGIN
		DECLARE @mRendement MONEY
		
		-- FT1, FT2 : Va chercher le bon taux selon le plan et la date RI estimée
		DECLARE @iDelaiRI INT

		SET @iDelaiRI = dbo.fnGENE_ObtenirParametre('OPER_TAUX_DELAI_RI', null, null, null, null, null, null)

		SELECT @dTauxRendement =	CASE WHEN P.PlanID = 4
									THEN
										CASE WHEN RIO.iID_Operation_RIO IS NOT NULL AND RIO.OperTypeID IN ('RIO', 'RIM')
										THEN -- INDIVIDUELLE RIO
											RT.dTaux_Individuel_RIO
										ELSE -- INDIVIDUELLE
											RT.dTaux_Individuel
										END 
									ELSE
										CASE WHEN @iCheckDateRI = 0
										THEN
											RT.dTaux_AvantDelaiRI
										ELSE
											CASE WHEN dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) > dateadd(month, @iDelaiRI, getdate())
											THEN -- COLLECTIVE AVANT DELAI RI
												RT.dTaux_AvantDelaiRI
											ELSE -- COLLECTIVE APRES DELAI RI
												RT.dTaux_ApresDelaiRI
											END 
										END 
									END
		FROM tblOPER_RendementTaux RT
		JOIN Un_Plan P ON P.PlanID = RT.PlanID
		JOIN dbo.Un_Convention C ON C.PlanID = P.PlanID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		LEFT JOIN tblOPER_OperationsRIO RIO ON RIO.iID_Convention_Destination = C.ConventionID
		WHERE	C.ConventionID = @iIDConvention
		AND		RT.iID_Taux_Rendement = @iIDTauxRendement
		-- /FT1,FT2

		SET @mRendement = @mMontantTransaction * @dTauxRendement / 100 * (CAST(@tiNbrJrsMoisCalcul - @tiJourOperation AS DECIMAL(10,4))) / CAST(@tiNbrJrsMoisCalcul AS DECIMAL(10,4))

		SET @mRendement = ROUND(@mRendement,2)

		RETURN @mRendement
	END


