/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_TT_CRQ_PostDatedAddress
Description         :	Traitement qui met en vigueur les changements d'adresse post daté.
Valeurs de retours  :	
Note                :	ADX0000590 IA  2004-11-19  Bruno Lapointe	  Création
					ADX0001210 UP	2007-07-30  Bruno Lapointe      Renvoi des 200 des souscripteurs et bénéficiaires dont l'adresse a changée
					ADX0003026 UR  2007-08-10  Bruno Lapointe	  La changement d'adresse ne s'appliquait pas sur la province des taxes des souscripteurs.
					ADX0003071 UR  2007-09-19  Bruno Lapointe	  Gérer les doublons de changement d'adresse pour une même date et une même personne.
								2008-09-19  Josée Parent        Modification de la Requete Update Mo_Human pour prendre l'adresse de la table temporaire et non celle de Mo_Adr.
								2009-02-26  Donald Huppé		  GLPI 1489 : Modifier le traitement pour que toutes les nouvelles adresses soient automatiquement inscrites comme étant valide (addressLost = 0)
								2012-02-14  Eric Michaud		  Ajout parametre entrée pour traitement portail
								2014-04-09  Pierre-Luc Simard	  Nouvelle structure d'adresses
								2014-06-04  Maxime Martel	  Mise à jour du champ dateFin dans tblGENE_Telephone
								2015-01-07  Pierre-Luc Simard	  Gestion des prévalidations suite à un changement d'adresse sur un bénéficiaire
                                        2016-09-03  Steeve Picard       Ajout du blocage du trigger de delete sur la table tblGENE_Adresse qui créait un doublon dans l'historique
exec SP_TT_CRQ_PostDatedAddress
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SP_TT_CRQ_PostDatedAddress (
    @AsDate date = NULL,
    @ID_Source INT = NULL
) AS
BEGIN
    IF @AsDate IS NULL
        SET @AsDate = Cast(GetDate() as date)

	-- Table temporaire des adresses actives en date du jour, selon le type  (1 = Résidence, 4 = Affaire, 2 = Livraison)
	DECLARE @tAdresseType TABLE (
		iID_Humain INT,
		iID_Type INT,
		iID_Adresse INT)
	
	DECLARE @iMaxBeneficiaryID INT

	INSERT INTO @tAdresseType (iID_Humain, iID_Type, iID_Adresse)
		SELECT 
			A.iID_Source,
			A.iID_Type,
			MAX(A.iID_Adresse)
		FROM (
			SELECT 
				A.iID_Source,
				A.iID_Type,
				Max_Date_Debut = MAX(A.dtDate_Debut)
			FROM tblGENE_Adresse A
			WHERE A.iID_Source = IsNull(@ID_Source, A.iid_Source)
                 AND Cast(A.dtDate_Debut as date) <= @AsDate
			GROUP BY 
				A.iID_Source, 
				A.iID_Type
                HAVING count(*) > 1
			) MA 
		JOIN tblGENE_Adresse A ON A.iID_Source = MA.iID_Source 
			AND A.iID_Type = MA.iID_Type
			AND Cast(A.dtDate_Debut as date) = Cast(MA.Max_Date_Debut as date)
		GROUP BY 
			A.iID_Source, 
			A.iID_Type
	
	-- Table temporaire des humains dont l'adresse en vigueur doit être modifiée
	DECLARE @tAdresseHumain TABLE (
		iID_Humain INT,
		iID_Type INT,
		iID_Adresse INT)
	
	INSERT INTO @tAdresseHumain (iID_Humain, iID_Type, iID_Adresse)
	SELECT 
		AT.iID_Humain,
		AT.iID_Type,
		AT.iID_Adresse	 
	FROM @tAdresseType AT 
	JOIN dbo.Mo_Human H ON H.HumanID = AT.iID_Humain
	LEFT JOIN Un_Rep R ON R.RepID = H.HumanID
	WHERE 	(H.AdrID <> AT.iID_Adresse AND AT.iID_Type = 1 AND R.RepID IS NULL) -- Adresse de résidence pour les non représentants
		OR (H.AdrID <> AT.iID_Adresse AND AT.iID_Type = 4 AND R.RepID IS NOT NULL) -- Adresse d'affaire pour les représentants
	/*
	SELECT * 
	FROM @tAdresseType 
	WHERE iID_Humain = 149469
		
	SELECT * 
	FROM @tAdresseHumain AH
	JOIN dbo.Mo_Human H ON H.HumanID = AH.iID_Humain
	LEFT JOIN dbo.tblGENE_Adresse A ON A.iID_Adresse = AH.iID_Adresse
	LEFT JOIN dbo.tblGENE_Adresse A2 ON A2.iID_Adresse = H.AdrID
	*/
	IF EXISTS (SELECT 1 FROM @tAdresseHumain) 
	BEGIN 
		-- Met l'adresse en vigueur pour les humains
		UPDATE dbo.Mo_Human
		SET AdrID = AH.iID_Adresse
		FROM dbo.Mo_Human H
		JOIN @tAdresseHumain AH ON AH.iID_Humain = H.HumanID
	
		-- Applique le changement de province sur la province des taxes du souscripteur.
		UPDATE dbo.Un_Subscriber 
		SET StateID = A.iID_Province,
			AddressLost = A.bInvalide -- GLPI 1489
		FROM dbo.Un_Subscriber S
		JOIN @tAdresseHumain AH ON AH.iID_Humain = S.SubscriberID
		JOIN tblGENE_Adresse A ON A.iID_Adresse = AH.iID_Adresse
			
		-- GLPI 1489 -------
		UPDATE dbo.Un_Beneficiary 
		SET bAddressLost = A.bInvalide
		FROM dbo.Un_Beneficiary B
		JOIN @tAdresseHumain AH ON AH.iID_Humain = B.BeneficiaryID
		JOIN tblGENE_Adresse A ON A.iID_Adresse = AH.iID_Adresse

		-- Boucler sur les changements afin de mettre à jour les prévalidations et le BEC
		SELECT 
			@iMaxBeneficiaryID = MAX(B.BeneficiaryID) 
		FROM dbo.Un_Beneficiary B
		JOIN @tAdresseHumain AH ON Ah.iID_Humain = B.BeneficiaryID
	
		WHILE @iMaxBeneficiaryID	IS NOT NULL
			BEGIN
				EXEC psCONV_EnregistrerPrevalidationPCEE 2, NULL, @iMaxBeneficiaryID, NULL, NULL

				SELECT 
					@iMaxBeneficiaryID = MAX(B.BeneficiaryID) 
				FROM dbo.Un_Beneficiary B
				JOIN @tAdresseHumain AH ON Ah.iID_Humain = B.BeneficiaryID
				WHERE B.BeneficiaryID < @iMaxBeneficiaryID
			END
	END	

	-- Déplacer les anciennes adresses dans la table historique
    -- On insère l'ancienne adresse dans la table des adresses historiques
    INSERT INTO tblGENE_AdresseHistorique (
	   iID_Source,
	   cType_Source,
	   iID_Type,
	   dtDate_Debut,
	   dtDate_Fin,
	   bInvalide,
	   dtDate_Creation,
	   vcLogin_Creation,
	   vcNumero_Civique,
	   vcNom_Rue,
	   vcUnite,
	   vcCodePostal,
	   vcBoite,
	   iID_TypeBoite,
	   iID_Ville,
	   vcVille,
	   iID_Province,
	   vcProvince,
	   cID_Pays,
	   vcPays,
	   bNouveau_Format,
	   bResidenceFaitQuebec,
	   bResidenceFaitCanada,
	   vcInternationale1,
	   vcInternationale2,
	   vcInternationale3)
    SELECT     
	   A.iID_Source,
	   A.cType_Source,
	   A.iID_Type,
	   A.dtDate_Debut,
	   (SELECT Min(dtDate_Debut) From tblGENE_Adresse WHERE iID_Source = A.iID_Source And cType_Source = A.cType_Source 
                                                         And iID_Type = A.iID_Type And dtDate_Debut > A.dtDate_Debut), 
	   A.bInvalide,
	   A.dtDate_Creation,
	   A.vcLogin_Creation,
	   A.vcNumero_Civique,
	   A.vcNom_Rue,
	   A.vcUnite,
	   A.vcCodePostal,
	   A.vcBoite,
	   A.iID_TypeBoite,
	   A.iID_Ville,
	   A.vcVille,
	   A.iID_Province,
	   A.vcProvince,
	   A.cID_Pays,
	   A.vcPays,
	   A.bNouveau_Format,
	   A.bResidenceFaitQuebec,
	   A.bResidenceFaitCanada,
	   A.vcInternationale1,
	   A.vcInternationale2,
	   A.vcInternationale3
    FROM tblGENE_Adresse A
        JOIN @tAdresseType AH ON AH.iID_Humain = A.iID_Source And AH.iID_Type = A.iID_Type
        --LEFT JOIN @tAdresseType AH ON AH.iID_Adresse = A.iID_Adresse
    WHERE A.iID_Source = IsNull(@ID_Source, A.iid_Source)
        AND A.iID_Adresse <> AH.iID_Adresse
        --AND AH.iID_Adresse IS NULL
	   AND cast(A.dtDate_Debut as date) <= @AsDate

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is null 
	   CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

    INSERT INTO #DisableTrigger 
    VALUES ('TRG_GENE_Adresse_Historisation_D')
							
    -- On supprime l'ancienne adresse de la table des adresses courantes
    DELETE A
    FROM tblGENE_Adresse A
        JOIN @tAdresseType AH ON AH.iID_Humain = A.iID_Source And AH.iID_Type = A.iID_Type
        --LEFT JOIN @tAdresseType AH ON AH.iID_Adresse = A.iID_Adresse
    WHERE A.iID_Source = IsNull(@ID_Source, A.iid_Source)
        AND A.iID_Adresse <> AH.iID_Adresse
        --AND AH.iID_Adresse IS NULL
	   AND cast(A.dtDate_Debut as date) <= @AsDate

    DELETE FROM #DisableTrigger 
    WHERE vcTriggerName = 'TRG_GENE_Adresse_Historisation_D'
				
/*
	
		-- Met en vigueur pour les compagnies
		UPDATE Mo_Dep
		SET AdrID = A.iID_Adresse
		FROM Mo_Dep
		JOIN dbo.Mo_Adr A ON A.AdrTypeID = 'C' AND A.SourceID = Mo_Dep.DepID
		WHERE dbo.FN_CRQ_DateNoTime(A.InForce) = @AsDate
			AND A.AdrID <> Mo_Dep.AdrID -- Adresse à changer

		-- Supprime les enregistrements 200 non envoyé lié à les souscripteurs
		-- et bénéficiaires dont les adresses ont changées. Ils seront recréés 
		-- avec les données à jour.
		DELETE
		FROM Un_CESP200
		WHERE HumanID IN (SELECT HumanID FROM @tHumanPostAddress) -- Adresses changées
			AND iCESPSendFileID IS NULL

	-- Table temporaire des conventions et de leurs dates d'entrées en vigueur 
	-- pour le PCEE
	DECLARE @tCESPOfConventions TABLE (
		ConventionID INTEGER PRIMARY KEY,
		EffectDate DATETIME NOT NULL )

	INSERT INTO @tCESPOfConventions
		SELECT 
			C.ConventionID,
			EffectDate = -- Date d'entrée en vigueur de la convention pour le PCEE
				CASE 
					-- Avant le 1 janvier 2003 on envoi toujours la date d'entrée en vigueur de la convention
					WHEN C.dtRegStartDate < '2003-01-01' THEN C.dtRegStartDate
					-- La date d'entrée en vigueur de la convention est la récente c'est donc elle qu'on envoit
					WHEN C.dtRegStartDate > B.BirthDate THEN C.dtRegStartDate
					-- La date de naissance du bénéficiaire est la plus récente c'est donc elle qu'on envoit
					ELSE B.BirthDate		
				END
		FROM @tHumanPostAddress HP
		JOIN dbo.Un_Convention C ON HP.HumanID = C.BeneficiaryID OR HP.HumanID = C.SubscriberID
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
		JOIN dbo.Un_Convention I ON I.ConventionID = C.ConventionID
		WHERE	C.tiCESPState > 0 -- Pré-validation minimums passe sur la convention
			AND C.bSendToCESP <> 0 -- À envoyer au PCEE			
			AND C.dtRegStartDate IS NOT NULL	-- 
			AND C.ConventionID NOT IN ( -- Conventions fermées
					SELECT T.ConventionID
					FROM (-- Retourne la plus grande date de début d'un état par convention
						SELECT 
							S.ConventionID,
							MaxDate = MAX(S.StartDate)
						FROM Un_ConventionConventionState S
						JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
						GROUP BY S.ConventionID
						) T
					JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
					WHERE CCS.ConventionStateID = 'FRM'
					)
		GROUP BY 
			C.ConventionID, 
			C.dtRegStartDate,
			B.BirthDate
	
	-- Crées les 200 avec les adresses à jour. 
	INSERT INTO Un_CESP200 (
			ConventionID,
			HumanID,
			tiRelationshipTypeID,
			vcTransID,
			tiType,
			dtTransaction,
			iPlanGovRegNumber,
			ConventionNo,
			vcSINorEN,
			vcFirstName,
			vcLastName,
			dtBirthdate,
			cSex,
			vcAddress1,
			vcAddress2,
			vcAddress3,
			vcCity,
			vcStateCode,
			CountryID,
			vcZipCode,
			cLang,
			vcTutorName,
			bIsCompany )
		SELECT
			V.ConventionID,
			V.HumanID,
			V.tiRelationshipTypeID,		
			CASE V.tiType
				WHEN 3 THEN 'BEN'
				WHEN 4 THEN 'SUB'
			END,
			V.tiType,
			V.dtTransaction,
			V.iPlanGovRegNumber,
			V.ConventionNo,
			V.vcSINorEN,
			V.vcFirstName,
			V.vcLastName,
			V.dtBirthdate,
			V.cSex,
			V.vcAddress1,
			V.vcAddress2,
			V.vcAddress3,
			V.vcCity,
			V.vcStateCode,
			V.CountryID,
			V.vcZipCode,
			V.cLang,
			V.vcTutorName,
			V.bIsCompany
		FROM (
			SELECT
				C.ConventionID,
				HumanID = B.BeneficiaryID,
				tiRelationshipTypeID = NULL,
				tiType = 3,
				dtTransaction = CS.EffectDate,
				iPlanGovRegNumber = P.PlanGovernmentRegNo,
				ConventionNo = C.ConventionNo,
				vcSINorEN = H.SocialNumber,
				vcFirstName = H.FirstName,
				vcLastName = H.LastName,
				dtBirthdate = H.BirthDate,
				cSex = H.SexID,
				vcAddress1 = A.Address,
				vcAddress2 = 
					CASE
						WHEN RTRIM(A.CountryID) <> 'CAN' THEN A.Statename
					ELSE ''
					END,
				vcAddress3 =
					CASE
						WHEN RTRIM(A.CountryID) NOT IN ('CAN','USA') THEN ISNULL(Co.CountryName,'')
					ELSE ''
					END,
				vcCity = A.City,
				vcStateCode = 
					CASE
						WHEN RTRIM(A.CountryID) = 'CAN' THEN UPPER(ST.StateCode)
					ELSE '' 
					END,
				CountryID = A.CountryID,
				vcZipCode = A.ZipCode,
				cLang = H.LangID,
				vcTutorName =
					CASE 
						WHEN T.IsCompany = 0 THEN T.FirstName+' '+T.LastName
					ELSE T.LastName
					END,
				bIsCompany = H.IsCompany
			FROM @tHumanPostAddress HP
			JOIN dbo.Un_Beneficiary B ON HP.HumanID = B.BeneficiaryID
			JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
			JOIN @tCESPOfConventions CS ON CS.ConventionID = C.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			JOIN Mo_Country Co ON Co.CountryID = A.CountryID
			JOIN Mo_State ST ON ST.StateName = A.StateName
			JOIN dbo.Mo_Human T ON T.HumanID = B.iTutorID
			-----
			UNION
			-----
			SELECT
				C.ConventionID,
				HumanID = S.SubscriberID,
				C.tiRelationshipTypeID,
				tiType = 4,
				dtTransaction = CS.EffectDate,
				iPlanGovRegNumber = P.PlanGovernmentRegNo,
				ConventionNo = C.ConventionNo,
				vcSINorEN = H.SocialNumber,
				vcFirstName = ISNULL(H.FirstName,''),
				vcLastName = H.LastName,
				dtBirthdate = H.BirthDate,
				cSex = H.SexID,
				vcAddress1 = A.Address,
				vcAddress2 = 
					CASE
						WHEN RTRIM(A.CountryID) <> 'CAN' THEN A.Statename
					ELSE ''
					END,
				vcAddress3 =
					CASE
						WHEN RTRIM(A.CountryID) NOT IN ('CAN','USA') THEN ISNULL(Co.CountryName,'')
					ELSE ''
					END,
				vcCity = A.City,
				vcStateCode = 
					CASE
						WHEN RTRIM(A.CountryID) = 'CAN' THEN UPPER(ST.StateCode)
					ELSE '' 
					END,
				CountryID = A.CountryID,
				A.ZipCode,
				cLang = H.LangID,
				vcTutorName = NULL,
				bIsCompany = H.IsCompany
			FROM @tHumanPostAddress HP
			JOIN dbo.Un_Convention C ON HP.HumanID = C.SubscriberID
			JOIN dbo.Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
			JOIN @tCESPOfConventions CS ON CS.ConventionID = C.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			JOIN Mo_Country Co ON Co.CountryID = A.CountryID
			JOIN Mo_State ST ON ST.StateName = A.StateName
			) V
		LEFT JOIN (
			SELECT 
				G2.HumanID, 
				G2.ConventionID,
				G2.tiType,
				iCESPSendFileID = MAX(ISNULL(G2.iCESPSendFileID,999))
			FROM Un_CESP200 G2
			JOIN @tCESPOfConventions CS ON CS.ConventionID = G2.ConventionID
			GROUP BY
				G2.HumanID, 
				G2.ConventionID,
				G2.tiType
			) M ON M.HumanID = V.HumanID AND M.ConventionID = V.ConventionID AND M.tiType = V.tiType
		LEFT JOIN Un_CESP200 G2 ON G2.HumanID = M.HumanID 
										AND G2.ConventionID = M.ConventionID 
										AND ISNULL(G2.iCESPSendFileID,999) = ISNULL(M.iCESPSendFileID,999) 
										AND G2.tiType = M.tiType
		-- S'assure que les informations ne sont pas les mêmes que les dernières expédiées
		WHERE G2.iCESP200ID IS NULL
			OR V.dtTransaction <> G2.dtTransaction
			OR	V.iPlanGovRegNumber <> G2.iPlanGovRegNumber
			OR V.ConventionNo <> G2.ConventionNo
			OR V.vcSINorEN <> G2.vcSINorEN
			OR V.vcFirstName <> G2.vcFirstName
			OR V.vcLastName <> G2.vcLastName
			OR V.dtBirthdate <> G2.dtBirthdate
			OR V.cSex <> G2.cSex
			OR V.vcAddress1 <> G2.vcAddress1
			OR V.vcAddress2 <> G2.vcAddress2
			OR V.vcAddress3 <> G2.vcAddress3
			OR V.vcCity <> G2.vcCity
			OR V.vcStateCode <> G2.vcStateCode
			OR V.CountryID <> G2.CountryID
			OR V.vcZipCode <> G2.vcZipCode
			OR V.cLang <> G2.cLang
			OR V.vcTutorName <> G2.vcTutorName
			OR V.bIsCompany <> G2.bIsCompany
			OR V.tiRelationshipTypeID <> G2.tiRelationshipTypeID

	-- Inscrit le vcTransID avec le ID Ex: BEN + <iCESP200ID>.
	UPDATE Un_CESP200
	SET vcTransID = vcTransID+CAST(iCESP200ID AS VARCHAR(12))
	WHERE vcTransID IN ('BEN','SUB')
	*/
	
	-----------------------------------
	-- Liste des telephones à modifier
	-----------------------------------
	SELECT 
		T.iID_Source,
		T.iID_Type,
		T.cType_source,
		MIN(T.iID_Telephone) AS IDTelephone 
	INTO #t
	FROM tblGENE_Telephone T 
	WHERE T.iID_Source = IsNull(@ID_Source, T.iid_Source)
          AND dtDate_Fin IS NULL
		AND dtDate_Debut BETWEEN '1950-01-01' and @AsDate
	GROUP BY 
		iID_source,
		cType_Source,
		iID_type
	HAVING COUNT(*) > 1
	ORDER BY 
		iID_Source,
		iID_Type

	------------------------------------------
	-- UPDATE de la table tblGENE_Telephone
	------------------------------------------
	UPDATE tblGENE_Telephone 
		SET dtDate_Fin = Z.nouvelleDate
	FROM tblGENE_Telephone tele
	JOIN (
		SELECT DISTINCT
			T.*, 
			U.dtDate_Debut AS nouvelleDate
		FROM tblGENE_Telephone T 
		JOIN #t A ON T.iID_Telephone = A.IDTelephone
		JOIN (

			SELECT 
				dtDate_Debut, 
				T.iID_Source, 
				T.iID_Type, 
				T.iID_Telephone 
			FROM tblGENE_Telephone T 
			JOIN #t A ON T.iID_Source = A.iID_Source
			WHERE dtDate_Fin IS NULL 
				AND T.iID_Telephone <> A.IDTelephone

		) U ON U.iID_Source = T.iID_Source 
			AND U.iID_Type = T.iID_Type 
			AND U.iID_Telephone <> T.iID_Telephone
	) Z ON Z.iID_Telephone = tele.iID_Telephone
END


