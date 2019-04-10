/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirListeFichierSouscripteur
Nom du service		: Obtenir la liste des fichiers pour un souscripteur
But 				: Obtenir la liste des fichiers pour un souscripteur
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iIDSubscriber				Identifiant du souscripteur

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					
	- Obtenir la liste des fichiers pour un souscripteur
		EXEC psGENE_ObtenirListeFichierSouscripteur 601617

TODO:

Historique des modifications:
        Date        Programmeur                 Description
        ----------  ------------------------    -----------------------------------------------------
        2011-07-20  Eric Michaud                Création du service
        2012-09-06  Donald Huppé                Gestion des / et \ dans les nom et prenom
        2013-04-19  Pierre-Luc Simard           Vider les tables tblTEMP_LstFichierSousc (anciennement dirList) au lieu de la supprimer et la refaire
        2014-02-24  Jean-Philippe Fortin        Liste des fichiers des bénéficiaires
        2014-04-16  Pierre-Luc Simard           Delete au lieu des Truncate
        2014-05-07  Pierre-Luc Simard           Récupérer les lettres du dossier souscripteur qui ne sont pas dans le dossier Portail (Proacces)
        2014-09-23  Donald Huppé                Ajout de la recherche des documents génériques à partir de la table DocumentGenerique
        2015-02-25  Pierre-Luc Simard           Ajout d'un DISTINCT pour ne pas afficher plusieurs fois le même document générique
        2015-08-13  Pierre-Luc Simard           Ajout des documents d'assurances manquants
        2015-12-18  Pierre-Luc Simard           Ajout des documents génériques communs
        2016-01-12  Pierre-Luc Simard           Retrait des documents génériques communs et des documents d'assurances manquants
        2016-09-14  Steeve Picard               Renommage de la fonction en «fntCONV_ObtenirStatutConventionEnDate_PourTous»
        2018-03-21  Pierre-Luc Simard           Bloquer temporairement l'affichage des relevés en du 2017-12-31 sur le Portail
        2018-04-10  Pierre-Luc Simard           Bloquer les relevés des avant 2013
        2018-04-11  Pierre-Luc Simard           Ne plus bloquer les relevés du 2017-12-31
        2018-06-05  Sébastien Rodrigue          Ajout de le_conf_aju_ind et le_nq_cot
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirListeFichierSouscripteur]
	@iIDSubscriber INT

AS
BEGIN
	SET NOCOUNT ON;
	DECLARE 	
		@commandeline VARCHAR(250),
		@repertoire VARCHAR(250),
		@typehumain VARCHAR(1)

	DECLARE 
		@id INT,
		@Line VARCHAR(2000),
		@NewLine VARCHAR(2000)
	DECLARE	@list TABLE (line VARCHAR(2000))

	CREATE TABLE #tmp (line NVARCHAR (2000))

	CREATE TABLE #tmpDocGenerique (line NVARCHAR (2000))

	IF EXISTS (SELECT 1 FROM dbo.Un_Subscriber WHERE SubscriberID = @iIDSubscriber)
		SELECT DISTINCT
			@repertoire = GPS.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(hu.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(hu.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(hu.firstname)),' ','_') + '_' + cast(hu.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','') --+ '\RELEVES_DEPOTS'
	    FROM dbo.Un_Subscriber Su 
		JOIN dbo.mo_Human Hu ON SU.subscriberid = hu.humanId
		LEFT JOIN tblGENE_TypesParametre GTPS ON GTPS.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_SOUSCRIPTEUR'
		LEFT JOIN tblGENE_Parametres GPS ON GTPS.iID_Type_Parametre = GPS.iID_Type_Parametre
		WHERE Su.subscriberID = @iIDSubscriber
	ELSE IF EXISTS (SELECT 1 FROM dbo.Un_Beneficiary WHERE BeneficiaryID = @iIDSubscriber)
		SELECT DISTINCT
			@repertoire = GPS.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(hu.lastname)),1,1)) + '\' + replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(hu.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(hu.firstname)),' ','_') + '_' + cast(hu.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')-- + '\PORTAIL'
		FROM dbo.Un_Beneficiary Su 
		JOIN dbo.mo_Human Hu ON Su.BeneficiaryID = hu.humanId
		LEFT JOIN tblGENE_TypesParametre GTPS ON GTPS.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_BENEFICIAIRE'
		LEFT JOIN tblGENE_Parametres GPS ON GTPS.iID_Type_Parametre = GPS.iID_Type_Parametre
		WHERE Su.BeneficiaryID = @iIDSubscriber
	ELSE
		SELECT 'u' AS TypeHumain -- UNKNOWN

	SET @commandeline = 'dir ' + @repertoire + '\*.pdf /b /s'

	INSERT INTO #tmp (line) EXEC xp_cmdshell @commandeline

	INSERT INTO @list 
	SELECT DISTINCT D.CheminFichier
	FROM DocumentGenerique D
	JOIN DocumentGeneriqueHumain DH ON D.ID = DH.IdDocument
	WHERE dh.IdHumain = @iIDSubscriber
	    AND D.TypeChemin = 'dossier'

	/*-- Le souscripteur n'a pas de document d'assurances dans la table générique mais il devrait en avoir 
	INSERT INTO @list 
	SELECT DISTINCT 
		CheminFichier = CASE WHEN HS.LangID = 'ENU' 
									THEN (SELECT D.CheminFichier FROM DocumentGenerique D WHERE D.ID = 4)
									ELSE (SELECT D.CheminFichier FROM DocumentGenerique D WHERE D.ID = 3)
								END 		 			
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	LEFT JOIN DocumentGeneriqueHumain DH ON DH.IdHumain = C.SubscriberID AND DH.IdDocument IN (3 ,4) 
	WHERE C.SubscriberID = @iIDSubscriber
		AND DH.IdDocument IS NULL
		AND U.WantSubscriberInsurance = 1
		AND ISNULL(M.SubscriberInsuranceRate, 0) <> 0 
		AND U.PETransactionId IS NOT NULL

	-- Ajout des documents communs
	INSERT INTO @list 
	SELECT DISTINCT 
		CheminFichier = CASE WHEN HS.LangID = 'ENU' 
									THEN (SELECT D.CheminFichier FROM DocumentGenerique D WHERE D.ID = 10)
									ELSE (SELECT D.CheminFichier FROM DocumentGenerique D WHERE D.ID = 9)
								END 		 			
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON CS.conventionID = C.ConventionID
	WHERE C.SubscriberID = @iIDSubscriber
		AND CS.ConventionStateID IN ('TRA', 'REE') 
	*/		  	
	WHILE (SELECT COUNT(*) FROM @list) > 0
	BEGIN
		SELECT TOP 1 
            @Line = line, 
            @NewLine = line 
        FROM @list

		-- Ajouter un \ à la fin au besoin
		SET @NewLine = CASE WHEN SUBSTRING(REVERSE(@NewLine),1,1) <> '\' THEN @NewLine + '\' ELSE @NewLine END

        SET @commandeline = 'dir ' + @NewLine + '*.pdf /b /s'

        --PRINT @commandeline

        INSERT INTO #tmpDocGenerique (line) EXEC xp_cmdshell @commandeline

        DELETE FROM @list WHERE line = @Line
	END

	INSERT INTO #tmpDocGenerique 
	SELECT DISTINCT  D.CheminFichier
	FROM DocumentGenerique D
	JOIN DocumentGeneriqueHumain DH ON D.ID = DH.IdDocument
	WHERE dh.IdHumain = @iIDSubscriber
	    AND D.TypeChemin = 'fichier'

	SELECT vcNom = line 
	FROM #tmp 
	WHERE line IS NOT NULL 
		AND line <> 'File Not Found' 
		AND line <> 'The system cannot find the path specified.' 
		AND line <> 'The system cannot find the file specified.'
		AND (line LIKE '%\RELEVES_DEPOTS\%'
			OR line LIKE '%\PORTAIL\%'
			OR line LIKE '%le_conf_chq_pae_col%'
			OR line LIKE '%le_conf_chq_pae_col_nres%'
			OR line LIKE '%le_conf_chq_pae_ind%'
			OR line LIKE '%le_conf_chq_pae_ind_nres%'
			OR line LIKE '%le_conf_chq_rin%'
			OR line LIKE '%le_conf_dd_pae_col%'
			OR line LIKE '%le_conf_dd_pae_col_nres%'
			OR line LIKE '%le_conf_dd_pae_ind%'
			OR line LIKE '%le_conf_dd_pae_ind_nres%'
			OR line LIKE '%le_conf_dd_rin%'
			OR line LIKE '%le_conf_aju_ind%'
			OR line LIKE '%le_nq_pae%'
			OR line LIKE '%le_nq_rin%'
			OR line LIKE '%le_nq_cot%')
        AND NOT (line LIKE '%\RELEVES_DEPOTS\%_RD_%' AND SUBSTRING(line, CHARINDEX('\RELEVES_DEPOTS\', line, 1) + 16, 4) < 2013)
        --AND (line NOT LIKE '%\RELEVES_DEPOTS\20171231_RD_%' OR @iIDSubscriber IN (601813))

	UNION ALL

	-- Les documents génériques
	SELECT DISTINCT vcNom = line 
	FROM #tmpDocGenerique 
	WHERE line IS NOT NULL 
		AND line <> 'File Not Found' 
		AND line <> 'The system cannot find the path specified.' 
		AND line <> 'The system cannot find the file specified.'
		AND line <> 'Access is denied.'

END