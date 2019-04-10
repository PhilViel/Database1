


CREATE FUNCTION [dbo].[fn_Mo_Encrypt2008]
-- Par JJL 03-juillet-2008
-- Pour utilisation des majuscules minuscules dans le mot de passe.
 (@String       VarChar(75))
RETURNS MoDesc
AS
BEGIN
  DECLARE
    @position INT,
    @CharList VarChar(62),
    @NewString VarChar(75);
  SET @CharList = 'GDCYI56UVWX81BZPQRS0KJ34L2EF7MNO9ATHwoqcdguxamkjbsrlnfeziyhvpt';
  SET @NewString = '';
  SET @position = 1;
  WHILE @position <= DATALENGTH(@string)
  BEGIN
    SET @NewString = @NewString + CHAR(50 + len(@String) + CHARINDEX(cast(SUBSTRING(@String, @position, 1) as varbinary(1)), cast(@CharList as varbinary(62))));
    SET @position = @position + 1;
  END

  RETURN(@NewString)
END


