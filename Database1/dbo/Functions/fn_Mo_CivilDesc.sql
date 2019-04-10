
--  dbo UDF fn_Mo_SexDesc
--	and returns the civil description 
CREATE FUNCTION dbo.fn_Mo_CivilDesc 
(
  @CivilID       MoLang
)  
RETURNS MoDesc 
AS  
BEGIN
  DECLARE
    @Result MoDesc;
    
  IF ISNULL(@CivilID, '') = '' SET @Result = ''
  ELSE IF @CivilID = 'U' SET @Result = 'Unknow'
  ELSE IF @CivilID = 'S' SET @Result = 'Single'
  ELSE IF @CivilID = 'M' SET @Result = 'Maried'
  ELSE IF @CivilID = 'J' SET @Result = 'Joint'
  ELSE IF @CivilID = 'D' SET @Result = 'Divorced'
  ELSE IF @CivilID = 'P' SET @Result = 'Separated'
  ELSE IF @CivilID = 'W' SET @Result = 'Widowed'

  RETURN(@Result)                  
END

