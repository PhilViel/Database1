/****************************************************************************************************
	Fonction qui extrait une partie de la chaine de caractères selon la langue.
*********************************************************************************
	2004-08-25 Bruno Lapointe
		Migration
*********************************************************************************/
CREATE FUNCTION dbo.fn_Mo_GetCurrentLangDesc
  (@Desc       	varchar(5000),
   @LangID	varchar(3))
  RETURNS varchar(5000)
AS
BEGIN
  DECLARE @ix int,
          @Pos	int,
          @str varchar(8000)
  SET @ix = 0
  SET @pos = charindex('@@', @Desc, @ix);
  IF @pos > 0
  BEGIN
    SET @ix = charindex('@@'+@LangID, @Desc, 1);
    IF @ix > 0
      SET @pos = charindex('@@', @Desc, @ix + 1)
    ELSE
      SET @pos = charindex('@@', @Desc, @Pos + 1);
    IF @pos = 0
      SET @pos = len(@Desc)+1;
    SET @str = SUBSTRING(@Desc, @ix + 5, @pos - @ix - 5);
  END
  ELSE
    SET @str = @Desc;
  RETURN (@str)
END

