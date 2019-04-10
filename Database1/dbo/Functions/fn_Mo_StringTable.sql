

CREATE FUNCTION [dbo].[fn_Mo_StringTable] (@list varchar(8000))
      RETURNS @tbl TABLE (val varchar(50)) AS
BEGIN
  DECLARE @ix  int,
          @pos int,
          @str varchar(8000)
  SET @pos = 1
  SET @ix = 1
  WHILE @ix > 0
  BEGIN
    SET @ix = charindex(',', @list, @pos)
    IF @ix > 0
      SET @str = substring(@list, @pos, @ix - @pos)
    ELSE
      SET @str = substring(@list, @pos, len(@list))
    SET @str = ltrim(rtrim(@str))
    IF (@str LIKE '%[A-Z]%') OR
       (@str LIKE '%[0-9]%')
    BEGIN
      INSERT @tbl (val) VALUES(RTRIM(@str))
    END
    SET @pos = @ix + 1
  END
  RETURN
END

