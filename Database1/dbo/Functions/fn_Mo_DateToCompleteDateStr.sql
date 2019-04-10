
CREATE FUNCTION dbo.fn_Mo_DateToCompleteDateStr
( @FDate       MoDate,
  @FLang       MoLang     -- Language  FRA = French / ENU = English / UNK = Unknown
)
RETURNS MoDesc
AS
BEGIN
DECLARE
  @FDateStr  MoDesc,
  @FDayStr   MoDesc,
  @FMonthStr MoDesc,
  @FAbrev    MoDesc,
  @FDay      MoID;

  IF (dbo.fn_Mo_DateNoTime(@FDate)) IS NULL
    RETURN('')

  --Default setting is in english
  SET @FDayStr = dbo.fn_Mo_TranslateDayToStr(@FDate, @FLang)
  SET @FMonthStr = dbo.fn_Mo_TranslateMonthToStr(@FDate, @FLang)

  SET @FDay = DATEPART(Day, @FDate)


  IF @FLang = 'FRA'
  BEGIN
    IF @FDay = 1
      SET @FAbrev = 'er'
    ELSE
      SET @FAbrev = ''

    SET @FDateStr = @FDayStr + ' le ' + RTRIM(LTRIM(DATENAME(Day, @FDate)))+ @FAbrev + ' ' + @FMonthStr + ', ' + RTRIM(LTRIM(DATENAME(Year, @FDate)))
  END
  ELSE
  BEGIN
    IF @FDay IN (1, 21, 31)
      SET @FAbrev = 'st'
    ELSE IF @FDay IN (2, 22)
      SET @FAbrev = 'nd'
    ELSE IF @FDay IN (3, 23)
      SET @FAbrev = 'rd'
    ELSE
      SET @FAbrev = 'th'

    SET @FDateStr = @FDayStr + ', ' + @FMonthStr + ' ' + RTRIM(LTRIM(DATENAME(Day, @FDate)))+@FAbrev + ' ' + RTRIM(LTRIM(DATENAME(Year, @FDate)))
  END

  RETURN(@FDateStr)
END

