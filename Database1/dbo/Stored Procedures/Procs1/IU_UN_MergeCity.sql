/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	IU_UN_MergeCity
Description 		:	Fusion des villes
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001278	IA	2007-03-19	Alain Quirion		Création
							2014-04-30	Maxime Martel		Modification dans tblGENE_Adresse au lieu de Mo_Adr
							2015-02-24	Pierre-Luc Simard	Correction dans le nom du trigger
*************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_MergeCity](	
	@ConnectID INTEGER,				--ID de connexion
	@oldCityName VARCHAR(100),		--Nom de la ville à fusionnée
	@newCityID INTEGER,				--Identifiant de la ville
	@CountryID CHAR(4),				--Identifiant du pays
	@StateID INTEGER)				--Identifiant de la province
AS
BEGIN
	DECLARE @iResult INTEGER
		
	SET @iResult = 1

	IF @StateID = 0
		SET @StateID = NULL
/*
	DECLARE @tCESP200ToSend TABLE(
		HumanID INTEGER PRIMARY KEY)

	DECLARE @tConvInForceDate TABLE (
			ConventionID INTEGER PRIMARY KEY)

	DECLARE @tCESPOfConventions TABLE (
		ConventionID INTEGER PRIMARY KEY,
		EffectDate DATETIME NOT NULL )

	INSERT INTO @tCESP200ToSend
		SELECT 
				H.HumanID
		FROM dbo.Mo_Adr A
		LEFT JOIN Mo_State S ON S.StateName = ISNULL(A.StateName,'')
		JOIN dbo.Mo_Human H ON H.AdrID = A.AdrID				
		LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
		LEFT JOIN dbo.Un_Subscriber Su ON Su.SubscriberID = H.HumanID
		WHERE (Su.SubscriberID IS NOT NULL
				OR B.BeneficiaryID IS NOT NULL)
				AND A.City = @oldCityName	
				AND A.CountryID = @CountryID	
				AND ISNULL(S.StateID,0) = @StateID

	INSERT INTO @tConvInForceDate
		SELECT 
			C.ConventionID
		FROM dbo.Un_Convention C
		JOIN @tCESP200ToSend T ON T.HumanID = C.BeneficiaryID
								OR T.HumanID = C.SubscriberID	
		GROUP BY C.ConventionID	

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
		FROM @tConvInForceDate I 
		JOIN dbo.Un_Convention C ON I.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
		WHERE	C.tiCESPState > 0 -- Pré-validation minimums passe sur la convention
			AND C.bSendToCESP <> 0 -- À envoyer au PCEE			
			AND C.dtRegStartDate IS NOT NULL	
		GROUP BY 
			C.ConventionID, 
			C.dtRegStartDate,
			B.BirthDate
*/
	BEGIN TRANSACTION

	-- Desactiver Triggers
	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
		INSERT INTO #DisableTrigger VALUES('TtblGENE_Adresse')

	--Mise à jours des adresses
	UPDATE tblGENE_Adresse
	SET vcVille = C.CityName, iID_Ville = @newCityID	
	FROM tblGENE_Adresse A 
	JOIN Mo_City C ON C.CityID = @newCityID	
	LEFT JOIN Mo_State S ON ISNULL(S.StateID, 0) = ISNULL(C.StateID,0)
	WHERE A.vcVille = @oldCityName
		AND A.cID_Pays = @CountryID	
		AND ISNULL(S.StateID,0) = @StateID
		
	Delete #DisableTrigger where vcTriggerName = 'TtblGENE_Adresse'
		
	UPDATE tblGENE_AdresseHistorique
	SET iID_Ville = NULL	
	FROM tblGENE_AdresseHistorique A 
	JOIN Mo_City C ON C.CityID = @newCityID	
	LEFT JOIN Mo_State S ON ISNULL(S.StateID, 0) = ISNULL(C.StateID,0)
	WHERE A.vcVille = @oldCityName
		AND A.cID_Pays = @CountryID	
		AND ISNULL(S.StateID,0) = @StateID
/*
	UPDATE dbo.Mo_Adr 
	SET City = C.CityName	
	FROM Mo_Adr	
	JOIN Mo_City C ON C.CityID = @newCityID
	LEFT JOIN Mo_State S ON ISNULL(S.StateID,0) = ISNULL(C.StateID,0)
	WHERE Mo_Adr.City = @oldCityName
		AND Mo_Adr.CountryID = @CountryID	
		AND ISNULL(S.StateID,0) = @StateID
*/

	IF @@ERROR <>0
		SET @iResult = -1
/*
	IF @iResult > 0
	BEGIN
		IF EXISTS (
			-- Vérifie si on doit supprimer les enregistrements 200 non-expédiés (d'autres seront insérés pour les remplacer)
			SELECT iCESP200ID
			FROM Un_CESP200
			JOIN @tConvInForceDate C ON C.ConventionID = Un_CESP200.ConventionID
			WHERE Un_CESP200.iCESPSendFileID IS NULL
			)
		BEGIN
			-- Supprime les enregistrements 200 non-expédiés (d'autres seront insérés pour les remplacer)
			DELETE Un_CESP200
			FROM Un_CESP200
			JOIN @tConvInForceDate C ON C.ConventionID = Un_CESP200.ConventionID
			WHERE Un_CESP200.iCESPSendFileID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -2
		END

		IF @iResult > 0
		BEGIN
			-- Insert les enregistrements 200 (Bénéficiaire et souscripteur)
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
						FROM dbo.Un_Beneficiary B
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
						FROM dbo.Un_Beneficiary B
						JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
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
							iCESPSendFileID = MAX(G2.iCESPSendFileID)
						FROM Un_CESP200 G2
						JOIN @tCESPOfConventions CS ON CS.ConventionID = G2.ConventionID
						GROUP BY
							G2.HumanID, 
							G2.ConventionID,
							G2.tiType
						) M ON M.HumanID = V.HumanID AND M.ConventionID = V.ConventionID AND M.tiType = V.tiType
					LEFT JOIN Un_CESP200 G2 ON G2.HumanID = M.HumanID AND G2.ConventionID = M.ConventionID AND G2.iCESPSendFileID = M.iCESPSendFileID AND G2.tiType = M.tiType
					-- S'assure que les informations ne sont pas les mêmes que les dernières expédiées
					WHERE V.tiType <> G2.tiType
						OR	V.dtTransaction <> G2.dtTransaction
						OR	V.iPlanGovRegNumber <> G2.iPlanGovRegNumber
						OR	V.ConventionNo <> G2.ConventionNo
						OR	V.vcSINorEN <> G2.vcSINorEN
						OR	V.vcFirstName <> G2.vcFirstName
						OR	V.vcLastName <> G2.vcLastName
						OR	V.dtBirthdate <> G2.dtBirthdate
						OR	V.cSex <> G2.cSex
						OR	V.vcAddress1 <> G2.vcAddress1
						OR	V.vcAddress2 <> G2.vcAddress2
						OR	V.vcAddress3 <> G2.vcAddress3
						OR	V.vcCity <> G2.vcCity
						OR	V.vcStateCode <> G2.vcStateCode
						OR	V.CountryID <> G2.CountryID
						OR	V.vcZipCode <> G2.vcZipCode
						OR	V.cLang <> G2.cLang
						OR	V.vcTutorName <> G2.vcTutorName
						OR V.bIsCompany <> G2.bIsCompany
						OR V.tiRelationshipTypeID <> G2.tiRelationshipTypeID
						OR G2.iCESP200ID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -3
		END

		IF @iResult = 1
		BEGIN
			-- Inscrit le vcTransID avec le ID Ex: BEN + <iCESP200ID>.
			UPDATE Un_CESP200
			SET vcTransID = vcTransID+CAST(iCESP200ID AS VARCHAR(12))
			WHERE vcTransID IN ('BEN','SUB')

			IF @@ERROR <> 0
				SET @iResult = -4
		END
		-----------------------------------------------
		-- Fin de la gestion des enregistrements 200 --
		-----------------------------------------------		
	END
*/
	IF @iResult > 0
	BEGIN
		INSERT INTO Mo_CityFusion(oldCityName,CityID,StateID,ConnectID)
		VALUES(@oldCityName, @newCityID, @StateID, @ConnectID)

		IF @@ERROR <> 0
			SET @iResult = -5
	END

	IF @iResult >0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @iResult	
END


