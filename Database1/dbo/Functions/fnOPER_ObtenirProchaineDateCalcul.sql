/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnOPER_ObtenirProchaineDateCalcul
Nom du service		: TBLOPER_RENDEMENTS 
But 				: Permet d'obtenir la prochaine date de calcul pour un type de rendement
Description			: Cette fonction est appelée pour obtenir la prochaine date de calcul 
						pour un type de rendement
Facette				: OPER
Référence			: Noyau-OPER

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
						--------------------------	-----------	-----------------------------------------------------------------
						tiID_Type_Rendement		Oui			Identifiant unique du type de rendement					
		  			
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblOPER_Rendements			dtDate_Calcul_Rendement			Date de calcul du rendement					

Exemple d'appel : 
				SELECT dbo.fnOPER_ObtenirProchaineDateCalcul(3)

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-08-06		Jean-François Gauthier		Création de la fonction			1.4.4 dans le P171U - Services du noyau de la facette OPER - Opérations
		2009-09-25		Jean-François Gauthier		Si aucune valeur n'est trouvée, retourne la date du dernier jour du mois en cours.
		2009-10-07		Jean-François Gauthier		Correction d'un bug sur le calcul du dernier jour de certains mois
		2010-01-14		Jean-François Gauthier		Modification du calcul la date qui ne fonctionnait pas dans tous les cas
****************************************************************************************************/
CREATE FUNCTION dbo.fnOPER_ObtenirProchaineDateCalcul
	(
		@tiID_Type_Rendement	TINYINT
	)
RETURNS DATETIME
AS
	BEGIN
		DECLARE 
				@dtProchaineDateCalcul DATETIME

		--	SELECTIONNER LE RENDEMENT AVEC dtDate_Calcul_Rendement LA PLUS RÉCENTE ET
		--	CORRESPONDANT AU @tiID_Type_Rendements PASSÉ EN PARAMÈTRE
		--
		--	EN FONCTION DE LA DATE TROUVÉE, CALCULER LE DERNIER JOUR DU MOIS SUIVANT
		SELECT
			TOP 1 @dtProchaineDateCalcul = DATEADD(dd,-1,DATEADD(mm,2,DATEADD(dd, -DAY(r.dtDate_Calcul_Rendement)+1, r.dtDate_Calcul_Rendement)))
		FROM
			dbo.tblOPER_Rendements r
		WHERE
			r.tiID_Type_Rendement = @tiID_Type_Rendement
		ORDER BY
			r.dtDate_Calcul_Rendement DESC

		IF @dtProchaineDateCalcul IS NULL
			BEGIN
				SET @dtProchaineDateCalcul = CAST(CONVERT(VARCHAR(10),DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+1,0)),126) AS DATETIME) --DATEADD(mm,1,DATEADD(dd, -DAY(GETDATE()), GETDATE()))
			END
			
		RETURN @dtProchaineDateCalcul
	END
