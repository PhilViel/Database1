/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperTFR
Description         :	Procédure de sauvegarde d’ajout/modification de transferts de frais.
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000863	IA	2006-03-31	Bruno Lapointe		Création
			ADX0000984	IA	2006-05-15	Alain Quirion		Modification 	Nouveau type d'objet Un_TFR dans un blob
													Nouvelles règles :	Dans le cas où la case « À envoyer au PCEE » sera cochée et qu’il n’y aura pas un enregistrement 400 sur l’opération TFR, on en créera un. 
																Dans le cas où la case « À envoyer au PCEE » sera cochée et qu’il y aura déjà un enregistrement 400 sur l’opération TFR non expédié au PCEE, on le modifiera pour qu’il tienne compte des modifications. 
																Dans le cas où la case « À envoyer au PCEE » sera cochée et qu’il y aura déjà un enregistrement 400 sur l’opération TFR expédié au PCEE, on créera un enregistrement 400 d’annulation pour l’annuler et on créera un nouvel enregistrement 400 qui tiendra compte des modifications faites à l’opération TFR. 
																Dans le cas où la case « À envoyer au PCEE » ne sera pas cochée et qu’il n’y aura pas un enregistrement 400 sur l’opération TFR, rien ne sera fait. 
																Dans le cas où la case « À envoyer au PCEE » ne sera pas cochée et qu’il y aura un enregistrement 400 sur l’opération TFR non expédiée au PCEE, on le supprimera. 
																Dans le cas où la case « À envoyer au PCEE » ne sera pas cochée et qu’il y aura déjà un enregistrement 400 sur l’opération TFR expédiée au PCEE, on créera un enregistrement 400 d’annulation pour l’annuler. 
			ADX0001940	BR	2006-05-29	Alain Quirion		Ajout d'un objet Un_TFR lors d'un OtherAccountOper
			ADX0001940	BR	2006-05-30	Alain Quirion		
			ADX0001119	IA	2006-10-31	Alain Quirion		Ajout de l'objet Un_AvaibleFeeUse
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperTFR] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@bOnlySendToPCEECheckIsModify BIT, -- Indique si seulement la case à cocher "À envoyer au PCEE" a été modifié
	@iBlobID INTEGER) -- ID Unique du blob contenant les opérations à sauvegarder
AS
BEGIN

	DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@CotisationID INTEGER,
		@bConventionOper BIT,
		@bOtherAccountOper BIT,
		@bNewOper BIT

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

		-- Tables temporaires créé à partir du blob contenant les données du transfert de frais TFR.
		DECLARE @tTFR TABLE (
			OperID INTEGER,
			bSendToPCEE BIT)

		-- Table temporaire des frais disponibles utilisés
		DECLARE @AvailableFeeUseTable TABLE (
			iAvailableFeeUseID INTEGER,
			iUnitReductionID INTEGER,
			iOperID INTEGER,
			fUnitQtyUse MONEY
		)		

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
			WHERE OperTypeID = 'TFR'

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

		-- Rempli la table temporaire des opérations dans les autres comptes
		INSERT INTO @OtherAccountOperTable
			SELECT *
			FROM dbo.FN_UN_OtherAccountOperOfBlob(@iBlobID)	

		IF EXISTS (SELECT * FROM @OtherAccountOperTable )
			SET @bOtherAccountOper = 1
		ELSE
			SET @bOtherAccountOper = 0

		-- Rempli la table temporaire des données de TFR
		INSERT INTO @tTFR
			SELECT *
			FROM dbo.FN_UN_TFROfBlob(@iBlobID)

		-- Rempli la table temporaire des frais disponibles utilisés
		INSERT INTO @AvailableFeeUseTable
			SELECT *
			FROM dbo.FN_UN_AvailableFeeUseOfBlob(@iBlobID)

		-----------------
		BEGIN TRANSACTION
		-----------------
	
		IF NOT EXISTS (
			SELECT *
			FROM @OperTable )
			SET @iResult = -20

		IF @bOnlySendToPCEECheckIsModify = 1
		AND EXISTS (SELECT * FROM @OperTable WHERE OperID = 0 )
			SET @iResult = -30

		IF @iResult > 0
		BEGIN

			-- Vérifie si des opérations sont nouvelles
			IF EXISTS ( 
				SELECT 
					OperID
				FROM @OperTable
				WHERE OperID <= 0 )
				AND @bOnlySendToPCEECheckIsModify = 0
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
				AND @bOnlySendToPCEECheckIsModify = 0
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
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			JOIN @OperTable O ON O.NewOperID = Ct.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL	
				AND Un_CESP400.iReversedCESP400ID IS NULL 

			IF @@ERROR <> 0
				SET @iResult = -23
		END

		-- Supprime les cotisations de l'opération que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		AND @bOnlySendToPCEECheckIsModify = 0
		BEGIN
			DELETE Un_Cotisation
			FROM Un_Cotisation
			JOIN @OperTable O ON O.OperID = Un_Cotisation.OperID
			LEFT JOIN @CotisationTable C ON C.CotisationID = Un_Cotisation.CotisationID
			WHERE C.CotisationID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -24
		END
	
		-- Supprime les opérations sur conventions de l'opération que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		AND @bOnlySendToPCEECheckIsModify = 0
		BEGIN
			DELETE Un_ConventionOper
			FROM Un_ConventionOper
			JOIN @OperTable O ON O.OperID = Un_ConventionOper.OperID
			LEFT JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID
			WHERE C.ConventionOperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -25
		END

		-- Supprime les opérations dans les autres comptes de l'opération que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		AND @bOnlySendToPCEECheckIsModify = 0
		BEGIN
			DELETE Un_OtherAccountOper
			FROM Un_OtherAccountOper
			JOIN @OperTable O ON O.OperID = Un_OtherAccountOper.OperID
			LEFT JOIN @OtherAccountOperTable OAO ON OAO.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID
			WHERE OAO.OtherAccountOperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -26
		END

		-- Supprime les données TFR que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		AND @bOnlySendToPCEECheckIsModify = 0
		BEGIN
			DELETE Un_TFR
			FROM Un_TFR
			JOIN @OperTable O ON O.OperID = Un_TFR.OperID
			LEFT JOIN @tTFR T ON T.OperID = Un_TFR.OperID
			WHERE T.OperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -27
		END

		-- Supprime les frais disponibles utilisés lié au TFR supprimé
		IF @iResult = 1
		BEGIN
			DELETE Un_AvailableFeeUse
			FROM Un_AvailableFeeUse
			JOIN @OperTable O ON O.OperID = Un_AvailableFeeUse.OperID
			LEFT JOIN @AvailableFeeUseTable A ON A.iOperID = O.OperID
			WHERE O.OperTypeID = 'TFR'
				AND A.iAvailableFeeUseID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -28
		END		

		-- Met à jour les enregistrements de cotisation
		IF @iResult > 0
		AND @bNewOper = 0
		AND @bOnlySendToPCEECheckIsModify = 0
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
				SET @iResult = -29
		END

		-- Met à jour les enregistrements d'opération sur convention
		IF @iResult > 0
		AND @bConventionOper = 1
		AND @bNewOper = 0
		AND @bOnlySendToPCEECheckIsModify = 0
		BEGIN
			UPDATE Un_ConventionOper SET
				ConventionID = C.ConventionID,
				ConventionOperTypeID = C.ConventionOperTypeID,
				ConventionOperAmount = C.ConventionOperAmount
			FROM Un_ConventionOper
			JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID AND C.ConventionOperTypeID NOT IN ('SUB','SU+','BEC')
		

			IF @@ERROR <> 0 
				SET @iResult = -30
		END

		-- Met à jour les données TFR
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			UPDATE Un_TFR SET
				bSendToPCEE = T.bSendToPCEE
			FROM Un_TFR
			JOIN @tTFR T ON T.OperID = Un_TFR.OperID

			IF @@ERROR <> 0 
				SET @iResult = -31
		END

		-- Met à jour les enregistrements d'opération dans les autres comptes
		IF @iResult > 0
		AND @bOtherAccountOper = 1
		AND @bNewOper = 0
		AND @bOnlySendToPCEECheckIsModify = 0
		BEGIN
			UPDATE Un_OtherAccountOper SET
				OtherAccountOperAmount = OAO.OtherAccountOperAmount
			FROM Un_OtherAccountOper
			JOIN @OtherAccountOperTable OAO ON OAO.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID

			IF @@ERROR <> 0 
				SET @iResult = -32
		END

		-- Met a jour les données des frais disponibles utilisés
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			UPDATE Un_AvailableFeeUse SET				
				fUnitQtyUse = A.fUnitQtyUse
			FROM Un_AvailableFeeUse
			JOIN @AvailableFeeUseTable A ON A.iAvailableFeeUseID = Un_AvailableFeeUse.iAvailableFeeUseID

			IF @@ERROR <> 0 
				SET @iResult = -33
		END

		-- Insère les nouvelles transactions de cotisations de l'opération
		IF @iResult > 0
		AND @bOnlySendToPCEECheckIsModify = 0
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
				SET @iResult = -34
		END
	
		-- Insère les nouvelles transactions d'opération sur convention de l'opération
		IF @iResult > 0
		AND @bConventionOper = 1
		AND @bOnlySendToPCEECheckIsModify = 0
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
				SET @iResult = -35
		END

		-- Insère les nouvelles transactions d'opération dans les autres comptes de l'opération
		IF @iResult > 0
		AND @bOtherAccountOper = 1
		AND @bOnlySendToPCEECheckIsModify = 0
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
				SET @iResult = -36
		END

		-- Insère les nouvelles transactions d'opération sur convention de l'opération
		IF @iResult > 0
		AND (@bConventionOper = 1 OR @bOtherAccountOper = 1)
		AND @bOnlySendToPCEECheckIsModify = 0
		BEGIN
			INSERT INTO Un_TFR (
					OperID,					
					bSendToPCEE)
				SELECT 
					O.NewOperID,					
					T.bSendToPCEE
				FROM @tTFR T
				JOIN @OperTable O ON O.OperID = T.OperID
				LEFT JOIN Un_TFR TF ON TF.OperID = T.OperID
				WHERE TF.OperID IS NULL -- N'existe pas encore

			IF @@ERROR <> 0 
				SET @iResult = -37
		END

		IF @iResult > 0
		AND (@bConventionOper = 1 OR @bOtherAccountOper = 1)
		AND @bOnlySendToPCEECheckIsModify = 0
		BEGIN
			INSERT INTO Un_AvailableFeeUse (
				UnitReductionID,
				OperID,
				fUnitQtyUse)
			SELECT
				Av.iUnitReductionID,
				O.NewOperID,
				Av.fUnitQtyUse
			FROM @AvailableFeeUseTable Av
			JOIN @OperTable O ON O.OperID = Av.iOperID			
			LEFT JOIN Un_AvailableFeeUse A ON A.OperID = Av.iOperID AND A.UnitReductionID = Av.iUnitReductionID 
			WHERE A.iAvailableFeeUseID IS NULL -- N'existe pas encore

			IF @@ERROR <> 0 
				SET @iResult = -38
		END			

		-- Renverse les enregistrements 400 déjà expédiés qui ont été modifié
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			-- Renverse les enregistrements 400 des cotisations dont la somme des frais et des épargnes a changé
			DECLARE crTFR_Reverse400 CURSOR
			FOR
				SELECT CotisationID
				FROM @CotisationTable
				WHERE bReSendToCESP = 1
				-----
				UNION
				-----
				SELECT C.CotisationID
				FROM @CotisationTable C
				JOIN @tTFR T ON T.OperID=C.OperID
				WHERE T.bSendToPCEE=0			-- Annule les enregistrements 400 si la case n'est pas cochée
				
			OPEN crTFR_Reverse400

			FETCH NEXT FROM crTFR_Reverse400 
			INTO @CotisationID

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
				-- Appelle la procédure de renversement pour la cotisation
				EXECUTE @iResult = IU_UN_ReverseCESP400 @ConnectID, @CotisationID, 0

				FETCH NEXT FROM crTFR_Reverse400 
				INTO @CotisationID
			END

			CLOSE crTFR_Reverse400
			DEALLOCATE crTFR_Reverse400			
		END

		-- Insère les enregistrements 400 de type -1(11 ou 21 selon le montant) sur l'opération
		IF EXISTS (	--Seulement si la case  Envoyé au PCEE est cochée ADX0000984
			SELECT OperID
			FROM @tTFR
			WHERE bSendToPCEE = 1)
		BEGIN		
			-- TFR
			SET @OperID = 0

			SELECT @OperID = NewOperID
			FROM @OperTable
			WHERE OperTypeID = 'TFR'
			IF @OperID > 0				
				EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @OperID, -1, 0
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
	IF @iResult <> -1
	BEGIN
		DELETE 
		FROM CRI_Blob
		WHERE iBlobID = @iBlobID
			OR dtBlob <= DATEADD(DAY,-2,GETDATE())
	
		IF @@ERROR <> 0
			SET @iResult = -39 -- Erreur à la suppression du blob
	END


	RETURN @iResult
END



