/********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperOUT
Description         :	Procédure de sauvegarde d’ajout/modification de transfert OUT.
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.

Note                :	
	ADX0000922	IA	2006-05-23	Alain Quirion		Création
	ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900						
	ADX0001281	UP	2008-02-25	Bruno Lapointe		Permettre de changer les données du formulaires après la date de blocage.
					2008-10-02	Radu T.				Enlever les SELECT * inutiles qui causent des bugs.	
					2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
					2016-04-27  Steeve Picard		Forcer le «OtherConventionNo» en majuscule dans les tables «Un_TIN & Un_OUT»
                    2018-11-20  Steeve Picard       Ajout d'une table temporaire pour le log des blobs de transfert (à effacer en 2020)
                    2018-11-19  Steeve Picard       Ajout du ConventionID dans Un_OUT
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperOUT] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iBlobID INTEGER) -- ID Unique du blob contenant les opérations à sauvegarder
AS
BEGIN
	SET NOCOUNT ON

    --  Éliminer ce bloc de code (IF-ELSE) après juin 2019
    IF YEAR(GETDATE()) < 2020
    BEGIN
        IF OBJECT_ID('dbo._Blob_Transfert') IS NULL 
            CREATE TABLE dbo._Blob_Transfert (iBlobID INT, cOperType CHAR(3), vcLine VARCHAR(1000), dtCreate DATE)
        ELSE 
            DELETE FROM dbo._Blob_Transfert WHERE dtCreate < CAST(GETDATE() AS date)
    
        INSERT INTO dbo._Blob_Transfert
        SELECT @iBlobID, 'OUT', LEFT(vcVal, 1000), GETDATE()
          FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
    END
    ELSE IF OBJECT_ID('dbo._Blob_Transfert') IS NOT NULL 
        DROP TABLE dbo._Blob_Transfert
    
	DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@CotisationID INTEGER,
		@iConventionID INTEGER,
		@bConventionOper BIT,
		@bChequeSuggestion BIT,
		@bOtherAccountOper BIT,
		@UnitReductionID INTEGER,
		@bNewOper BIT,
		@bNewOUT BIT,
		@iOtherPlanGovRegNumber INTEGER,
		@vcOtherConventionNo VARCHAR(15)

	SET @bNewOper = 1
	SET @bNewOUT = 1
	-- Validation du blob
	EXECUTE @iResult = VL_UN_BlobFormatOfOper @iBlobID

	IF @iResult > 0
	BEGIN
		-- Tables temporaires créé à partir du blob contenant l'opération
		DECLARE @OperTable TABLE (
			LigneTrans INTEGER,
			OperID INTEGER,
			NewOperID INTEGER,
			ConnectID INTEGER,
			OperTypeID CHAR(3),
			OperDate DATETIME,
			IsDelete BIT)
	
		-- Tables temporaires créé à partir du blob contenant les opérations sur conventions et les subventions
		DECLARE @ConventionOperTable TABLE (
			LigneTrans INTEGER,
			ConventionOperID INTEGER,
			OperID INTEGER,
			ConventionID INTEGER,
			ConventionOperTypeID VARCHAR(3),
			ConventionOperAmount MONEY)
	
		-- Tables temporaires créé à partir du blob contenant les cotisations
		DECLARE @CotisationTable TABLE (
			LigneTrans INTEGER,
			CotisationID INTEGER,
			OperID INTEGER,
			UnitID INTEGER,
			EffectDate DATETIME,
			Cotisation MONEY,
			Fee MONEY,
			BenefInsur MONEY,
			SubscInsur MONEY,
			TaxOnInsur MONEY,
			bReSendToCESP BIT)

		-- Table temporaire de proposition de modification de chèque
		DECLARE @ChequeSuggestionTable TABLE (
			ChequeSuggestionID INTEGER,
			OperID INTEGER,
			iHumanID INTEGER)

		-- Table temporaire de réduction d'unités
		DECLARE @UnitReductionTable TABLE (
			UnitReductionID INTEGER,
			UnitID INTEGER,
			ReductionConnectID INTEGER,
			ReductionDate DATETIME,
			UnitQty MONEY,
			FeeSumByUnit MONEY,
			SubscInsurSumByUnit MONEY,
			UnitReductionReasonID INTEGER,
			NoChequeReasonID INTEGER)

		-- Table temporaire des opérations dans les autres comptes
		DECLARE @OtherAccountOperTable TABLE (
			LigneTrans INTEGER,
			OtherAccountOperID INTEGER,
			OperID INTEGER,
			OtherAccountOperAmount MONEY)

		DECLARE @RecipientTable TABLE (
			iRecipientID INTEGER, -- ID du destinataire, correspond au HumanID et 0 = ajout.
			FirstName VARCHAR(35), -- Prénom du destinataire
			OrigName VARCHAR(50), -- Nom à la naissance
			Initial VARCHAR(4), -- Initial (Jr, Sr, etc.)
			LastName VARCHAR(50), -- Nom
			BirthDate DATETIME, -- Date de naissance
			DeathDate DATETIME, -- Date du décès
			SexID VARCHAR(1), -- Sexe (code)
			LangID VARCHAR(3), -- Langue (code)
			CivilID VARCHAR(1), -- Statut civil (code)
			SocialNumber VARCHAR(75), -- Numéro d’assurance sociale
			ResidID VARCHAR(4), -- Pays de résidence (code)
			DriverLicenseNo VARCHAR(75), -- Numéro de permis
			WebSite VARCHAR(75), -- Site internet
			CompanyName VARCHAR(75), -- Nom de compagnie
			CourtesyTitle VARCHAR(35), -- Titre de courtoisie (Docteur, Professeur, etc.)
			UsingSocialNumber BIT, -- Droit d’utiliser le NAS.
			SharePersonalInfo BIT, -- Droit de partager les informations personnelles
			MarketingMaterial BIT, -- Veux recevoir le matériel publicitaire.
			IsCompany BIT, -- Compagny ou humain
			InForce DATETIME, -- Date d’entrée en vigueur de l’adresse.
			AdrTypeID VARCHAR(1), -- Type d’adresse (H = humain, C = Compagnie)
			SourceID INTEGER, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
			Address VARCHAR(75), -- # civique, rue et # d’appartement.
			City VARCHAR(100), -- Ville
			StateName VARCHAR(75), -- Province
			CountryID CHAR(4), -- Pays (code)
			ZipCode VARCHAR(10), -- Code postal
			Phone1 VARCHAR(27), -- Tél. résidence
			Phone2 VARCHAR(27), -- Tél. bureau
			Fax VARCHAR(15), -- Fax
			Mobile VARCHAR(15), -- Tél. cellulaire
			WattLine VARCHAR(27), -- Tél. sans frais
			OtherTel VARCHAR(27), -- Autre téléphone.
			Pager VARCHAR(15), -- Paget
			Email VARCHAR(100) ) -- Courriel
	
		-- Tables temporaires créé à partir du blob contenant les données du transfert OUT.
		DECLARE @tOUT TABLE (
            RowID INTEGER IDENTITY(1,1),
            OperID INTEGER,
            --ConventionID INT,
			ExternalPlanID INTEGER,
			tiBnfRelationWithOtherConvBnf TINYINT,
			vcOtherConventionNo VARCHAR(15),
			tiREEEType TINYINT,
			bEligibleForCESG BIT,
			bEligibleForCLB BIT,
			bOtherContratBnfAreBrothers BIT,
			fYearBnfCot MONEY,
			fBnfCot MONEY,
			fNoCESGCotBefore98 MONEY,
			fNoCESGCot98AndAfter MONEY,
			fCESGCot MONEY,
			fCESG MONEY,
			fCLB MONEY,
			fAIP MONEY,
			fMarketValue MONEY,
			bReSendToCESP BIT)

		-- Rempli la table temporaire de l'opération
		INSERT INTO @OperTable
			SELECT
				LigneTrans,
				OperID,
				OperID,
				ConnectID,
				OperTypeID,
				OperDate,
				IsDelete = 0
			FROM dbo.FN_UN_OperOfBlob(@iBlobID)
			WHERE OperTypeID IN ('OUT','TFR')

		-- Rempli la table temporaire des cotisations
		INSERT INTO @CotisationTable(
			LigneTrans,
			CotisationID,
			OperID,
			UnitID,
			EffectDate,
			Cotisation,
			Fee,
			BenefInsur,
			SubscInsur,
			TaxOnInsur
			)
			SELECT *
			FROM dbo.FN_UN_CotisationOfBlob(@iBlobID)
			
		-- Rempli la table temporaire des opérations sur conventions et des subventions
		INSERT INTO @ConventionOperTable
			SELECT *
			FROM dbo.FN_UN_ConventionOperOfBlob(@iBlobID)	
	
		IF EXISTS (SELECT * FROM @ConventionOperTable )
			SET @bConventionOper = 1
		ELSE
			SET @bConventionOper = 0

		-- Rempli la table temporaire de proposition de modification de chèque
		INSERT INTO @ChequeSuggestionTable
			SELECT *
			FROM dbo.FN_UN_ChequeSuggestionOfBlob(@iBlobID)	

		IF EXISTS (SELECT * FROM @ChequeSuggestionTable )
			SET @bChequeSuggestion = 1
		ELSE
			SET @bChequeSuggestion = 0	

		-- Rempli la table temporaire de réduction d'unités
		INSERT INTO @UnitReductionTable
			SELECT *
			FROM dbo.FN_UN_UnitReductionOfBlob(@iBlobID)

		-- Rempli la table temporaire des opérations dans les autres comptes
		INSERT INTO @OtherAccountOperTable
			SELECT *
			FROM dbo.FN_UN_OtherAccountOperOfBlob(@iBlobID)

		IF EXISTS (SELECT * FROM @OtherAccountOperTable )
			SET @bOtherAccountOper = 1
		ELSE
			SET @bOtherAccountOper = 0	

		INSERT INTO @RecipientTable
			SELECT *
			FROM dbo.FN_UN_RecipientOfBlob(@iBlobID)	

		-- Rempli la table temporaire des données de OUT
    		;WITH CTE_OUTOfBlob AS (
                SELECT V.*,
                       -- Indique si l'on doit renvoyer au PCEE si le Un_OUT a été modifié
                       CASE WHEN OU.OperID IS NULL
                                 OR ( OU.vcOtherConventionNo = V.vcOtherConventionNo
                                      AND OU.ExternalPlanID = V.ExternalPlanID
                                    ) THEN 0
                            ELSE 1 END AS bReSendToCESP
                  FROM dbo.FN_UN_OUTOfBlob(@iBlobID) V
                       LEFT JOIN Un_OUT OU ON OU.OperID = V.OperID
            )
            INSERT INTO @tOUT
			SELECT 
				V.OperID,
				V.ExternalPlanID,
				V.tiBnfRelationWithOtherConvBnf,
				V.vcOtherConventionNo,
				V.tiREEEType,
				V.bEligibleForCESG,
				V.bEligibleForCLB,
				V.bOtherContratBnfAreBrothers,
				V.fYearBnfCot,
				V.fBnfCot,
				V.fNoCESGCotBefore98,
				V.fNoCESGCot98AndAfter,
				V.fCESGCot,
				V.fCESG,
				V.fCLB,
				V.fAIP,
				V.fMarketValue,
				-- Indique si l'on doit renvoyer au PCEE si le Un_OUT a été modifié
				bReSendToCESP
            FROM 
                CTE_OUTOfBlob V
                
		IF EXISTS (	SELECT 
					OperID
				FROM @tOUT
				WHERE OperID > 0 )
				SET @bNewOUT = 0

		-- Un chèque a été émis
		IF EXISTS (
			SELECT OT.OperID
			FROM @OperTable OT
			JOIN Un_OperLinkToCHQOperation CO ON CO.OperID = OT.OperID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = CO.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
			WHERE C.iCheckStatusID NOT IN (3,5) -- Pas refusé ou annulé
			)
			SET @iResult = -1

		-- Opération barrée par le module des chèques
		IF EXISTS (
			SELECT OT.OperID
			FROM @OperTable OT
			JOIN Un_OperLinkToCHQOperation CO ON CO.OperID = OT.OperID
			JOIN CHQ_OperationLocked OL ON OL.iOperationID = CO.iOperationID
			)
			SET @iResult = -2

		-----------------
		BEGIN TRANSACTION
		-----------------

		IF EXISTS (
			SELECT *
			FROM @RecipientTable )
		BEGIN
			DECLARE
				@iResRecipient INTEGER,
				@iRecipientID INTEGER, -- ID du destinataire, correspond au HumanID et 0 = ajout.
				@FirstName VARCHAR(35), -- Prénom du destinataire
				@OrigName VARCHAR(50), -- Nom à la naissance
				@Initial VARCHAR(4), -- Initial (Jr, Sr, etc.)
				@LastName VARCHAR(50), -- Nom
				@BirthDate DATETIME, -- Date de naissance
				@DeathDate DATETIME, -- Date du décès
				@SexID VARCHAR(1), -- Sexe (code)
				@LangID VARCHAR(3), -- Langue (code)
				@CivilID VARCHAR(1), -- Statut civil (code)
				@SocialNumber VARCHAR(75), -- Numéro d’assurance sociale
				@ResidID VARCHAR(4), -- Pays de résidence (code)
				@DriverLicenseNo VARCHAR(75), -- Numéro de permis
				@WebSite VARCHAR(75), -- Site internet
				@CompanyName VARCHAR(75), -- Nom de compagnie
				@CourtesyTitle VARCHAR(35), -- Titre de courtoisie (Docteur, Professeur, etc.)
				@UsingSocialNumber BIT, -- Droit d’utiliser le NAS.
				@SharePersonalInfo BIT, -- Droit de partager les informations personnelles
				@MarketingMaterial BIT, -- Veux recevoir le matériel publicitaire.
				@IsCompany BIT, -- Compagny ou humain
				@InForce DATETIME, -- Date d’entrée en vigueur de l’adresse.
				@AdrTypeID VARCHAR(1), -- Type d’adresse (H = humain, C = Compagnie)
				@SourceID INTEGER, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
				@Address VARCHAR(75), -- # civique, rue et # d’appartement.
				@City VARCHAR(100), -- Ville
				@StateName VARCHAR(75), -- Province
				@CountryID CHAR(4), -- Pays (code)
				@ZipCode VARCHAR(10), -- Code postal
				@Phone1 VARCHAR(27), -- Tél. résidence
				@Phone2 VARCHAR(27), -- Tél. bureau
				@Fax VARCHAR(15), -- Fax
				@Mobile VARCHAR(15), -- Tél. cellulaire
				@WattLine VARCHAR(27), -- Tél. sans frais
				@OtherTel VARCHAR(27), -- Autre téléphone.
				@Pager VARCHAR(15), -- Paget
				@Email VARCHAR(100) -- Courriel

			DECLARE crRES_Recipient CURSOR
			FOR
				SELECT *
				FROM @RecipientTable
				WHERE iRecipientID = 0

			OPEN crRES_Recipient

			FETCH NEXT FROM crRES_Recipient
			INTO
				@iRecipientID,
				@FirstName,
				@OrigName,
				@Initial,
				@LastName,
				@BirthDate,
				@DeathDate,
				@SexID,
				@LangID,
				@CivilID,
				@SocialNumber,
				@ResidID,
				@DriverLicenseNo,
				@WebSite,
				@CompanyName,
				@CourtesyTitle,
				@UsingSocialNumber,
				@SharePersonalInfo,
				@MarketingMaterial,
				@IsCompany,
				@InForce,
				@AdrTypeID,
				@SourceID,
				@Address,
				@City,
				@StateName,
				@CountryID,
				@ZipCode,
				@Phone1,
				@Phone2,
				@Fax,
				@Mobile,
				@WattLine,
				@OtherTel,
				@Pager,
				@Email

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
				IF RTRIM(LTRIM(@ResidID)) = ''
					SET @ResidID = NULL

				EXECUTE @iResRecipient = IU_UN_Recipient 
						@ConnectID, 
						@iRecipientID,
						@FirstName,
						@OrigName,
						@Initial,
						@LastName,
						@BirthDate,
						@DeathDate,
						@SexID,
						@LangID,
						@CivilID,
						@SocialNumber,
						@ResidID,
						@DriverLicenseNo,
						@WebSite,
						@CompanyName,
						@CourtesyTitle,
						@UsingSocialNumber,
						@SharePersonalInfo,
						@MarketingMaterial,
						@IsCompany,
						@InForce,
						@AdrTypeID,
						@SourceID,
						@Address,
						@City,
						@StateName,
						@CountryID,
						@ZipCode,
						@Phone1,
						@Phone2,
						@Fax,
						@Mobile,
						@WattLine,
						@OtherTel,
						@Pager,
						@Email

				IF @iResRecipient <= 0
					SET @iResult = -17
				ELSE
				BEGIN
					UPDATE @ChequeSuggestionTable
					SET iHumanID = @iResRecipient
					WHERE iHumanID = @iRecipientID
				END

				FETCH NEXT FROM crRES_Recipient
				INTO
					@iRecipientID,
					@FirstName,
					@OrigName,
					@Initial,
					@LastName,
					@BirthDate,
					@DeathDate,
					@SexID,
					@LangID,
					@CivilID,
					@SocialNumber,
					@ResidID,
					@DriverLicenseNo,
					@WebSite,
					@CompanyName,
					@CourtesyTitle,
					@UsingSocialNumber,
					@SharePersonalInfo,
					@MarketingMaterial,
					@IsCompany,
					@InForce,
					@AdrTypeID,
					@SourceID,
					@Address,
					@City,
					@StateName,
					@CountryID,
					@ZipCode,
					@Phone1,
					@Phone2,
					@Fax,
					@Mobile,
					@WattLine,
					@OtherTel,
					@Pager,
					@Email
			END

			CLOSE crRES_Recipient
			DEALLOCATE crRES_Recipient
		END

		IF NOT EXISTS (	SELECT *
				FROM @OperTable ) 
		AND NOT EXISTS (SELECT *
				FROM @tOUT )
				SET @iResult = -100 -- Pas d'opération

		IF @iResult > 0
		BEGIN
			-- Vérifie si des opérations sont nouvelles
			IF EXISTS ( 
				SELECT 
					OperID
				FROM @OperTable
				WHERE OperID <= 0 )
			BEGIN
				-- Déclaration d'un curseur pour insérer une opération à la fois
				DECLARE UnOper CURSOR FOR
					SELECT 
						OperID
					FROM @OperTable
					WHERE OperID <= 0
	
				-- Ouverture du curseur
				OPEN UnOper
	
				-- Passe au premier enregistrement du curseur
				FETCH NEXT FROM UnOper
				INTO
					@OperID
	
				-- Fait une boucle sur le curseur pour insérer toutes les nouvelles opérations
				WHILE @@FETCH_STATUS = 0 AND
						@iResult > 0
				BEGIN
					-- Insertion d'une nouvelle opération
					INSERT INTO Un_Oper (
						ConnectID,
						OperTypeID,
						OperDate)
						SELECT 
							ConnectID,
							OperTypeID,
							OperDate
						FROM @OperTable
						WHERE OperID = @OperID
			
					-- Va chercher l'identifiant unique de l'opération qui vient d'être créé et l'inscrit dans la table temporaire.
					IF @@ERROR = 0
					BEGIN
						SET @iResult = SCOPE_IDENTITY()

						UPDATE @OperTable
						SET NewOperID = @iResult
						WHERE OperID = @OperID
					END

					IF @@ERROR <> 0
						SET @iResult = -4

					-- Passe à la prochaine nouvelle opération
					FETCH NEXT FROM UnOper
					INTO
						@OperID
				END
	
				-- Ferme le curseur	
				CLOSE UnOper
				DEALLOCATE UnOper
			END
	
			-- Vérifie si c'est une opération déjà existante
			ELSE IF EXISTS (
				SELECT 
					OperID
				FROM @OperTable
				WHERE OperID > 0 )
			BEGIN
				SET @bNewOper = 0
				SET @bNewOUT = 0

				SELECT @iResult = OperID
				FROM @OperTable

				-- Met à jour une opération existante
				UPDATE Un_Oper SET
					OperTypeID = O.OperTypeID,
					OperDate = O.OperDate
				FROM Un_Oper
				JOIN @OperTable O ON O.OperID = Un_Oper.OperID
		
				IF @@ERROR <> 0
					SET @iResult = -5
			END
		END

		-- Supprime les enregistrements 400 non-expédiés (d'autres seront insérés pour les remplacer)
		-- On ne supprime pas les enregistrement de subvention CESP car les montants ne peuvent pas changés
		IF @iResult > 0
		AND @bNewOUT = 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			JOIN @tOUT O ON O.OperID = Ct.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL
				AND Un_CESP400.iReversedCESP400ID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -7
		END

		-- Supprime les cotisations de l'opération que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			DELETE Un_Cotisation
			FROM Un_Cotisation
			JOIN @OperTable O ON O.OperID = Un_Cotisation.OperID
			LEFT JOIN @CotisationTable C ON C.CotisationID = Un_Cotisation.CotisationID
			WHERE C.CotisationID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -8
		END
	
		-- Supprime les opérations sur conventions de l'opération que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			DELETE Un_ConventionOper
			FROM Un_ConventionOper
			JOIN @OperTable O ON O.OperID = Un_ConventionOper.OperID
			LEFT JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID
			WHERE C.ConventionOperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -9
		END

		-- Supprime les opérations sur autres comptes de l'opération que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			DELETE Un_OtherAccountOper
			FROM Un_OtherAccountOper
			JOIN @OperTable O ON O.OperID = Un_OtherAccountOper.OperID
			LEFT JOIN @OtherAccountOperTable A ON A.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID
			WHERE A.OtherAccountOperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -10
		END

		-- Supprime les propositions de modification de chèque de l'opération que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			DELETE Un_ChequeSuggestion
			FROM Un_ChequeSuggestion
			JOIN @OperTable O ON O.OperID = Un_ChequeSuggestion.OperID
			LEFT JOIN @ChequeSuggestionTable C ON C.ChequeSuggestionID = Un_ChequeSuggestion.ChequeSuggestionID
			WHERE C.ChequeSuggestionID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -11
		END

		-- Supprime les données OUT que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOUT = 0
		BEGIN
			DELETE Un_OUT
			FROM Un_OUT
			JOIN @OperTable O ON O.OperID = Un_OUT.OperID
			LEFT JOIN @tOUT T ON T.OperID = Un_OUT.OperID
			WHERE T.OperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -12
		END

		-- Met à jour les enregistrements de cotisation
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			UPDATE Un_Cotisation SET
				UnitID = C.UnitID,
				EffectDate = C.EffectDate,
				Cotisation = C.Cotisation,
				Fee = C.Fee,
				BenefInsur = C.BenefInsur,
				SubscInsur = C.SubscInsur,
				TaxOnInsur = C.TaxOnInsur
			FROM Un_Cotisation
			JOIN @CotisationTable C ON C.CotisationID = Un_Cotisation.CotisationID

			IF @@ERROR <> 0 
				SET @iResult = -13
		END
	
		-- Met à jour les enregistrements d'opération sur convention
		IF @iResult > 0
		AND @bConventionOper = 1
		AND @bNewOper = 0
		BEGIN
			UPDATE Un_ConventionOper SET
				ConventionID = C.ConventionID,
				ConventionOperTypeID = C.ConventionOperTypeID,
				ConventionOperAmount = C.ConventionOperAmount
			FROM Un_ConventionOper
			JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID AND C.ConventionOperTypeID NOT IN ('SUB','SU+','BEC')

			IF @@ERROR <> 0 
				SET @iResult = -14
		END

		-- Met à jour les enregistrements d'opération sur autres comptes
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			UPDATE Un_OtherAccountOper SET
				OperID = A.OperID,
				OtherAccountOperAmount = A.OtherAccountOperAmount
			FROM Un_OtherAccountOper
			JOIN @OtherAccountOperTable A ON A.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID

			IF @@ERROR <> 0 
				SET @iResult = -15
		END	

		-- Met à jour les propositions de modification de chèque
		IF @iResult > 0
		AND @bChequeSuggestion = 1
		BEGIN
			UPDATE Un_ChequeSuggestion SET
				OperID = C.OperID,
				iHumanID = C.iHumanID
			FROM Un_ChequeSuggestion
			JOIN @ChequeSuggestionTable C ON C.ChequeSuggestionID = Un_ChequeSuggestion.ChequeSuggestionID

			IF @@ERROR <> 0 
				SET @iResult = -16
		END	

		-- Met à jour les données OUT
		IF @iResult > 0
		AND @bNewOUT = 0
		BEGIN
			UPDATE O SET
				ExternalPlanID = T.ExternalPlanID,
				tiBnfRelationWithOtherConvBnf = T.tiBnfRelationWithOtherConvBnf,
				vcOtherConventionNo = Upper(T.vcOtherConventionNo),
				tiREEEType = T.tiREEEType,
				bEligibleForCESG = T.bEligibleForCESG,
				bEligibleForCLB = T.bEligibleForCLB,
				bOtherContratBnfAreBrothers = T.bOtherContratBnfAreBrothers,
				fYearBnfCot = T.fYearBnfCot,
				fBnfCot = T.fBnfCot,
				fNoCESGCotBefore98 = T.fNoCESGCotBefore98,
				fNoCESGCot98AndAfter = T.fNoCESGCot98AndAfter,
				fCESGCot = T.fCESGCot,
				fCESG = T.fCESG,
				fCLB = T.fCLB,
				fAIP = T.fAIP,
				fMarketValue = T.fMarketValue
			FROM Un_OUT O
            JOIN @tOUT T ON T.OperID = O.OperID-- AND O.ConventionID = T.ConventionID 

			IF @@ERROR <> 0 
				SET @iResult = -17
		END

		-- Insère les nouvelles transactions de cotisations de l'opération
		IF @iResult > 0
		BEGIN
			-- Insertion d'une nouvelle cotisation
			INSERT INTO Un_Cotisation (
				UnitID,
				OperID,
				EffectDate,
				Cotisation,
				Fee,
				BenefInsur,
				SubscInsur,
				TaxOnInsur)
				SELECT 
					Ct.UnitID,
					O.NewOperID,
					Ct.EffectDate,
					Ct.Cotisation,
					Ct.Fee,
					Ct.BenefInsur,
					Ct.SubscInsur,
					Ct.TaxOnInsur
				FROM @CotisationTable Ct
				JOIN @OperTable O ON O.OperID = Ct.OperID
				WHERE Ct.CotisationID <= 0

			-- Erreur à l'insertion de cotisation
			IF @@ERROR <> 0
				SET @iResult = -18
		END
	
		-- Insère les nouvelles transactions d'opération sur convention de l'opération
		IF @iResult > 0
		AND @bConventionOper = 1
		BEGIN
			INSERT INTO Un_ConventionOper (
				ConventionID,
				OperID,
				ConventionOperTypeID,
				ConventionOperAmount)
				SELECT 
					CO.ConventionID,
					O.NewOperID,
					CO.ConventionOperTypeID,
					CO.ConventionOperAmount
				FROM @ConventionOperTable CO
				JOIN @OperTable O ON O.OperID = CO.OperID
				WHERE CO.ConventionOperID <= 0 
				  AND CO.ConventionOperTypeID NOT IN ('SUB','SU+','BEC')

			IF @@ERROR <> 0 
				SET @iResult = -19
		END

		-- Insère les nouvelles transactions d'autres comptes sur opération
		IF @iResult > 0
		AND @bOtherAccountOper = 1
		BEGIN		
			INSERT INTO Un_OtherAccountOper (				
				OperID,
				OtherAccountOperAmount)
				SELECT 					
					O.NewOperID,
					A.OtherAccountOperAmount
				FROM @OtherAccountOperTable A
				JOIN @OperTable O ON O.OperID = A.OperID
				WHERE A.OtherAccountOperID <= 0

			-- Erreur à l'insertion
			IF @@ERROR <> 0
				SET @iResult = -20
		END

		-- Gére l'insertion ou la modification des montants de PCEE.
		-- Il doit toujours avoir un enregistrement de subvention CESP sur les OUT
		IF @iResult > 0
		BEGIN
			DECLARE
				@fCESG MONEY,
				@fACESG MONEY,
				@fCLB MONEY,
				@fCESGCot MONEY,
				@iCESPID INTEGER,
				@ConventionID INTEGER,
				@NewOperID INTEGER

			--SELECT * FROM @ConventionOperTable

			SELECT
				@ConventionID = MAX(C.ConventionID),
				@iCESPID = MAX(C.ConventionOperID),
				@NewOperID = MAX(O.NewOperID),
				@fCESG = 
					SUM(
						CASE 
							WHEN ConventionOperTypeID = 'SUB' THEN C.ConventionOperAmount
						ELSE 0
						END
						),
				@fACESG = 
					SUM(
						CASE 
							WHEN ConventionOperTypeID = 'SU+' THEN C.ConventionOperAmount
						ELSE 0
						END
						),
				@fCLB = 
					SUM(
						CASE 
							WHEN ConventionOperTypeID = 'BEC' THEN C.ConventionOperAmount
						ELSE 0
						END
						)
			FROM @ConventionOperTable C
			JOIN @OperTable O ON O.OperID = C.OperID
			WHERE C.ConventionOperTypeID IN ('SUB','SU+','BEC')

			-- Pas d'opération sur convention, on va chercher le ConventionID par la cotisation
			IF ISNULL(@ConventionID,0) <= 0
				SELECT @ConventionID = U.ConventionID
				FROM @CotisationTable CT
				JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID

			--SELECT NewOper = @NewOperID

			--SELECT *
			--FROM @OperTable

			-- Pas d'opération sur convention, on va chercher le NewOperID différemment
			IF ISNULL(@NewOperID,0) <= 0
				SELECT @NewOperID = NewOperID
				FROM @OperTable
				WHERE OperTypeID = 'OUT'

			SET @iCESPID = ISNULL(@iCESPID,0)
			SET @fCESG = ISNULL(@fCESG,0)
			SET @fACESG = ISNULL(@fACESG,0)
			SET @fCLB = ISNULL(@fCLB,0)

			SET @fCESGCot = 0

			SELECT
				@fCESGCot = fCESGCot,
				@OperID = OperID
			FROM @tOUT

			--ALTER TABLE Un_CESP 
			--	DISABLE TRIGGER TUn_CESP
			IF object_id('tempdb..#DisableTrigger') is null
				CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

			INSERT INTO #DisableTrigger VALUES('TUn_CESP')				
			
			--Mise à jour du champ CotisationGranted en tout temps
			UPDATE Un_CESP
			SET fCotisationGranted = -@fCESGCot
			FROM Un_CESP
			WHERE OperID = @OperID

			--ALTER TABLE Un_CESP 
			--	ENABLE TRIGGER TUn_CESP
		
			Delete #DisableTrigger where vcTriggerName = 'TUn_CESP'

			IF @iCESPID > 0
			BEGIN
				--Modification de l'enregistrement de subvention CESP
				UPDATE Un_CESP
				SET
					fCESG = @fCESG,
					fACESG = @fACESG,
					fCLB = @fCLB,
					fCotisationGranted = -@fCESGCot
				FROM Un_CESP
				WHERE iCESPID = @iCESPID

				IF @@ERROR <> 0 
					SET @iResult = -21
			END	
			ELSE IF @NewOperID > 0
			BEGIN
				--Va chercher la cotisation
				SELECT @CotisationID = MIN(Ct.CotisationID)
				FROM Un_Cotisation Ct
				JOIN @OperTable OT ON OT.NewOperID = Ct.OperID

				--Création d'un enregistrement de subvention CESP pour le OUT	
				INSERT INTO Un_CESP (						
						ConventionID,
						OperID,
						CotisationID,
						fCESG,
						fACESG,
						fCLB,
						fCLBFee,
						fPG,
						fCotisationGranted,
						OperSourceID)
					SELECT 						
						@ConventionID,
						@NewOperID,
						@CotisationID,
						@fCESG,
						@fACESG,
						@fCLB,
						0,
						0,
						-@fCESGCot,	
						@NewOperID
					FROM dbo.Un_Convention 
					WHERE ConventionID = @ConventionID

				IF @@ERROR <> 0 
					SET @iResult = -22	
			END		
		END

		-- Insère les nouvelles propositions de modification de chèque de l'opération
		IF @iResult > 0
		AND @bChequeSuggestion = 1
		BEGIN
			INSERT INTO Un_ChequeSuggestion (
					OperID,
					iHumanID )
				SELECT 
					O.NewOperID,
					iHumanID
				FROM @ChequeSuggestionTable T
				JOIN @OperTable O ON O.OperID = T.OperID
				WHERE ChequeSuggestionID <= 0 

			IF @@ERROR <> 0 
				SET @iResult = -23
		END

		-- Insère les nouvelles transactions d'opération OUT
		IF @iResult > 0
		AND @bNewOUT = 1
		BEGIN
			INSERT INTO Un_OUT (
					OperID, 
                    ConventionID,
                    ExternalPlanID,
					tiBnfRelationWithOtherConvBnf,
					vcOtherConventionNo,
					tiREEEType,
					bEligibleForCESG,
					bEligibleForCLB,
					bOtherContratBnfAreBrothers,
					fYearBnfCot,
					fBnfCot,
					fNoCESGCotBefore98,
					fNoCESGCot98AndAfter,
					fCESGCot,
					fCESG,
					fCLB,
					fAIP,
					fMarketValue)
				SELECT 
					O.NewOperID, 
                    C.ConventionID, 
					T.ExternalPlanID,
					T.tiBnfRelationWithOtherConvBnf,
					Upper(T.vcOtherConventionNo),
					T.tiREEEType,
					T.bEligibleForCESG,
					T.bEligibleForCLB,
					T.bOtherContratBnfAreBrothers,
					T.fYearBnfCot,
					T.fBnfCot,
					T.fNoCESGCotBefore98,
					T.fNoCESGCot98AndAfter,
					T.fCESGCot,
					T.fCESG,
					T.fCLB,
					T.fAIP,
					T.fMarketValue
				FROM @tOUT T
				JOIN @OperTable O ON O.OperID = T.OperID
				LEFT JOIN Un_OUT TI ON TI.OperID = T.OperID
                LEFT JOIN (
                    SELECT 
                        V.OperID,
                        ConventionID = MIN(COALESCE(C.ConventionID, CO.ConventionID, U.ConventionID))
                    FROM @tOUT V
                    LEFT JOIN dbo.Un_CESP C ON C.OperID = V.OperID
                    LEFT JOIN dbo.Un_ConventionOper CO ON CO.OperID = V.OperID
                    LEFT JOIN dbo.Un_Cotisation Ct ON Ct.OperID = V.OperID
                    LEFT JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                    LEFT JOIN (SELECT ConventionID FROM dbo.Un_CESP GROUP BY ConventionID HAVING SUM(fACESG) > 0) X ON X.ConventionID = C.ConventionID
                    GROUP BY V.OperID
                    ) C ON C.OperID = T.OperID
				WHERE TI.OperID IS NULL -- N'existe pas encore

			IF @@ERROR <> 0 
				SET @iResult = -24
		END

		-- Diminue le nombre d'unité sur le groupe d'unités
		IF @iResult > 0
		AND EXISTS(
				SELECT *
				FROM @UnitReductionTable)
		BEGIN
			UPDATE dbo.Un_Unit 
			SET 
				UnitQty = Un_Unit.UnitQty - UT.UnitQty
			FROM dbo.Un_Unit 
			JOIN @UnitReductionTable UT ON UT.UnitID = Un_Unit.UnitID
			WHERE UT.UnitReductionID = 0

			IF @@ERROR <> 0 
				SET @iResult = -25
		END

		-- Met la date de résiliation s'il y lieu sur le groupe d'unités
		IF @iResult > 0
		AND EXISTS(
				SELECT *
				FROM @UnitReductionTable)
		BEGIN
			UPDATE dbo.Un_Unit 
			SET 
				TerminatedDate = UT.ReductionDate
			FROM dbo.Un_Unit 
			JOIN @UnitReductionTable UT ON UT.UnitID = Un_Unit.UnitID
			WHERE UT.UnitReductionID = 0
				AND Un_Unit.UnitQty = 0

			IF @@ERROR <> 0 
				SET @iResult = -26
		END
		-- Insère les nouvelles réduction d'unités de l'opération
		IF @iResult > 0
		AND EXISTS(
				SELECT *
				FROM @UnitReductionTable
				WHERE UnitReductionID = 0
				)
		BEGIN
			INSERT INTO Un_UnitReduction (
					UnitID,
					ReductionConnectID,
					ReductionDate,
					UnitQty,
					FeeSumByUnit,
					SubscInsurSumByUnit,
					UnitReductionReasonID,
					NoChequeReasonID)
				SELECT 
					UnitID,
					ReductionConnectID,
					ReductionDate =
						CASE 
							WHEN ISNULL(ReductionDate,0) <= 0 THEN GETDATE()
						ELSE ReductionDate
						END,
					UnitQty,
					FeeSumByUnit,
					SubscInsurSumByUnit,
					UnitReductionReasonID =
						CASE 
							WHEN ISNULL(UnitReductionReasonID,0) <= 0 THEN NULL
						ELSE UnitReductionReasonID
						END,
					NoChequeReasonID =
						CASE 
							WHEN ISNULL(NoChequeReasonID,0) <= 0 THEN NULL
						ELSE NoChequeReasonID
						END
				FROM @UnitReductionTable
				WHERE UnitReductionID = 0
	
			SET @UnitReductionID = SCOPE_IDENTITY()

			IF @@ERROR <> 0 
				SET @iResult = -27
			
			-- Inscrit le Identity dans la table temporaire
			UPDATE @UnitReductionTable
			SET UnitReductionID = @UnitReductionID

			IF @@ERROR <> 0 
				SET @iResult = -28
		END

		-- Calcul les valeurs des champs FeeSumByUnit et SubscInsurSumByUnit des réductions d'unités.
		-- Ces champs servent aux commissions.
		IF @iResult > 0
		AND EXISTS(
				SELECT *
				FROM @UnitReductionTable)
		BEGIN

			UPDATE Un_UnitReduction
			SET 
				FeeSumByUnit = ROUND(ISNULL(VF.SumFee,0)/Un_UnitReduction.UnitQty, 2), -- Divise la somme de frais remboursé dans le RES ou OUT par le nombre d'unités
				SubscInsurSumByUnit = ISNULL(VS.SumSubscInsur,0) -- Divise la somme d'assurance souscripteur remboursé dans le RES ou OUT par le nombre d'unités
			FROM Un_UnitReduction
			JOIN @UnitReductionTable UR ON UR.UnitReductionID = Un_UnitReduction.UnitReductionID
			LEFT JOIN ( -- Va chercher le montant de frais et d'assurance souscripteur des opérations OUT par réductions d'unités.
				SELECT
					UR.UnitReductionID,
					SumFee = -SUM(Ct.Fee)
				FROM @UnitReductionTable UR
				JOIN @CotisationTable Ct ON Ct.UnitID = UR.UnitID
				JOIN @OperTable O ON O.OperID = Ct.OperID
				WHERE O.OperTypeID = 'TFR'
				GROUP BY UR.UnitReductionID
				) VF ON VF.UnitReductionID = Un_UnitReduction.UnitReductionID
			LEFT JOIN ( -- Va chercher le montant de frais et d'assurance souscripteur des opérations OUT par réductions d'unités.
				SELECT
					UR.UnitReductionID,
					SumSubscInsur = ROUND(SUM(Ct.SubscInsur)/(U.UnitQty+UR.UnitQty),2)
				FROM @UnitReductionTable UR
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
				JOIN @CotisationTable CtT ON CtT.UnitID = UR.UnitID
				JOIN @OperTable OT ON OT.OperID = CtT.OperID AND OT.OperTypeID IN ('RES', 'OUT')
				JOIN Un_Cotisation Ct ON Ct.UnitID = UR.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				WHERE O.OperDate < UR.ReductionDate
					OR	( O.OperDate = UR.ReductionDate
						AND O.OperID < OT.NewOperID )
				GROUP BY
					UR.UnitReductionID,
					U.UnitQty,
					UR.UnitQty
				) VS ON VS.UnitReductionID = Un_UnitReduction.UnitReductionID
			WHERE Un_UnitReduction.UnitQty <> 0

			IF @@ERROR <> 0 
				SET @iResult = -29
		END

		-- Insère les nouveaux liens cotisations vs réductions d'unités de l'opération
		IF @iResult > 0
		BEGIN
			INSERT INTO Un_UnitReductionCotisation (
					CotisationID,
					UnitReductionID)
				SELECT DISTINCT
					Ct.CotisationID,
					@UnitReductionID
				FROM Un_Cotisation Ct
				JOIN @OperTable OT ON OT.NewOperID = Ct.OperID
				LEFT JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID AND @UnitReductionID = URC.UnitReductionID
				WHERE URC.CotisationID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -30
		END

		-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de convention.
		IF @iResult > 0
		BEGIN
			DECLARE
				@iOperID INTEGER

			DECLARE crRES_CHQ_Operation CURSOR
			FOR
				SELECT
					O.NewOperID
				FROM @OperTable O
				WHERE OperTypeID = 'OUT'

			OPEN crRES_CHQ_Operation

			FETCH NEXT FROM crRES_CHQ_Operation
			INTO
				@iOperID

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
				-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de
				-- convention.
				EXECUTE @iOperID = IU_UN_OperCheck @ConnectID, @iOperID

				IF @iOperID <= 0
					SET @iResult = -15

				FETCH NEXT FROM crRES_CHQ_Operation
				INTO
					@iOperID
			END

			CLOSE crRES_CHQ_Operation
			DEALLOCATE crRES_CHQ_Operation
		END

		-- Renverse les enregistrements 400 déjà expédiés qui ont été modifié
		IF @iResult > 0
		AND @bNewOUT = 0
		AND EXISTS (SELECT * FROM @tOUT WHERE bReSendToCESP = 1)
		BEGIN
			-- Renverse les enregistrements 400 des cotisations dont l'objet Un_OUT a été modifié
			SELECT @CotisationID = MIN(C.CotisationID)
			FROM @tOUT T
			JOIN Un_Cotisation C ON T.OperID = C.OperID
			WHERE T.bReSendToCESP = 1					

			-- Appelle la procédure de renversement pour la cotisation
			EXECUTE @iResult = IU_UN_ReverseCESP400 @ConnectID, @CotisationID, 0	
		END

		-- Trouve le bon OperID
		IF @bNewOUT = 0
		BEGIN
			SELECT @OperID = OperID
			FROM @tOUT
		END
		ELSE
			SELECT @OperID = OT.NewOperID
			FROM @OperTable OT
			JOIN @tOUT O ON O.OperID = OT.OperID

		-- Si le promoteur n'a pas signé d'entente avec le RHDCC pour administrer la SCEE OU que le régime cessionnaire 
		-- comporte plusieurs bénéficiaires qui ne sont pas tous frères et soeurs et que de la 
		-- SCEE+ a été envoyé PAE pour la convention(sur ce groupe d'unités), alors il y a création d'un enregistrement 400
		-- de remboursement avec comme raison "Transfert Inadmissible".  La SCEE et la SCEE+ seront remboursées au prorata au PCEE
		IF @iResult > 0
		AND (EXISTS ( SELECT OperID FROM @tOUT WHERE bEligibleForCESG = 0 ) --Le promoteur n'a pas signé d'entente avec le RHDCC
		OR (EXISTS ( SELECT OperID FROM @tOUT WHERE bOtherContratBnfAreBrothers = 0) --Le régime cessionnaire comporte plusieurs bénéficiaires qui ne sont pas tous frères et soeurs
			AND EXISTS (	SELECT C4.ConventionID 
					FROM (
						SELECT DISTINCT UnitID
						FROM Un_Cotisation
						WHERE OperID = @OperID
						) Ct
					JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
					JOIN Un_CESP400 C4 ON C4.ConventionID = U.ConventionID
					JOIN Un_CESP CE ON CE.OperID = C4.OperID
					WHERE C4.tiCESP400TypeID = 13 
						AND CE.fACESG <> 0 ))) -- SCEE+ envoyé PAE pour la convention(sur ce groupe d'unités)
		BEGIN
			-- Enregistrement 400 de type 21-4 Avec remboursement au prorata de la SCEE et SCEE+
			EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @OperID, 21, 4
		END

		-- Insère les enregistrements 400 sur l'opération OUT	
		IF @iResult > 0		
			EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @OperID, 23, 0

		IF @iResult <= 0
			--------------------
			ROLLBACK TRANSACTION
			--------------------
		ELSE
			------------------
			COMMIT TRANSACTION
			------------------
	END

	-- Supprime le blob des objets
	IF @iResult <> -1
	BEGIN
		DELETE 
		FROM CRI_Blob
		WHERE iBlobID = @iBlobID
			OR dtBlob <= DATEADD(DAY,-2,GETDATE())
	
		IF @@ERROR <> 0
			SET @iResult = -10 -- Erreur à la suppression du blob
	END

	RETURN @iResult

	SET NOCOUNT OFF
END