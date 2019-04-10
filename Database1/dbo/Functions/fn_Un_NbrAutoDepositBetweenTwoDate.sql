
--  dbo UDF fn_Un_GetLastDepositDate
--	and returns the last Deposit date 
CREATE FUNCTION dbo.fn_Un_NbrAutoDepositBetweenTwoDate 
(
  @FFirstPmtDate       MoDate,
  @FStartDate          MoDate,
  @FEndDate            MoDate,
  @FTimeUnit           UnTimeOut,
  @FTimeLap            MoID,
  @FConventionID       MoID
)  
RETURNS MoID 
AS  
BEGIN

  DECLARE 
    @FNbrOfDeposit  MoID,
    @WorkDate       MoDate

  SET @FNbrOfDeposit = 0
  SET @WorkDate      = @FStartDate

  WHILE @WorkDate <= @FEndDate
  BEGIN
    IF (NOT EXISTS ( SELECT 
                       ConventionID 
                     FROM Un_Breaking 
                     WHERE (ConventionID = @FConventionID) 
                       AND (@WorkDate BETWEEN BreakingStartDate AND BreakingEndDate)))
    BEGIN
      IF   ((@FTimeUnit = 0) AND (@FFirstPmtDate = @WorkDate)) 
        OR ((@FTimeUnit = 1) 
        AND (CAST(DATEDIFF(DAY, @FFirstPmtDate, @WorkDate) AS FLOAT) / @FTimeLap) - FLOOR((DATEDIFF(DAY, @FFirstPmtDate, @WorkDate) / @FTimeLap)) = 0) 
        OR ((@FTimeUnit = 2) 
        AND (DATEPART(dw, @FFirstPmtDate) = DATEPART(dw, @WorkDate)) 
        AND (CAST(DATEDIFF(WEEK, @FFirstPmtDate, @WorkDate) AS FLOAT) / @FTimeLap) - FLOOR((DATEDIFF(WEEK, @FFirstPmtDate, @WorkDate) / @FTimeLap)) = 0) 
        OR ((@FTimeUnit = 3) 
        AND (DATEPART(dd, @FFirstPmtDate) = DATEPART(dd, @WorkDate)) 
        AND (CAST(DATEDIFF(MONTH, @FFirstPmtDate, @WorkDate) AS FLOAT) / @FTimeLap) - FLOOR((DATEDIFF(MONTH, @FFirstPmtDate, @WorkDate) / @FTimeLap)) = 0) 
        OR ((@FTimeUnit = 4) 
        AND (DATEPART(dd, @FFirstPmtDate) = DATEPART(dd, @WorkDate)) 
        AND (DATEPART(mm, @FFirstPmtDate) = DATEPART(mm, @WorkDate)) 
        AND (CAST(DATEDIFF(YEAR, @FFirstPmtDate, @WorkDate) AS FLOAT) / @FTimeLap) - FLOOR((DATEDIFF(YEAR, @FFirstPmtDate, @WorkDate) / @FTimeLap)) = 0)
        SET @FNbrOfDeposit = @FNbrOfDeposit +1
    END

    SET @WorkDate = DATEADD(DAY, 1, @WorkDate)
  END

  RETURN(@FNbrOfDeposit)                  
END

