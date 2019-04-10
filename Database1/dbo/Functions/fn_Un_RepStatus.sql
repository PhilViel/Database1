
CREATE FUNCTION dbo.fn_Un_RepStatus 
(
  @StartDate     MoGetDate,   
  @EndDate       MoGetDate,
  @CurrentDate   MoGetDate
)  
RETURNS MoID 
AS  
BEGIN
  DECLARE @Result MoID;


  IF (@StartDate IS NOT NULL) AND
     (@StartDate <= @CurrentDate) AND
     (@EndDate IS NULL OR
      @EndDate >= @CurrentDate)
    SET @Result = 1
  ELSE 
    SET @Result = 0;
  RETURN(@Result);
END

