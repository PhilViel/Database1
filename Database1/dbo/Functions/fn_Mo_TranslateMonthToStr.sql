
CREATE FUNCTION dbo.fn_Mo_TranslateMonthToStr
( @FDate       MoDate,
  @FLang       MoLang     -- Language  FRA = French / ENU = English / UNK = Unknown
)
RETURNS MoDesc
AS
BEGIN
DECLARE
  @FMonthStr  MoDesc;

  IF (dbo.fn_Mo_DateNoTime(@FDate)) IS NULL
    RETURN('')

  --Default setting is in english
  SET @FMonthStr = RTRIM(LTRIM(DATENAME(Month, @FDate)))

  IF @FLang = 'FRA'
  BEGIN
    IF UPPER(@FMonthStr) = 'JANUARY' SET @FMonthStr = 'janvier'
    ELSE IF UPPER(@FMonthStr) = 'FEBRUARY' SET @FMonthStr = 'février'
    ELSE IF UPPER(@FMonthStr) = 'MARCH' SET @FMonthStr = 'mars'
    ELSE IF UPPER(@FMonthStr) = 'APRIL' SET @FMonthStr = 'avril'
    ELSE IF UPPER(@FMonthStr) = 'MAY' SET @FMonthStr = 'mai'
    ELSE IF UPPER(@FMonthStr) = 'JUNE' SET @FMonthStr = 'juin'
    ELSE IF UPPER(@FMonthStr) = 'JULY' SET @FMonthStr = 'juillet'
    ELSE IF UPPER(@FMonthStr) = 'AUGUST' SET @FMonthStr = 'août'
    ELSE IF UPPER(@FMonthStr) = 'SEPTEMBER' SET @FMonthStr = 'septembre'
    ELSE IF UPPER(@FMonthStr) = 'OCTOBER' SET @FMonthStr = 'octobre'
    ELSE IF UPPER(@FMonthStr) = 'NOVEMBER' SET @FMonthStr = 'novembre'
    ELSE IF UPPER(@FMonthStr) = 'DECEMBER' SET @FMonthStr = 'décembre'
  END;

  RETURN(@FMonthStr)
END

