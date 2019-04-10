/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_TINOfBlob
Description 		:	Retourne tous les objets de type Un_TIN contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000925	IA	2006-05-09	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_TINOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tTIN
	TABLE (
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
		bPendingApplication BIT
		)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		-----------------
		@OperID INTEGER,
		@ExternalPlanID INTEGER,
		@tiBnfRelationWithOtherConvBnf TINYINT,
		@vcOtherConventionNo VARCHAR(15),
		@dtOtherConvention DATETIME,
		@tiOtherConvBnfRelation TINYINT,
		@bAIP BIT,
		@bACESGPaid BIT,
		@bBECInclud BIT,
		@bPGInclud BIT,
		@fYearBnfCot MONEY,
		@fBnfCot MONEY,
		@fNoCESGCotBefore98 MONEY,
		@fNoCESGCot98AndAfter MONEY,
		@fCESGCot MONEY,
		@fCESG MONEY,
		@fCLB MONEY,
		@fAIP MONEY,
		@fMarketValue MONEY,
		@bPendingApplication BIT

	-- Va chercher les lignes contenus dans le blob
	DECLARE crLinesOfBlob CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
		
	OPEN crLinesOfBlob
	
	-- Va chercher la première ligne			
	FETCH NEXT FROM crLinesOfBlob
	INTO
		@vcLine
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Recherche la prochaine ligne de données TIN du blob
		IF CHARINDEX('Un_TIN', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_TIN dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1

			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ExternalPlanID 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ExternalPlanID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le tiBnfRelationWithOtherConvBnf 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @tiBnfRelationWithOtherConvBnf = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le vcOtherConventionNo 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @vcOtherConventionNo = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le dtOtherConvention 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @dtOtherConvention = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
			SET @iPos = @iEndPos + 1

			-- Va chercher le tiOtherConvBnfRelation
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @tiOtherConvBnfRelation = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le bAIP
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @bAIP = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le bACESGPaid
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @bACESGPaid = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le bBECInclud
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @bBECInclud = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le bPGInclud
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @bPGInclud = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fYearBnfCot
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fYearBnfCot = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fBnfCot
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fBnfCot = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fNoCESGCotBefore98
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fNoCESGCotBefore98 = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fNoCESGCot98AndAfter
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fNoCESGCot98AndAfter = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fCESGCot
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fCESGCot = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fCESG
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fCESG = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fCLB
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fCLB = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fAIP
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fAIP = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fMarketValue
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fMarketValue = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le bPendingApplication
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @bPendingApplication = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)

			-- Insère l'objet qu'on vient de finir de lire.
			INSERT INTO @tTIN (
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
				bPendingApplication )
			VALUES (
				@OperID,
				@ExternalPlanID,
				@tiBnfRelationWithOtherConvBnf,
				@vcOtherConventionNo,
				@dtOtherConvention,
				@tiOtherConvBnfRelation,
				@bAIP,
				@bACESGPaid,
				@bBECInclud,
				@bPGInclud,
				@fYearBnfCot,
				@fBnfCot,
				@fNoCESGCotBefore98,
				@fNoCESGCot98AndAfter,
				@fCESGCot,
				@fCESG,
				@fCLB,
				@fAIP,
				@fMarketValue,
				@bPendingApplication )

			-- Remet les variables de champs vides pour le prochain objet.
			SET @OperID = NULL
			SET @ExternalPlanID = NULL
			SET @tiBnfRelationWithOtherConvBnf = NULL
			SET @vcOtherConventionNo = NULL
			SET @dtOtherConvention = NULL
			SET @tiOtherConvBnfRelation = NULL
			SET @bAIP = NULL
			SET @bACESGPaid = NULL
			SET @bBECInclud = NULL
			SET @bPGInclud = NULL
			SET @fYearBnfCot = NULL
			SET @fBnfCot = NULL
			SET @fNoCESGCotBefore98 = NULL
			SET @fNoCESGCot98AndAfter = NULL
			SET @fCESGCot = NULL
			SET @fCESG = NULL
			SET @fCLB = NULL
			SET @fAIP = NULL
			SET @fMarketValue = NULL
			SET @bPendingApplication = NULL
		END

		-- Passe à la prochaine ligne
		FETCH NEXT FROM crLinesOfBlob
		INTO
			@vcLine
	END

	CLOSE crLinesOfBlob
	DEALLOCATE crLinesOfBlob

	-- Fin des traitements
	RETURN
END

