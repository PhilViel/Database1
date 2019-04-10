
--  dbo UDF fn_Mo_PmtByYearDesc
--	and returns the payment by year description 
CREATE FUNCTION dbo.fn_Mo_PmtByYearDesc 
(
  @PmtByYearID       MoPmtByYear
)  
RETURNS MoDesc 
AS  
BEGIN
  DECLARE
    @Result MoDesc;
  
  IF @PmtByYearID = 1 SET @Result  = 'Annual'
  ELSE IF @PmtByYearID = 2 SET @Result  = 'Semi-Annual'
  ELSE IF @PmtByYearID = 4 SET @Result  = 'Quarterly'
  ELSE IF @PmtByYearID = 6 SET @Result  = 'Two Months'
  ELSE IF @PmtByYearID = 12 SET @Result = 'Monthly'
  ELSE SET @Result  = ''


  RETURN(@Result)                  
END

