/****************************************************************************************************
	Fonction de transformation d'un blob en lignes de textes.  En fait il, crée 
	une table contenant en enregistrement par ligne retrouvé dans le blob.  
	8000 caractères maximum par ligne retour de chariot inclus.
*********************************************************************************
	2004-08-02 Bruno Lapointe
		Création
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_LinesOfBlob (@BlobID INTEGER) -- ID du blob de la table CRQ_Blob qui contient les IDs 
RETURNS @LineTable TABLE (Val VARCHAR(8000))
AS
BEGIN
	
	-- Variables de travail
	DECLARE 
		@PosOper INTEGER,
		@EndPos INTEGER,
		@BlobPart VARCHAR(8000)

	-- Découpe le blob en section de moins de 8000 caractères
	DECLARE BlobPart CURSOR FOR
		SELECT Val
		FROM dbo.FN_CRQ_SectionOfBlob(@BlobID)
		
	OPEN BlobPart
	
	-- Va chercher la première section du blob			
	FETCH NEXT FROM BlobPart
	INTO
		@BlobPart
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @PosOper = 1
		SET @EndPos = 1

		WHILE @EndPos > 0
		BEGIN
			IF CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper) > 0
				SET @EndPos = CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper)
			ELSE 
				SET @EndPos = 0
	
			IF @EndPos > 0
			BEGIN
				INSERT INTO @LineTable (Val)
				VALUES (SUBSTRING(@BlobPart, @PosOper, @EndPos - @PosOper))
	
				SET @PosOper = @EndPos + 2
			END
		END

		-- Passe à la prochaine section
		FETCH NEXT FROM BlobPart
		INTO
			@BlobPart
	END

	CLOSE BlobPart
	DEALLOCATE BlobPart

	-- Fin des traitements
	RETURN
END
