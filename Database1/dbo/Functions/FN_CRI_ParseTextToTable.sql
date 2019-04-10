/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRI_ParseTextToTable
Description 		:	Decode une chaîne de caractères délimitée et le retourner dans une table
Valeurs de retour	:	Table temporaire
Note					:	ADX0000709	IA	2005-09-14	Bernie MacIntyre		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRI_ParseTextToTable (
	@InputString  varchar(8000),	-- The input string to be parsed.
	@Delimiter    varchar(100) = ','	-- The default delimiter is a comma.
)
RETURNS @OutputTable TABLE (
	Position     int identity(1,1),	-- La position dans @InputString
	IntegerValue int,			-- La valeur si c'est un integer
	NumericValue decimal(18,4),	-- La valeur si c'est numeric avec decimal
	VarCharValue varchar(2000)	-- La valeur en charactères
)
AS
BEGIN

	-- Empty or NULL string or Delimiter only
	IF (@InputString IS NULL) OR (DATALENGTH(@InputString) = 0) OR (@InputString = @Delimiter)
		RETURN

	-- Declare all variables
	DECLARE @StartPosition int
	DECLARE @NextPosition  int
	DECLARE @StringLength  int
	DECLARE @IntegerValue int
	DECLARE @DecimalValue decimal(18,4)
	DECLARE @StringValue   varchar(4000)

	-- The last character in the InputString must be a delimiter
	SELECT @InputString = @InputString + @Delimiter

	-- Remove all spaces and doubled delimiters
	SELECT @InputString = REPLACE(@InputString, @Delimiter + @Delimiter, @Delimiter)
	SELECT @InputString = REPLACE(@InputString, ' ', '')

	-- Initialize variables
	SELECT @StringLength = DATALENGTH(@InputString),
			@StartPosition = 0

	-- While there are still values to retrieve
	WHILE (@StartPosition <> @StringLength) BEGIN

		SELECT @IntegerValue = NULL, @DecimalValue = NULL

			-- Retrieve the value from the InputString
		SELECT
			@StartPosition = @StartPosition + 1,
			@NextPosition  = CHARINDEX(@Delimiter, @InputString, @StartPosition + 1),
			@StringValue   = SUBSTRING(@InputString, @StartPosition, @NextPosition - @StartPosition)

		    -- Convert the string to the corresponding numeric value
		IF ISNUMERIC(@StringValue)  = 1 BEGIN
			SELECT @IntegerValue = CAST(CAST(@StringValue AS numeric) AS int),
				@DecimalValue = CAST(@StringValue AS decimal(18,4))
		END

		-- Insert the value in the table
		INSERT INTO @OutputTable VALUES (@IntegerValue, @DecimalValue, @StringValue )

		-- Reposition the starting value
		SELECT @StartPosition = @NextPosition

	END

RETURN

END
