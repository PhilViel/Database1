
CREATE FUNCTION dbo.fn_Mo_FormatStringForSearch
  (@FString     MoDescOption)
RETURNS MoDesc
AS
BEGIN
  DECLARE
    @i		 int,
    @FChar 	 varchar,
    @ReplaceChar varchar(10),
    @NewString   varchar(5000);

  IF @FString IS NULL
    RETURN('')

  SET @NewString = '';
  SET @i = 0;

  WHILE @i <= Len(@FString)
  BEGIN
    SET @FChar = SUBSTRING (@FString, @i, 1);

    IF CHARINDEX(@FChar, 'AÀÁÂÃÄÅ',0) > 0
      SET @ReplaceChar = '[AÀÁÂÃÄÅ]'
    ELSE
    IF CHARINDEX(@FChar, 'EÈÉÊË',0)  > 0
      SET @ReplaceChar = '[EÈÉÊË]'
    ELSE
    IF CHARINDEX(@FChar, 'IÌÍÎÏ',0)  > 0
      SET @ReplaceChar = '[IÌÍÎÏ]'
    ELSE
    IF CHARINDEX(@FChar, 'OÒÓÔÕÖ',0)  > 0
      SET @ReplaceChar = '[OÒÓÔÕÖ]'
    ELSE
    IF CHARINDEX(@FChar, 'UÙÚÛÜ',0)  > 0
      SET @ReplaceChar = '[UÙÚÛÜ]'
    ELSE
    IF CHARINDEX(@FChar, 'YÝ',0)  > 0
      SET @ReplaceChar = '[YÝ]'
    ELSE
    IF CHARINDEX(@FChar, 'NÑ',0)  > 0
      SET @ReplaceChar = '[NÑ]'
    ELSE
    IF CHARINDEX(@FChar, 'CÇ',0)  > 0
      SET @ReplaceChar = '[CÇ]'
    ELSE
      SET @ReplaceChar = @FChar;

    SET @NewString = @NewString + @ReplaceChar;
    SET @i = @i + 1;
  END;

  RETURN(@NewString)
END

