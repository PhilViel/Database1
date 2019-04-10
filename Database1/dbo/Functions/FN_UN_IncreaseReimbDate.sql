/****************************************************************************************************
Copyright (c) 2006 Gestion Universitas Inc
Nom 			:	FN_UN_IncreaseReimbDate
Description 		:	Fonction qui renvoit la date de remboursement intégral suivante
Valeurs de retour	:	
Note			:	ADX0001114	IA	2006-11-20	Alain Quirion	Création				
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_IncreaseReimbDate (
	@dtReimbDate DATETIME )  
RETURNS DATETIME 
AS
BEGIN
	DECLARE 
		@dtNewReimbDate DATETIME,
		@iYear INTEGER,
		@iMonth INTEGER,
		@iDay INTEGER
	
	SET @iYear = YEAR(@dtReimbDate)
	SET @iMonth = MONTH(@dtReimbDate)
	SET @iDay = DAY(@dtReimbDate)
	
	IF @iMonth = 1
		AND @iDay = 15		-- 15 Jan.
	BEGIN
		SET @dtNewReimbDate = CAST(CAST(@iYear AS VARCHAR) + '-05-01' AS DATETIME)
	END
	ELSE IF @iMonth = 5
		AND @iDay = 1		-- 1er Mai
	BEGIN
		SET @dtNewReimbDate = CAST(CAST(@iYear AS VARCHAR) + '-05-15' AS DATETIME)
	END
	ELSE IF @iMonth = 5
		AND @iDay = 15		-- 15 Mai
	BEGIN
		SET @dtNewReimbDate = CAST(CAST(@iYear AS VARCHAR) + '-09-15' AS DATETIME)
	END
	ELSE IF @iMonth = 9
		AND @iDay = 15		-- 15 Sept.
	BEGIN
		SET @dtNewReimbDate = CAST(CAST(@iYear AS VARCHAR) + '-11-01' AS DATETIME)
	END
	ELSE IF @iMonth = 11
		AND @iDay = 1		-- 1er Nov.
	BEGIN
		SET @dtNewReimbDate = CAST(CAST((@iYear+1) AS VARCHAR) + '-01-15' AS DATETIME)
	END

	RETURN @dtNewReimbDate
END


