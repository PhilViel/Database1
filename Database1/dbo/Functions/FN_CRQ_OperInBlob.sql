/****************************************************************************************************
	Fonction qui va extraire les opérations d'un blob contenant du text ASCII
*********************************************************************************
	2004-06-28 Bruno Lapointe
		Création
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_OperInBlob (
	@BlobID INTEGER) -- ID du blob contenant l'information qu'il faut aller chercher
RETURNS @OperTable 
	TABLE (
		LigneTrans INTEGER,
		OperID INTEGER,
		ConnectID INTEGER,
		OperTypeID CHAR(3),
		OperDate DATETIME)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@Pos INTEGER,
		@PosOper INTEGER,
		@EndPos INTEGER,
		@StrOper VARCHAR(8000),
		@LigneTrans INTEGER,
		@OperID INTEGER,
		@ConnectID INTEGER,
		@OperTypeID CHAR(3),
		@OperDate DATETIME,
		@BlobPos INTEGER,
		@BlobPart VARCHAR(8000),
		@BlobLength INTEGER

	SET @BlobPos = 1

	SELECT 
		@BlobPart = 
			CASE 
				WHEN DATALENGTH (Blob) < 8000 THEN SUBSTRING(Blob, @BlobPos, DATALENGTH (Blob))
			ELSE SUBSTRING(Blob, @BlobPos, 8000)
			END,
		@BlobLength = DATALENGTH (Blob)
	FROM CRQ_Blob
	WHERE BlobID = @BlobID


	WHILE @BlobPos < @BlobLength 
	BEGIN
		-- Initilisation des variables	
		SET @PosOper = 1

		-- Boucle tant qu'il reste des caractères dans la chaîne
		WHILE @PosOper > 0
		BEGIN
			-- Recherche la prochaine ligne d'opération du blob
			IF CHARINDEX('Un_Oper', @BlobPart, @PosOper) = 0
				SET @PosOper = 0
			ELSE
			BEGIN
				SET @PosOper = CHARINDEX('Un_Oper', @BlobPart, @PosOper)
	
				SET @EndPos = CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper)
	
				IF @EndPos > 0
				BEGIN
					-- Va chercher la ligne contenant l'opération
					SET @StrOper = SUBSTRING(@BlobPart, @PosOper, @EndPos - @PosOper)
	
					-- Saute la ligne au niveau du blob avant de traité l'opération
					SET @PosOper = @EndPos + 2
	
					-- Début du traitement de l'opération
	
					-- Saute par dessus le nom de la table qui est Un_Oper dans tout les cas
					SET @Pos = CHARINDEX(';', @StrOper, 1) + 1
	
					-- Va chercher le numéro de ligne 
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @LigneTrans = CAST(SUBSTRING(@StrOper, @Pos, @EndPos - @Pos) AS INTEGER)
					SET @Pos = @EndPos + 1
	
					-- Va chercher le OperID
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @OperID = CAST(SUBSTRING(@StrOper, @Pos, @EndPos - @Pos) AS INTEGER)
					SET @Pos = @EndPos + 1
	
					-- Va chercher le ConnectID
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @ConnectID = CAST(SUBSTRING(@StrOper, @Pos, @EndPos - @Pos) AS INTEGER)
					SET @Pos = @EndPos + 1
	
					-- Va chercher le OperTypeID
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @OperTypeID = SUBSTRING(@StrOper, @Pos, @EndPos - @Pos)
					SET @Pos = @EndPos + 1
	
					-- Va chercher le OperDate
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @OperDate = CAST(SUBSTRING(@StrOper, @Pos, @EndPos - @Pos) AS DATETIME)
	
					INSERT INTO @OperTable ( 
						LigneTrans,
						OperID,
						ConnectID,
						OperTypeID,
						OperDate)
					VALUES (
						@LigneTrans,
						@OperID,
						@ConnectID,
						@OperTypeID,
						@OperDate)
					-- Fin du traitement de l'opération
				END	
				ELSE 
					SET @PosOper = 0 -- Il n'y a pas de caractère de fin de ligne, le format du blob est donc incorrect alors il quitte la fonction 
			END
		END
		-- Va chercher la position du dernier retour de chariot
		SET @PosOper = 1
		WHILE CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper) > 0
			SET @PosOper = CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper) + 2
		SET @BlobPos = @BlobPos - 2 + @PosOper 

		IF @BlobPos < @BlobLength
			SELECT 
				@BlobPart = 
					CASE 
						WHEN @BlobLength < (@BlobPos + 8000) THEN SUBSTRING(Blob, @BlobPos, @BlobLength - @BlobPos + 1)
					ELSE SUBSTRING(Blob, @BlobPos, 8000)
					END
			FROM CRQ_Blob
			WHERE BlobID = @BlobID
	END

	-- Fin des traitements
	RETURN
END
