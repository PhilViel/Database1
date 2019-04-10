/********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_OperTIN
Description         :	Procédure de sauvegarde d’ajout/modification de transfert IN.
Valeurs de retours  :	@ReturnValue :
									> 0	: Réussite
									<= 0 : Erreurs.
Note                :	
	ADX0000925	IA	2006-05-08	Bruno Lapointe		Création
	ADX0002426  BR	2007-05-08	Bruno Lapointe		Recréé les 900 si déjà envoyé
	ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
	ADX0001355	IA	2007-06-06	Alain Quirion		Modification de la date d’entrée en vigueur TIN (dtInforceDateTIN) 
													de la convention et du groupe d’unités s’il y a lieu.
					2016-04-27  Steeve Picard		Forcer le «OtherConventionNo» en majuscule dans les tables «Un_TIN & Un_OUT»
                    2018-11-20  Steeve Picard       Ajout d'une table temporaire pour le log des blobs de transfert (à effacer en 2020)
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_OperTIN (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@iBlobID INTEGER)	-- ID Unique du blob contenant les opérations à sauvegarder
AS
BEGIN
    --  Éliminer ce bloc de code (IF-ELSE) après juin 2019
    IF YEAR(GETDATE()) < 2020
    BEGIN
        IF OBJECT_ID('dbo._Blob_Transfert') IS NULL 
            CREATE TABLE dbo._Blob_Transfert (iBlobID INT, cOperType CHAR(3), vcLine VARCHAR(1000), dtCreate DATE)
        ELSE 
            DELETE FROM dbo._Blob_Transfert WHERE dtCreate < CAST(GETDATE() AS date)
    
        INSERT INTO dbo._Blob_Transfert
        SELECT @iBlobID, 'TIN', LEFT(vcVal, 1000), GETDATE()
          FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
    END
    ELSE IF OBJECT_ID('dbo._Blob_Transfert') IS NOT NULL 
        DROP TABLE dbo._Blob_Transfert

	DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@CotisationID INTEGER,
		@bConventionOper BIT,
		@bNewOper BIT,
		@dtLastVerifDate DATETIME,
		@bSaveTINOnly BIT,
		@dtConvInforceDateTIN DATETIME,
		@dtOtherConvention DATETIME,
		@dtUnitInforceDateTIN DATETIME,
		@UnitID INTEGER,
		@ConventionID INTEGER,
		@dtMinUnitInforceDateTIN DATETIME

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
	
		-- Tables temporaires créé à partir du blob contenant les données du transfert IN.
		DECLARE @tTIN TABLE (
			OperID INTEGER,
			ExternalPlanID INTEGER,
			tiBnfRelationWithOtherConvBnf TINYINT,
			vcOtherConventionNo VARCHAR(15),
			dtOtherConvention DATETIME,
			tiOtherConvBnfRelation TINYINT,
			bAIP BIT,
			bACESGPaid BIT,
			bBECInclud BIT,
			bPGInclud BIT,
			fYearBnfCot MONEY,
			fBnfCot MONEY,
			fNoCESGCotBefore98 MONEY,
			fNoCESGCot98AndAfter MONEY,
			fCESGCot MONEY,
			fCESG MONEY,
			fCLB MONEY,
			fAIP MONEY,
			fMarketValue MONEY,
			bPendingApplication BIT)

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
			WHERE OperTypeID = 'TIN'

		SELECT 
			@dtLastVerifDate = LastVerifDate
		FROM Un_Def

		IF EXISTS (
			SELECT *
			FROM @OperTable OT
			LEFT JOIN Un_Oper O ON OT.OperID = O.OperID
			WHERE ISNULL(dbo.FN_CRQ_DateNoTime(O.OperDate),@dtLastVerifDate+1) <= dbo.FN_CRQ_DateNoTime(@dtLastVerifDate)
				OR ISNULL(dbo.FN_CRQ_DateNoTime(OT.OperDate),0) <= dbo.FN_CRQ_DateNoTime(@dtLastVerifDate)
			)
			SET @bSaveTINOnly = 1
		ELSE
			SET @bSaveTINOnly = 0

		-- Rempli la table temporaire des données de TIN
		INSERT INTO @tTIN
			SELECT *
			FROM dbo.FN_UN_TINOfBlob(@iBlobID)	

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
							WHEN EXISTS ( -- Numéro de contrat externe, plan externe, SCEE ou BEC modifié on doit réexpédier
								SELECT NT.OperID
								FROM @tTIN NT
								JOIN Un_TIN T ON T.OperID = NT.OperID
								WHERE NT.ExternalPlanID <> T.ExternalPlanID
									OR NT.vcOtherConventionNo <> T.vcOtherConventionNo
									OR NT.fCESG <> T.fCESG
									OR NT.fCLB <> T.fCLB ) THEN 1
							WHEN EXISTS ( -- Si on supprime des 400 il faut absolument les recréer
								SELECT C4.OperID
								FROM Un_CESP400 C4
								JOIN Un_Cotisation Ct ON C4.CotisationID = Ct.CotisationID
								JOIN @OperTable O ON O.NewOperID = Ct.OperID
								WHERE C4.iCESPSendFileID IS NULL ) THEN 1
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
		AND @bSaveTINOnly = 0
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

		IF @iResult > 0
		AND @bSaveTINOnly = 1
		BEGIN
			IF EXISTS (
					SELECT 
						OperID
					FROM @OperTable
					WHERE OperID > 0 )
				SET @bNewOper = 0

			SELECT @iResult = OperID
			FROM @OperTable
		END

		-- Supprime les enregistrements 400 non-expédiés (d'autres seront insérés pour les remplacer)
		-- On ne supprime pas les enregistrement de subvention CESP car les montants ne peuvent pas changés
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			JOIN @OperTable O ON O.NewOperID = Ct.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -7
		END

		-- Supprime les cotisations de l'opération que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		AND @bSaveTINOnly = 0
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
		AND @bSaveTINOnly = 0
		BEGIN
			DELETE Un_ConventionOper
			FROM Un_ConventionOper
			JOIN @OperTable O ON O.OperID = Un_ConventionOper.OperID
			LEFT JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID
			WHERE C.ConventionOperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -9
		END

		-- Supprime les données TIN que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		AND @bSaveTINOnly = 0
		BEGIN
			DELETE Un_TIN
			FROM Un_TIN
			JOIN @OperTable O ON O.OperID = Un_TIN.OperID
			LEFT JOIN @tTIN T ON T.OperID = Un_TIN.OperID
			WHERE T.OperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -11
		END

		-- Met à jour les enregistrements de cotisation
		IF @iResult > 0
		AND @bNewOper = 0
		AND @bSaveTINOnly = 0
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
				SET @iResult = -12
		END
	
		-- Met à jour les enregistrements d'opération sur convention
		IF @iResult > 0
		AND @bConventionOper = 1
		AND @bNewOper = 0
		AND @bSaveTINOnly = 0
		BEGIN
			UPDATE Un_ConventionOper SET
				ConventionID = C.ConventionID,
				ConventionOperTypeID = C.ConventionOperTypeID,
				ConventionOperAmount = C.ConventionOperAmount
			FROM Un_ConventionOper
			JOIN @ConventionOperTable C ON C.ConventionOperID = Un_ConventionOper.ConventionOperID AND C.ConventionOperTypeID NOT IN ('SUB','SU+','BEC')

			IF @@ERROR <> 0 
				SET @iResult = -13
		END

		-- Met à jour les données TIN
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			UPDATE Un_TIN SET
				ExternalPlanID = T.ExternalPlanID,
				tiBnfRelationWithOtherConvBnf = T.tiBnfRelationWithOtherConvBnf,
				vcOtherConventionNo = Upper(T.vcOtherConventionNo),
				dtOtherConvention = T.dtOtherConvention,
				tiOtherConvBnfRelation = T.tiOtherConvBnfRelation,
				bAIP = T.bAIP,
				bACESGPaid = T.bACESGPaid,
				bBECInclud = T.bBECInclud,
				bPGInclud = T.bPGInclud,
				fYearBnfCot = T.fYearBnfCot,
				fBnfCot = T.fBnfCot,
				fNoCESGCotBefore98 = T.fNoCESGCotBefore98,
				fNoCESGCot98AndAfter = T.fNoCESGCot98AndAfter,
				fCESGCot = T.fCESGCot,
				fCESG = T.fCESG,
				fCLB = T.fCLB,
				fAIP = T.fAIP,
				fMarketValue = T.fMarketValue,
				bPendingApplication = T.bPendingApplication
			FROM Un_TIN
			JOIN @tTIN T ON T.OperID = Un_TIN.OperID

			IF @@ERROR <> 0 
				SET @iResult = -14
		END

		-- Insère les nouvelles transactions de cotisations de l'opération
		IF @iResult > 0
		AND @bSaveTINOnly = 0
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
				SET @iResult = -15
		END
	
		-- Insère les nouvelles transactions d'opération sur convention de l'opération
		IF @iResult > 0
		AND @bConventionOper = 1
		AND @bSaveTINOnly = 0
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
				SET @iResult = -16
		END

		-- Mise à jour de la date TIN du groupe d'unités et de la convention
		IF @iResult > 0
		BEGIN
			--Va chercher les date d'opéartions TIN du groupe d'unité et de la convention ainsi que la date de la convention du TIN
			SELECT	@dtConvInforceDateTIN = C.dtInforceDateTIN,
					@dtUnitInforceDateTIN = U.dtInforceDateTIN,
					@dtOtherConvention = T.dtOtherConvention,
					@UnitID = U.UnitID,
					@ConventionID = C.ConventionID
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN @OperTable O ON O.NewOperID = Ct.OperID
			JOIN @tTIN T ON T.OperID = O.OperID

			IF @dtOtherConvention < ISNULL(@dtUnitInforceDateTIN, @dtOtherConvention+1)
			BEGIN
				-- Mise à jour de la date d'opération TIN pour le groupe d'unités
				UPDATE dbo.Un_Unit 
				SET dtInforceDateTIN = @dtOtherConvention
				WHERE UnitID = @UnitID

				IF @@ERROR <> 0 
					SET @iResult = -17

				--Va chercher la date TIN minimale parmis les groupes d'unités de la convention
				SELECT @dtMinUnitInforceDateTIN = MIN(U.dtInforceDateTIN)					
				FROM dbo.Un_Convention C
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				WHERE C.ConventionID = @ConventionID
					AND U.dtInforceDateTIN IS NOT NULL
				GROUP BY C.ConventionID
				
				UPDATE dbo.Un_Convention 
				SET dtInforceDateTIN = @dtMinUnitInforceDateTIN
				WHERE ConventionID = @ConventionID

				IF @@ERROR <> 0 
					SET @iResult = -18				
			END	
		END

		-- Gére l'insertion ou la modification des montants de PCEE.
		IF @iResult > 0
		AND @bSaveTINOnly = 0
		BEGIN
			DECLARE
				@fCESG MONEY,
				@fACESG MONEY,
				@fCLB MONEY,
				@fCESGCot MONEY,
				@iCESPID INTEGER,
				@NewOperID INTEGER

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
			WHERE C.ConventionOperTypeID IN ('SUB','SU+','BEC')

			-- Pas d'opération sur convention, on va chercher le ConventionID par la cotisation
			IF ISNULL(@ConventionID,0) <= 0
				SELECT @ConventionID = U.ConventionID
				FROM @CotisationTable CT
				JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID

			-- Pas d'opération sur convention, on va chercher le NewOperID différemment
			IF ISNULL(@NewOperID,0) <= 0
				SELECT @NewOperID = NewOperID
				FROM @OperTable
				WHERE OperTypeID = 'TIN'

			SET @iCESPID = ISNULL(@iCESPID,0)
			SET @fCESG = ISNULL(@fCESG,0)
			SET @fACESG = ISNULL(@fACESG,0)
			SET @fCLB = ISNULL(@fCLB,0)

			SET @fCESGCot = 0

			SELECT
				@fCESGCot = fCESGCot
			FROM @tTIN

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
					SET @iResult = -19
			END
			ELSE
			BEGIN
				--Va chercher la cotisation
				SELECT @CotisationID = MIN(Ct.CotisationID)
				FROM Un_Cotisation Ct
				JOIN @OperTable OT ON OT.NewOperID = Ct.OperID

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
						OperSourceID )
					SELECT 						
						@ConventionID,
						@NewOperID,
						@CotisationID,
						@fCESG,
						@fACESG,
						@fCLB,
						0,
						0,
						@fCESGCot,
						@NewOperID
					FROM dbo.Un_Convention 
					WHERE ConventionID = @ConventionID

				IF @@ERROR <> 0 
					SET @iResult = -20
			END
		END

		-- Insère les nouvelles transactions d'opération sur convention de l'opération
		IF @iResult > 0
		BEGIN
			INSERT INTO Un_TIN (
					OperID,
					ExternalPlanID,
					tiBnfRelationWithOtherConvBnf,
					vcOtherConventionNo,
					dtOtherConvention,
					tiOtherConvBnfRelation,
					bAIP,
					bACESGPaid,
					bBECInclud,
					bPGInclud,
					fYearBnfCot,
					fBnfCot,
					fNoCESGCotBefore98,
					fNoCESGCot98AndAfter,
					fCESGCot,
					fCESG,
					fCLB,
					fAIP,
					fMarketValue,
					bPendingApplication)
				SELECT 
					O.NewOperID,
					T.ExternalPlanID,
					T.tiBnfRelationWithOtherConvBnf,
					Upper(T.vcOtherConventionNo),
					T.dtOtherConvention,
					T.tiOtherConvBnfRelation,
					T.bAIP,
					T.bACESGPaid,
					T.bBECInclud,
					T.bPGInclud,
					T.fYearBnfCot,
					T.fBnfCot,
					T.fNoCESGCotBefore98,
					T.fNoCESGCot98AndAfter,
					T.fCESGCot,
					T.fCESG,
					T.fCLB,
					T.fAIP,
					T.fMarketValue,
					T.bPendingApplication
				FROM @tTIN T
				JOIN @OperTable O ON O.OperID = T.OperID
				LEFT JOIN Un_TIN TI ON TI.OperID = T.OperID
				WHERE TI.OperID IS NULL -- N'existe pas encore

			IF @@ERROR <> 0 
				SET @iResult = -21
		END

		-- Renverse les enregistrements 400 déjà expédiés qui ont été modifié
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			-- Renverse les enregistrements 400 des cotisations dont la somme des frais et des épargnes a changé
			DECLARE crTIN_Reverse400 CURSOR
			FOR
				SELECT CotisationID
				FROM @CotisationTable
				WHERE bReSendToCESP = 1

			OPEN crTIN_Reverse400

			FETCH NEXT FROM crTIN_Reverse400 
			INTO @CotisationID

			WHILE @@FETCH_STATUS = 0 AND @iResult > 0
			BEGIN
				-- Appelle la procédure de renversement pour la cotisation
				EXECUTE @iResult = IU_UN_ReverseCESP400 @ConnectID, @CotisationID, 0

				FETCH NEXT FROM crTIN_Reverse400 
				INTO @CotisationID
			END

			CLOSE crTIN_Reverse400
			DEALLOCATE crTIN_Reverse400
		END

		-- Insère les enregistrements 400 de type 19 sur l'opération
		EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @iResult, 19, 0

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
			SET @iResult = -22 -- Erreur à la suppression du blob
	END

	RETURN @iResult
END
