/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_Operation
Description         :	Création ou modification d'un opération à partir d'un blob temporaire
Valeurs de retours  :	-1 -> Le blob n'existe pas
								-2 -> Update du blob par le service par encore fait
								-3 -> Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
								-53 -> Un chèque a été émis.
								-54 -> Imporation des chèques dans le module des chèques
								-55 -> Opération barrée par le module des chèques
Note                :						2004-07-12	Bruno Lapointe		Création
								ADX0000509	IA	2004-10-04	Bruno Lapointe		Sauvegarde de raison de retrait
								ADX0001120	BR	2004-10-22	Bruno Lapointe		Correction de la sauvegarde de raison de retrait
								ADX0000510	IA	2004-11-15	Bruno Lapointe		Sauvegarde de NSF, renommé et adapté pour les 
																							opérations multiples.
								ADX0000510	IA	2004-11-16	Bruno Lapointe		Commande automatique de lettre NSF sur NSF manuel
								ADX0000575	IA	2004-11-18	Bruno Lapointe		Gestion des RES.
								ADX0000588	IA	2004-11-18	Bruno Lapointe		Gestion des AVC.
								ADX0000623	IA	2005-01-04	Bruno Lapointe		Validation des ARI et gestion PlanOper et 
																							OtherAccountOper
								ADX0000625	IA	2004-01-05	Bruno Lapointe		Gestion des RIN
								ADX0001334	BR	2005-03-14	Bruno Lapointe		Gestion date de RI sur groupe d'unités pour les RIN
								ADX0001404	BR	2005-04-19	Bruno Lapointe		Correction valeur FeeSumByUnit dans RES et OUT.
								ADX0001417	BR	2005-04-29	Bruno Lapointe		Correction valeur FeeSumByUnit dans RES et OUT.
								ADX0001482	BR	2005-06-23	Bruno Lapointe		Correction valeur SubscInsurSumByUnit dans RES et OUT.
								ADX0001492	BR	2005-06-28	Bruno Lapointe		Correction SCEE non remboursé sur NSF.
								ADX0001588	BR	2005-09-23	Bruno Lapointe		Meilleur utilisation des IDENT_CURRENT par et 
																							des SCOPE_IDENTITY()
								ADX0000753	IA	2005-10-04	Bruno Lapointe		1. Le codage de l’objet Un_ChequeSuggestion dans le 
																							blob a changé pour celui-ci :
																							Un_ChequeSuggestion;ChequeSuggestionID;OperID;HumanID;
																							2. Pour les opérations RES, TFR, OUT, RIN, RET, PAE, 
																							RGC, AVC le système expédie l’opération au module des 
																							chèques.  Il expédie aussi les destinataires 
																							originaux et les changements de destinataire.
								ADX0001596	BR	2005-10-11	Bruno Lapointe		Correction erreur causé par la correction du bogue
																							ADX0001588.
								ADX0001602	BR	2005-10-11	Bruno Lapointe		Utilisation de SCOPE_IDENTITY() au lieu de IDENT_CURRENT().
								ADX0001620	BR	2005-10-18	Bruno Lapointe		Correction : Lettre NSF qui ne s'envoit pas.
								ADX0001962	BR	2006-06-12	Bruno Lapointe		Adaptation PCEE 4.3.
												2010-01-19	Jean-F. Gauthier	Ajout du champ EligibilityConditionID (table Un_Beneficiary) 
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Operation] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@BlobID INTEGER) -- ID Unique du blob (CRI_Blob) contenant les opérations à sauvegarder
AS
BEGIN
	DECLARE
		@Result INTEGER,
		@iTmpResult INTEGER,
		@OperID INTEGER,
		@OldOperID INTEGER,
		@CotisationID INTEGER,
		@OldCotisationID INTEGER,
		@bScholarshipPmt BIT,
		@bPlanOper BIT,
		@bOtherAccountOper BIT,
		@bConventionOper BIT

	-- Validation du blob
	EXECUTE @Result = VL_UN_BlobFormatOfOper @BlobID

	IF @Result > 0
	BEGIN

		-- Tables temporaires créé à partir du blob contenant l'opération
		DECLARE @OperTable TABLE (
			LigneTrans INTEGER,
			OperID INTEGER,
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
	
		-- Table temporaire des opérations sur plans
		DECLARE @PlanOperTable TABLE (
			LigneTrans INTEGER,
			PlanOperID INTEGER,
			OperID INTEGER,
			PlanID INTEGER,
			PlanOperTypeID CHAR(3),
			PlanOperAmount MONEY)

		-- Table temporaire des opérations dans les autres comptes
		DECLARE @OtherAccountOperTable TABLE (
			LigneTrans INTEGER,
			OtherAccountOperID INTEGER,
			OperID INTEGER,
			OtherAccountOperAmount MONEY)

		-- Table temporaire de paiement de bourses
		DECLARE @ScholarshipPmtTable TABLE (
			ScholarshipPmtID INTEGER,
			OperID INTEGER,
			ScholarshipID INTEGER,
			CollegeID INTEGER,
			ProgramID INTEGER,
			StudyStart DATETIME,
			ProgramLength INTEGER,
			ProgramYear INTEGER,
			RegistrationProof BIT,
			SchoolReport BIT,
			EligibilityQty INTEGER,
			CaseOfJanuary BIT,
			EligibilityConditionID	CHAR(3))	-- 2010-01-19 : JFG : Ajout

		-- Rempli la table temporaire de l'opération
		INSERT INTO @OperTable
			SELECT
				LigneTrans,
				OperID,
				ConnectID,
				OperTypeID,
				OperDate,
				IsDelete = 0
			FROM dbo.FN_UN_OperOfBlob(@BlobID)

		-- Rempli la table temporaire des cotisations
		INSERT INTO @CotisationTable
			SELECT *
			FROM dbo.FN_UN_CotisationOfBlob(@BlobID)
			
		-- Rempli la table temporaire des opérations sur conventions et des subventions
		INSERT INTO @ConventionOperTable
			SELECT *
			FROM dbo.FN_UN_ConventionOperOfBlob(@BlobID)	
	
		IF EXISTS (SELECT * FROM @ConventionOperTable )
			SET @bConventionOper = 1
		ELSE
			SET @bConventionOper = 0

		-- Rempli la table temporaire des opérations sur plans
		INSERT INTO @PlanOperTable
			SELECT *
			FROM dbo.FN_UN_PlanOperOfBlob(@BlobID)	

		IF EXISTS (SELECT * FROM @PlanOperTable )
			SET @bPlanOper = 1
		ELSE
			SET @bPlanOper = 0

		-- Rempli la table temporaire des opérations dans les autres comptes
		INSERT INTO @OtherAccountOperTable
			SELECT *
			FROM dbo.FN_UN_OtherAccountOperOfBlob(@BlobID)	

		IF EXISTS (SELECT * FROM @OtherAccountOperTable )
			SET @bOtherAccountOper = 1
		ELSE
			SET @bOtherAccountOper = 0

		-- Rempli la table temporaire de paiements de bourse
		INSERT INTO @ScholarshipPmtTable
			SELECT *
			FROM dbo.FN_UN_ScholarshipPmtOfBlob(@BlobID)	

		IF EXISTS (SELECT * FROM @ScholarshipPmtTable )
			SET @bScholarshipPmt = 1
		ELSE
			SET @bScholarshipPmt = 0

		-----------------
		BEGIN TRANSACTION
		-----------------
	
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
			SET @Result = -53

		-- Opération barrée par le module des chèques
		IF EXISTS (
			SELECT OT.OperID
			FROM @OperTable OT
			JOIN Un_OperLinkToCHQOperation CO ON CO.OperID = OT.OperID
			JOIN CHQ_OperationLocked OL ON OL.iOperationID = CO.iOperationID
			)
			SET @Result = -55

		-- Opération barrée par le module des chèques
		IF EXISTS (
			SELECT 
				OperID
			FROM @OperTable
			WHERE OperTypeID = 'OUT'
			)
			SET @Result = -1

		IF @Result > 0
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
					@OldOperID
	
				-- Fait une boucle sur le curseur pour insérer toutes les nouvelles opérations
				WHILE @@FETCH_STATUS = 0 AND
						@Result > 0
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
						WHERE OperID = @OldOperID
			
					-- Va chercher l'identifiant unique de l'opération qui vient d'être créé
					IF @@ERROR = 0
						SET @OperID = SCOPE_IDENTITY()
					ELSE 
						SET @Result = -4
	
					-- Met le nouveau ID sur l'opération
					IF @Result > 0
					BEGIN
						UPDATE @OperTable
						SET OperID = @OperID
						WHERE OperID = @OldOperID
	
						IF @@ERROR <> 0
							SET @Result = -5
					END
	
					-- Met le nouveau ID dans les opérations sur conventions liées à l'opération
					IF @Result > 0
					AND @bConventionOper = 1
					BEGIN
						UPDATE @ConventionOperTable
						SET OperID = @OperID
						WHERE OperID = @OldOperID
	
						IF @@ERROR <> 0
							SET @Result = -6
					END
	
					-- Met le nouveau ID dans les cotisations liées à l'opération
					IF @Result > 0
					BEGIN
						UPDATE @CotisationTable
						SET OperID = @OperID
						WHERE OperID = @OldOperID
	
						IF @@ERROR <> 0
							SET @Result = -7
					END
	
					-- Met le nouveau ID dans les opérations sur plan liées à l'opération
					IF @Result > 0
					AND @bPlanOper = 1
					BEGIN
						UPDATE @PlanOperTable
						SET OperID = @OperID
						WHERE OperID = @OldOperID
	
						IF @@ERROR <> 0
							SET @Result = -8
					END
	
					-- Met le nouveau ID dans les opérations dans les autres comptes liées à l'opération
					IF @Result > 0
					AND @bOtherAccountOper = 1
					BEGIN
						UPDATE @OtherAccountOperTable
						SET OperID = @OperID
						WHERE OperID = @OldOperID
	
						IF @@ERROR <> 0
							SET @Result = -9
					END
	
					-- Met le nouveau ID dans les paiements de bourses liées à l'opération
					IF @Result > 0
					AND @bScholarshipPmt = 1
					BEGIN
						UPDATE @ScholarshipPmtTable
						SET OperID = @OperID
						WHERE OperID = @OldOperID
	
						IF @@ERROR <> 0
							SET @Result = -4
					END

					-- Passe à la prochaine nouvelle opération
					FETCH NEXT FROM UnOper
					INTO
						@OldOperID
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
				-- Met à jour une opération existante
				UPDATE Un_Oper SET
					OperTypeID = O.OperTypeID,
					OperDate = O.OperDate
				FROM Un_Oper
				JOIN @OperTable O ON O.OperID = Un_Oper.OperID
		
				IF @@ERROR <> 0
					SET @Result = -10
			END
		END
			
		-- Supprime les cotisations de l'opération que l'usager a enlevé
		IF @Result > 0
		BEGIN
			DELETE Un_Cotisation
			FROM Un_Cotisation
			JOIN @OperTable O ON O.OperID = Un_Cotisation.OperID
			LEFT JOIN @CotisationTable C ON C.CotisationID = Un_Cotisation.CotisationID
			WHERE C.CotisationID IS NULL

			IF @@ERROR <> 0 
				SET @Result = -11
		END
	
		-- Supprime les opérations sur conventions de l'opération que l'usager a enlevé
		IF @Result > 0
		BEGIN
			DELETE Un_ConventionOper
			FROM Un_ConventionOper
			JOIN @OperTable O ON O.OperID = Un_ConventionOper.OperID
			LEFT JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID
			WHERE C.ConventionOperID IS NULL

			IF @@ERROR <> 0 
				SET @Result = -12
		END

		-- Supprime les opérations sur plans de l'opération que l'usager a enlevé
		IF @Result > 0
		BEGIN
			DELETE Un_PlanOper
			FROM Un_PlanOper
			JOIN @OperTable O ON O.OperID = Un_PlanOper.OperID
			LEFT JOIN @PlanOperTable P ON P.PlanOperID = Un_PlanOper.PlanOperID
			WHERE P.PlanOperID IS NULL

			IF @@ERROR <> 0 
				SET @Result = -13
		END

		-- Supprime les opérations dans les autres comptes de l'opération que l'usager a enlevé
		IF @Result > 0
		BEGIN
			DELETE Un_OtherAccountOper
			FROM Un_OtherAccountOper
			JOIN @OperTable O ON O.OperID = Un_OtherAccountOper.OperID
			LEFT JOIN @OtherAccountOperTable OAO ON OAO.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID
			WHERE OAO.OtherAccountOperID IS NULL

			IF @@ERROR <> 0 
				SET @Result = -14
		END

		-- Met à jour les enregistrements de cotisation
		IF @Result > 0
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
				SET @Result = -15
		END
	
		-- Met à jour les enregistrements d'opération sur convention
		IF @Result > 0
		AND @bConventionOper = 1
		BEGIN
			UPDATE Un_ConventionOper SET
				ConventionID = C.ConventionID,
				ConventionOperTypeID = C.ConventionOperTypeID,
				ConventionOperAmount = C.ConventionOperAmount
			FROM Un_ConventionOper
			JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID AND C.ConventionOperTypeID <> 'SUB'

			IF @@ERROR <> 0 
				SET @Result = -16
		END

		-- Met à jour les enregistrements d'opération sur plan
		IF @Result > 0
		AND @bPlanOper = 1
		BEGIN
			UPDATE Un_PlanOper SET
				PlanID = PO.PlanID,
				PlanOperTypeID = PO.PlanOperTypeID,
				PlanOperAmount = PO.PlanOperAmount
			FROM Un_PlanOper
			JOIN @PlanOperTable PO ON PO.PlanOperID = Un_PlanOper.PlanOperID

			IF @@ERROR <> 0 
				SET @Result = -17
		END

		-- Met à jour les enregistrements d'opération dans les autres comptes
		IF @Result > 0
		AND @bOtherAccountOper = 1
		BEGIN
			UPDATE Un_OtherAccountOper SET
				OtherAccountOperAmount = OAO.OtherAccountOperAmount
			FROM Un_OtherAccountOper
			JOIN @OtherAccountOperTable OAO ON OAO.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID

			IF @@ERROR <> 0 
				SET @Result = -18
		END

		-- Met à jour les paiements de bourses
		IF @Result > 0
		AND @bScholarshipPmt = 1
		BEGIN
			UPDATE Un_ScholarshipPmt 
			SET
				OperID = T.OperID,
				ScholarshipID = T.ScholarshipID,
				CollegeID = T.CollegeID,
				ProgramID = T.ProgramID,
				StudyStart =
					CASE 
						WHEN ISNULL(T.StudyStart,0) <= 0 THEN NULL
					ELSE T.StudyStart
					END,
				ProgramLength = T.ProgramLength,
				ProgramYear = T.ProgramYear,
				RegistrationProof = T.RegistrationProof,
				SchoolReport = T.SchoolReport,
				EligibilityQty = T.EligibilityQty,
				CaseOfJanuary = T.CaseOfJanuary,
				EligibilityConditionID = T.EligibilityConditionID		-- 2010-01-19 : JFG : Ajout du champ
			FROM 
				Un_ScholarshipPmt
				INNER JOIN @ScholarshipPmtTable T 
					ON T.ScholarshipPmtID = Un_ScholarshipPmt.ScholarshipPmtID

			IF @@ERROR <> 0 
				SET @Result = -19
		END

		-- Insère les nouvelles transactions de cotisations de l'opération
		IF @Result > 0
		BEGIN
			-- Déclaration d'un curseur pour insérer une cotisation à la fois
			DECLARE UnCotisation CURSOR FOR
				SELECT 
					CotisationID
				FROM @CotisationTable
				WHERE CotisationID <= 0

			-- Ouverture du curseur
			OPEN UnCotisation

			-- Passe au premier enregistrement du curseur
			FETCH NEXT FROM UnCotisation
			INTO
				@OldCotisationID

			-- Fait une boucle sur le curseur pour insérer toutes les nouvelles cotisations
			WHILE @@FETCH_STATUS = 0 AND
					@Result > 0
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
						UnitID,
						OperID,
						EffectDate,
						Cotisation,
						Fee,
						BenefInsur,
						SubscInsur,
						TaxOnInsur
					FROM @CotisationTable
					WHERE CotisationID = @OldCotisationID
		
				-- Va chercher l'identifiant unique de l'opération qui vient d'être créé
				IF @@ERROR = 0
					SET @CotisationID = SCOPE_IDENTITY()
				ELSE 
					SET @Result = -20

				-- Met le nouveau ID sur la cotisation
				IF @Result > 0
				BEGIN
					UPDATE @CotisationTable
					SET CotisationID = @CotisationID
					WHERE CotisationID = @OldCotisationID

					IF @@ERROR <> 0
						SET @Result = -21
				END

				-- Passe à la prochaine nouvelle opération
				FETCH NEXT FROM UnCotisation
				INTO
					@OldCotisationID
			END

			-- Ferme le curseur	
			CLOSE UnCotisation
			DEALLOCATE UnCotisation
		END
	
		-- Insère les nouvelles transactions d'opération sur convention de l'opération
		IF @Result > 0
		AND @bConventionOper = 1
		BEGIN
			INSERT INTO Un_ConventionOper (
				ConventionID,
				OperID,
				ConventionOperTypeID,
				ConventionOperAmount)
				SELECT 
					ConventionID,
					OperID,
					ConventionOperTypeID,
					ConventionOperAmount
				FROM @ConventionOperTable
				WHERE ConventionOperID <= 0 
				  AND ConventionOperTypeID <> 'SUB'

			IF @@ERROR <> 0 
				SET @Result = -22
		END

		-- Insère les nouvelles transactions d'opération sur plan de l'opération
		IF @Result > 0
		AND @bPlanOper = 1
		BEGIN
			INSERT INTO Un_PlanOper (
				PlanID,
				OperID,
				PlanOperTypeID,
				PlanOperAmount)
				SELECT 
					PlanID,
					OperID,
					PlanOperTypeID,
					PlanOperAmount
				FROM @PlanOperTable
				WHERE PlanOperID <= 0 

			IF @@ERROR <> 0 
				SET @Result = -23
		END

		-- Insère les nouvelles transactions d'opération dans les autres comptes de l'opération
		IF @Result > 0
		AND @bOtherAccountOper = 1
		BEGIN
			INSERT INTO Un_OtherAccountOper (
				OperID,
				OtherAccountOperAmount)
				SELECT 
					OperID,
					OtherAccountOperAmount
				FROM @OtherAccountOperTable
				WHERE OtherAccountOperID = 0 

			IF @@ERROR <> 0 
				SET @Result = -24
		END

		-- Insère les nouveaux paiement de bourse de l'opération
		IF @Result > 0
		AND @bScholarshipPmt = 1
		BEGIN
			INSERT INTO Un_ScholarshipPmt (
					OperID,
					ScholarshipID,
					CollegeID,
					ProgramID,
					StudyStart,
					ProgramLength,
					ProgramYear,
					RegistrationProof,
					SchoolReport,
					EligibilityQty,
					CaseOfJanuary,
					EligibilityConditionID)		-- 2010-01-19 : JFG : ajout
				SELECT 
					OperID,
					ScholarshipID,
					CollegeID,
					ProgramID,
					StudyStart =
						CASE 
							WHEN ISNULL(StudyStart,0) <= 0 THEN NULL
						ELSE StudyStart
						END,
					ProgramLength,
					ProgramYear,
					RegistrationProof,
					SchoolReport,
					EligibilityQty,
					CaseOfJanuary,
					EligibilityConditionID		-- 2010-01-19 : JFG : ajout
				FROM @ScholarshipPmtTable
				WHERE ScholarshipPmtID = 0 

			IF @@ERROR <> 0 
				SET @Result = -25
		END

		-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de convention.
		IF @Result > 0
		AND EXISTS (
			SELECT O.OperID
			FROM @OperTable O
			WHERE O.OperTypeID IN ('RES', 'TFR', 'OUT', 'RIN', 'RET', 'PAE', 'RGC', 'AVC')
			) 
		BEGIN
			DECLARE
				@iOperID INTEGER

			DECLARE crCHQ_Operation CURSOR
			FOR
				SELECT
					O.OperID
				FROM @OperTable O
				WHERE O.OperTypeID IN ('RES', 'TFR', 'OUT', 'RIN', 'RET', 'PAE', 'RGC', 'AVC')

			OPEN crCHQ_Operation

			FETCH NEXT FROM crCHQ_Operation
			INTO
				@iOperID

			WHILE @@FETCH_STATUS = 0 AND @Result > 0
			BEGIN
				-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de
				-- convention.
				EXECUTE @iOperID = IU_UN_OperCheck @ConnectID, @iOperID

				IF @iOperID <= 0
					SET @Result = -26

				FETCH NEXT FROM crCHQ_Operation
				INTO
					@iOperID
			END

			CLOSE crCHQ_Operation
			DEALLOCATE crCHQ_Operation
		END

		IF @Result <= 0
			--------------------
			ROLLBACK TRANSACTION
			--------------------
		ELSE
			------------------
			COMMIT TRANSACTION
			------------------
	END

	IF @Result <> -1
	BEGIN
		DELETE 
		FROM CRI_Blob
		WHERE iBlobID = @BlobID
			OR dtBlob <= DATEADD(DAY,-2,GETDATE())
	
		IF @@ERROR <> 0
			SET @Result = -27 -- Erreur à la suppression du blob
	END

	RETURN @Result
END
