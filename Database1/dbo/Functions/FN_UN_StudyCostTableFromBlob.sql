/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 			:	FN_UN_StudyCostTableFromBlob
Description 		:	Retourne une table des années et coûts des études inclus dans le blob : Format du blob : Année,Cout,Année,Cout,Année,Cout, [Doit terminer par une virgule]
Valeurs de retour	:	Table temporaire
Note			:	ADX0001158	IA	2006-10-10	Alain Quirion		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_StudyCostTableFromBlob(
@iBlobID INTEGER) 					-- ID Unique du blob de la table CRI_Blob
RETURNS @tStudyCostTable 
	TABLE (
		YearQualif INTEGER,
		StudyCost FLOAT)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,	
		@iLineLength INTEGER,
		@iYearQualif INTEGER,
		@fStudyCost FLOAT

	SELECT @vcLine = txBlob
	FROM CRI_Blob
	WHERE iBlobID = @iBlobID
	
	SET @iLineLength = LEN(@vcLine)
	SET @iPos = 1		
	SET @iEndPos = 0
	
	IF @iLineLength > 1
	BEGIN
		WHILE @iEndPos < @iLineLength
		BEGIN		
			-- Va chercher l'année de qualification
			SET @iEndPos = CHARINDEX(',', @vcLine, @iPos)
			SET @iYearQualif = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
		
			-- Va chercher le coût des études
			SET @iEndPos = CHARINDEX(',', @vcLine, @iPos)
			SET @fStudyCost = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS FLOAT)
			SET @iPos = @iEndPos + 1
		
			INSERT INTO @tStudyCostTable(YearQualif, StudyCost)
			VALUES(@iYearQualif, @fStudyCost)
		END
	END
	
	RETURN
END

