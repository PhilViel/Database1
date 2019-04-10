/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_CESP800Corrected
Description         :	Sauvegarde les corrections d'erreurs sur enregistrement 100, 200 et 400 ainsi que les usagers qui les a faites
Valeurs de retours  :	@ReturnValue :
					> 0  : Réussite
					<= 0 : Échec
				
Note                :	ADX0001153	IA	2006-11-10	Alain Quirion		Création
						ADX0002408	BR	2007-05-01	Alain Quirion		Modification : Création des enregistrements 400 seulement si le blob contient des cotisations non nulles
						ADX0002435	BR	2007-05-15	Alain Quirion		Création des enregistrement 400 des opérations PAE
						ADX0002416	BR	2007-06-04	Alain Quirion		Modification : Renvoi des enregistrements 400 liés aux 100 et 200
									2008-09-26	Pierre-Luc Simard			Supprime les tables ayant des index pour éviter les problèmes lorsqu'appelé en boucle
									2009-02-13	Patrick Robitaille				Modification pour les corrections d'enregistrements 800 associés à des enregistrements 511
									2009-11-23	Jean-François Gauthier	Modification pour la détermination de la date effective (EffectDate)
									2015-01-12	Pierre-Luc Simard			Remplacer la validation du tiCESPState par l'état de la convention (REE, FRM)
									2015-02-24	Pierre-Luc Simard			La ville peut être NULL
                                             2016-01-18     Steve Picard            Considérer toujours les PRAs comme corriger peut importe la valeur dans @bReSend
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_CESP800Corrected]
	(
	@iBlobID	INT,	-- ID contenant les iCESP800ID des erreurs corrigées séparé par des virgules.	
	@bReSend	BIT,	-- Indique si on doit renvoyer ou non les 400
	@ConnectID	INT		-- Connect ID
	)
AS
BEGIN
	DECLARE @dtToday					DATETIME,
			@iReturn					INT,
			@OperID						INT,
			@iCESP400ID					INT,		
			@tiCESP400TypeID			INT,
			@tiCESP400WithdrawReasonID	INT,
			@iReversedCESP400ID			INT,
			@from100200Tool				BIT	

	SET @iReturn = 1

	SET @from100200Tool = 1

	SET @dtToday = GETDATE()

	CREATE TABLE  #CESP800Table (
		iCESP800ID INTEGER NOT NULL PRIMARY KEY,
		Done BIT)

	-- Va chercher les ID des enregistrement 800
	INSERT INTO #CESP800Table
		SELECT iVal, 0
		FROM dbo.FN_CRI_BlobToIntegerTable (@iBlobID)

	IF @@ERROR <> 0 
		SET @iReturn = -10

	IF EXISTS (
			SELECT TOP 1 *
			FROM #CESP800Table C8T
			JOIN Un_CESP400 C4 ON C4.iCESP800ID = C8T.iCESP800ID)
	OR EXISTS (
			SELECT TOP 1 *
			FROM #CESP800Table C8T
			JOIN Un_CESP511 C5 ON C5.iCESP800ID = C8T.iCESP800ID)
		SET @from100200Tool = 0

	IF @iReturn > 0
	BEGIN
		-- Insère les enregistrement 800 des 400 liés à un enregistrement 100 qui a été corrigé
		INSERT INTO #CESP800Table(iCESP800ID, Done)
		SELECT
			C8T.iCESP800ID,
			0
		FROM Un_CESP800ToTreat C8T
		JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8T.iCESP800ID
		JOIN Un_CESP400 C4 ON C4.iCESP800ID = C8.iCESP800ID
		JOIN Un_CESP100 C1 ON C1.ConventionID = C4.ConventionID
		JOIN Un_CESP800 C8B ON C8B.iCESP800ID = C1.iCESP800ID
		JOIN #CESP800Table C8TB ON C8TB.iCESP800ID = C8B.iCESP800ID
		WHERE C8.iCESPReceiveFileID = C8B.iCESPReceiveFileID

		IF @@ERROR <> 0 
			SET @iReturn = -11
	END

	IF @iReturn > 0
	BEGIN
		-- Insère les enregistrement 800 des 400 liés à un enregistrement 200 qui a été corrigé
		INSERT INTO #CESP800Table(iCESP800ID, Done)
		SELECT
			C8T.iCESP800ID,
			0
		FROM Un_CESP800ToTreat C8T
		JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8T.iCESP800ID
		JOIN Un_CESP400 C4 ON C4.iCESP800ID = C8.iCESP800ID
		JOIN Un_CESP200 C2 ON C2.ConventionID = C4.ConventionID
		JOIN Un_CESP800 C8B ON C8B.iCESP800ID = C2.iCESP800ID
		JOIN #CESP800Table C8TB ON C8TB.iCESP800ID = C8B.iCESP800ID
		WHERE C8.iCESPReceiveFileID = C8B.iCESPReceiveFileID

		IF @@ERROR <> 0 
			SET @iReturn = -12
	END

	CREATE TABLE #tCESPOfConventions (
		ConventionID INTEGER,
		EffectDate DATETIME NOT NULL,
		iTransactionType INTEGER,
		tiType TINYINT,
		CONSTRAINT PK_tCESPOfConv PRIMARY KEY (ConventionID, iTransactionType, tiType))

	CREATE TABLE #tCESPOfConventionsNotSendToPCEE (
		ConventionID INTEGER,
		EffectDate DATETIME NOT NULL,
		iTransactionType INTEGER,
		tiType TINYINT,
		CONSTRAINT PK_tCESPOfConvNotSend PRIMARY KEY (ConventionID, iTransactionType, tiType))

	BEGIN TRANSACTION
	
	IF @iReturn > 0 AND @bReSend = 1
	BEGIN
		CREATE TABLE #tConvInForceDate (
			ConventionID INTEGER,
			InForceDate DATETIME NULL,
			iTransactionType INTEGER,
			tiType TINYINT,
			CONSTRAINT PK_tConvInForce PRIMARY KEY (ConventionID, iTransactionType, tiType))

		CREATE TABLE #tConventions (
			ConventionID INTEGER,
			iTransactionType INTEGER,
			tiType TINYINT,
			CONSTRAINT PK_tConv PRIMARY KEY (ConventionID, iTransactionType, tiType))		

		INSERT INTO #tConventions
		SELECT DISTINCT V.ConventionID, iTransactionType, tiType
		FROM (
			SELECT DISTINCT
				ConventionID, 
				iTransactionType = 200,
				Un_CESP200.tiType
			FROM Un_CESP200 
			JOIN #CESP800Table CT ON CT.iCESP800ID = Un_CESP200.iCESP800ID
			UNION ALL
			SELECT DISTINCT
				ConventionID, 
				iTransactionType = 100,
				0
			FROM Un_CESP100 
			JOIN #CESP800Table CT ON CT.iCESP800ID = Un_CESP100.iCESP800ID 
			UNION ALL
			SELECT DISTINCT
				ConventionID, 
				iTransactionType = 400,
				0
			FROM Un_CESP400 
			JOIN #CESP800Table CT ON CT.iCESP800ID = Un_CESP400.iCESP800ID) V

		CREATE INDEX IX_tConventions
		ON #tConventions (ConventionID)

		INSERT INTO #tConvInForceDate
			SELECT 
				C.ConventionID,
				InForceDate = MIN(U.InForceDate),
				T.iTransactionType, 
				T.tiType
			FROM dbo.Un_Convention C
			LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN #tConventions T ON T.ConventionID = C.ConventionID
			GROUP BY C.ConventionID, T.iTransactionType, T.tiType

		CREATE INDEX IX_tConvInForceDate
		ON #tConvInForceDate (ConventionID)
			
		--Table des conventions à envoyés au PCEE
		INSERT INTO #tCESPOfConventions
			SELECT 
				C.ConventionID,
				EffectDate = -- Date d'entrée en vigueur de la convention pour le PCEE
					CASE 
						-- Avant le 1 janvier 2003 on envoi toujours la date d'entrée en vigueur de la convention
						-- 2009-11-23 : JFG :WHEN I.InForceDate < '2003-01-01' THEN I.InForceDate
						-- La date d'entrée en vigueur de la convention est la récente c'est donc elle qu'on envoit
						WHEN I.InForceDate > MIN(SSN.EffectDate) AND I.InForceDate > MIN(BSN.EffectDate) AND I.InForceDate > B.BirthDate THEN I.InForceDate
						-- La date de naissance du bénéficiaire est la plus récente c'est donc elle qu'on envoit
						WHEN B.BirthDate > MIN(SSN.EffectDate) AND B.BirthDate > MIN(BSN.EffectDate) THEN B.BirthDate
						-- La date d'inscription du NAS du souscripteur est la plus récente c'est donc elle qu'on envoit
						WHEN MIN(SSN.EffectDate) > MIN(BSN.EffectDate) THEN MIN(SSN.EffectDate)
					-- La date d'inscription du NAS du bénéficiaire est la plus récente c'est donc elle qu'on envoit
					ELSE MIN(BSN.EffectDate)
					END,
				I.iTransactionType, 
				I.tiType
			FROM #tConvInForceDate I 
			JOIN dbo.Un_Convention C ON I.ConventionID = C.ConventionID
			JOIN ( -- On s'assure que la convention a déjà été en état REEE
				SELECT DISTINCT
					CS.ConventionID
				FROM Un_ConventionConventionState CS
				WHERE CS.ConventionStateID = 'REE'
				) CSS ON CSS.ConventionID = C.ConventionID
			JOIN Un_HumanSocialNumber SSN ON SSN.HumanID = C.SubscriberID
			JOIN Un_HumanSocialNumber BSN ON BSN.HumanID = C.BeneficiaryID
			JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
			JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
			WHERE	C.bSendToCESP <> 0 -- À envoyer au PCEE
				AND I.InForceDate IS NOT NULL
				AND ISNULL(S.SocialNumber,'') <> ''
				AND ISNULL(B.SocialNumber,'') <> ''
			GROUP BY 
				C.ConventionID, 
				I.InForceDate,
				B.BirthDate,
				I.iTransactionType, 
				I.tiType

		CREATE INDEX IX_tCESPOfConventions
		ON #tCESPOfConventions (ConventionID)

		--Table des conventions qui auraient été envoyées au PCEE si ce n'numéros que de la case à cocher "A envoyer au PCEE"
		INSERT INTO #tCESPOfConventionsNotSendToPCEE
			SELECT 
				C.ConventionID,
				EffectDate = -- Date d'entrée en vigueur de la convention pour le PCEE
					CASE 
						-- Avant le 1 janvier 2003 on envoi toujours la date d'entrée en vigueur de la convention
						-- 2009-11-23 : JFG : WHEN I.InForceDate < '2003-01-01' THEN I.InForceDate
						-- La date d'entr‚e en vigueur de la convention est la récente c'est donc elle qu'on envoit
						WHEN I.InForceDate > MIN(SSN.EffectDate) AND I.InForceDate > MIN(BSN.EffectDate) AND I.InForceDate > B.BirthDate THEN I.InForceDate
						-- La date de naissance du bénéficiare est la plus récente c'est donc elle qu'on envoit
						WHEN B.BirthDate > MIN(SSN.EffectDate) AND B.BirthDate > MIN(BSN.EffectDate) THEN B.BirthDate
						-- La date d'inscription du NAS du souscripteur est la plus récente c'est donc elle qu'on envoit
						WHEN MIN(SSN.EffectDate) > MIN(BSN.EffectDate) THEN MIN(SSN.EffectDate)
					-- La date d'inscription du NAS du bénéficiare est la plus récente c'est donc elle qu'on envoit
					ELSE MIN(BSN.EffectDate)
					END,
				I.iTransactionType, 
				I.tiType
			FROM #tConvInForceDate I 
			JOIN dbo.Un_Convention C ON I.ConventionID = C.ConventionID
			JOIN ( -- On s'assure que la convention a déjà été en état REEE
				SELECT DISTINCT
					CS.ConventionID
				FROM Un_ConventionConventionState CS
				WHERE CS.ConventionStateID = 'REE'
				) CSS ON CSS.ConventionID = C.ConventionID
			JOIN Un_HumanSocialNumber SSN ON SSN.HumanID = C.SubscriberID
			JOIN Un_HumanSocialNumber BSN ON BSN.HumanID = C.BeneficiaryID
			JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
			JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
			WHERE I.InForceDate IS NOT NULL
				AND ISNULL(S.SocialNumber,'') <> ''
				AND ISNULL(B.SocialNumber,'') <> ''
			GROUP BY 
				C.ConventionID, 
				I.InForceDate,
				B.BirthDate,
				I.iTransactionType, 
				I.tiType

		CREATE INDEX IX_tCESPOfConventionsNotSendToPCEE
		ON #tCESPOfConventionsNotSendToPCEE (ConventionID)
		
		IF @iReturn > 0
		AND EXISTS (
			-- Vérifie si on doit supprimer les enregistrements 400 de demande de BEC non-expédiés (d'autres seront insérés pour les remplacer)
			SELECT iCESP400ID
			FROM Un_CESP400
			JOIN #tConvInForceDate C ON C.ConventionID = Un_CESP400.ConventionID
			WHERE Un_CESP400.iCESPSendFileID IS NULL
				AND Un_CESP400.tiCESP400TypeID = 24 -- BEC
			)
		BEGIN
               PRINT 'Supprime les enregistrements 400 de demande de BEC non-expédiés'
			-- Supprime les enregistrements 400 de demande de BEC non-expédiés (d'autres seront insérés pour les remplacer)
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN #tConvInForceDate C ON C.ConventionID = Un_CESP400.ConventionID
			WHERE Un_CESP400.iCESPSendFileID IS NULL
				AND Un_CESP400.tiCESP400TypeID = 24 -- BEC
	
			IF @@ERROR <> 0
				SET @iReturn = -15
		END
	
		IF @iReturn > 0
		AND EXISTS (
			-- Vérifie si on doit supprimer les enregistrements 200 non-expédiés (d'autres seront insérés pour les remplacer)
			SELECT iCESP200ID
			FROM Un_CESP200
			JOIN #tConvInForceDate C ON C.ConventionID = Un_CESP200.ConventionID
			WHERE Un_CESP200.iCESPSendFileID IS NULL
				AND C.iTransactionType = 200
				AND C.tiType = Un_CESP200.tiType
			)
		BEGIN
               PRINT 'Supprime les enregistrements 200 non-expédiés'
			-- Supprime les enregistrements 200 non-expédiés (d'autres seront insérés pour les remplacer)
			DELETE Un_CESP200
			FROM Un_CESP200
			JOIN #tConvInForceDate C ON C.ConventionID = Un_CESP200.ConventionID
			WHERE Un_CESP200.iCESPSendFileID IS NULL
				AND C.iTransactionType = 200
				AND C.tiType = Un_CESP200.tiType
	
			IF @@ERROR <> 0
				SET @iReturn = -16
		END
	
		IF @iReturn > 0
		AND EXISTS (
			-- Vérifie si on doit supprimer les enregistrements 100 non-expédiés (d'autres seront insérés pour les remplacer)
			SELECT iCESP100ID
			FROM Un_CESP100
			JOIN #tConvInForceDate C ON C.ConventionID = Un_CESP100.ConventionID
			WHERE Un_CESP100.iCESPSendFileID IS NULL
				AND C.iTransactionType = 100
			)
		BEGIN
               PRINT 'Supprime les enregistrements 100 non-expédiés'
			-- Supprime les enregistrements 100 non-expédiés (d'autres seront insérés pour les remplacer)
			DELETE Un_CESP100
			FROM Un_CESP100
			JOIN #tConvInForceDate C ON C.ConventionID = Un_CESP100.ConventionID
			WHERE Un_CESP100.iCESPSendFileID IS NULL
				AND C.iTransactionType = 200
	
			IF @@ERROR <> 0
				SET @iReturn = -17
		END

		IF EXISTS (SELECT * FROM #tCESPOfConventions)
		BEGIN
			IF @iReturn > 0
			BEGIN
                   PRINT 'Insert les enregistrements 200'
				-- Insert les enregistrements 200 (bénéficiare et souscripteur)
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
							vcCity = ISNULL(A.City,''),
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
						JOIN #tCESPOfConventions CS ON CS.ConventionID = C.ConventionID
						JOIN Un_Plan P ON P.PlanID = C.PlanID
						JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
						JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
						JOIN Mo_Country Co ON Co.CountryID = A.CountryID
						JOIN Mo_State ST ON ST.StateName = A.StateName
						JOIN dbo.Mo_Human T ON T.HumanID = B.iTutorID
						WHERE CS.tiType = 3
							AND CS.iTransactionType = 200
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
							vcCity = ISNULL(A.City,''),
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
						JOIN #tCESPOfConventions CS ON CS.ConventionID = C.ConventionID
						JOIN Un_Plan P ON P.PlanID = C.PlanID
						JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
						JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
						JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
						JOIN Mo_Country Co ON Co.CountryID = A.CountryID
						JOIN Mo_State ST ON ST.StateName = A.StateName
						WHERE CS.tiType = 4
							AND CS.iTransactionType = 200
						) V
					LEFT JOIN (
						SELECT 
							G2.HumanID, 
							G2.ConventionID,
							G2.tiType,
							iCESPSendFileID = MAX(G2.iCESPSendFileID)
						FROM Un_CESP200 G2
						JOIN #tCESPOfConventions CS ON CS.ConventionID = G2.ConventionID
						GROUP BY
							G2.HumanID, 
							G2.ConventionID,
							G2.tiType
						) M ON M.HumanID = V.HumanID AND M.ConventionID = V.ConventionID AND M.tiType = V.tiType
					LEFT JOIN Un_CESP200 G2 ON G2.HumanID = M.HumanID AND G2.ConventionID = M.ConventionID AND G2.iCESPSendFileID = M.iCESPSendFileID AND G2.tiType = M.tiType
						
				IF @@ERROR <> 0
					SET @iReturn = -18
			END
	
			IF @iReturn > 0
			BEGIN
                   PRINT '   Inscrit le vcTransID'
				-- Inscrit le vcTransID avec le ID Ex: BEN + <iCESP200ID>.
				UPDATE Un_CESP200
				SET vcTransID = vcTransID+CAST(iCESP200ID AS VARCHAR(12))
				WHERE vcTransID IN ('BEN','SUB')
	
				IF @@ERROR <> 0
					SET @iReturn = -19
			END
			-----------------------------------------------
			-- Fin de la gestion des enregistrements 200 --
			-----------------------------------------------
	
			-------------------------------------------------
			-- Début de la gestion des enregistrements 100 --
			-------------------------------------------------
			IF @iReturn > 0
			BEGIN
                   PRINT 'Insert les enregistrements 100'
				-- Insertion d'enregistrements 100 pour les conventions
				INSERT INTO Un_CESP100 (
						ConventionID,
						vcTransID,
						dtTransaction,
						iPlanGovRegNumber,
						ConventionNo )
					SELECT
						C.ConventionID,
						'CON',
						CS.EffectDate,
						P.PlanGovernmentRegNo,
						C.ConventionNo
					FROM #tCESPOfConventions CS
					JOIN dbo.Un_Convention C ON CS.ConventionID = C.ConventionID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					LEFT JOIN (
						SELECT 
							G1.ConventionID,
							iCESPSendFileID = MAX(G1.iCESPSendFileID)
						FROM Un_CESP100 G1
						JOIN #tCESPOfConventions CS ON CS.ConventionID = G1.ConventionID
						GROUP BY
							G1.ConventionID
						) M ON M.ConventionID = C.ConventionID
					LEFT JOIN Un_CESP100 G1 ON G1.ConventionID = M.ConventionID AND G1.iCESPSendFileID = M.iCESPSendFileID
					WHERE CS.iTransactionType = 100
						
					IF @@ERROR <> 0
						SET @iReturn = -20
			END
	
			IF @iReturn > 0
			BEGIN
                   PRINT '   Inscrit le vcTransID avec le ID'
				-- Inscrit le vcTransID avec le ID CON + <iCESP100ID>.
				UPDATE Un_CESP100
				SET vcTransID = vcTransID+CAST(iCESP100ID AS VARCHAR(12))
				WHERE vcTransID = 'CON' 
	
				IF @@ERROR <> 0
					SET @iReturn = -21
			END
			-----------------------------------------------
			-- Fin de la gestion des enregistrements 100 --
			-----------------------------------------------	
			-------------------------------------------------
			-- Début de la gestion des enregistrements 400 --
			-------------------------------------------------
			IF @iReturn > 0
			BEGIN
                   PRINT 'Met à jour l''informations des enregistrements 400 qui n''ont pas été expédiés'
				-- Met à jour l'informations des enregistrements 400 qui n'ont pas été expédiés. Cela exclu les demande de BEC car 
				-- les enregistrements 400 de BEC non-expédiés ont été préalablement supprimés.
				UPDATE Un_CESP400
				SET 
					vcSubscriberSINorEN = SUBSTRING(S.SocialNumber,1,9),
					vcBeneficiarySIN = SUBSTRING(HB.SocialNumber,1,9),
					bCESPDemand = 
						CASE 
							WHEN Un_CESP400.tiCESP400TypeID = 11 THEN C.bCESGRequested
						ELSE 1
						END,
					vcPCGSINorEN =
						CASE 
							WHEN ( C.bACESGRequested <> 0 AND Un_CESP400.tiCESP400TypeID = 11 ) THEN B.vcPCGSINOrEN
						ELSE NULL
						END,
					vcPCGFirstName =
						CASE 
							WHEN ( C.bACESGRequested <> 0 AND Un_CESP400.tiCESP400TypeID = 11 ) THEN B.vcPCGFirstName
						ELSE NULL
						END,
					vcPCGLastName =
						CASE 
							WHEN ( C.bACESGRequested <> 0 AND Un_CESP400.tiCESP400TypeID = 11 ) THEN B.vcPCGLastName
						ELSE NULL
						END,
					tiPCGType =
						CASE 
							WHEN ( C.bACESGRequested <> 0 AND Un_CESP400.tiCESP400TypeID = 11 ) THEN B.tiPCGType
						ELSE NULL
						END
				FROM Un_CESP400
				JOIN dbo.Un_Convention C ON C.ConventionID = Un_CESP400.ConventionID
				JOIN #tCESPOfConventions CS ON CS.ConventionID = Un_CESP400.ConventionID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
				JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
				WHERE Un_CESP400.iCESPSendFileID IS NULL
	
				IF @@ERROR <> 0
					SET @iReturn = -22
			END
			-----------------------------------------------
			-- Fin de la gestion des enregistrements 400 --
			-----------------------------------------------
		END
	END

	IF @iReturn > 0 AND @bReSend = 1
	BEGIN	
		-- Renvoit des enregistrements 400 qui ont été corrigés
		DECLARE @BlobID INTEGER,
			@Tempstring VARCHAR(50),	-- String tampon	
			@BlobPointer BINARY(16), 	-- Pointeur sur le texte du blob
			@BlobLength INTEGER,		-- Longueur du blob
			@CotisationID INTEGER

		SET @BlobID = -1

		-- Renvoit des enregistrement 400
		DECLARE curCESP400TypeIDWithdrawReason CURSOR FOR
		SELECT DISTINCT
			C4.tiCESP400TypeID,
			C4.tiCESP400WithdrawReasonID
		FROM #CESP800Table C8T
		JOIN Un_CESP400 C4 ON C4.iCESP800ID = C8T.iCESP800ID
				
		OPEN curCESP400TypeIDWithdrawReason

		FETCH NEXT FROM curCESP400TypeIDWithdrawReason
		INTO
			@tiCESP400TypeID,
			@tiCESP400WithdrawReasonID

		WHILE @@FETCH_STATUS = 0
		BEGIN				
               PRINT '@tiCESP400TypeID : ' + LTrim(Str(@tiCESP400TypeID)) + '-' + LTrim(Str(@tiCESP400WithdrawReasonID))
			-- Insertion dans un blob des cotisations du 900 du type en cours
			INSERT INTO CRI_Blob(txBlob, dtBlob)
			SELECT '', GETDATE()

			SELECT @BlobID = SCOPE_IDENTITY()
			
			DECLARE CUR_iCESP400ID CURSOR FOR
				SELECT 
					C4.iCESP400ID,
					C4.OperID,
					C4.CotisationID,
					C4.iReversedCESP400ID
				FROM #CESP800Table C8T
				JOIN Un_CESP400 C4 ON C4.iCESP800ID = C8T.iCESP800ID
				LEFT JOIN #tCESPOfConventions CE ON CE.ConventionID = C4.ConventionID
				JOIN #tCESPOfConventionsNotSendToPCEE NCE ON NCE.ConventionID = C4.ConventionID -- Convention pouvant être envoyé au PCEE sauf si la case a coché "A envoyé au PCEE" est décoché
				WHERE (CE.ConventionID IS NOT NULL --Convention pouvant être envoyé au PCEE
							OR @from100200Tool = 1)					
					AND C4.tiCESP400TypeID = @tiCESP400TypeID
					AND (C4.tiCESP400WithdrawReasonID = @tiCESP400WithdrawReasonID
						OR (C4.tiCESP400WithdrawReasonID IS NULL
							AND @tiCESP400WithdrawReasonID IS NULL))
					AND C8T.Done = 0

			OPEN CUR_iCESP400ID

			FETCH NEXT FROM CUR_iCESP400ID
				INTO 
					@iCESP400ID,
					@OperID,
					@CotisationID,
					@iReversedCESP400ID

			WHILE @@FETCH_STATUS = 0
			BEGIN
                    PRINT '@iCESP400ID : ' + Str(@iCESP400ID)
                    PRINT '@OperID : ' + Str(@OperID)
                    PRINT '@CotisationID : ' + Str(ISNULL(@CotisationID,-1))
                    PRINT '@iReversedCESP400ID : ' + Str(ISNULL(@iReversedCESP400ID,-1))
				IF ISNULL(@CotisationID,-1) = -1 --Les PAE n'ont pas de Cotisation
					AND ISNULL(@iReversedCESP400ID,-1) < 0 --Les annulations sont traités dans IU_UN_CESP400For400					
				BEGIN
					EXECUTE IU_UN_CESP400ForOper @ConnectID, @OperID, @tiCESP400TypeID, @tiCESP400WithdrawReasonID
				END
				ELSE
				BEGIN
					SET @TempString = CONVERT(VARCHAR(50),@iCESP400ID) + ','
				
					SELECT @BlobPointer = TEXTPTR(txBlob) FROM CRI_Blob WHERE iBlobID = @BlobID
					SELECT @BlobLength = DATALENGTH(txBlob) FROM CRI_Blob WHERE iBlobID = @BlobID
					UPDATETEXT CRI_Blob.txBlob @BlobPointer @BlobLength 0 @TempString
				END

				UPDATE #CESP800Table
				SET Done = 1
				FROM #CESP800Table
				JOIN Un_CESP400 C4 ON C4.iCESP800ID = #CESP800Table.iCESP800ID
				WHERE C4.iCESP400ID = @iCESP400ID

				FETCH NEXT FROM CUR_iCESP400ID
					INTO 
						@iCESP400ID,
						@OperID,
						@CotisationID,
						@iReversedCESP400ID
			END		

			CLOSE CUR_iCESP400ID
			DEALLOCATE CUR_iCESP400ID
							
			-- S'il existe des enregistrement 400 a envoyé
			IF EXISTS (SELECT * FROM CRI_Blob WHERE iBlobID = @BlobID AND txBlob NOT LIKE '')
			BEGIN
                    PRINT 'IU_UN_CESP400For400'
				EXECUTE IU_UN_CESP400For400 @ConnectID, @BlobID, @tiCESP400TypeID, @tiCESP400WithdrawReasonID
			END

			FETCH NEXT FROM curCESP400TypeIDWithdrawReason
			INTO
				@tiCESP400TypeID,
				@tiCESP400WithdrawReasonID
		END

		CLOSE curCESP400TypeIDWithdrawReason
		DEALLOCATE curCESP400TypeIDWithdrawReason
	END	

	--Validation des corrections
	IF @iReturn > 0
	BEGIN
		-- Insère les corrections
		INSERT INTO Un_CESP800Corrected (iCESP800ID, iCorrectedConnectID, dtCorrected, bCESP400Resend)
			SELECT 
				C4A.iCESP800ID,
				@ConnectID,		
				@dtToday,
				@bReSend
			FROM #CESP800Table	
			JOIN Un_CESP400 C4A ON C4A.iCESP800ID = #CESP800Table.iCESP800ID
			JOIN Un_CESP400 C4B ON C4B.OperID = C4A.OperID
			WHERE C4B.iCESPSendFileID IS NULL  --S'assure qu'un nouvel enregistrement 400 a été créé
					AND C4B.CotisationID IS NULL
					AND C4A.CotisationID IS NULL
			-----
			UNION
			-----
			SELECT 
				C4A.iCESP800ID,
				@ConnectID,		
				@dtToday,
				@bReSend
			FROM #CESP800Table	
			JOIN Un_CESP400 C4A ON C4A.iCESP800ID = #CESP800Table.iCESP800ID
			JOIN Un_CESP400 C4B ON C4B.CotisationID = C4A.CotisationID
			WHERE C4B.iCESPSendFileID IS NULL  --S'assure qu'un nouvel enregistrement 400 a été créé
					AND C4A.CotisationID IS NOT NULL
			-----
			UNION
			-----
			SELECT 
				C4A.iCESP800ID,
				@ConnectID,		
				@dtToday,
				@bReSend
			FROM #CESP800Table	
			JOIN Un_CESP400 C4A ON C4A.iCESP800ID = #CESP800Table.iCESP800ID
			WHERE @bReSend = 0 --S'il ne fallait pas renvoyer les 400			
			-----
			UNION
			-----
			/* Les 2 SELECT suivants servent pour les enregistrements 511 */
			SELECT
				C5.iCESP800ID,
				@ConnectID,
				@dtToday,
				@bResend
			FROM #CESP800Table
			JOIN Un_CESP511 C5 ON C5.iCESP800ID = #CESP800Table.iCESP800ID
			-----
			UNION
			-----
			SELECT
				C5.iCESP800ID,
				@ConnectID,
				@dtToday,
				@bResend
			FROM #CESP800Table
			JOIN Un_CESP511 C5 ON C5.iCESP800ID = #CESP800Table.iCESP800ID
			WHERE @bResend = 0 --Inclut les enregistrements 511 à ne pas renvoyer
			/* Fin de la gestion des enregistrements 511 */
			-----
			UNION
			-----				
			SELECT 
				C1A.iCESP800ID,
				@ConnectID,		
				@dtToday,
				@bReSend
			FROM #CESP800Table	
			JOIN Un_CESP100 C1A ON C1A.iCESP800ID = #CESP800Table.iCESP800ID
			JOIN Un_CESP100 C1B ON C1B.ConventionID = C1A.ConventionID
			WHERE C1B.iCESPSendFileID IS NULL  --S'assure qu'un nouvel enregistrement 100 a été créé
			-----
			UNION
			-----
			SELECT 
				C1A.iCESP800ID,
				@ConnectID,		
				@dtToday,
				@bReSend
			FROM #CESP800Table	
			JOIN Un_CESP100 C1A ON C1A.iCESP800ID = #CESP800Table.iCESP800ID
			JOIN #tCESPOfConventionsNotSendToPCEE NCE ON NCE.ConventionID = C1A.ConventionID
			LEFT JOIN #tCESPOfConventions CE ON CE.ConventionID = C1A.ConventionID
			WHERE CE.ConventionID IS NULL --Si la convention ne fait pas partie de celle pouvant être renvoyées
			-----
			UNION
			-----
			SELECT 
				C2A.iCESP800ID,
				@ConnectID,		
				@dtToday,
				@bReSend
			FROM #CESP800Table	
			JOIN Un_CESP200 C2A ON C2A.iCESP800ID = #CESP800Table.iCESP800ID
			JOIN Un_CESP200 C2B ON C2B.ConventionID = C2A.ConventionID AND C2B.tiType = C2A.tiType
			WHERE C2B.iCESPSendFileID IS NULL  --S'assure qu'un nouvel enregistrement 200 a été créé
			-----
			UNION
			-----
			SELECT 
				C2A.iCESP800ID,
				@ConnectID,		
				@dtToday,
				@bReSend
			FROM #CESP800Table	
			JOIN Un_CESP200 C2A ON C2A.iCESP800ID = #CESP800Table.iCESP800ID
			JOIN #tCESPOfConventionsNotSendToPCEE NCE ON NCE.ConventionID = C2A.ConventionID
			LEFT JOIN #tCESPOfConventions CE ON CE.ConventionID = C2A.ConventionID
			WHERE CE.ConventionID IS NULL --Si la convention ne fait pas partie de celle pouvant être renvoyées
			-----
			UNION
			-----
			SELECT 
				C4A.iCESP800ID,
				@ConnectID,		
				@dtToday,
				@bReSend
			FROM #CESP800Table	
			JOIN Un_CESP400 C4A ON C4A.iCESP800ID = #CESP800Table.iCESP800ID
               JOIN Un_Oper O ON O.OperID = C4A.OperID
			WHERE O.OperTypeID = 'PRA'
		
		IF @@ERROR <> 0 
			SET @iReturn = -13
	END
		
	IF @iReturn > 0
	BEGIN
		-- Suppression de la table des enregistrement a traiter
		DELETE Un_CESP800ToTreat
		FROM Un_CESP800ToTreat
		JOIN Un_CESP800Corrected C8C ON C8C.iCESP800ID = Un_CESP800ToTreat.iCESP800ID

		IF @@ERROR <> 0 
			SET @iReturn = -14
	END

	--Renvoit les numéros de conventions des erreurs qui ont été inscrites comme corrigés
	--mais qui n'ont pas été renvoyées car la case à cocher "A Envoyer au PCEE" n'‚tait pas coché
	IF @from100200Tool = 1 -- à partir de l'outil des 100/1200
	BEGIN
		SELECT DISTINCT 
			C8T.iCESP800ID,
			C.ConventionNo,
			Status = 1
		FROM #CESP800Table C8T
		JOIN Un_CESP100 C1A ON C1A.iCESP800ID = C8T.iCESP800ID
		JOIN #tCESPOfConventionsNotSendToPCEE NCE ON NCE.ConventionID = C1A.ConventionID
		JOIN dbo.Un_Convention C ON C.ConventionID = C1A.ConventionID
		LEFT JOIN #tCESPOfConventions CE ON CE.ConventionID = C1A.ConventionID
		WHERE CE.ConventionID IS NULL --Si la convention ne fait pas partie de celle pouvant être renvoyées
		-----
		UNION
		-----
		SELECT DISTINCT
			C8T.iCESP800ID,
			C.ConventionNo,
			Status = 1
		FROM #CESP800Table C8T
		JOIN Un_CESP200 C2A ON C2A.iCESP800ID = C8T.iCESP800ID
		JOIN #tCESPOfConventionsNotSendToPCEE NCE ON NCE.ConventionID = C2A.ConventionID
		JOIN dbo.Un_Convention C ON C.ConventionID = C2A.ConventionID
		LEFT JOIN #tCESPOfConventions CE ON CE.ConventionID = C2A.ConventionID
		WHERE CE.ConventionID IS NULL --Si la convention ne fait pas partie de celle pouvant être renvoyées
		-----
		UNION
		-----
		SELECT DISTINCT
			C8T.iCESP800ID,
			C.ConventionNo,
			Status = 2
		FROM #CESP800Table C8T
		JOIN Un_CESP200 C2A ON C2A.iCESP800ID = C8T.iCESP800ID
		JOIN dbo.Un_Convention C ON C.ConventionID = C2A.ConventionID
		LEFT JOIN Un_CESP200 C2B ON C2A.ConventionID = C2B.ConventionID AND C2A.tiType = C2B.tiType	AND C2B.iCESPSendFileID IS NULL
		LEFT JOIN #tCESPOfConventions CE ON CE.ConventionID = C2A.ConventionID
		LEFT JOIN #tCESPOfConventionsNotSendToPCEE NCE ON NCE.ConventionID = C2A.ConventionID
		WHERE C2B.ConventionID IS NULL --L'erreur 200 n'a pas été corrigée
				AND ( (CE.ConventionID IS NOT NULL AND NCE.ConventionID IS NOT NULL)
						OR (CE.ConventionID IS NULL AND NCE.ConventionID IS NULL)) 
					--Si la convention est dans les deux tables ou n'est dans aucune des tables,
					--l'erreur retrouvée doit être de statut 2 car elle ne sera jamais de statut 1.
		-----
		UNION
		-----
		SELECT 
			C8T.iCESP800ID,
			C.ConventionNo,
			Status = 2
		FROM #CESP800Table C8T
		JOIN Un_CESP100 C1A ON C1A.iCESP800ID = C8T.iCESP800ID
		JOIN dbo.Un_Convention C ON C.ConventionID = C1A.ConventionID
		LEFT JOIN Un_CESP100 C1B ON C1B.ConventionID = C1A.ConventionID AND C1B.iCESPSendFileID IS NULL
		LEFT JOIN #tCESPOfConventions CE ON CE.ConventionID = C1A.ConventionID
		LEFT JOIN #tCESPOfConventionsNotSendToPCEE NCE ON NCE.ConventionID = C1A.ConventionID		
		WHERE C1B.ConventionID IS NULL  --L'erreur 100 n'a pas été corrigée
			AND ( (CE.ConventionID IS NOT NULL AND NCE.ConventionID IS NOT NULL)
						OR (CE.ConventionID IS NULL AND NCE.ConventionID IS NULL)) 
					--Si la convention est dans les deux tables ou n'est dans aucune des tables,
					--l'erreur retrouvée doit être de statut 2 car elle ne sera jamais de statut 1.
	END
	ELSE --A partir de l'outil des 400
	BEGIN
		SELECT DISTINCT
			C8T.iCESP800ID,
			C.ConventionNo,
			Status = 1
		FROM #CESP800Table C8T
		JOIN Un_CESP400 C4A ON C4A.iCESP800ID = C8T.iCESP800ID		
		JOIN dbo.Un_Convention C ON C.ConventionID = C4A.ConventionID
		JOIN Un_CESP800ToTreat C8 ON C8.iCESP800ID = C8T.iCESP800ID
		-- N'a pas été corrigée
	END
	
	-- Supprime les tables ayant des index pour éviter les problèmes lorsqu'appelé en boucle
	DROP TABLE #tCESPOfConventions  
	DROP TABLE #tCESPOfConventionsNotSendToPCEE
	
	IF @iReturn > 0
		COMMIT TRANSACTION	
	ELSE
		ROLLBACK TRANSACTION

	RETURN @iReturn		
END
