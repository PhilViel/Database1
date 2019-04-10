
/****************************************************************************************************
Copyright (c) 2006 Gestion Universitas.Inc
Nom 			:	fn_Un_GetLastDepositDate
Description 		:	Fonction calculant la date du dernier dépôt
Valeurs de retour	:	Table temporaire
Note			:	
									2004-08-20	Bruno Lapointe	Migration de l'ancienne fonction selon les nouveaux standards
					ADX0001374	IA	2007-05-30	Alain Quirion	Si @FPmtQty = 1 alros on retuorne la date d'entrée en vigueur de la convention	
*********************************************************************************/
CREATE FUNCTION dbo.fn_Un_GetLastDepositDate (
	@FPmtByYearID        INTEGER,   
	@FFirstPmtDate       DATETIME,
	@FInForceDate        DATETIME,
	@FPmtQty             INTEGER)  
RETURNS MoDate 
AS  
BEGIN
	DECLARE 
		@FLastPmtDate   DATETIME,
		@FMonth         INTEGER,
		@FDay           INTEGER,
		@FYear          INTEGER,
		@FNbrMonth      INTEGER

	IF @FPmtQty = 1
	BEGIN
		SET @FLastPmtDate = @FInForceDate
	END
	ELSE IF @FPmtByYearID = 1
	BEGIN
		SET @FMonth = MONTH(@FFirstPmtDate)
		SET @FDay   = DAY(@FFirstPmtDate)
		SET @FYear  = YEAR(@FInForceDate)+(@FPmtQty-1) 

		IF DAY(DATEADD(DAY, -1, DATEADD(MONTH, 1, CAST(CAST(@FYear AS VARCHAR) +'-'+ CAST(@FMonth AS VARCHAR) +'-'+ CAST(1 AS VARCHAR) AS DATETIME)))) < @FDay
		SET @FDay = DAY(DATEADD(DAY, -1, DATEADD(MONTH, 1, CAST(CAST(@FYear AS VARCHAR) +'-'+ CAST(@FMonth AS VARCHAR) +'-'+ CAST(1 AS VARCHAR) AS DATETIME))))

		SET @FLastPmtDate = CAST(CAST(@FYear AS VARCHAR) +'-'+ CAST(@FMonth AS VARCHAR) +'-'+ CAST(@FDay AS VARCHAR) AS DATETIME)
	END 
	ELSE 
	BEGIN
		SET @FMonth = MONTH(@FInForceDate) 
		SET @FDay   = DAY(@FFirstPmtDate) 
		SET @FYear  = YEAR(@FInForceDate) 
		
		IF @FPmtByYearID = 0 
			SET @FNbrMonth = 0
		ELSE 
			SET @FNbrMonth = FLOOR((@FPmtQty-1) * (12/@FPmtByYearID)) 
		
		SET @FYear = @FYear + FLOOR(@FNbrMonth/12) 
		
		SET @FNbrMonth = @FNbrMonth - (FLOOR(@FNbrMonth/12)*12) 
		
		IF (@FNbrMonth + @FMonth) > 12 
		BEGIN 
			SET @FYear  = @FYear + 1 
			SET @FMonth = (@FNbrMonth + @FMonth)-12 
		END
		ELSE
			SET @FMonth = @FMonth + @FNbrMonth

		IF DAY(DATEADD(DAY, -1, DATEADD(MONTH, 1, CAST(CAST(@FYear AS VARCHAR) +'-'+ CAST(@FMonth AS VARCHAR) +'-'+ CAST(1 AS VARCHAR) AS DATETIME)))) < @FDay
		SET @FDay = DAY(DATEADD(DAY, -1, DATEADD(MONTH, 1, CAST(CAST(@FYear AS VARCHAR) +'-'+ CAST(@FMonth AS VARCHAR) +'-'+ CAST(1 AS VARCHAR) AS DATETIME))))

		SET @FLastPmtDate = CAST(CAST(@FYear AS VARCHAR) +'-'+ CAST(@FMonth AS VARCHAR) +'-'+ CAST(@FDay AS VARCHAR) AS DATETIME)
	END

	RETURN(@FLastPmtDate)                  
END

