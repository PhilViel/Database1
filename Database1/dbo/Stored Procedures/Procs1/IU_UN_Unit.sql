
/************************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : IU_UN_Unit
Description         : Sauvegarde d'ajouts/modifications de groupes d'unités
Valeurs de retours  : >0  :	Tout à fonctionn‚
                      <=0 :	Erreur SQL
Note                :						2004-06-17	Bruno Lapointe		création
					ADX0000867	BR	2004-08-16	Bruno Lapointe		Bug report
					ADX0000868	BR	2004-08-16	Bruno Lapointe		Bug report
					ADX0000670	IA	2005-03-14	Bruno Lapointe		Ajout du champ LastDepositForDoc
					ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
					ADX0000831	IA	2006-03-23	Bruno Lapointe		Adaptation des conventions pour PCEE 4.3
					ADX0001114	IA	2006-11-17	Alain Quirion		Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate)
													                Modification du champ IntReimbMonthAdd (SmallInt) pour le champ IntReimbDateAdjust (DateTime)
					ADX0003172	UR  2008-06-25    Bruno Lapointe	Logger toujours la modification à la date d'entrée en vigueur, le nombre d'unités et du représentant
									2009-06-16  Patrick Robitaille  Ajout du champ iSous_Cat_ID pour gérer les catégories de groupes d'unités
                                    2016-05-26  Pierre-Luc Simard   Ajout des champs iID_BeneficiaireOriginal et iID_RepComActif à la création d'un groupe d'unité déjà activé
                                    2017-02-08	Donald Huppé		jira prod-7534 : nouveau param @iID_RepComActif qui contient le repid du souscripteur
 ***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Unit] (
    @ConnectID INTEGER, -- ID unique de connexion de l'usager
	@UnitID INTEGER, -- ID Unique du groupe d'unités (= 0 si on veut le créer)
	@ConventionID INTEGER, -- ID Unique de la convention à laquel appartient le groupe d'unités
	@ModalID INTEGER, -- ID Unique de la modalité de paiement
	@UnitQty MONEY, -- Quantité d'unités
	@InForceDate DATETIME, -- Date de mise en vigueur
	@SignatureDate DATETIME, -- Date de la signature du contrat
	@IntReimbDate DATETIME, -- Date du remboursement intégral (Null s'il n'a pas encore eu lieu)
	@TerminatedDate DATETIME, -- Date de la résiliation (Null si elle n'a pas encore eu lieu)
	@BenefInsurID INTEGER, -- ID Unique de l'assurance bénéficiaire (Null s'il n'y en a pas)
	@WantSubscriberInsurance INTEGER, -- Champ boolean déterminant si le souscripteur à de l'assurance souscripteur ou non
	@ActivationConnectID INTEGER, -- ID Unique de connection de l'usager qui a activé le groupe d'unités (Null si pas actif)
	@ValidationConnectID INTEGER, -- ID Unique de connection de l'usager qui a validé le groupe d'unités (Null si pas validé)
	@RepID INTEGER, -- ID Unique du représentant qui a fait la vente
	@RepResponsableID INTEGER, -- ID Unique du représentant responsable du représentant qui a fait la ventes s'il y a lieu.
	@SubscribeAmountAjustment MONEY, -- Montant à ajouter au montant souscrit réel dans les relevés de dépôts
	@SaleSourceID INTEGER, -- ID unique d'une source de vente de la table Un_SaleSource
	@LastDepositForDoc DATETIME, -- Date de dernier dépôt pour relevé et contrat
	@iSousCatID INTEGER -- ID de catégorie de groupe d'unités
	,@iID_RepComActif INTEGER = NULL)
AS
BEGIN
	DECLARE
		@iExecResult INTEGER,
		@IUnitNo VARCHAR(75),
		@LogDescTmp VARCHAR(8000),
		@LogDesc VARCHAR(8000),
		@OldTmp VARCHAR(8000),
		@NewTmp VARCHAR(8000),
		@Old_UnitQty MONEY,
		@Old_InForceDate DATETIME,
		@Old_RepID INTEGER,
		@Old_ModalID INTEGER,
		@Old_RepName VARCHAR(75),
		@New_RepName VARCHAR(75),
		@ConvInforceDate DATETIME,
		@Today DATETIME,
        @iID_BeneficiaireOriginal INT

	SET @InForceDate = dbo.fn_Mo_IsDateNull(@InForceDate)
	SET @SignatureDate = dbo.fn_Mo_IsDateNull(@SignatureDate)
	SET @TerminatedDate = dbo.fn_Mo_IsDateNull(@TerminatedDate)
	SET @IntReimbDate = dbo.fn_Mo_IsDateNull(@IntReimbDate)
	SET @LastDepositForDoc = dbo.fn_Mo_IsDateNull(@LastDepositForDoc)

	-----------------
	BEGIN TRANSACTION
	-----------------

	SET @Today = GETDATE()

	IF @BenefInsurID <= 0
		SET @BenefInsurID = NULL

	IF @RepID <= 0
		SET @RepID = NULL

	IF @RepResponsableID <= 0
		SET @RepResponsableID = NULL

	IF @SaleSourceID <= 0
		SET @SaleSourceID = NULL

	IF @ActivationConnectID <= 0
		SET @ActivationConnectID = NULL

	IF @ValidationConnectID <= 0
		SET @ValidationConnectID = NULL

	IF @UnitID = 0
	BEGIN
		SELECT
			@IUnitNo = ISNULL(MAX(ConventionNo),''),
            @iID_BeneficiaireOriginal = CASE WHEN @ActivationConnectID IS NULL THEN NULL ELSE BeneficiaryID END 
		FROM dbo.Un_Convention 
		WHERE @ConventionID = ConventionID
        GROUP BY BeneficiaryID

		IF @IUnitNo = ''
			SET @UnitID = -1
		ELSE
		BEGIN
            INSERT INTO dbo.Un_Unit (
				UnitNo,
				ConventionID,
				ModalID,
				UnitQty,
				InForceDate,				
				SignatureDate,
				IntReimbDate,
				TerminatedDate,
				BenefInsurID,
				WantSubscriberInsurance,
				ActivationConnectID,
				ValidationConnectID,
				RepID,
				RepResponsableID,
				SubscribeAmountAjustment,
				SaleSourceID,
				LastDepositForDoc,
				iSous_Cat_ID,
                iID_BeneficiaireOriginal,
                iID_RepComActif)
			VALUES (
				@IUnitNo,
				@ConventionID,
				@ModalID,
				@UnitQty,
				@InForceDate,
				@SignatureDate,
				@IntReimbDate,
				@TerminatedDate,
				@BenefInsurID,
				@WantSubscriberInsurance,
				@ActivationConnectID,
				ISNULL(@ValidationConnectID,@ConnectID),
				@RepID,
				@RepResponsableID,
				@SubscribeAmountAjustment,
				@SaleSourceID,
				@LastDepositForDoc,
				@iSousCatID,
                @iID_BeneficiaireOriginal,
                CASE WHEN @ActivationConnectID IS NULL THEN NULL ELSE ISNULL(@iID_RepComActif, 149876) /*ISNULL(@RepID, 149876)*/ END)

			IF @@ERROR = 0
				SET @UnitID = SCOPE_IDENTITY()
			ELSE
				SET @UnitID = -2
            
            -- Remplir la table historique des représentants sur les commissions sur l'actif, à l'activation
            IF @UnitID > 0 
                AND @ActivationConnectID IS NOT NULL 
			BEGIN
                INSERT INTO tblCONV_HistoriqueRepComActif
                    (UnitID, dtDateDebut, RepID, LoginName)
                SELECT 
                    U.UnitID,
                    GETDATE(), 
                    U.iID_RepComActif, 
                    ISNULL(US.LoginNameID, '')
                FROM Un_Unit U
                JOIN Mo_Connect C ON C.ConnectID = U.ActivationConnectID
                JOIN Mo_User US ON US.UserID = C.UserID
                WHERE U.UnitID = @UnitID
                
                IF @@ERROR <> 0
			        SET @UnitID = -8
            END
             

			IF @UnitID > 0
			BEGIN
 				EXECUTE @iExecResult = SP_IU_UN_UnitModalHistory @ConnectID, 0, @UnitID, @ModalID, @Today

				IF @iExecResult <= 0 
					SET @UnitID = -3
			END

			IF @UnitID > 0
			BEGIN
				-- Fait un ajustement si nécessaire sur la date estimée de RI pour que la date ajustée soit la même que celle du premier groupe d'unité.
				UPDATE dbo.Un_Unit 
				SET 
					Un_Unit.IntReimbDateAdjust = 
						dbo.fn_Un_EstimatedIntReimbDate(MF.PmtByYearID, MF.PmtQty, MF.BenefAgeOnBegining, UF.InForceDate, PF.IntReimbAge, UF.IntReimbDateAdjust)
				FROM dbo.Un_Unit 
				JOIN dbo.Un_Convention C ON C.ConventionID = Un_Unit.ConventionID
				JOIN Un_Modal M ON M.ModalID = Un_Unit.ModalID
				JOIN Un_Plan P ON P.PlanID = M.PlanID
				JOIN (
					SELECT 
						I.ConventionID,
						UnitID = MIN(UnitID),	
						I.InForceDate
					FROM dbo.Un_Unit U
					JOIN (	
						SELECT 
							ConventionID,
							InForceDate = MIN(InForceDate)
						FROM dbo.Un_Unit 
						WHERE ISNULL(TerminatedDate,0) < 1
						  AND ConventionID = @ConventionID
						GROUP BY ConventionID
						) I ON I.ConventionID = U.ConventionID AND I.InForceDate = U.InForceDate
					WHERE ISNULL(U.TerminatedDate,0) < 1
					GROUP BY 
						I.ConventionID,
						I.InForceDate
					) I ON I.ConventionID = Un_Unit.ConventionID AND Un_Unit.InForceDate > I.InForceDate
				JOIN dbo.Un_Unit UF ON UF.UnitID = I.UnitID
				JOIN Un_Modal MF ON MF.ModalID = UF.ModalID
				JOIN Un_Plan PF ON PF.PlanID = MF.PlanID
				WHERE Un_Unit.UnitID = @UnitID
				  AND ISNULL(UF.TerminatedDate,0) < 1
				  AND ISNULL(UF.IntReimbDate,0) < 1
				  AND dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, Un_Unit.InForceDate, P.IntReimbAge, Un_Unit.IntReimbDateAdjust)
					<> dbo.fn_Un_EstimatedIntReimbDate(MF.PmtByYearID, MF.PmtQty, MF.BenefAgeOnBegining, UF.InForceDate, PF.IntReimbAge, UF.IntReimbDateAdjust)

				IF @@ERROR <> 0
					SET @UnitID = -4
			END
		END
	END
	ELSE
	BEGIN
		SELECT 
			@Old_ModalID = ModalID
		FROM dbo.Un_Unit 
		WHERE UnitID = @UnitID

		-- Va chercher les anciennes valeurs uniquement
		SELECT
			@Old_UnitQty = U.UnitQty,
			@Old_InForceDate = U.InForceDate,
			@Old_RepID = U.RepID,
			@Old_RepName = R.FirstName + ' ' + R.LastName
		FROM dbo.Un_Unit U
		JOIN dbo.Mo_Human R ON R.HumanID = U.RepID
		WHERE U.UnitID = @UnitID

		-- Met à jour le groupe d'unités
		UPDATE dbo.Un_Unit SET
			ConventionID = @ConventionID,
			ModalID = @ModalID,
			UnitQty = @UnitQty,
			InForceDate = @InForceDate,
			SignatureDate = @SignatureDate,
			IntReimbDate = @IntReimbDate,
			TerminatedDate = @TerminatedDate,
			BenefInsurID = @BenefInsurID,
			WantSubscriberInsurance = @WantSubscriberInsurance,
			ActivationConnectID = @ActivationConnectID,
			ValidationConnectID = @ValidationConnectID,
			RepID = @RepID,
			RepResponsableID = @RepResponsableID,
			SubscribeAmountAjustment = @SubscribeAmountAjustment,
			SaleSourceID = @SaleSourceID,
			LastDepositForDoc = @LastDepositForDoc,
			iSous_Cat_ID = @iSousCatID
		WHERE UnitID = @UnitID

		IF @@ERROR <> 0
			SET @UnitID = -5

		-- Gère l'historique des modalités de dépôts du groupe d'unités
		IF @UnitID > 0
		BEGIN
			IF @Old_ModalID <> @ModalID
			BEGIN
				EXECUTE @iExecResult = SP_IU_UN_UnitModalHistory @ConnectID, 0, @UnitID, @ModalID, @Today
			END
			ELSE
				SET @iExecResult = 1

			IF @iExecResult <= 0
				SET @UnitID = -6 
		END

		-- Garde une trace des modifications qui peuvent avoir desc implications majeures  
		IF @UnitID > 0
		AND EXISTS (
				SELECT
					UnitID
				FROM dbo.Un_Unit 
				WHERE UnitID = @UnitID
				)
		AND( @UnitQty <> @Old_UnitQty
			OR @InForceDate <> @Old_InForceDate
			OR @RepID <> @Old_RepID
			)
		BEGIN
			SET @LogDesc = ''
			
			IF @UnitQty <> @Old_UnitQty
			BEGIN
				SET @OldTmp = CAST(@Old_UnitQty AS VARCHAR)
				SET @NewTmp = CAST(@UnitQty AS VARCHAR)

				EXECUTE RUn_FormatLog 'UNITQTY', @OldTmp, @NewTmp, @LogDescTmp OUTPUT

				SET @LogDesc = @LogDesc + @LogDescTmp
			END

			IF @InForceDate <> @Old_InForceDate
			BEGIN
				SET @OldTmp = CAST(@Old_InForceDate AS VARCHAR);
				SET @NewTmp = CAST(@InForceDate AS VARCHAR);

				EXECUTE RUn_FormatLog 'INFORCEDATE', @OldTmp, @NewTmp, @LogDescTmp OUTPUT
				
				SET @LogDesc = @LogDesc + @LogDescTmp
			END

			IF @RepID <> @Old_RepID
			BEGIN
				SELECT
					@New_RepName = FirstName + ' ' + LastName
				FROM dbo.Mo_Human 
				WHERE HumanID = @RepID

				SET @OldTmp = @Old_RepName + '(' + CAST(@Old_RepID AS VARCHAR) + ')';
				SET @NewTmp = @New_RepName + '(' + CAST(@RepID AS VARCHAR) + ')';

				EXECUTE RUn_FormatLog 'REPRESENTATIVE', @OldTmp, @NewTmp, @LogDescTmp OUTPUT
				
				SET @LogDesc = @LogDesc + @LogDescTmp
			END

			EXECUTE IMo_Log @ConnectID, 'Un_Unit', @UnitID, 'U', @LogDesc;
		END
	END

	IF @UnitID > 0
	AND @InForceDate <> ISNULL(@Old_InForceDate,0) -- Si on insère le gestion se fera dans tout les cas, si on modifie, la gestion se fera uniquement si la date d'entrée en vigueur a été modifiée
	BEGIN
		-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de la convention du groupe d'unités.
		EXECUTE @iExecResult = TT_UN_CESPOfConventions @ConnectID, 0, 0, @ConventionID

		IF @iExecResult <= 0
			SET @UnitID = -7
	END

	IF @UnitID <= 0
		--------------------
		ROLLBACK TRANSACTION
		--------------------
	ELSE
		------------------
		COMMIT TRANSACTION
		------------------

	RETURN @UnitID
END


