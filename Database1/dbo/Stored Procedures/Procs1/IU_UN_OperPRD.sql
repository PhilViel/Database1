/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperPRD
Description         :	Procédure de sauvegarde d’ajout/modification de premiers dépôts.
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000860	IA	2006-03-23	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperPRD] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iBlobID INTEGER) -- ID Unique du blob contenant les opérations à sauvegarder
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@CotisationID INTEGER,
		@bConventionOper BIT

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
			WHERE OperTypeID = 'PRD'

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
		IF @iResult > 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			JOIN @OperTable O ON O.NewOperID = Ct.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -12
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
				SET @iResult = -6
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
				SET @iResult = -7
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
				SET @iResult = -8
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
				SET @iResult = -9
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
				SET @iResult = -10
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
				SET @iResult = -11
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

		-- Insère les enregistrements 400 de type 11 sur l'opération
		EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @iResult, 11, 0

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
			SET @iResult = -16 -- Erreur à la suppression du blob
	END

	RETURN @iResult
END

