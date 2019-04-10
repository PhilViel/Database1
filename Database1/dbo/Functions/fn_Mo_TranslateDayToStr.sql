
CREATE FUNCTION dbo.fn_Mo_TranslateDayToStr
( @FDate       MoDate,
  @FLang       MoLang     -- Language  FRA = French / ENU = English / UNK = Unknown
)
RETURNS MoDesc
AS
BEGIN
DECLARE
  @FDayStr  MoDesc;

  IF (dbo.fn_Mo_DateNoTime(@FDate)) IS NULL
    RETURN('')

  --Default setting is in english

  SET @FDayStr = RTRIM(LTRIM(DATENAME(WeekDay, @FDate)))

  IF @FLang = 'FRA'
  BEGIN
    IF UPPER(@FDayStr) = 'SUNDAY' SET @FDayStr = 'Dimanche'
    ELSE IF UPPER(@FDayStr) = 'MONDAY' SET @FDayStr = 'Lundi'
    ELSE IF UPPER(@FDayStr) = 'TUESDAY' SET @FDayStr = 'Mardi'
    ELSE IF UPPER(@FDayStr) = 'WEDNESDAY' SET @FDayStr = 'Mercredi'
    ELSE IF UPPER(@FDayStr) = 'THURSDAY' SET @FDayStr = 'Jeudi'
    ELSE IF UPPER(@FDayStr) = 'FRIDAY' SET @FDayStr = 'Vendredi'
    ELSE IF UPPER(@FDayStr) = 'SATURDAY' SET @FDayStr = 'Samedi'
  END;

  RETURN(@FDayStr)
END

