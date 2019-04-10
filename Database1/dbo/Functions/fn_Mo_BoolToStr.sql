
CREATE FUNCTION dbo.fn_Mo_BoolToStr
( @FBool       MoBitTrue,
  @FLang       MoLang     -- Language  FRA = French / ENU = English / UNK = Unknown
)
RETURNS MoDesc
AS
BEGIN
DECLARE
  @FBoolStr  MoDesc

  IF @FBool IS NULL
    RETURN ('');
    
  IF @FLang = 'FRA'
  BEGIN
    IF @FBool = 0
      SET @FBoolStr = 'Faux'
    ELSE
      SET @FBoolStr = 'Vrai'
  END
  ELSE
  BEGIN
    --Default setting is in english
    IF @FBool = 0
      SET @FBoolStr = 'False'
    ELSE
      SET @FBoolStr = 'True'
  END

  RETURN(@FBoolStr)
END

