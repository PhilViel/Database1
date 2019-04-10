/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperTRA
Description         :	Procédure de sauvegarde d’ajout/modification de transferts de frais.
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note :	ADX0000742	IA  2006-10-24	Alain Quirion		Création
                        2016-06-08  Pierre-Luc Simard   Ajout du champ Un_Cotisation.bInadmissibleComActif 
                        2016-06-21  Pierre-Luc Simard   Ajout de paramètre lors de l'appel de la fonction fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperTRA] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iBlobID INTEGER) -- ID Unique du blob contenant les opérations à sauvegarder
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@CotisationID INTEGER,
		@bConventionOper BIT,
		@bOtherAccountOper BIT,
		@bNewOper BIT,
        @bInadmissibleComActif BIT 

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
			TaxOnInsur MONEY)	
		
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
			WHERE OperTypeID = 'TRA'

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

		-----------------
		BEGIN TRANSACTION
		-----------------
	
		IF NOT EXISTS (
			SELECT *
			FROM @OperTable )
			SET @iResult = -20

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
		BEGIN
			DELETE Un_ConventionOper
			FROM Un_ConventionOper
			JOIN @OperTable O ON O.OperID = Un_ConventionOper.OperID
			LEFT JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID
			WHERE C.ConventionOperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -25
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
				SET @iResult = -26
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
				SET @iResult = -27
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
				SET @iResult = -28
		END

        -- Mise à jour du champ bInadmissibleComActif
        IF @iResult > 0
		BEGIN
            SET @bInadmissibleComActif = 0

            -- On récupère les paramètres
            DECLARE
		        @iAgeBenef INT = dbo.fnGENE_ObtenirParametre('CONV_AGE_MIN_BENEF_COMM_ACTIF', GETDATE(), NULL, NULL, NULL, NULL, NULL),
		        @dtSignature DATETIME = dbo.fnGENE_ObtenirParametre('CONV_DATE_SIGNATURE_MIN_COMM_ACTIF', GETDATE(), NULL, NULL, NULL, NULL, NULL)

            SELECT 
                @bInadmissibleComActif = MAX(CASE WHEN US.UnitID IS NULL THEN 1 ELSE 0 END)
            FROM (
                -- Liste des opérations TRA dont de l'épargne a été ajouté
                SELECT DISTINCT 
                    O.OperID, 
                    O.OperDate
                FROM Un_Oper O
                JOIN @OperTable OT ON OT.NewOperID = O.OperID
                JOIN Un_Cotisation CT ON CT.OperID = O.OperID
                LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID -- Pas une annulation
                WHERE OC.OperID IS NULL
                    AND CT.Cotisation > 0
                ) O
            JOIN Un_Cotisation CT ON CT.OperID = O.OperID
            OUTER APPLY (
	            SELECT US.UnitID
	            FROM dbo.fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif(O.OperDate, CT.UnitID, @iAgeBenef, @dtSignature) US
	            ) US
            WHERE (CT.Cotisation < 0 
                    OR CT.Fee < 0
                    OR CT.BenefInsur < 0
                    OR CT.SubscInsur < 0 
                    OR CT.TaxOnInsur < 0)
            GROUP BY O.OperID
            ORDER BY O.OperID

            UPDATE Un_Cotisation
            SET bInadmissibleComActif = @bInadmissibleComActif
            WHERE OperID = @iResult
                AND Cotisation > 0
                AND bInadmissibleComActif <> @bInadmissibleComActif

            IF @@ERROR <> 0 
				SET @iResult = -30

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
				SET @iResult = -29
		END
	
		-- Insère les enregistrements 400 de type -1(11 ou 21 selon le montant) sur l'opération	
		IF @iResult > 0
		BEGIN	
			SET @OperID = 0
	
			SELECT @OperID = NewOperID
			FROM @OperTable
			WHERE OperTypeID = 'TRA'

			IF @OperID > 0	
				EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @OperID, -2, 0	

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
			SET @iResult = -30 -- Erreur à la suppression du blob
	END

	RETURN @iResult
END


