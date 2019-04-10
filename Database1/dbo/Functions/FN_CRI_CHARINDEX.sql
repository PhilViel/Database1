/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRI_CHARINDEX
Description 		:	Recherche une chaine de caractère dans un blob avec une position de départ.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000714	IA	2005-09-13	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRI_CHARINDEX (
	@SearchString VARCHAR(5), -- The sequence of characters to be found
	@InputString TEXT, -- The expression or column searched for the specified sequence
	@Position INTEGER ) -- The character position to start searching for @SearchString in @InputString.
RETURNS INTEGER
AS
BEGIN
  DECLARE 
		@OutputPosition INTEGER,
		@TextSize INTEGER

  -- Retrieve the text length
  SET @TextSize = DATALENGTH(@InputString)

  -- StartPosition cannot be negative
  IF @Position <= 0
		SET @Position = 1

  -- If StartPosition is greater than the length of InputString RETURN 0
  IF (@Position > @TextSize)
		RETURN (0)

  -- Now search the TextValue field of the table for the @SearchString value starting at the desired point
  SELECT @OutputPosition = @Position + PATINDEX('%' + @SearchString + '%', SUBSTRING(@InputString, @Position, (@TextSize - @Position + 1))) - 1

  RETURN (@OutputPosition)
END
