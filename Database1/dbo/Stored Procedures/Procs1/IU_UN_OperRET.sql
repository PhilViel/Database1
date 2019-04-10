/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperRET
Description         :	Procédure de sauvegarde d’ajout/modification de retraits.
Valeurs de retours  :	@ReturnValue :
								> 0 : Réussite
								<= 0 : Erreurs.

Note                :	ADX0000862	IA	2006-03-31	Bruno Lapointe			Création
						ADX0001123	IA	2006-10-06	Alain Quirion			Modification : Gestion de la raison de retrait de cotisation excédentaire
						ADX0001290	IA	2007-05-25	Alain Quirion			Modification : Ajout de l'objet Un_ChequeSuggestion
						ADX0001357	IA	2007-06-04	Alain Quirion			Création automatique de la proposition de chèque au nom de 
																			Gestion Universitas Inc. si ;e champ @bIsContestWiner = 1
										2010-03-25	Jean-François Gauthier	Modification afin d'éviter d'envoyer une transaction au PCEE
																			dans les cas de décès du souscripteur assuré
****************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperRET] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iBlobID INTEGER, -- ID du blob de la table CRI_Blob qui contient les objets de l’opération RET à sauvegarder
	@bIsContestWinner BIT) --Indique si tous les groupes d'unités du retrait sont de types gagnant de concours.
AS
BEGIN
	DECLARE
		@iResult					INTEGER,
		@OperID						INTEGER,
		@CotisationID				INTEGER,
		@bChequeSuggestion			BIT,
		@bConventionOper			BIT,
		@tiCESP400WithdrawReasonID	TINYINT,
		@bRaisonPCEE				BIT			-- 2010-03-25 : JFG : Ajout

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
	
		-- Table temporaire de raison de retrait
		DECLARE @WithdrawalReasonTable TABLE (
			LigneTrans INTEGER,
			OperID INTEGER,
			WithdrawalReasonID INTEGER,
			tiCESP400WithdrawReasonID TINYINT)

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
			WHERE OperTypeID IN ('RET')

		-- Rempli la table temporaire des raisons de retrait
		INSERT INTO @WithdrawalReasonTable
			SELECT *
			FROM dbo.FN_UN_WithdrawalReasonOfBlob(@iBlobID)	

		-- Rempli la table temporaire des cotisations
		INSERT INTO @CotisationTable
			SELECT
				V.LigneTrans,
				V.CotisationID,
				V.OperID,
				V.UnitID,
				V.EffectDate,
				V.Cotisation,
				V.Fee,
				V.BenefInsur,
				V.SubscInsur,
				V.TaxOnInsur,
				-- Les cotisations dont la somme des frais et des épargnes n'a pas changé ne doivent pas être réexpédié au PCEE
				-- Ici on marque s'ils doivent être réexpédié ou non.
				CAST	(CASE
							WHEN Ct.CotisationID IS NULL
							OR Ct.Cotisation + Ct.Fee = V.Cotisation + V.Fee THEN 0
						ELSE 1
						END AS BIT
						)
			FROM dbo.FN_UN_CotisationOfBlob(@iBlobID) V
			LEFT JOIN Un_Cotisation Ct ON Ct.CotisationID = V.CotisationID
			
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

		INSERT INTO @RecipientTable
			SELECT *
			FROM dbo.FN_UN_RecipientOfBlob(@iBlobID)	

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
					SET @iResult = -3
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
	
		IF NOT EXISTS (
			SELECT *
			FROM @OperTable )
			SET @iResult = -4

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
						SET @iResult = -5
	
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
				SELECT @iResult = OperID
				FROM @OperTable

				-- Met à jour une opération existante
				UPDATE Un_Oper SET
					OperTypeID = O.OperTypeID,
					OperDate = O.OperDate
				FROM Un_Oper
				JOIN @OperTable O ON O.OperID = Un_Oper.OperID
		
				IF @@ERROR <> 0
					SET @iResult = -6
			END
		END

		-- Supprime les enregistrements 400 non-expédiés (d'autres seront insérés pour les remplacer)
		IF @iResult > 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			JOIN @OperTable O ON O.NewOperID = Ct.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -7
		END

		-- Supprime les raisons de retrait de l'opération que l'usager a enlevé
		IF @iResult > 0
		BEGIN
			DELETE Un_WithdrawalReason
			FROM Un_WithdrawalReason
			JOIN @OperTable O ON O.OperID = Un_WithdrawalReason.OperID
			LEFT JOIN @WithdrawalReasonTable W ON W.OperID = Un_WithdrawalReason.OperID
			WHERE W.OperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -8
		END

		-- Supprime les cotisations de l'opération que l'usager a enlevé
		IF @iResult > 0
		BEGIN
			DELETE Un_Cotisation
			FROM Un_Cotisation
			JOIN @OperTable O ON O.OperID = Un_Cotisation.OperID
			LEFT JOIN @CotisationTable C ON C.CotisationID = Un_Cotisation.CotisationID
			WHERE C.CotisationID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -9
		END
	
		-- Supprime les opérations sur conventions de l'opération que l'usager a enlevé
		IF @iResult > 0
		BEGIN
			DELETE Un_ConventionOper
			FROM Un_ConventionOper
			JOIN @OperTable O ON O.OperID = Un_ConventionOper.OperID
			LEFT JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID
			WHERE C.ConventionOperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -10
		END

		--Suppresion des proposition ed changement de destinataire qui ont été supprimé lors de l'édition
		IF @iResult > 0
		BEGIN	
			DELETE CHQ_OperationPayee
			FROM CHQ_OperationPayee
			JOIN Un_OperLinkToCHQOperation OLC ON OLC.iOperationID = CHQ_OperationPayee.iOperationID
			JOIN @OperTable O ON O.OperID = OLC.OperID
			JOIN Un_ChequeSuggestion CS ON CS.OperID = O.OperID AND CS.iHumanID = CHQ_OperationPayee.iPayeeID
			LEFT JOIN @ChequeSuggestionTable C ON C.ChequeSuggestionID = CS.ChequeSuggestionID			
			WHERE C.ChequeSuggestionID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -11
		END

		-- Supprime les propositions de modification de chèque de l'opération que l'usager a enlevé
		IF @iResult > 0
		BEGIN
			DELETE Un_ChequeSuggestion
			FROM Un_ChequeSuggestion
			JOIN @OperTable O ON O.OperID = Un_ChequeSuggestion.OperID
			LEFT JOIN @ChequeSuggestionTable C ON C.ChequeSuggestionID = Un_ChequeSuggestion.ChequeSuggestionID
			WHERE C.ChequeSuggestionID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -12
		END		

		-- Met à jour les enregistrements de raison de retrait
		IF @iResult > 0
		BEGIN
			UPDATE Un_WithdrawalReason SET
				WithdrawalReasonID = W.WithdrawalReasonID,
				tiCESP400WithdrawReasonID = W.tiCESP400WithdrawReasonID
			FROM Un_WithdrawalReason
			JOIN @WithdrawalReasonTable W ON W.OperID = Un_WithdrawalReason.OperID

			IF @@ERROR <> 0 
				SET @iResult = -13
		END

		-- Met à jour les enregistrements de cotisation
		IF @iResult > 0
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
				SET @iResult = -14
		END
	
		-- Met à jour les enregistrements d'opération sur convention
		IF @iResult > 0
		AND @bConventionOper = 1
		BEGIN
			UPDATE Un_ConventionOper SET
				ConventionID = C.ConventionID,
				ConventionOperTypeID = C.ConventionOperTypeID,
				ConventionOperAmount = C.ConventionOperAmount
			FROM Un_ConventionOper
			JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID AND C.ConventionOperTypeID NOT IN ('SUB','SU+','BEC')

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

		-- Insère les nouvelles raisons de retraits de l'opération
		IF @iResult > 0
		BEGIN
			INSERT INTO Un_WithdrawalReason (
				OperID,
				WithdrawalReasonID,
				tiCESP400WithdrawReasonID)
				SELECT 
					O.NewOperID,
					E.WithdrawalReasonID,
					E.tiCESP400WithdrawReasonID
				FROM @WithdrawalReasonTable E
				JOIN @OperTable O ON O.OperID = E.OperID
				LEFT JOIN Un_WithdrawalReason T ON T.OperID = E.OperID
				WHERE T.OperID IS NULL

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

		-- Insère les nouvelles propositions de modification de chèque de l'opération
		IF @iResult > 0
		BEGIN
			INSERT INTO Un_ChequeSuggestion (
					OperID,
					iHumanID )
				SELECT 
					O.NewOperID,
					CS.iHumanID
				FROM @ChequeSuggestionTable CS
				JOIN @OperTable O ON O.OperID = CS.OperID
				WHERE CS.ChequeSuggestionID = 0 

			IF @@ERROR <> 0 
				SET @iResult = -20
		END

		IF @iResult > 0
			AND @bIsContestWinner = 1
		BEGIN
			DECLARE @HumanID INTEGER

			SELECT TOP 1 @HumanID = HumanID
			FROM dbo.Mo_Human H		
			WHERE H.LastName + ' ' + H.Firstname = 'Gestion Universitas Inc.'
			ORDER BY H.HumanID

			INSERT INTO Un_ChequeSuggestion (
				OperID,
				iHumanID )
			SELECT 
				O.NewOperID,
				@HumanID
			FROM @OperTable O	
			JOIN Un_Cotisation Ct ON Ct.OperID = O.NewOperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			WHERE O.OperTypeID = 'RET'
					AND O.OperID <= 0 --Nouvelles opéartions de retrait seulement
					AND C.SubscriberID <> @HumanID --Le souscripteur n'est pas déjà Gestion Universitas Inc.

			IF @@ERROR <> 0 
				SET @iResult = -21
		END 

		-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de convention.
		IF @iResult > 0
		BEGIN
			DECLARE
				@iOperID INTEGER

			DECLARE crRET_CHQ_Operation CURSOR
			FOR
				SELECT
					O.NewOperID
				FROM @OperTable O

			OPEN crRET_CHQ_Operation

			FETCH NEXT FROM crRET_CHQ_Operation
			INTO
				@iOperID

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
				-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de
				-- convention.
				EXECUTE @iOperID = IU_UN_OperCheck @ConnectID, @iOperID

				IF @iOperID <= 0
					SET @iResult = -22

				FETCH NEXT FROM crRET_CHQ_Operation
				INTO
					@iOperID
			END

			CLOSE crRET_CHQ_Operation
			DEALLOCATE crRET_CHQ_Operation
		END

		-- 2010-03-25 : JFG : Déplacement du code et ajout de la récupération de la valeur de bRaisonPCEE
		-- Sélectionne la raison de retrait pour l'enregistrement 400
		SELECT 
			TOP 1 
				@tiCESP400WithdrawReasonID	= tiCESP400WithdrawReasonID
		FROM	
			@WithdrawalReasonTable
		
		SELECT
			@bRaisonPCEE = r.bRaisonPCEE
		FROM
			dbo.Un_CESP400WithdrawReason r
		WHERE
			r.tiCESP400WithdrawReasonID = @tiCESP400WithdrawReasonID

		-- Renverse les enregistrements 400 déjà expédiés qui ont été modifié
		IF @iResult > 0 AND @bRaisonPCEE = 1		-- 2010-03-25 : JFG : Ajout de la validation sur @bRaisonPCEE
		BEGIN
			-- Renverse les enregistrements 400 des cotisations dont la somme des frais et des épargnes a changé
			DECLARE crCHQ_Reverse400 CURSOR
			FOR
				SELECT CotisationID
				FROM @CotisationTable
				WHERE bReSendToCESP = 1

			OPEN crCHQ_Reverse400

			FETCH NEXT FROM crCHQ_Reverse400 
			INTO @CotisationID

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
				-- Appelle la procédure de renversement pour la cotisation
				EXECUTE @iResult = IU_UN_ReverseCESP400 @ConnectID, @CotisationID, 0

				FETCH NEXT FROM crCHQ_Reverse400 
				INTO @CotisationID
			END

			CLOSE crCHQ_Reverse400
			DEALLOCATE crCHQ_Reverse400
		END

		-- 2010-03-25 : JFG : Déplacement de ce code avant la condition contenant le curseur
		-- Sélectionne la raison de retrait pour l'enregistrement 400
		-- SELECT TOP 1 @tiCESP400WithdrawReasonID = tiCESP400WithdrawReasonID
		-- FROM @WithdrawalReasonTable

		-- Insère les enregistrements 400 de type 21 sur l'opération
		IF	@bRaisonPCEE = 1	-- 2010-03-25 : JFG : Ajout de la validation sur @bRaisonPCEE
			BEGIN
				EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @iResult, 21, @tiCESP400WithdrawReasonID
			END

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
	IF @iResult > 0
	BEGIN		
		DELETE 
		FROM CRI_Blob
		WHERE iBlobID = @iBlobID
			OR dtBlob <= DATEADD(DAY,-2,GETDATE())
		
		IF @@ERROR <> 0
			SET @iResult = -21 -- Erreur à la suppression du blob
	END

	RETURN @iResult
END


