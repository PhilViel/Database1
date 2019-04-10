/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_StudyCostBatch 
Description         :	Procédure qui insère ou met à jour les coût des études en Batch pour une année de qualification.
Valeurs de retours  :	@ReturnValue :
					> 0 : [Réussite]
					<= 0 : [Échec].
Note                :	ADX0001158	IA	2006-10-10	Alain Quirion		Création
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_StudyCostBatch](
@iBlobID INTEGER)		-- ID du blob
AS
BEGIN
	DECLARE
		@iReturn INTEGER,
		@iYearQualif INTEGER,
		@fStudyCost FLOAT

	SET @iReturn = 1

	CREATE TABLE #Tmp_StudyCost(
		YearQualif INTEGER,
		StudyCost FLOAT)

	INSERT INTO #Tmp_StudyCost
	SELECT * FROM dbo.FN_UN_StudyCostTableFromBlob(@iBlobID)

	DECLARE CUR_StudyCost CURSOR FOR
	SELECT *
	FROM #Tmp_StudyCost

	OPEN CUR_StudyCost

	FETCH NEXT FROM CUR_StudyCost
	INTO
		@iYearQualif,
		@fStudyCost

	WHILE @@FETCH_STATUS = 0 AND @iReturn > 0
	BEGIN	
		IF NOT EXISTS(SELECT * FROM Un_StudyCost WHERE YearQualif = @iYearQualif)
		BEGIN
			INSERT INTO Un_StudyCost(YearQualif, StudyCost)
			VALUES(@iYearQualif, @fStudyCost)
	
			IF @@ERROR <> 0
				SET @iReturn = -1
		END
		ELSE
		BEGIN
			UPDATE Un_StudyCost
			SET StudyCost = @fStudyCost
			WHERE YearQualif = @iYearQualif
	
			IF @@ERROR <> 0
				SET @iReturn = -2
		END

		FETCH NEXT FROM CUR_StudyCost
		INTO
			@iYearQualif,
			@fStudyCost	
	END

	CLOSE CUR_StudyCost
	DEALLOCATE CUR_StudyCost
	
	RETURN @iReturn
END

