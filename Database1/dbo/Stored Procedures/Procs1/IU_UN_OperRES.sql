/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperRES
Description         :	Procédure de sauvegarde d’ajout/modification de résiliations.
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.

Note                :	ADX0000861	IA	2006-03-24	Bruno Lapointe			Création
						ADX0001351	IA	2007-04-11	Alain Quirion			Commande des lettre de résiliation sans NAS sans Cotisation automatique
						ADX0001357	IA	2007-06-04	Alain Quirion			Création automatique de la proposition de chèque au nom de 
																			Gestion Universitas Inc. si l’unité du remboursement intégral 
																			a une source de vente de type « Gagnant de concours ».
										2009-11-26	Jean-François Gauthier	Modification pour gérer les changements de bénéficiaires non-admissibles (cas 21 - 5)
										2010-01-27	Jean-François Gauthier	Ajout du 'BNA' lors du traitement du BLOB
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperRES] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iBlobID INTEGER) -- ID Unique du blob contenant les opérations à sauvegarder
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@UnitReductionID INTEGER,
		@bConventionOper BIT,
		@bOtherAccountOper BIT

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
			TaxOnInsur MONEY)
	
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
			WHERE OperTypeID IN ('RES','TFR','BNA')	-- 2010-01-27 : JFG : Ajout du BNA

		-- Insère les opérations reliés des résiliations/transferts OUT qui ne sont pas dans le blob, donc à supprimer
		INSERT INTO @OperTable
			SELECT
				LigneTrans = 0,
				O.OperID,
				O.OperID,
				O.ConnectID,
				O.OperTypeID,
				O.OperDate,
				1
			FROM @OperTable OT
			JOIN Un_Cotisation Ct ON Ct.OperID = OT.OperID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID  AND URC2.CotisationID <> URC.CotisationID
			JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
			JOIN Un_Oper O ON O.OperID = Ct2.OperID
			LEFT JOIN @OperTable OT2 ON OT2.OperID = Ct2.OperID
			WHERE OT2.OperID IS NULL

		-- Rempli la table temporaire des cotisations
		INSERT INTO @CotisationTable
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

		-- On ne gère pas les modifications de RES
		IF EXISTS (
			SELECT 
				OperID
			FROM @OperTable
			WHERE OperID > 0
			)
			SET @iResult = -3

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

		IF NOT EXISTS (
			SELECT *
			FROM @OperTable )
			SET @iResult = -100

		IF @iResult > 0
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
				SET @iResult = -5
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
				SET @iResult = -6
		END

		-- Insère les nouvelles transactions d'opération dans les autres comptes de l'opération
		IF @iResult > 0
		AND @bOtherAccountOper = 1
		BEGIN
			INSERT INTO Un_OtherAccountOper (
				OperID,
				OtherAccountOperAmount)
				SELECT 
					O.NewOperID,
					OT.OtherAccountOperAmount
				FROM @OtherAccountOperTable OT
				JOIN @OperTable O ON O.OperID = OT.OperID
				WHERE OT.OtherAccountOperID = 0 

			IF @@ERROR <> 0 
				SET @iResult = -7
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
				SET @iResult = -8
		END

		--Création de la proposition de chèque au nom de Gestion Universitas Inc. si la source de vente
		--du groupe d'unités est de type "gagnant de concours"
		IF @iResult > 0			
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
			JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID						
			WHERE SS.bIsContestWinner = 1
					AND O.OperTypeID = 'RES'
					AND O.OperID <= 0 --Lors de l'ajout seulement
					AND C.SubscriberID <> @HumanID --Le souscripteur n'est pas déjà Gestion Universitas Inc.

			IF @@ERROR <> 0 
				SET @iResult = -9
		END

		-- Diminue le nombre d'unité sur le groupe d'unités
		IF @iResult > 0
		BEGIN
			UPDATE dbo.Un_Unit 
			SET 
				UnitQty = Un_Unit.UnitQty - UT.UnitQty
			FROM dbo.Un_Unit 
			JOIN @UnitReductionTable UT ON UT.UnitID = Un_Unit.UnitID
			WHERE UT.UnitReductionID = 0

			IF @@ERROR <> 0 
				SET @iResult = -10
		END

		-- Met la date de résiliation s'il y lieu sur le groupe d'unités
		IF @iResult > 0
		BEGIN
			UPDATE dbo.Un_Unit 
			SET 
				TerminatedDate = UT.ReductionDate
			FROM dbo.Un_Unit 
			JOIN @UnitReductionTable UT ON UT.UnitID = Un_Unit.UnitID
			WHERE UT.UnitReductionID = 0
				AND Un_Unit.UnitQty = 0

			IF @@ERROR <> 0 
				SET @iResult = -11
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
				SET @iResult = -12
			
			-- Inscrit le Identity dans la table temporaire
			UPDATE @UnitReductionTable
			SET UnitReductionID = @UnitReductionID

			IF @@ERROR <> 0 
				SET @iResult = -13
		END

		-- Calcul les valeurs des champs FeeSumByUnit et SubscInsurSumByUnit des réductions d'unités.
		-- Ces champs servent aux commissions.
		IF @iResult > 0
		BEGIN
			UPDATE Un_UnitReduction
			SET 
				FeeSumByUnit = ROUND(ISNULL(VF.SumFee,0)/Un_UnitReduction.UnitQty, 2), -- Divise la somme de frais remboursé dans le RES ou OUT par le nombre d'unités
				SubscInsurSumByUnit = ISNULL(VS.SumSubscInsur,0) -- Divise la somme d'assurance souscripteur remboursé dans le RES ou OUT par le nombre d'unités
			FROM Un_UnitReduction
			JOIN @UnitReductionTable UR ON UR.UnitReductionID = Un_UnitReduction.UnitReductionID
			LEFT JOIN ( -- Va chercher le montant de frais et d'assurance souscripteur des opérations RES par réductions d'unités.
				SELECT
					UR.UnitReductionID,
					SumFee = -SUM(Ct.Fee)
				FROM @UnitReductionTable UR
				JOIN @CotisationTable Ct ON Ct.UnitID = UR.UnitID
				JOIN @OperTable O ON O.OperID = Ct.OperID
				WHERE O.OperTypeID = 'TFR'
				GROUP BY UR.UnitReductionID
				) VF ON VF.UnitReductionID = Un_UnitReduction.UnitReductionID
			LEFT JOIN ( -- Va chercher le montant de frais et d'assurance souscripteur des opérations RES par réductions d'unités.
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
				SET @iResult = -14
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
				SET @iResult = -15
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
				WHERE OperTypeID = 'RES'

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
					SET @iResult = -16

				FETCH NEXT FROM crRES_CHQ_Operation
				INTO
					@iOperID
			END

			CLOSE crRES_CHQ_Operation
			DEALLOCATE crRES_CHQ_Operation
		END

		-- Insère les enregistrements 400 sur l'opération TFR s'il y en a une
		IF @iResult > 0
		BEGIN
			-- TFR
			SET @OperID = 0

			SELECT @OperID = NewOperID
			FROM @OperTable
			WHERE OperTypeID = 'TFR'

			IF @OperID > 0
				-- Insère les enregistrements 400 de type 21 sur l'opération
				EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @OperID, 21, 1
		END

		-- Insère les enregistrements 400 sur l'opération
		IF @iResult > 0
		BEGIN
			SET @OperID = 0

			SELECT @OperID = NewOperID
			FROM @OperTable
			WHERE OperTypeID = 'RES'

			IF NOT EXISTS ( -- Vérifie s'il s'agit d'une résiliations totales
				SELECT U.ConventionID
				FROM @UnitReductionTable UT 
				JOIN dbo.Un_Unit U ON UT.UnitID = U.UnitID
				JOIN dbo.Un_Unit UC ON UC.ConventionID = U.ConventionID
				GROUP BY U.ConventionID
				HAVING SUM(UC.UnitQty) = 0
				)
			AND @OperID > 0
				BEGIN
					-- Résiliation partielles - Insère les enregistrements 400 de type 21-1 sur l'opération
					EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @OperID, 21, 1
				END
			ELSE IF @OperID > 0
				BEGIN
					-- Résiliation totales - Insère les enregistrements 400 de type 21-3 sur l'opération
					EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @OperID, 21, 3
				END

			-- 2009-11-26 : JFG
			SELECT	@OperID = NewOperID 
			FROM	@OperTable 
			WHERE	OperTypeID = 'BNA'   

			EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID , @OperID , 21, 5

		END

		--Commande des lettres de résiliation "sans NAS - aucune épargne"
		DECLARE @ConventionID INTEGER
	
		DECLARE CUR_ConventionNoNASNoCotisation	CURSOR FOR
			SELECT DISTINCT C.ConventionID
			FROM @UnitReductionTable UR			
			JOIN dbo.Un_Unit U ON UR.UnitID = U.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID		
			JOIN (	SELECT 
						CCS.ConventionID,
						MaxDate = MAX(CCS.StartDate)
					FROM Un_Cotisation Ct
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = U.ConventionID
					JOIN @OperTable OT ON OT.NewOperID = Ct.OperID					
					GROUP BY CCS.ConventionID
					) CS ON U.ConventionID = CS.ConventionID
			JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = CS.ConventionID AND CCS.StartDate = CS.MaxDate
			WHERE URR.UnitReductionReason = 'sans NAS après un (1) an'	
					AND UR.ReductionDate = ISNULL(U.TerminatedDate,0)
					AND CCS.ConventionStateID = 'FRM'
					AND Ct.Cotisation = 0.00

		OPEN CUR_ConventionNoNASNoCotisation
	
		FETCH NEXT FROM CUR_ConventionNoNASNoCotisation
		INTO
			@ConventionID

		WHILE @@FETCH_STATUS = 0 AND @iResult > 0
		BEGIN
			EXEC RP_UN_RESCheckWithoutNASAndCotisation @ConnectID, 	@ConventionID, 0

			FETCH NEXT FROM CUR_ConventionNoNASNoCotisation
			INTO
				@ConventionID
		END

		CLOSE CUR_ConventionNoNASNoCotisation
		DEALLOCATE CUR_ConventionNoNASNoCotisation		

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
			SET @iResult = -17 -- Erreur à la suppression du blob
	END

	RETURN @iResult
END


