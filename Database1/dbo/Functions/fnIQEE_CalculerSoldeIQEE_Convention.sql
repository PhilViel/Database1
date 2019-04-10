
/****************************************************************************************************
Code de service		:		fnIQEE_CalculerSoldeIQEE_Convention
Nom du service		:		CalculerSoldeIQEE_Convention
But					:		Calculer le solde de l'IQÉÉ de base d'une convention
Facette				:		IQÉÉ
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_Convention              ID de la convention concernée par l'appel
                        dtDate_Fin                  Date de fin de la période considérée par l'appel

Exemple d'appel:
                SELECT * FROM DBO.[fnIQEE_CalculerSoldeIQEE_Convention] (1234, 2011-12-19 07:52:45.930)

Parametres de sortie : Le solde de l'IQEE

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2012-08-06                  Stéphane Barbeau                        Création de la fonction
						2012-08-14					Stéphane Barbeau						Nouvelle formule de calcul en temps réel
						2013-12-13					Stéphane Barbeau						Ajout nouvelles conditions (O.OperTypeID <> 'IQE'  AND O.OperDate <= @dtDate_Fin)						
****************************************************************************************************/

CREATE FUNCTION dbo.fnIQEE_CalculerSoldeIQEE_Convention( @iID_Convention INT, @dtDate_Fin DATETIME)
RETURNS MONEY
AS
BEGIN

	DECLARE @mMontant_IQEE Money;
	DECLARE @mIQEE_Majoration Money;
	DECLARE @mIQEE_Crédit_de_base Money;

	SELECT @mIQEE_Majoration = isnull(IQEE.iqee,0),@mIQEE_Crédit_de_base = isnull(cbq.cbq,0)
					FROM dbo.Un_Convention C
							left join (SELECT iqee = ISNULL(SUM(isnull(CO.ConventionOperAmount,0)),0),CO.ConventionID
								FROM Un_ConventionOper CO
									 JOIN Un_Oper O ON O.OperID = CO.OperID
												   AND (
															(O.OperTypeID <> 'IQE'  AND O.OperDate <= @dtDate_Fin)
															OR (O.OperTypeID = 'IQE' AND CO.ConventionOperAmount < 0.00)
															OR (O.OperTypeID = 'IQE' AND O.OperDate <= @dtDate_Fin)
														)
								WHERE CO.ConventionOperTypeID = 'MMQ'
								GROUP BY CO.ConventionID) IQEE on IQEE.ConventionID = C.conventionid 
							left JOIN(SELECT	cbq = ISNULL(SUM(isnull(CO.ConventionOperAmount,0)),0),CO.ConventionID
								FROM Un_ConventionOper CO
									 JOIN Un_Oper O ON O.OperID = CO.OperID
												   AND (
															(O.OperTypeID <> 'IQE'  AND O.OperDate <= @dtDate_Fin)
															OR (O.OperTypeID = 'IQE' AND CO.ConventionOperAmount < 0.00)
															OR (O.OperTypeID = 'IQE' AND O.OperDate <= @dtDate_Fin)
														)
								WHERE CO.ConventionOperTypeID = 'CBQ'
								GROUP BY CO.ConventionID) cbq on cbq.ConventionID = C.conventionid 
					WHERE C.ConventionID = @iID_Convention

	SET @mMontant_IQEE = @mIQEE_Crédit_de_base + @mIQEE_Majoration
	
	RETURN @mMontant_IQEE

	--DECLARE @mMontant_IQEE Money;

	--SELECT @mMontant_IQEE = ISNULL(SUM(co.ConventionOperAmount),0)
	--FROM Un_ConventionOper co
	--	JOIN dbo.Un_Oper op on co.OperID = op.OperID
	--Where co.ConventionID = @iID_Convention
	--	AND op.OperDate <= @dtDate_Fin
	--	AND co.ConventionOperTypeID IN ('CBQ','MMQ')

	--	RETURN @mMontant_IQEE

END


