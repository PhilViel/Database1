
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_CESP900Verified
Description         :	Sauvegarde les corrections d’erreurs sur enregistrement 100, 200 et 400 ainsi que les usagers qui les a faites
Valeurs de retours  :	@ReturnValue :
								> 0  : Réussite
								<= 0 : Échec
				
Note                :	ADX0001153	IA	2006-11-10	Alain Quirion		Création
						ADX0002507	BR	2007-07-17	Alain Quirion		Modification : Utilisation de Un_CESP au lieu de Un_CESP900
										2011-01-31	Frederick Thibault	Ajout du champ fACESGPart pour régler le problème SCEE+
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_CESP900Verified](
	@iBlobID INTEGER,	-- ID contenant les iCESP900ID des erreurs corrigées séparé par des virgules.	
	@bReSend BIT,		-- Indique si on doit renvoyer ou non les 400
	@ConnectID INTEGER)	-- Connect ID
AS
BEGIN
	DECLARE @dtToday DATETIME,
		@iReturn INTEGER,
		@OperID INTEGER,
		@tiCESP400TypeID INTEGER,
		@tiCESP400WithdrawReasonID INTEGER,
		@iReversedCESP400ID INTEGER
		

	SET @iReturn = 1

	SET @dtToday = GETDATE()

	CREATE TABLE #CESP900Table  (
		iValID INTEGER,
		iCESP900ID INTEGER,
		isUpdated BIT)

	INSERT INTO #CESP900Table
	SELECT *, 0 FROM dbo.FN_CRI_BlobToIntegerTable (@iBlobID)

	BEGIN TRANSACTION

	INSERT INTO Un_CESP900Verified (iCESP900ID, iVerifiedConnectID, dtVerified, bCESP400Resend)
	SELECT 
		iCESP900ID,
		@ConnectID,		
		@dtToday,
		@bReSend
	FROM #CESP900Table

	IF @@ERROR = 0 AND @bResend = 1	
	BEGIN	
		DECLARE @iCESP400ID INTEGER

		SELECT @iCESP400ID =  MAX(iCESP400ID)
		FROM Un_CESP400		
		
		-- Annualation des 400
		INSERT INTO Un_CESP400 (
				OperID,
				CotisationID,
				ConventionID,
				iReversedCESP400ID,
				tiCESP400TypeID,
				tiCESP400WithdrawReasonID,
				vcTransID,
				dtTransaction,
				iPlanGovRegNumber,
				ConventionNo,
				vcSubscriberSINorEN,
				vcBeneficiarySIN,
				fCotisation,
				bCESPDemand,
				dtStudyStart,
				tiStudyYearWeek,
				fCESG,
				fACESGPart,
				fEAPCESG,
				fEAP,
				fPSECotisation,
				iOtherPlanGovRegNumber,
				vcOtherConventionNo,
				tiProgramLength,
				cCollegeTypeID,
				vcCollegeCode,
				siProgramYear,
				vcPCGSINorEN,
				vcPCGFirstName,
				vcPCGLastName,
				tiPCGType,
				fCLB,
				fEAPCLB,
				fPG,
				fEAPPG,
				vcPGProv,
				fCotisationGranted )
			SELECT
				G4.OperID,
				G4.CotisationID,
				G4.ConventionID,
				G4.iCESP400ID,
				G4.tiCESP400TypeID,
				G4.tiCESP400WithdrawReasonID,
				'FIN',
				G4.dtTransaction,
				G4.iPlanGovRegNumber,
				G4.ConventionNo,
				G4.vcSubscriberSINorEN,
				G4.vcBeneficiarySIN,
				-G4.fCotisation,
				G4.bCESPDemand,
				G4.dtStudyStart,
				G4.tiStudyYearWeek,
				-G4.fCESG,
				-G4.fACESGPart,
				-G4.fEAPCESG,
				-G4.fEAP,
				-G4.fPSECotisation,
				G4.iOtherPlanGovRegNumber,
				G4.vcOtherConventionNo,
				G4.tiProgramLength,
				G4.cCollegeTypeID,
				G4.vcCollegeCode,
				G4.siProgramYear,
				G4.vcPCGSINorEN,
				G4.vcPCGFirstName,
				G4.vcPCGLastName,
				G4.tiPCGType,
				-C9B.fCLB,
				-G4.fEAPCLB,
				-G4.fPG,
				-G4.fEAPPG,
				G4.vcPGProv,
				-C9B.fCotisationGranted
			FROM #CESP900Table G9
			JOIN Un_CESP900 C9B ON C9B.iCESP900ID = G9.iCESP900ID
			JOIN Un_CESP400 G4 ON G4.iCESP400ID = C9B.iCESP400ID
			LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
			WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
				AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
				AND R4.iCESP400ID IS NULL -- Pas annulé
		
		IF @@ERROR <> 0 
			SET @iReturn = -1		
		ELSE
		BEGIN
			-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
			UPDATE Un_CESP400
			SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
			WHERE vcTransID = 'FIN' 
				AND iCESP400ID  > @iCESP400ID
				AND iReversedCESP400ID IS NOT NULL		
	
			IF @@ERROR <> 0
				SET @iReturn = -2	
		END		

		DECLARE @BlobID INTEGER,
			@Tempstring VARCHAR(50),	-- String tampon	
			@BlobPointer BINARY(16), 	-- Pointeur sur le texte du blob
			@BlobLength INTEGER,		-- Longueur du blob
			@CotisationID INTEGER

		SET @BlobID = -1

		-- Renvoit des enregistrement 400
		DECLARE curCESP400TypeIDWithdrawReason CURSOR FOR
		SELECT DISTINCT
			C4.tiCESP400TypeID,
			C4.tiCESP400WithdrawReasonID
		FROM #CESP900Table C9T
		JOIN Un_CESP900 C9 ON C9.iCESP900ID = C9T.iCESP900ID
		JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
				
		OPEN curCESP400TypeIDWithdrawReason

		FETCH NEXT FROM curCESP400TypeIDWithdrawReason
		INTO
			@tiCESP400TypeID,
			@tiCESP400WithdrawReasonID

		WHILE @@FETCH_STATUS = 0 AND @iReturn > 0
		BEGIN		
			-- Insertion dans un blob des cotisations du 900 du type en cours
			INSERT INTO CRI_Blob(txBlob, dtBlob)
			SELECT '', GETDATE()

			SELECT @BlobID = SCOPE_IDENTITY()

			WHILE EXISTS (
					SELECT TOP 1 C4.iCESP400ID 
					FROM #CESP900Table C9T
					JOIN Un_CESP900 C9 ON C9.iCESP900ID = C9T.iCESP900ID
					JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
					WHERE C4.tiCESP400TypeID = @tiCESP400TypeID
						AND (C4.tiCESP400WithdrawReasonID = @tiCESP400WithdrawReasonID
							OR (C4.tiCESP400WithdrawReasonID IS NULL
								AND @tiCESP400WithdrawReasonID IS NULL))
						AND C9T.isUpdated = 0)
			BEGIN
				SELECT TOP 1 
					@iCESP400ID = C4.iCESP400ID,
					@OperID = C4.OperID,
					@CotisationID = C4.CotisationID,
					@iReversedCESP400ID = C4.iReversedCESP400ID
				FROM #CESP900Table C9T
				JOIN Un_CESP900 C9 ON C9.iCESP900ID = C9T.iCESP900ID
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
				WHERE C4.tiCESP400TypeID = @tiCESP400TypeID
					AND (C4.tiCESP400WithdrawReasonID = @tiCESP400WithdrawReasonID
						OR (C4.tiCESP400WithdrawReasonID IS NULL
							AND @tiCESP400WithdrawReasonID IS NULL))
					AND C9T.isUpdated = 0

				IF ISNULL(@CotisationID,-1) = -1 --Les PAE n'ont pas de Cotisation
					AND ISNULL(@iReversedCESP400ID,-1) < 0 --Les annulations sont traités dans IU_UN_CESP400For400
				BEGIN
					EXECUTE IU_UN_CESP400ForOper @ConnectID, @OperID, @tiCESP400TypeID, @tiCESP400WithdrawReasonID
				END
				ELSE
				BEGIN
					SET @TempString = CONVERT(VARCHAR(50),@iCESP400ID) + ','
					
					SELECT @BlobPointer = TEXTPTR(txBlob) FROM CRI_Blob WHERE iBlobID = @BlobID
					SELECT @BlobLength = DATALENGTH(txBlob) FROM CRI_Blob WHERE iBlobID = @BlobID
					UPDATETEXT CRI_Blob.txBlob @BlobPointer @BlobLength 0 @TempString
				END

				UPDATE #CESP900Table
				SET isUpdated = 1
				FROM #CESP900Table
				JOIN Un_CESP900 C9 ON C9.iCESP900ID = #CESP900Table.iCESP900ID
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
				WHERE C4.iCESP400ID = @iCESP400ID
			END

			IF EXISTS (SELECT * FROM CRI_Blob WHERE iBlobID = @BlobID AND txBlob NOT LIKE '')
			BEGIN
				EXECUTE IU_UN_CESP400For400 @ConnectID, @BlobID, @tiCESP400TypeID, @tiCESP400WithdrawReasonID
			END
			ELSE
				SET @iReturn = -4

			FETCH NEXT FROM curCESP400TypeIDWithdrawReason
			INTO
				@tiCESP400TypeID,
				@tiCESP400WithdrawReasonID
		END

		CLOSE curCESP400TypeIDWithdrawReason
		DEALLOCATE curCESP400TypeIDWithdrawReason
	END

	IF @@ERROR <> 0 
		SET @iReturn = -5

	IF @iReturn > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @iReturn		
END

