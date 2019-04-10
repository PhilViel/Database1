/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_CESP900OfBlob
Description 		:	Fonction qui extrait les enregistrements 900 d'un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000811	IA	2006-04-17	Bruno Lapointe	Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_CESP900OfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tCESP900 
	TABLE (
		vcTransID VARCHAR(15),
		fCESG MONEY,
		cCESP900CESGReasonID VARCHAR(1),
		tiCESP900OriginID INTEGER,
		ConventionNo VARCHAR(75),
		vcBeneficiarySIN VARCHAR(75),
		fCLB MONEY,
		fACESG MONEY,
		fCLBFee MONEY,
		fPG MONEY,
		vcPGProv VARCHAR(2),
		fCotisationGranted MONEY,
		cCESP900ACESGReasonID VARCHAR(1))
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@vcTransID VARCHAR(15),
		@fCESG MONEY,
		@cCESP900CESGReasonID VARCHAR(1),
		@tiCESP900OriginID INTEGER,
		@ConventionNo VARCHAR(75),
		@vcBeneficiarySIN VARCHAR(75),
		@fCLB MONEY,
		@fACESG MONEY,
		@fCLBFee MONEY,
		@fPG MONEY,
		@vcPGProv VARCHAR(2),
		@fCotisationGranted MONEY,
		@cCESP900ACESGReasonID VARCHAR(1)

	-- va chercher toutes les lignes que contient le blob
	DECLARE crLinesOfBlob CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
		
	OPEN crLinesOfBlob
	
	-- Va chercher la première section du blob			
	FETCH NEXT FROM crLinesOfBlob
	INTO
		@vcLine
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF SUBSTRING(@vcLine, 1, 3) = '900'
		BEGIN
			-- Va chercher les valeurs dans la string
			SET @vcTransID = RTRIM(LTRIM(SUBSTRING(@vcLine, 52, 15)))
			SET @fCESG = CAST(SUBSTRING(@vcLine, 26, 11) AS MONEY)/100
			IF RTRIM(LTRIM(SUBSTRING(@vcLine, 67, 1))) = ''
				SET @cCESP900CESGReasonID = '0'
			ELSE
				SET @cCESP900CESGReasonID = RTRIM(LTRIM(SUBSTRING(@vcLine, 67, 1)))
			SET @tiCESP900OriginID = CAST(SUBSTRING(@vcLine, 68, 1) AS INTEGER)
			SET @ConventionNo = RTRIM(LTRIM(SUBSTRING(@vcLine, 95, 15)))
			SET @vcBeneficiarySIN = RTRIM(LTRIM(SUBSTRING(@vcLine, 118, 9)))
			IF RTRIM(LTRIM(SUBSTRING(@vcLine, 127, 9))) = ''
				SET @fCLB = 0
			ELSE
				SET @fCLB = CAST(SUBSTRING(@vcLine, 127, 9) AS MONEY)/100
			IF RTRIM(LTRIM(SUBSTRING(@vcLine, 136, 9))) = ''
				SET @fACESG = 0
			ELSE
				SET @fACESG = CAST(SUBSTRING(@vcLine, 136, 9) AS MONEY)/100
			IF RTRIM(LTRIM(SUBSTRING(@vcLine, 145, 9))) = ''
				SET @fCLBFee = 0
			ELSE
				SET @fCLBFee = CAST(SUBSTRING(@vcLine, 145, 9) AS MONEY)/100
			IF RTRIM(LTRIM(SUBSTRING(@vcLine, 154, 9))) = ''
				SET @fPG = 0
			ELSE
				SET @fPG = CAST(SUBSTRING(@vcLine, 154, 9) AS MONEY)/100
			SET @vcPGProv = RTRIM(LTRIM(SUBSTRING(@vcLine, 163, 2)))
			IF RTRIM(LTRIM(SUBSTRING(@vcLine, 165, 9))) = ''
				SET @fCotisationGranted = 0
			ELSE
				SET @fCotisationGranted = CAST(SUBSTRING(@vcLine, 165, 9) AS MONEY)/100
			IF RTRIM(LTRIM(SUBSTRING(@vcLine, 174, 1))) = ''
				SET @cCESP900ACESGReasonID = '0'
			ELSE
				SET @cCESP900ACESGReasonID = RTRIM(LTRIM(SUBSTRING(@vcLine, 174, 1)))

			INSERT INTO @tCESP900 ( 
				vcTransID,
				fCESG,
				cCESP900CESGReasonID,
				tiCESP900OriginID,
				ConventionNo,
				vcBeneficiarySIN,
				fCLB,
				fACESG,
				fCLBFee,
				fPG,
				vcPGProv,
				fCotisationGranted,
				cCESP900ACESGReasonID)
			VALUES (
				@vcTransID,
				@fCESG,
				@cCESP900CESGReasonID,
				@tiCESP900OriginID,
				@ConventionNo,
				@vcBeneficiarySIN,
				@fCLB,
				@fACESG,
				@fCLBFee,
				@fPG,
				@vcPGProv,
				@fCotisationGranted,
				@cCESP900ACESGReasonID)
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

