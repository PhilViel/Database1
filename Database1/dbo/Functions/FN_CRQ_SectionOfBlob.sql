/****************************************************************************************************
	Fonction de transformation d'un blob en lignes de textes.  En fait il, crée 
	une table contenant en enregistrement par ligne retrouvé dans le blob.  
	8000 caractères maximum par ligne retour de chariot inclus.
*********************************************************************************
	2004-08-02 Bruno Lapointe
		Création
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_SectionOfBlob (@BlobID INTEGER) -- ID du blob de la table CRQ_Blob qui contient les IDs 
RETURNS @Table TABLE (Val VARCHAR(8000))
AS
BEGIN
	
	-- Variables de travail
	DECLARE 
		@PosOper INTEGER,
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
		SET @PosOper = 1
		-- Va chercher la position du dernier retour de chariot
		IF CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper) > 0
			SET @PosOper = 1
		ELSE 
			SET @PosOper = LEN(@BlobPart)+1

		WHILE CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper) > 0
			SET @PosOper = CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper) + 2
		SET @BlobPos = @BlobPos - 1 + @PosOper

		SET @BlobPart = SUBSTRING(@BlobPart,1,@PosOper-1) 

		INSERT INTO @Table (Val)
		VALUES (@BlobPart)

		IF @BlobPos < @BlobLength
			-- Passe à la prochaine section
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
