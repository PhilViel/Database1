
--  dbo UDF fn_Mo_SexDesc
--	and returns the language description 
CREATE FUNCTION dbo.fn_Mo_LangDesc 
(
  @LangID       MoLang
)  
RETURNS MoDesc 
AS  
BEGIN
  DECLARE
    @Result MoDesc;
    
  IF ISNULL(@LangID, '') = '' SET @Result = ''
  ELSE IF @LangID = 'UNK' SET @Result = 'Unknow'
  ELSE IF @LangID = 'ENU' SET @Result = 'English'
  ELSE IF @LangID = 'FRA' SET @Result = 'French'

  RETURN(@Result)                  
END

