/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_ObtenirCompteInexistantPortail
Nom du service		: Obtenir les comptes inexistants sur le Portail
But 					:	Obtenir les informations des bénéficiaires et des souscripteurs dont le compte n'existe pas sur le Portail-Client.
							On valide l'existance des comptes qui sont enregistrés dans la BD IdentityServerUsersPortail.
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:	
	EXEC psCONV_ObtenirCompteInexistantPortail
	
Historique des modifications:
		Date				Programmeur					Description										Référence
		------------		----------------------------	-----------------------------------------	------------
		2015-04-17	Pierre-Luc Simard			Création du service							
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirCompteInexistantPortail] 
AS
BEGIN

	DECLARE @SQL VARCHAR(2000)

	-- Liste des conventions actives
	SELECT 
		C.ConventionID
	INTO #tConvention
	FROM dbo.Un_Convention C
	LEFT JOIN (
		SELECT
			CS.ConventionID,
			CCS.StartDate,
			CS.ConventionStateID
		FROM Un_ConventionConventionState CS
		JOIN (
			SELECT
						ConventionID ,
						StartDate = MAX(StartDate)
			FROM Un_ConventionConventionState
			GROUP BY ConventionID
			) CCS ON CCS.ConventionID = CS.ConventionID
				AND CCS.StartDate = CS.StartDate 
		) CSS on C.ConventionID = CSS.ConventionID
	WHERE CSS.ConventionStateID <> 'FRM'

	-- Liste des bénéficiaires et des souscripteurs dont le compte n'existe pas dans la BD IdentityServerUsersPortail
	SET @sql = 
	'SELECT --TOP 5000
		CH.HumanID,
		iEtat = isnull(PA.iEtat,0),
		--PE.vcDescEtat,
		--PA.dtDernierAcces,
		--PA.dtInscription,
		CH.TypeHumain,
		Langue = ISNULL(H.LangID, ''FRA''),
		EMail = dbo.fnGENE_CourrielEnDate (CH.HumanID, 1, NULL, 0)
	FROM (
		SELECT
			HumanID = C.BeneficiaryID,
			TypeHumain = ''Beneficiaire''  
		FROM #tConvention CO
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		GROUP BY C.BeneficiaryID
		UNION 
		SELECT
			HumanID = C.SubscriberID,
			TypeHumain = ''Souscripteur''
		FROM #tConvention CO
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		GROUP BY C.SubscriberID
		) CH
	JOIN dbo.Mo_Human H ON H.HumanID = CH.HumanID
	LEFT JOIN tblGENE_PortailAuthentification PA ON PA.iUserId = CH.HumanID
	LEFT JOIN tblGENE_PortailEtat PE ON PE.iIDEtat = PA.iEtat
	LEFT JOIN ' +
		dbo.fnGENE_ObtenirParametre('GENE_BD_USER_PORTAIL', NULL, NULL, NULL, NULL, NULL, NULL) 
		+ '.dbo.Users U ON U.UserName = CAST(CH.HumanID AS VARCHAR(50))  
	WHERE U.UserName IS NULL '

	EXEC (@SQL)

	DROP TABLE #tConvention

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[psCONV_ObtenirCompteInexistantPortail] TO [svc-portailmigrationprod]
    AS [dbo];

