
--  dbo UDF fn_Un_GetLastDepositDate
--	Returns the Age in years between 2 dates 
CREATE FUNCTION dbo.fn_Mo_Age 
(
  @FBirthDate       MoDate,
  @FToDate          MoDate
)  
RETURNS MoID 
AS  
BEGIN

  DECLARE 
    @Age MoID;

  IF @FToDate < @FBirthDate 
    RETURN(0)
  ELSE 
    SELECT 
      @Age = DATEDIFF(YY, @FBirthDate, @FToDate) - 
             (CASE 
                WHEN (DATEPART(m, @FBirthDate) > DATEPART(m, @FToDate)) 
                  OR (DATEPART(m, @FBirthDate) = DATEPART(m, @FToDate) 
                  AND DATEPART(d, @FBirthDate) > DATEPART(d, @FToDate)) THEN 1
                ELSE 0
	      END)
  RETURN(@Age)
END

