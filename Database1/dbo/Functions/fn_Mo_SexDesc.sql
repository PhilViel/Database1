
--  dbo UDF fn_Mo_SexDesc
--	and returns the sex description 
CREATE FUNCTION dbo.fn_Mo_SexDesc 
(
  @SexID       MoSex
)  
RETURNS MoDesc 
AS  
BEGIN
  DECLARE
    @Result MoDesc;

  IF ISNULL(@SexID, '') = '' SET @Result = ''
  ELSE IF @SexID = 'U' SET @Result = 'Unknow'
  ELSE IF @SexID = 'F' SET @Result = 'Female'
  ELSE IF @SexID = 'M' SET @Result = 'Male'

  RETURN(@Result)                  
END

