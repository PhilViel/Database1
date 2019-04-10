/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperPAE
Description         :	Procédure de sauvegarde d’ajout/modification d'un Paiement d'Aide aux Études.
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000863	IA	2006-05-30	Alain Quirion		Création
						ADX0002381	BR	2007-04-12	Alain Quirion		Correction.  Enregistrement 900 créé si les subventions PCEE sont différente de 0 et non plus grand que 0
						ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
										2010-01-19	Jean-F. Gauthier	Ajout du champ EligibilityConditionID
						GLPI6168		2011-10-28	Eric Michaud		Impression Régime Individuel – lettre PAE	
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée
                        			
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperPAE] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iBlobID INTEGER) -- ID Unique du blob contenant les opérations à sauvegarder
AS
BEGIN

    SELECT 1/0
    /*
	DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@bConventionOper BIT,
		@bNewOper BIT,
		@ConventionID INT,
		@ConventionIDPAE INT

	SET @bNewOper = 1
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
			EligibilityConditionID	CHAR(3))

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
			WHERE OperTypeID IN ('PAE','RGC')

		-- Rempli la table temporaire des opérations sur conventions et des subventions
		INSERT INTO @ConventionOperTable
			SELECT *
			FROM dbo.FN_UN_ConventionOperOfBlob(@iBlobID)	
	
		IF EXISTS (SELECT * FROM @ConventionOperTable )
			SET @bConventionOper = 1
		ELSE
			SET @bConventionOper = 0

		-- Rempli la table temporaire de paiements de bourse
		INSERT INTO @ScholarshipPmtTable
			SELECT *
			FROM dbo.FN_UN_ScholarshipPmtOfBlob(@iBlobID)	

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
	
		IF NOT EXISTS (
			SELECT *
			FROM @OperTable )
			SET @iResult = -100

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
						SET @iResult = -21
	
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
				
				SELECT @iResult = OperID
				FROM @OperTable

				UPDATE Un_Oper SET
					OperTypeID = O.OperTypeID,
					OperDate = O.OperDate
				FROM Un_Oper
				JOIN @OperTable O ON O.OperID = Un_Oper.OperID

				IF @@ERROR <> 0
					SET @iResult = -22
			END
			ELSE
				SET @bNewOper = 0
		END

		-- Supprime les enregistrements 400 non-expédiés (d'autres seront insérés pour les remplacer)
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN

			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN @OperTable O ON O.NewOperID = Un_CESP400.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL			

			IF @@ERROR <> 0
				SET @iResult = -24
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
				SET @iResult = -26
		END
		
		-- Supprime les données PAE que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			DELETE Un_ScholarshipPmt
			FROM Un_ScholarshipPmt
			JOIN @OperTable O ON O.OperID = Un_ScholarshipPmt.OperID
			LEFT JOIN @ScholarshipPmtTable S ON S.OperID = Un_ScholarshipPmt.OperID
			WHERE S.OperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -27
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
				SET @iResult = -28
		END

		-- Met à jour les PAE
		IF @iResult > 0
		AND @bNewOper = 0
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
				EligibilityConditionID = T.EligibilityConditionID
			FROM 
				Un_ScholarshipPmt
				JOIN @ScholarshipPmtTable T 
					ON T.ScholarshipPmtID = Un_ScholarshipPmt.ScholarshipPmtID

			IF @@ERROR <> 0 
				SET @iResult = -29
		END
		
		-- Insère les nouvelles transactions d'opération sur convention de l'opération
		IF @iResult > 0
		AND @bConventionOper = 1
		AND @bNewOper = 1
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
				SET @iResult = -30
		END

		-- Bourse à créé sur individuel
		IF EXISTS (
				SELECT ScholarshipID
				FROM @ScholarshipPmtTable
				WHERE ScholarshipID <= 0
				)
		BEGIN
			DECLARE
				@mySumScholarhip MONEY,
				@iScholarshipNo INTEGER,
				@iConventionID INTEGER,
				@iScholarshipID INTEGER

			SELECT @iConventionID = MAX(ConventionID)
			FROM @ConventionOperTable

			SELECT @iScholarshipNo = ISNULL(MAX(ScholarshipNo),0)+1
			FROM Un_Scholarship
			WHERE ConventionID = @iConventionID

			SELECT @mySumScholarhip = SUM(ConventionOperAmount)*-1
			FROM @ConventionOperTable

			INSERT INTO Un_Scholarship(
				ConventionID,
				ScholarshipNo,
				ScholarshipStatusID,
				ScholarshipAmount,
				YearDeleted)
			VALUES (
				@iConventionID,
				@iScholarshipNo,
				'TPA',
				@mySumScholarhip,
				0)

			IF @@ERROR <> 0 
				SET @iResult = -31
			ELSE
				SET @iScholarshipID = SCOPE_IDENTITY()

			IF 	@iResult > 0
			AND	@iScholarshipID > 0
			BEGIN
				UPDATE @ScholarshipPmtTable
				SET ScholarshipID = @iScholarshipID
				WHERE ScholarshipID <= 0

				IF @@ERROR <> 0 
					SET @iResult = -32
			END
		END

		-- Insère les nouveaux paiement de bourse de l'opération
		IF @iResult > 0
		AND @bNewOper = 1
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
					EligibilityConditionID)
				SELECT 
					O.NewOperID,
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
					S.EligibilityConditionID
				FROM @ScholarshipPmtTable S
				JOIN @OperTable O ON O.OperID = S.OperID
				WHERE S.ScholarshipPmtID <= 0 
			
			IF @@ERROR <> 0 
				SET @iResult = -33
		END

		-- Gére l'insertion ou la modification des montants de PCEE.
		IF @iResult > 0
		AND @bConventionOper = 1
		BEGIN
			DECLARE
				@fCESG MONEY,
				@fACESG MONEY,
				@fCLB MONEY,
				@fCESGCot MONEY,
				@iCESPID INTEGER,
				@NewOperID INTEGER,
				@iScholarshipCount INTEGER

			SELECT
				@ConventionID = MAX(C.ConventionID),
				@iCESPID = MAX(ISNULL(CE.iCESPID,0)),
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
			LEFT JOIN Un_CESP CE ON CE.iCESPID = C.ConventionOperID
			JOIN @OperTable O ON O.OperID = C.OperID
			WHERE O.OperTypeID = 'PAE'

			-- Nombre de bourse restant à payer pour la convention.
			SELECT
				@iScholarshipCount = COUNT(ScholarshipID)+1			-- Compte celle qui a été marqué "A payée"
			FROM Un_Scholarship
			WHERE ConventionID = @ConventionID
				AND ScholarshipStatusID IN ('RES','TPA','ADM','WAI')

			SET @fCESGCot = 0

			IF @iCESPID > 0
			BEGIN
				UPDATE Un_CESP 
				SET
					fCESG = @fCESG,
					fACESG = @fACESG,
					fCLB = @fCLB,
					fCotisationGranted = @fCESGCot
				FROM Un_CESP
				WHERE iCESPID = @iCESPID

				IF @@ERROR <> 0 
					SET @iResult = -34
			END
			ELSE IF (@fCESG <> 0 OR @fACESG <> 0 OR @fCLB <> 0)
			BEGIN				
				INSERT INTO Un_CESP (
						ConventionID,
						OperID,
						fCESG,
						fACESG,
						fCLB,
						fCLBFee,
						fPG,
						fCotisationGranted,
						OperSourceID )
					SELECT 						
						@ConventionID,
						@NewOperID,
						@fCESG,
						@fACESG,
						@fCLB,
						0,
						0,
						@fCESGCot,
						@NewOperID
					FROM dbo.Un_Convention C
					WHERE C.ConventionID = @ConventionID

				IF @@ERROR <> 0 
					SET @iResult = -35
			END
		END

		-- Met à payé la bourse
		IF @iResult > 0
		BEGIN
			UPDATE Un_Scholarship
			SET
				ScholarshipStatusID = 'PAD'
			FROM Un_Scholarship
			JOIN @ScholarshipPmtTable P ON P.ScholarshipID = Un_Scholarship.ScholarshipID
			JOIN @OperTable OT ON OT.OperID = P.OperID
			WHERE ScholarshipStatusID <> 'PAD'
				AND	OT.OperTypeID = 'PAE'

			IF @@ERROR <> 0 
				SET @iResult = -36
		END

		-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de convention.
		IF @iResult > 0
		BEGIN
			DECLARE
				@iOperID INTEGER

			DECLARE crPAE_CHQ_Operation CURSOR
			FOR
				SELECT
					O.NewOperID
				FROM @OperTable O

			OPEN crPAE_CHQ_Operation

			FETCH NEXT FROM crPAE_CHQ_Operation
			INTO
				@iOperID

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
				-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de
				-- convention.
				EXECUTE @iOperID = IU_UN_OperCheck @ConnectID, @iOperID

				IF @iOperID <= 0
					SET @iResult = -37

				FETCH NEXT FROM crPAE_CHQ_Operation
				INTO
					@iOperID
			END

			CLOSE crPAE_CHQ_Operation
			DEALLOCATE crPAE_CHQ_Operation
		END

		-- Impression Régime Individuel – lettre PAE
		IF @iResult > 0
		BEGIN
			-- Boucle pour chacune des conventions
			DECLARE lettrePAE CURSOR
			FOR
				SELECT 
					C.ConventionID
				FROM @ConventionOperTable C
				JOIN @OperTable O ON O.OperID = C.OperID
				JOIN dbo.Un_Convention U ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = U.PlanID
				WHERE O.OperTypeID = 'PAE'
					AND P.PlanTypeID = 'IND'
				group by C.ConventionID

			OPEN lettrePAE

			FETCH NEXT FROM lettrePAE 
			INTO @ConventionIDPAE

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
				-- Appelle la procédure
				EXECUTE SP_RP_UN_LettrePAE @ConnectID, @ConventionIDPAE, 0

				FETCH NEXT FROM lettrePAE 
				INTO @ConventionIDPAE
			END

			CLOSE lettrePAE
			DEALLOCATE lettrePAE
		END
		
		-- Insère les enregistrements 400 de type 13 sur l'opération	
		EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @iResult, 13, 0

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
    */
END