
CREATE FUNCTION dbo.fn_Mo_DateToCompleteDayStr
( @FDate	MoDate,
  @FLangID	MoLang
)
RETURNS MoDesc
AS
BEGIN
  DECLARE
    @FDay     MoID,
    @FDayStr  MoDesc,
    @FAbrev   MoDesc;

  IF (dbo.fn_Mo_DateNoTime(@FDate)) IS NULL
    RETURN('')

  SET @FDay = DAY( @FDate );
  SET @FDayStr = dbo.fn_Mo_TranslateDayToStr( @FDate, @FLangID );

  IF @FLangID = 'FRA'
  BEGIN
   IF @FDay = 1
     SET @FAbrev = 'er'
   ELSE
     SET @FAbrev = 'e'

   SET @FDayStr = DATENAME( Day, @FDate ) + @FAbrev;
  END
  ELSE
  IF @FLangID = 'ENU'
  BEGIN
    IF @FDay IN ( 1,21,31 )
      SET @FAbrev = 'st'
    ELSE IF @FDay IN ( 2, 22 )
      SET @FAbrev = 'nd'
    ELSE IF @FDay IN ( 3,23 )
      SET @FAbrev = 'rd'
    ELSE
      SET @FAbrev = 'th'

    SET @FDayStr = DATENAME( Day, @FDate ) + @FAbrev;
  END

  RETURN (@FDayStr);
END

