/********************************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	IU_UN_OperTIO
Description         :	Procédure de sauvegarde d’ajout/modification de transfert TIO.
Valeurs de retours  :	@ReturnValue :
								> 0 : Réussite
								<= 0 : Erreurs.

Note                :	
	ADX0001100	IA	2006-10-23	Alain Quirion		    Création
	ADX0002426	BR	2007-05-22	Alain Quirion		    Modification : Un_CESP au lieu de Un_CESP900
	ADX0001355	IA	2007-06-06	Alain Quirion		    Modification de la date d’entrée en vigueur TIN (dtInforceDateTIN) de la convention et du groupe d’unités s’il y a lieu.
	ADX0001264	UP	2007-12-10	Bruno Lapointe	        Correction de la mise à jour de la date d’entrée en vigueur TIN (dtInforceDateTIN) de la convention et du groupe d’unités.
					2010-03-29  Jean-François Gauthier	Modification afin de mettre à jour de Un_Convention.dtRegEndDateAdjust avec dtRegEndDateAjust de la convention source de la transaction TIN
					2010-04-12  Jean-François Gauthier	Modification afin de mettre à jour dtRegEndDateAjust seulement si cette date existe dans la convention source	
					2010-12-08  Donald Huppé			Mettre un distinct dans la correction du 2010-04-12	car il peut y avoir plus d'un ligne retournée		
                    2016-05-25  Pierre-Luc Simard       Ajout du champ bOUTInadmissibleComActif
                    2016-06-08  Pierre-Luc Simard       Remplacer Un_TIO.bOUTInadmissibleComActif par Un_cotisation.bInadmissibleComActif
                    2016-06-21  Pierre-Luc Simard       Ajout de paramètre lors de l'appel de la fonction fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif
                    2018-11-20  Steeve Picard           Ajout d'une table temporaire pour le log des blobs de transfert (à effacer en 2020)
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_OperTIO (
	@ConnectID INTEGER, 	-- ID Unique de connexion de l'usager
	@iBlobID INTEGER) 	-- ID du blob de la table CRI_Blob qui contient les objets des opérations OUT, TFR et TIN à sauvegarder.
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
        SELECT @iBlobID, 'TIO', LEFT(vcVal, 1000), GETDATE()
          FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
    END
    ELSE IF OBJECT_ID('dbo._Blob_Transfert') IS NOT NULL 
        DROP TABLE dbo._Blob_Transfert
    
    DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@iOUTOperID INTEGER,
		@iTINOperID INTEGER,
		@iTFROperID INTEGER,
		@CotisationID INTEGER,
		@iConventionID INTEGER,
		@bConventionOper BIT,
		@bChequeSuggestion BIT,
		@bOtherAccountOper BIT,
		@UnitReductionID INTEGER,
		@bNewOper BIT,
		@bNewTIO BIT,
		@iOtherPlanGovRegNumber INTEGER,
		@vcOtherConventionNo VARCHAR(15),
		@bSaveTINOnly BIT,
		@dtLastVerifDate DATETIME,
		@OperTypeID CHAR(3),
		@dtConvInforceDateTIN DATETIME,
		@dtOtherConvention DATETIME,
		@dtMinUnitInforceDateTIN DATETIME,
		@dtUnitInforceDateTIN DATETIME,
		@UnitID INTEGER,
        @UnitIDOUT INTEGER,
		@ConventionID INTEGER,
        @bInadmissibleComActif BIT 
         
    SET @bNewOper = 1
	SET @bNewTIO = 1
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
	
		-- Tables temporaires créé à partir du blob contenant les données du transfert OUT.
		DECLARE @tOUT TABLE (
			OperID INTEGER,
			ExternalPlanID INTEGER,
			tiBnfRelationWithOtherConvBnf TINYINT,
			vcOtherConventionNo VARCHAR(15),
			tiREEEType TINYINT,
			bEligibleForCESG BIT,
			bEligibleForCLB BIT,
			bOtherContratBnfAreBrothers BIT,
			fYearBnfCot MONEY,
			fBnfCot MONEY,
			fNoCESGCotBefore98 MONEY,
			fNoCESGCot98AndAfter MONEY,
			fCESGCot MONEY,
			fCESG MONEY,
			fCLB MONEY,
			fAIP MONEY,
			fMarketValue MONEY,
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

		DECLARE @AvailableFeeUseTable TABLE (
			iAvailableFeeUseID INTEGER,
			iUnitReductionID INTEGER,
			iOperID INTEGER,
			fUnitQtyUse MONEY)

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
			WHERE OperTypeID IN ('OUT','TFR','TIN')

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

		-- Rempli la table temporaire de réduction d'unités
		INSERT INTO @UnitReductionTable
			SELECT *
			FROM dbo.FN_UN_UnitReductionOfBlob(@iBlobID)

		DECLARE @UnitReductionReasonID INT

		SELECT @UnitReductionReasonID = UnitReductionReasonID
		FROM Un_UnitReductionReason
		WHERE UnitReductionReason = 'Transfert Interne'

		-- Met automatiquement le ID de raison de réduciton d'unité "Transfert Interne"
		UPDATE @UnitReductionTable
		SET UnitReductionReasonID = @UnitReductionReasonID		

		-- Rempli la table temporaire des opérations dans les autres comptes
		INSERT INTO @OtherAccountOperTable
			SELECT *
			FROM dbo.FN_UN_OtherAccountOperOfBlob(@iBlobID)

		IF EXISTS (SELECT * FROM @OtherAccountOperTable )
			SET @bOtherAccountOper = 1
		ELSE
			SET @bOtherAccountOper = 0	

		-- Rempli la table temporaire des données de OUT
		INSERT INTO @tOUT
			SELECT 
				V.OperID,
				V.ExternalPlanID,
				V.tiBnfRelationWithOtherConvBnf,
				V.vcOtherConventionNo,
				V.tiREEEType,
				V.bEligibleForCESG,
				V.bEligibleForCLB,
				V.bOtherContratBnfAreBrothers,
				V.fYearBnfCot,
				V.fBnfCot,
				V.fNoCESGCotBefore98,
				V.fNoCESGCot98AndAfter,
				V.fCESGCot,
				V.fCESG,
				V.fCLB,
				V.fAIP,
				V.fMarketValue,
				-- Indique si l'on doit renvoyer au PCEE si le Un_OUT a été modifié
				CAST	(CASE
						WHEN OU.OperID IS NULL
							OR (OU.vcOtherConventionNo  = V.vcOtherConventionNo		 
								AND OU.ExternalPlanID  = V.ExternalPlanID) THEN 0
						ELSE 1
						END AS BIT
						)
			FROM dbo.FN_UN_OUTOfBlob(@iBlobID) V
			LEFT JOIN Un_OUT OU ON OU.OperID = V.OperID

		-- Rempli la table temporaire des données de TIN
		INSERT INTO @tTIN
			SELECT *
			FROM dbo.FN_UN_TINOfBlob(@iBlobID)	

		-- Rempli la table temporaire des frais disponibles utilisés
		INSERT INTO @AvailableFeeUseTable
			SELECT *
			FROM dbo.FN_UN_AvailableFeeUseOfBlob(@iBlobID)

		IF EXISTS (	SELECT 
					OperID
				FROM @tOUT
				WHERE OperID > 0 )
			AND EXISTS( SELECT 
					OperID
					FROM @tTIN
					WHERE OperID > 0 )
				SET @bNewTIO = 0

		-----------------
		BEGIN TRANSACTION
		-----------------

		IF NOT EXISTS (	
					SELECT *
					FROM @OperTable ) 
			AND NOT EXISTS (
					SELECT *
					FROM @tOUT )
			SET @iResult = -100 -- Pas d'opération

		IF @iResult > 0
		BEGIN
			-- Vérifie si des opérations sont nouvelles
			IF EXISTS (
				SELECT 
					OperID
				FROM @OperTable
				WHERE OperID <= 0)
			BEGIN
				WHILE EXISTS ( 
					SELECT 
						OperID
					FROM @OperTable
					WHERE NewOperID <= 0 )
				BEGIN	
					SELECT TOP 1 @OperID = OperID
					FROM @OperTable
					WHERE OperID <= 0
					ORDER BY NewOperID
		
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

						SELECT @OperTypeID = OpertypeID
						FROM @OperTable
						WHERE OperID = @OperID

						IF @OperTypeID = 'OUT'
							SET @iOUTOperID = @iResult
						ELSE IF @OperTypeID = 'TFR'
							SET @iTFROperID = @iResult
						ELSE IF @OperTypeID = 'TIN'
							SET @iTINOperID = @iResult
					END
	
					IF @@ERROR <> 0
						SET @iResult = -4
				END
			END				
			ELSE IF EXISTS (	-- Vérifie si c'est une opération déjà existante
				SELECT 
					OperID
				FROM @OperTable
				WHERE OperID > 0 )
			BEGIN			
				SET @bNewOper = 0
				SET @bNewTIO = 0

				SELECT TOP 1 @iTINOperID = OperID
				FROM @OperTable
				WHERE OperTypeID = 'TIN'

				SELECT TOP 1 @iOUTOperID = OperID
				FROM @OperTable
				WHERE OperTypeID = 'OUT'

				SELECT TOP 1 @iTFROperID = OperID
				FROM @OperTable
				WHERE OperTypeID = 'TFR'

				-- Met à jour les opérations existantes
				UPDATE Un_Oper SET
					OperTypeID = O.OperTypeID,
					OperDate = O.OperDate
				FROM Un_Oper
				JOIN @OperTable O ON O.OperID = Un_Oper.OperID
		
				IF @@ERROR <> 0
					SET @iResult = -5
			END
			ELSE IF EXISTS (
				SELECT OperID
				FROM @tOUT
				WHERE OperID > 0)
				AND EXISTS(
					SELECT OperID
					FROM @tTIN
					WHERE OperID > 0)
			BEGIN
				SET @bNewOper = 0
				SET @bNewTIO = 0

				SELECT @iTINOperID = MAX(OperID)
				FROM @tTIN

				SELECT @iOUTOperID = MAX(OperID)
				FROM @tOUT
			END
		END

		-- Supprime les enregistrements 400 non-expédiés (d'autres seront insérés pour les remplacer)
		-- On ne supprime pas les enregistrement de subvention CESP car les montants ne peuvent pas changés		
		IF @iResult > 0
		AND @bNewTIO = 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			JOIN @tOUT O ON O.OperID = Ct.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL
				AND Un_CESP400.iReversedCESP400ID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -7
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
				SET @iResult = -8
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
				SET @iResult = -9
		END

		-- Supprime les opérations sur autres comptes de l'opération que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			DELETE Un_OtherAccountOper
			FROM Un_OtherAccountOper
			JOIN @OperTable O ON O.OperID = Un_OtherAccountOper.OperID
			LEFT JOIN @OtherAccountOperTable A ON A.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID
			WHERE A.OtherAccountOperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -10
		END

		-- Supprime les données OUT que l'usager a enlevé
		IF @iResult > 0
		AND @bNewTIO = 0
		BEGIN
			DELETE Un_OUT
			FROM Un_OUT
			JOIN @OperTable O ON O.OperID = Un_OUT.OperID
			LEFT JOIN @tOUT T ON T.OperID = Un_OUT.OperID
			WHERE T.OperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -11
		END

		-- Supprime les données TIN que l'usager a enlevé
		IF @iResult > 0
		AND @bNewTIO = 0
		BEGIN
			DELETE Un_TIN
			FROM Un_TIN
			JOIN @OperTable O ON O.OperID = Un_TIN.OperID
			LEFT JOIN @tTIN T ON T.OperID = Un_TIN.OperID
			WHERE T.OperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -12
		END

		-- Supprime les données TIO que l'usager a enlevé
		IF @iResult > 0
		AND @bNewTIO = 0
		BEGIN
			DELETE Un_TIO
			FROM Un_TIO
			JOIN @OperTable O1 ON O1.OperID = Un_TIO.iTINOperID
			JOIN @OperTable O2 ON O2.OperID = Un_TIO.iOUTOperID
			LEFT JOIN @tTIN T1 ON T1.OperID = Un_TIO.iTINOperID
			LEFT JOIN @tOUT T2 ON T2.OperID = Un_TIO.iOUTOperID
			WHERE T1.OperID IS NULL
				AND T2.OperID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -13
		END

		-- Supprime les données des frais disponibles que l'usager a enlevé
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			DELETE Un_AvailableFeeUse
			FROM Un_AvailableFeeUse
			JOIN @OperTable O ON O.OperID = Un_AvailableFeeUse.OperID
			LEFT JOIN @AvailableFeeUseTable A ON A.iAvailableFeeUseID = Un_AvailableFeeUse.iAvailableFeeUseID
			WHERE A.iAvailableFeeUseID IS NULL

			IF @@ERROR <> 0 
				SET @iResult = -13
		END

		-- Suppersion des unit reduction

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
				SET @iResult = -14
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
				SET @iResult = -15
		END
		
		-- Met à jour les enregistrements d'opération sur autres comptes
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			UPDATE Un_OtherAccountOper SET
				OperID = A.OperID,
				OtherAccountOperAmount = A.OtherAccountOperAmount
			FROM Un_OtherAccountOper
			JOIN @OtherAccountOperTable A ON A.OtherAccountOperID = Un_OtherAccountOper.OtherAccountOperID

			IF @@ERROR <> 0 
				SET @iResult = -16
		END	

		-- Met à jour les données OUT
		IF @iResult > 0
		AND @bNewTIO = 0
		BEGIN
			UPDATE Un_OUT SET
				ExternalPlanID = T.ExternalPlanID,
				tiBnfRelationWithOtherConvBnf = T.tiBnfRelationWithOtherConvBnf,
				vcOtherConventionNo = T.vcOtherConventionNo,
				tiREEEType = T.tiREEEType,
				bEligibleForCESG = T.bEligibleForCESG,
				bEligibleForCLB = T.bEligibleForCLB,
				bOtherContratBnfAreBrothers = T.bOtherContratBnfAreBrothers,
				fYearBnfCot = T.fYearBnfCot,
				fBnfCot = T.fBnfCot,
				fNoCESGCotBefore98 = T.fNoCESGCotBefore98,
				fNoCESGCot98AndAfter = T.fNoCESGCot98AndAfter,
				fCESGCot = T.fCESGCot,
				fCESG = T.fCESG,
				fCLB = T.fCLB,
				fAIP = T.fAIP,
				fMarketValue = T.fMarketValue
			FROM Un_OUT
			JOIN @tOUT T ON T.OperID = Un_OUT.OperID

			IF @@ERROR <> 0 
				SET @iResult = -19
		END

		-- Met à jour les données TIN
		IF @iResult > 0
		AND @bNewTIO = 0
		BEGIN
			UPDATE Un_TIN SET
				ExternalPlanID = T.ExternalPlanID,
				tiBnfRelationWithOtherConvBnf = T.tiBnfRelationWithOtherConvBnf,
				vcOtherConventionNo = T.vcOtherConventionNo,
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
				SET @iResult = -20
		END

		--Met à jour les données du TIO
		IF @iResult > 0
		AND @bNewTIO = 0
		BEGIN
			UPDATE Un_TIO SET
				iTINOperID = @iTINOperID,
				iOUTOperID = @iOUTOperID --On ne met pas a jour le TFR car il n'est jamais passé en paramètre lors de la mise à jour				
			FROM Un_TIO
			JOIN @tTIN T1 ON T1.OperID = Un_TIO.iTINOperID
			JOIN @tOUT T2 ON T2.OperID = Un_TIO.iOUTOperID

			IF @@ERROR <> 0 
				SET @iResult = -21
		END

		--Met à jour les données des frais disponibles
		IF @iResult > 0
		AND @bNewOper = 0
		BEGIN
			UPDATE Un_AvailableFeeUse SET
				UnitReductionID = Av.iUnitReductionID,
				OperID = Av.iOperID,
				fUnitQtyUse = Av.fUnitQtyUse
			FROM Un_AvailableFeeUse
			JOIN @AvailableFeeUseTable Av ON Av.iAvailableFeeUseID = Un_AvailableFeeUse.iAvailableFeeUseID

			IF @@ERROR <> 0 
				SET @iResult = -22
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
				SET @iResult = -23
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
				SET @iResult = -24
		END

		-- Insère les nouvelles transactions d'autres comptes sur opération
		IF @iResult > 0
		AND @bOtherAccountOper = 1
		BEGIN		
			INSERT INTO Un_OtherAccountOper (				
				OperID,
				OtherAccountOperAmount)
				SELECT 					
					O.NewOperID,
					A.OtherAccountOperAmount
				FROM @OtherAccountOperTable A
				JOIN @OperTable O ON O.OperID = A.OperID
				WHERE A.OtherAccountOperID <= 0

			-- Erreur à l'insertion
			IF @@ERROR <> 0
				SET @iResult = -25
		END

		-- Mise à jour de la date TIN du groupe d'unités et de la convention
		IF @iResult > 0
		BEGIN
			--Va chercher les date d'opéartions TIN du groupe d'unité et de la convention ainsi que la date de la convention du TIN
			SELECT	
				@dtConvInforceDateTIN = C.dtInforceDateTIN,
				@dtUnitInforceDateTIN = U.dtInforceDateTIN,
				@UnitID = U.UnitID,
				@ConventionID = C.ConventionID
			FROM 
				Un_Convention C
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN @OperTable O ON O.NewOperID = Ct.OperID
				JOIN @tTIN T ON T.OperID = O.OperID

			SELECT	@dtOtherConvention = CASE
											WHEN MIN(U2.InforceDate) < MIN(ISNULL(U2.dtInforceDateTIN, U2.InforceDate+1)) THEN MIN(U2.InforceDate)
											ELSE MIN(U2.dtInforceDateTIN)
										END --On va chercher la plus petite des date d'entré en vigueur entre celle TIN et la date d'entré en vigueur chez Universitas
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN @OperTable O ON O.NewOperID = Ct.OperID
			JOIN @tOUT T ON T.OperID = O.OperID 
			JOIN dbo.Un_Unit U2 ON U2.ConventionID = C.ConventionID
			GROUP BY C.ConventionID

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
				
				--2010-03-29 : JFG : Mise à jour de dtRegEndDateAdjust
				--					 via la valeur de dtRegEndDateAdjust de la convention d'origine
				
				UPDATE	dbo.Un_Convention
				SET		dtRegEndDateAdjust = ISNULL		-- 2010-04-12 : JFG : Si NULL, on ne change pas la valeur
												((SELECT DISTINCT
														c.dtRegEndDateAdjust
													 FROM
														dbo.Un_Oper o
														INNER JOIN dbo.Un_ConventionOper co
															ON o.OperID = co.OperID
														INNER JOIN dbo.Un_Convention c
															ON co.ConventionID = c.ConventionID
													 WHERE
														o.OperID = @iOUTOperID), dtRegEndDateAdjust)
				WHERE	ConventionID = @ConventionID	
				
				IF @@ERROR <> 0 
					SET @iResult = -18	
			END	
		END

    -- Mise à jour du champ @bInadmissibleComActif
        SET @UnitIDOUT = 0
        SET @bInadmissibleComActif = 0

        -- Récupèrer le groupe d'unité de l'épargne transféré s'il y a lieu
        SELECT @UnitIDOUT = CT.UnitID
        FROM Un_Cotisation CT
        WHERE CT.OperID = @iOUTOperID
            AND CT.Cotisation <> 0
        
        -- On récupère les paramètres
        DECLARE
		    @iAgeBenef INT = dbo.fnGENE_ObtenirParametre('CONV_AGE_MIN_BENEF_COMM_ACTIF', GETDATE(), NULL, NULL, NULL, NULL, NULL),
		    @dtSignature DATETIME = dbo.fnGENE_ObtenirParametre('CONV_DATE_SIGNATURE_MIN_COMM_ACTIF', GETDATE(), NULL, NULL, NULL, NULL, NULL)

        -- Valider si le groupe d'unité du OUT est admissible ou non à la commission sur l'actif
        IF @UnitIDOUT <> 0 AND NOT EXISTS(SELECT US.UnitID FROM dbo.fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif(GETDATE(), @UnitIDOUT, @iAgeBenef, @dtSignature) US)  
            SET @bInadmissibleComActif = 1

        IF @bInadmissibleComActif = 1
            UPDATE Un_Cotisation
            SET bInadmissibleComActif = @bInadmissibleComActif
            WHERE OperID = @iTINOperID
        
        IF @@ERROR <> 0 
		    SET @iResult = -40      
            


    -- Gére l'insertion ou la modification des montants de PCEE. (OUT)
		DECLARE
			@fCESG MONEY,
			@fACESG MONEY,
			@fCLB MONEY,
			@fCESGCot MONEY,
			@iCESPID INTEGER
        		
		IF @iResult > 0
		BEGIN
			DECLARE				
				@NewOUTOperID INTEGER

			SELECT
				@ConventionID = MAX(C.ConventionID),
				@iCESPID = MAX(C.ConventionOperID),
				@NewOUTOperID = MAX(O.NewOperID),
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
			JOIN @OperTable O ON O.OperID = C.OperID
			WHERE C.ConventionOperTypeID IN ('SUB','SU+','BEC')
				AND O.NewOperID = @iOUTOperID

			-- Pas d'opération sur convention, on va chercher le ConventionID par la cotisation
			IF ISNULL(@ConventionID,0) <= 0
				SELECT @ConventionID = U.ConventionID
				FROM @CotisationTable CT
				JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID

			-- Pas d'opération sur convention, on va chercher le NewOperID différemment
			IF ISNULL(@NewOUTOperID,0) <= 0
				SELECT @NewOUTOperID = NewOperID
				FROM @OperTable
				WHERE OperTypeID = 'OUT'

			SET @iCESPID = ISNULL(@iCESPID,0)
			SET @fCESG = ISNULL(@fCESG,0)
			SET @fACESG = ISNULL(@fACESG,0)
			SET @fCLB = ISNULL(@fCLB,0)

			SET @fCESGCot = 0

			SELECT
				@fCESGCot = fCESGCot,
				@OperID = OperID
			FROM @tOUT

			--Mise à jour du champ CotisationGranted en tout temps
			UPDATE Un_CESP
			SET	fCotisationGranted = -@fCESGCot
			FROM Un_CESP
			WHERE OperID = @OperID			

			IF @iCESPID > 0
			BEGIN
				--Modification de l'enregistrement de subvention CESP
				UPDATE Un_CESP
				SET
					fCESG = @fCESG,
					fACESG = @fACESG,
					fCLB = @fCLB,
					fCotisationGranted = -@fCESGCot
				FROM Un_CESP
				WHERE iCESPID = @iCESPID

				IF @@ERROR <> 0 
					SET @iResult = -26
			END
			ELSE
			BEGIN
				--Va chercher la cotisation
				SELECT @CotisationID = MIN(Ct.CotisationID)
				FROM Un_Cotisation Ct
				JOIN @OperTable OT ON OT.NewOperID = Ct.OperID
				WHERE OT.NewOperID = @NewOUTOperID 

				--Création d'un enregistrement de subvention CESP pour le OUT	
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
						OperSourceID)
					SELECT 						
						@ConventionID,
						@NewOUTOperID,
						@CotisationID,
						@fCESG,
						@fACESG,
						@fCLB,
						0,
						0,
						-@fCESGCot,	
						@NewOUTOperID
					FROM dbo.Un_Convention 
					WHERE ConventionID = @ConventionID

				IF @@ERROR <> 0 
					SET @iResult = -27
			END
		END		

		-- Gére l'insertion ou la modification des montants de PCEE. (TIN)
		IF @iResult > 0
		BEGIN
			DECLARE
				@NewTINOperID INTEGER

			SELECT
				@ConventionID = MAX(C.ConventionID),
				@iCESPID = MAX(ISNULL(C9.iCESPID,0)),
				@NewTINOperID = MAX(O.NewOperID),
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
			LEFT JOIN Un_CESP900 C9 ON C9.iCESP900ID = C.ConventionOperID
			JOIN @OperTable O ON O.OperID = C.OperID
			WHERE C.ConventionOperTypeID IN ('SUB','SU+','BEC')
				AND O.NewOperID = @iTINOperID

			-- Pas d'opération sur convention, on va chercher le ConventionID par la cotisation
			IF ISNULL(@ConventionID,0) <= 0
				SELECT @ConventionID = U.ConventionID
				FROM @CotisationTable CT
				JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID

			-- Pas d'opération sur convention, on va chercher le NewOperID différemment
			IF ISNULL(@NewTINOperID,0) <= 0
				SELECT @NewTINOperID = NewOperID
				FROM @OperTable
				WHERE OperTypeID = 'TIN'

			SET @iCESPID = ISNULL(@iCESPID,0)
			SET @fCESG = ISNULL(@fCESG,0)
			SET @fACESG = ISNULL(@fACESG,0)
			SET @fCLB = ISNULL(@fCLB,0)

			SET @fCESGCot = 0

			SELECT
				@fCESGCot = fCESGCot,
				@OperID = OperID
			FROM @tTIN

			--Mise à jour du champ CotisationGranted en tout temps
			UPDATE Un_CESP
			SET	fCotisationGranted = @fCESGCot
			FROM Un_CESP
			WHERE OperID = @OperID

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
					SET @iResult = -28
			END
			ELSE
			BEGIN
				--Va chercher la cotisation
				SELECT @CotisationID = MIN(Ct.CotisationID)
				FROM Un_Cotisation Ct
				JOIN @OperTable OT ON OT.NewOperID = Ct.OperID
				WHERE OT.NewOperID = @NewTINOperID

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
						@NewTINOperID,
						@CotisationID,
						@fCESG,
						@fACESG,
						@fCLB,
						0,
						0,
						@fCESGCot,
						@NewTINOperID
					FROM dbo.Un_Convention 
					WHERE ConventionID = @ConventionID

				IF @@ERROR <> 0 
					SET @iResult = -29
			END
		END

		-- Insère les nouvelles transactions d'opération OUT
		IF @iResult > 0
		AND @bNewTIO = 1
		BEGIN
			INSERT INTO Un_OUT (
					OperID,
					ExternalPlanID,
					tiBnfRelationWithOtherConvBnf,
					vcOtherConventionNo,
					tiREEEType,
					bEligibleForCESG,
					bEligibleForCLB,
					bOtherContratBnfAreBrothers,
					fYearBnfCot,
					fBnfCot,
					fNoCESGCotBefore98,
					fNoCESGCot98AndAfter,
					fCESGCot,
					fCESG,
					fCLB,
					fAIP,
					fMarketValue)
				SELECT 
					O.NewOperID,
					T.ExternalPlanID,
					T.tiBnfRelationWithOtherConvBnf,
					T.vcOtherConventionNo,
					T.tiREEEType,
					T.bEligibleForCESG,
					T.bEligibleForCLB,
					T.bOtherContratBnfAreBrothers,
					T.fYearBnfCot,
					T.fBnfCot,
					T.fNoCESGCotBefore98,
					T.fNoCESGCot98AndAfter,
					T.fCESGCot,
					T.fCESG,
					T.fCLB,
					T.fAIP,
					T.fMarketValue
				FROM @tOUT T
				JOIN @OperTable O ON O.OperID = T.OperID
				LEFT JOIN Un_OUT TI ON TI.OperID = O.NewOperID
				WHERE TI.OperID IS NULL -- N'existe pas encore

			IF @@ERROR <> 0 
				SET @iResult = -30
		END		

		-- Insère les nouvelles transactions d'opération TIN
		IF @iResult > 0
		AND @bNewTIO = 1
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
					T.vcOtherConventionNo,
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
				LEFT JOIN Un_TIN TI ON TI.OperID = O.NewOperID
				WHERE TI.OperID IS NULL -- N'existe pas encore

			IF @@ERROR <> 0 
				SET @iResult = -31
		END

		-- Insère les nouvelles transactions d'opération TIO
		IF @iResult > 0
		AND @bNewTIO = 1
		BEGIN
            INSERT INTO Un_TIO (
				iOUTOperID,
				iTINOperID,
				iTFROperID)
			VALUES (@iOUTOperID, @iTINOperID, @iTFROperID)

			IF @@ERROR <> 0 
				SET @iResult = -32
		END

		-- Diminue le nombre d'unité sur le groupe d'unités
		IF @iResult > 0
		AND EXISTS(
				SELECT *
				FROM @UnitReductionTable)
		BEGIN
			UPDATE dbo.Un_Unit 
			SET 
				UnitQty = Un_Unit.UnitQty - UT.UnitQty
			FROM dbo.Un_Unit 
			JOIN @UnitReductionTable UT ON UT.UnitID = Un_Unit.UnitID
			WHERE UT.UnitReductionID = 0

			IF @@ERROR <> 0 
				SET @iResult = -33
		END

		-- Met la date de résiliation s'il y lieu sur le groupe d'unités
		IF @iResult > 0
		AND EXISTS(
				SELECT *
				FROM @UnitReductionTable)
		BEGIN
			UPDATE dbo.Un_Unit 
			SET 
				TerminatedDate = UT.ReductionDate
			FROM dbo.Un_Unit 
			JOIN @UnitReductionTable UT ON UT.UnitID = Un_Unit.UnitID
			WHERE UT.UnitReductionID = 0
				AND Un_Unit.UnitQty = 0

			IF @@ERROR <> 0 
				SET @iResult = -34
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
				SET @iResult = -35
			
			-- Inscrit le Identity dans la table temporaire
			UPDATE @UnitReductionTable
			SET UnitReductionID = @UnitReductionID

			IF @@ERROR <> 0 
				SET @iResult = -36
		END

		-- Insère les nouvelles données des frais disponibles
		IF @iResult > 0
		AND @bNewOper = 1
		AND @iTFROperID IS NOT NULL
		BEGIN
			INSERT INTO Un_AvailableFeeUse (
				UnitReductionID,
				OperID,
				fUnitQtyUse)
			SELECT
				@UnitReductionID,
				@iTFROperID,
				fUnitQtyUse
			FROM @AvailableFeeUseTable

			IF @@ERROR <> 0 
				SET @iResult = -37
		END

		-- Calcul les valeurs des champs FeeSumByUnit et SubscInsurSumByUnit des réductions d'unités.
		-- Ces champs servent aux commissions.
		IF @iResult > 0
		AND EXISTS(
				SELECT *
				FROM @UnitReductionTable)
		BEGIN

			UPDATE Un_UnitReduction
			SET 
				FeeSumByUnit = ROUND(ISNULL(VF.SumFee,0)/Un_UnitReduction.UnitQty, 2), -- Divise la somme de frais remboursé dans le RES ou OUT par le nombre d'unités
				SubscInsurSumByUnit = ISNULL(VS.SumSubscInsur,0) -- Divise la somme d'assurance souscripteur remboursé dans le RES ou OUT par le nombre d'unités
			FROM Un_UnitReduction
			JOIN @UnitReductionTable UR ON UR.UnitReductionID = Un_UnitReduction.UnitReductionID
			LEFT JOIN ( -- Va chercher le montant de frais et d'assurance souscripteur des opérations OUT par réductions d'unités.
				SELECT
					UR.UnitReductionID,
					SumFee = -SUM(Ct.Fee)
				FROM @UnitReductionTable UR
				JOIN @CotisationTable Ct ON Ct.UnitID = UR.UnitID
				JOIN @OperTable O ON O.OperID = Ct.OperID
				WHERE O.OperTypeID = 'TFR'
				GROUP BY UR.UnitReductionID
				) VF ON VF.UnitReductionID = Un_UnitReduction.UnitReductionID
			LEFT JOIN ( -- Va chercher le montant de frais et d'assurance souscripteur des opérations OUT par réductions d'unités.
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
				SET @iResult = -38
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
					AND OT.OperTypeID NOT IN ('TIN')

			IF @@ERROR <> 0 
				SET @iResult = -39
		END

		-- Renverse les enregistrements 400 déjà expédiés qui ont été modifié (OUT)
		IF @iResult > 0
		AND @bNewTIO = 0
		AND EXISTS (SELECT * FROM @tOUT WHERE bReSendToCESP = 1)
		BEGIN
			-- Renverse les enregistrements 400 des cotisations dont l'objet Un_OUT a été modifié
			SELECT @CotisationID = MIN(C.CotisationID)
			FROM @tOUT T
			JOIN Un_Cotisation C ON T.OperID = C.OperID
			WHERE T.bReSendToCESP = 1		

			-- Appelle la procédure de renversement pour la cotisation
			EXECUTE @iResult = IU_UN_ReverseCESP400 @ConnectID, @CotisationID, 0	
		END

		-- Renverse les enregistrements 400 déjà expédiés qui ont été modifié (TIN)
		IF @iResult > 0
		AND @bNewTIO = 0
		BEGIN
			-- Renverse les enregistrements 400 des cotisations dont la somme des frais et des épargnes a changé
			DECLARE crTIN_Reverse400 CURSOR
			FOR
				SELECT CotisationID
				FROM @tTIN T
				JOIN @CotisationTable C ON T.OperID = C.OperID
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

		-- Insère les enregistrements 400 de type 23 sur l'opération OUT	
		IF @iResult > 0		
			EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @iOUTOperID, 23, 0

		-- Insère les enregistrements 400 de type 19 sur l'opération TIN
		IF @iResult > 0
			EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @iTINOperID, 19, 0

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
END
