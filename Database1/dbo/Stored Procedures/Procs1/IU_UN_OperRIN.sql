/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperRIN
Description         :	Procédure de sauvegarde d’ajout/modification de remboursements intégraux.
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.

Note                :	ADX0000829	IA	2006-04-03	Bruno Lapointe	Création
						ADX0001357	IA	2007-06-04	Alain Quirion		Création automatique de la proposition de chèque au nom de 
																							Gestion Universitas Inc. si l’unité du remboursement intégral 
																							a une source de vente de type « Gagnant de concours ».
										2008-10-16	Patrick Robitaille			Ajout du champ FeeRefund dans la table Un_IntReimb
						GLPI6168	2011-10-28	Eric Michaud				Impression Régime Individuel – lettre RIN			
										2014-05-20	Pierre-Luc Simard		Refonte - Bloquer l'ajout de nouveau RIN via Uniacces
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperRIN] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iBlobID INTEGER) -- ID du blob de la table CRI_Blob qui contient les objets de l’opération RIN à sauvegarder
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@CotisationID INTEGER,
		@ConventionID INTEGER,
		@IntReimbID INTEGER,
		@bOtherAccountOper BIT,
		@bIntReimb BIT,
		@bFlagPAE BIT,
		@bFlagFerme BIT,
		@Cotisation MONEY,
		@SumCotisation MONEY,
		@SumConventionOperAmount MONEY

	--SET @iResult = -1
    SELECT 1/0

/*
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
	
		-- Table temporaire des opérations dans les autres comptes
		DECLARE @OtherAccountOperTable TABLE (
			LigneTrans INTEGER,
			OtherAccountOperID INTEGER,
			OperID INTEGER,
			OtherAccountOperAmount MONEY)

		-- Table temporaire des remboursements intégraux
		DECLARE @IntReimbTable TABLE (
			IntReimbID INTEGER,
			UnitID INTEGER,
			CollegeID INTEGER,
			ProgramID INTEGER,
			IntReimbDate DATETIME,
			StudyStart DATETIME,
			ProgramYear INTEGER,
			ProgramLength INTEGER,
			CESGRenonciation BIT,
			FullRIN BIT,
			FeeRefund BIT)

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
			WHERE OperTypeID IN ('RIN','TFR')

		-- Insère les opérations reliés des remboursements intégraux qui ne sont pas dans le blob, donc à supprimer
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
			JOIN Un_IntReimbOper IRO ON IRO.OperID = OT.OperID
			JOIN Un_IntReimbOper IRO2 ON IRO2.IntReimbID = IRO.IntReimbID AND IRO2.OperID <> IRO.OperID
			JOIN Un_Oper O ON O.OperID = IRO2.OperID
			LEFT JOIN @OperTable OT2 ON OT2.OperID = IRO2.OperID
			WHERE OT2.OperID IS NULL

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
			
		-- Rempli la table temporaire des opérations dans les autres comptes
		INSERT INTO @OtherAccountOperTable
			SELECT *
			FROM dbo.FN_UN_OtherAccountOperOfBlob(@iBlobID)	

		IF EXISTS (SELECT * FROM @OtherAccountOperTable )
			SET @bOtherAccountOper = 1
		ELSE
			SET @bOtherAccountOper = 0

		-- Rempli la table temporaire des remboursements intégraux
		INSERT INTO @IntReimbTable
			SELECT *
			FROM dbo.FN_UN_IntReimbOfBlob(@iBlobID)	

		IF EXISTS (SELECT * FROM @IntReimbTable )
			SET @bIntReimb = 1
		ELSE
			SET @bIntReimb = 0

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
						SET @iResult = -20
	
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
					SET @iResult = -21
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
				SET @iResult = -22
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
				SET @iResult = -23
		END
	
		-- Supprime les liens remboursements intégraux vs opérations
		IF @iResult > 0
		BEGIN
			DELETE Un_IntReimbOper
			FROM Un_IntReimbOper IR
			JOIN @OperTable O ON O.OperID = IR.OperID
			LEFT JOIN @IntReimbTable I ON I.IntReimbID = IR.IntReimbID
			WHERE I.IntReimbID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -24
		END

		-- Supprime les opérations dans les autres comptes de l'opération que l'usager a enlevé
		IF @iResult > 0
		BEGIN
			DELETE Un_OtherAccountOper
			FROM Un_OtherAccountOper
			JOIN @OperTable O ON O.OperID = Un_OtherAccountOper.OperID
			LEFT JOIN @OtherAccountOperTable OAO ON OAO.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID
			WHERE OAO.OtherAccountOperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -25
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
				SET @iResult = -26
		END
	
		-- Met à jour les enregistrements d'opération dans les autres comptes
		IF @iResult > 0
		AND @bOtherAccountOper = 1
		BEGIN
			UPDATE Un_OtherAccountOper SET
				OtherAccountOperAmount = OAO.OtherAccountOperAmount
			FROM Un_OtherAccountOper
			JOIN @OtherAccountOperTable OAO ON OAO.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID

			IF @@ERROR <> 0 
				SET @iResult = -27
		END

		-- Met à jour les remboursements intégraux
		IF @iResult > 0
		AND @bIntReimb = 1
		BEGIN
			UPDATE Un_IntReimb 
			SET
				UnitID = T.UnitID,
				CollegeID = T.CollegeID,
				ProgramID = T.ProgramID,
				IntReimbDate = 
					CASE 
						WHEN ISNULL(T.IntReimbDate,0) <= 0 THEN NULL
					ELSE T.IntReimbDate
					END,
				StudyStart =
					CASE 
						WHEN ISNULL(T.StudyStart,0) <= 0 THEN NULL
					ELSE T.StudyStart
					END,
				ProgramYear = T.ProgramYear,
				ProgramLength = T.ProgramLength,
				CESGRenonciation = T.CESGRenonciation,
				FullRIN = T.FullRIN,
				FeeRefund = T.FeeRefund
			FROM Un_IntReimb
			JOIN @IntReimbTable T ON T.IntReimbID = Un_IntReimb.IntReimbID

			SELECT @IntReimbID = MAX(IntReimbID)
			FROM @IntReimbTable
			WHERE IntReimbID > 0

			IF @@ERROR <> 0 
				SET @iResult = -28
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
				SET @iResult = -29
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
					AND O.OperTypeID = 'RIN'
					AND O.OperID <= 0 --Lors de l'ajout seulement
					AND C.SubscriberID <> @HumanID --Le souscripteur n'est pas déjà Gestion Universitas Inc.

			IF @@ERROR <> 0 
				SET @iResult = -30
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
					OA.OtherAccountOperAmount
				FROM @OtherAccountOperTable OA
				JOIN @OperTable O ON O.OperID = OA.OperID
				WHERE OA.OtherAccountOperID = 0 

			IF @@ERROR <> 0 
				SET @iResult = -31
		END

		-- Insère les nouveaux remboursements intégraux
		IF @iResult > 0
		AND EXISTS (
				SELECT *
				FROM @IntReimbTable
				WHERE IntReimbID = 0
				)
		BEGIN
			INSERT INTO Un_IntReimb (
					UnitID,
					CollegeID,
					ProgramID,
					IntReimbDate,
					StudyStart,
					ProgramYear,
					ProgramLength,
					CESGRenonciation,
					FullRIN,
					FeeRefund)
				SELECT 
					UnitID,
					CollegeID,
					ProgramID,
					IntReimbDate =
						CASE 
							WHEN ISNULL(IntReimbDate,0) <= 0 THEN NULL
						ELSE IntReimbDate
						END,
					StudyStart =
						CASE 
							WHEN ISNULL(StudyStart,0) <= 0 THEN NULL
						ELSE StudyStart
						END,
					ProgramYear,
					ProgramLength,
					CESGRenonciation,
					FullRIN,
					FeeRefund
				FROM @IntReimbTable
				WHERE IntReimbID = 0
	
			SET @IntReimbID = SCOPE_IDENTITY()

			IF @@ERROR <> 0 
				SET @iResult = -32
			
			-- Inscrit le Identity dans la table temporaire
			UPDATE @IntReimbTable
			SET IntReimbID = @IntReimbID

			IF @@ERROR <> 0 
				SET @iResult = -33
		END

		-- Insère les nouveaux liens cotisations vs réductions d'unités de l'opération
		IF @iResult > 0
		AND @IntReimbID > 0
		BEGIN
			INSERT INTO Un_IntReimbOper (
					IntReimbID,
					OperID)
				SELECT
					@IntReimbID,
					OT.NewOperID
				FROM @OperTable OT
				LEFT JOIN Un_IntReimbOper IRO ON IRO.OperID = OT.NewOperID AND IRO.IntReimbID = @IntReimbID
				WHERE IRO.OperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -34
		END

		-- Met à jour la date de remboursement intégral du groupe d'unités
		IF @iResult > 0 
		AND @bIntReimb = 1
		BEGIN
			UPDATE dbo.Un_Unit 
			SET
				IntReimbDate = 
					CASE 
						WHEN P.PlanTypeID <> 'IND' OR Ct.UnitID IS NOT NULL THEN I.IntReimbDate
					ELSE NULL
					END
			FROM dbo.Un_Unit 
			JOIN @IntReimbTable I ON I.UnitID = Un_Unit.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = Un_Unit.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			LEFT JOIN (
				SELECT 
					I.UnitID,
					CotisationFee = SUM(Ct.Cotisation+Ct.Fee)
				FROM @IntReimbTable I
				JOIN Un_Cotisation Ct ON Ct.UnitID = I.UnitID
				GROUP BY I.UnitID
				HAVING SUM(Ct.Cotisation+Ct.Fee) = 0
				) Ct ON Ct.UnitID = Un_Unit.UnitID
				
			IF @@ERROR <> 0 
				SET @iResult = -35
		END

		-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de convention.
		IF @iResult > 0
		BEGIN
			DECLARE
				@iOperID INTEGER

			DECLARE crRIN_CHQ_Operation CURSOR
			FOR
				SELECT
					O.NewOperID
				FROM @OperTable O
				WHERE OperTypeID = 'RIN'

			OPEN crRIN_CHQ_Operation

			FETCH NEXT FROM crRIN_CHQ_Operation
			INTO
				@iOperID

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
				-- Inscrit ou modfie l'opération du module des chèques suite à l'ajout ou la modification d'une	opération du système de
				-- convention.
				EXECUTE @iOperID = IU_UN_OperCheck @ConnectID, @iOperID

				IF @iOperID <= 0
					SET @iResult = -36

				FETCH NEXT FROM crRIN_CHQ_Operation
				INTO
					@iOperID
			END

			CLOSE crRIN_CHQ_Operation
			DEALLOCATE crRIN_CHQ_Operation
		END

		-- Renverse les enregistrements 400 déjà expédiés qui ont été modifié
		IF @iResult > 0
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

		-- Insère les enregistrements 400 sur l'opération
		IF @iResult > 0
		BEGIN
			IF EXISTS (
				SELECT *
				FROM @IntReimbTable
				WHERE CESGRenonciation = 1
				)
				-- Renonce à la subvention : Retrait - Insère les enregistrements 400 de type 21 sur l'opération
				EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @iResult, 21, 1
			ELSE
				-- Garde la subvention : Retrait EPS - Insère les enregistrements 400 de type 14 sur l'opération
				EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @iResult, 14, 0
		END

		-- Impression Régime Individuel – lettre RIN
		IF @iResult > 0
		BEGIN
			-- Boucle pour chacune des conventions
			DECLARE lettreRIN CURSOR
			FOR		
				SELECT 
					U.ConventionID,
					sum(CT1.Cotisation)+sum(CT1.Fee)  
				FROM @OperTable O
				JOIN Un_Cotisation Ct ON Ct.OperID = O.NewOperID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN @CotisationTable CT1 ON O.OperID = Ct1.OperID
				WHERE O.OperTypeID = 'RIN'
						AND O.OperID <= 0 --Lors de l'ajout seulement	
						AND P.PlanTypeID = 'IND'		
				group by U.ConventionID

			OPEN lettreRIN

			FETCH NEXT FROM lettreRIN 
			INTO @ConventionID,@Cotisation

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
			
				IF EXISTS (SELECT 1 
						FROM dbo.Un_Convention C 
						JOIN Un_ConventionOper CO ON CO.ConventionID = c.ConventionID
						JOIN Un_Oper OP on OP.OperID = CO.OperID
						WHERE C.ConventionID = @ConventionID
						AND OP.OperTypeID = 'PAE'
						AND datediff(dd,OP.dtSequence_Operation,getdate()) = 0)
					SET @bFlagPAE = 1
				ELSE 			
					SET @bFlagPAE = 0
			
				SET @SumCotisation = 0.00
				SET @SumConventionOperAmount = 0.00
				
				SET @SumCotisation = (SELECT sum(CO.Cotisation)
										FROM dbo.Un_Convention C 
										JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
										JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID 
										JOIN Un_Oper OP on OP.OperID = CO.OperID
										WHERE C.ConventionID = @ConventionID
										GROUP BY C.ConventionNo)

				SET @SumConventionOperAmount = (SELECT sum(CO.ConventionOperAmount) 
													FROM dbo.Un_Convention C 
													JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
													JOIN Un_ConventionOper CO ON CO.ConventionID = U.ConventionID
													JOIN Un_Oper OP on OP.OperID = CO.OperID
													WHERE C.ConventionID = @ConventionID
													GROUP BY C.ConventionNo)
				
				IF @SumCotisation = 0.00 and @SumConventionOperAmount = 0.00
					SET @bFlagFerme = 1
				ELSE
					SET @bFlagFerme = 0
						
				-- Appelle la procédure 
				EXECUTE SP_RP_UN_LettreRIN @ConnectID,@ConventionID,@Cotisation,@bFlagPAE,@bFlagFerme,0

				FETCH NEXT FROM lettreRIN 
				INTO @ConventionID,@Cotisation
			END

			CLOSE lettreRIN
			DEALLOCATE lettreRIN
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
			SET @iResult = -38 -- Erreur à la suppression du blob
	END
*/
	RETURN @iResult
END