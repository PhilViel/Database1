/****************************************************************************************************
	Fonction de transformation d'un blob d'entiers en une table d'entiers
*********************************************************************************
	2004-06-28 Bruno Lapointe
		Création
	2004-10-18 Bruno Lapointe
		Ajout du ValID pour connaître l'ordre d'apparition dans le blob.
		IA-ADX0000547
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_BlobToIntegerTable (@BlobID INTEGER) -- ID du blob de la table CRQ_Blob qui contient les IDs 
RETURNS @Table TABLE (
	ValID INTEGER IDENTITY, 
	Val INTEGER)
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
		IF CHARINDEX(',', @BlobPart, @PosOper) > 0
			SET @PosOper = 1
		ELSE 
			SET @PosOper = LEN(@BlobPart)+1

		WHILE CHARINDEX(',', @BlobPart, @PosOper) > 0
			SET @PosOper = CHARINDEX(',', @BlobPart, @PosOper) + 1
		SET @BlobPos = @BlobPos - 1 + @PosOper 

		SET @BlobPart = SUBSTRING(@BlobPart,1,@PosOper-1) 

		INSERT INTO @Table (Val)
		SELECT Val
		FROM dbo.FN_CRQ_IntegerTable(@BlobPart)

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
