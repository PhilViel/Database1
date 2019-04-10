
CREATE FUNCTION [dbo].[fn_Mo_IntegerTable] (@list varchar(8000))
      RETURNS @tbl TABLE (val int) AS
BEGIN
  DECLARE @ix  int,
          @pos int,
          @str varchar(8000),
          @num int
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
    IF @str LIKE '%[0-9]%' AND
      (@str NOT LIKE '%[^0-9]%' OR
       @str LIKE '[-+]%' AND
      substring(@str, 2, len(@str)) NOT LIKE '[-+]%[^0-9]%')
    BEGIN
      SET @num = convert(int, @str)
      INSERT @tbl (val) VALUES(@num)
    END
    SET @pos = @ix + 1
  END
  RETURN
END

