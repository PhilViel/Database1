/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_CESPReceiveFileOfBlob
Description 		:	Fonction qui extrait les informations sur le fichier de retour du fichier des enregistrements 900.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000811	IA	2006-04-17	Bruno Lapointe	Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_CESPReceiveFileOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tCESPReceiveFile 
	TABLE (
		dtPeriodStart DATETIME,
		dtPeriodEnd DATETIME,
		fSumary MONEY,
		fPayment MONEY,
		vcPaymentReqID VARCHAR(10),
		vcCESPSendFile VARCHAR(26))
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@dtPeriodStart DATETIME,
		@dtPeriodEnd DATETIME,
		@fSumary MONEY,
		@fPayment MONEY,
		@vcPaymentReqID VARCHAR(10),
		@vcCESPSendFile VARCHAR(26)
		

	-- va chercher toutes les lignes que contient le blob
	DECLARE crLinesOfBlob CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
		
	OPEN crLinesOfBlob
	
	-- Va chercher la première section du blob			
	FETCH NEXT FROM crLinesOfBlob
	INTO
		@vcLine
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF SUBSTRING(@vcLine, 1, 3) = '002'
		BEGIN
			-- Va chercher les valeurs dans la string
			SET @dtPeriodStart = CAST(SUBSTRING(@vcLine, 19, 4)+'-'+SUBSTRING(@vcLine, 23, 2)+'-'+SUBSTRING(@vcLine, 25, 2) AS DATETIME)
			SET @dtPeriodEnd = CAST(SUBSTRING(@vcLine, 27, 4)+'-'+SUBSTRING(@vcLine, 31, 2)+'-'+SUBSTRING(@vcLine, 33, 2) AS DATETIME)
			SET @fSumary = CAST(SUBSTRING(@vcLine, 35, 12) AS MONEY)/100
			SET @fPayment = CAST(SUBSTRING(@vcLine, 47, 12) AS MONEY)/100
			SET @vcPaymentReqID = RTRIM(LTRIM(SUBSTRING(@vcLine, 59, 10)))

			INSERT INTO @tCESPReceiveFile ( 
				dtPeriodStart,
				dtPeriodEnd,
				fSumary,
				fPayment,
				vcPaymentReqID)
			VALUES (
				@dtPeriodStart,
				@dtPeriodEnd,
				@fSumary,
				@fPayment,
				@vcPaymentReqID)
		END
		ELSE IF SUBSTRING(@vcLine, 1, 3) = '003'
		BEGIN
			SET @vcCESPSendFile = 'P'+SUBSTRING(@vcLine, 4, 25)

			UPDATE @tCESPReceiveFile	
			SET 
				vcCESPSendFile = @vcCESPSendFile
		END

		-- Passe à la prochaine section
		FETCH NEXT FROM crLinesOfBlob
		INTO
			@vcLine
	END

	CLOSE crLinesOfBlob
	DEALLOCATE crLinesOfBlob

	-- Fin des traitements
	RETURN
END

