
CREATE FUNCTION dbo.fn_Mo_DateToShortDateStr
( @FDate       MoDate,
  @FLang       MoLang     -- Language  FRA = French / ENU = English / UNK = Unknown
)
RETURNS MoDesc
AS
BEGIN
DECLARE
  @FDateStr  MoDesc

  IF (dbo.fn_Mo_DateNoTime(@FDate)) IS NULL
    RETURN('')

  --Default setting is in english
  SET @FDateStr = CONVERT(Char(12), @FDate, 110)  -- mm-dd-yyyy

  IF @FLang = 'FRA'
    SET @FDateStr = CONVERT(Char(12), @FDate, 105)  -- dd-mm-yyyy

  RETURN(@FDateStr)
END

