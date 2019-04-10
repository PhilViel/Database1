/********************************************************************************
	Enlève tous les caractères qui ne sont pas des chiffres dans une string
*********************************************************************************
	2004-10-28 Bruno Lapointe
		Création
		BR-ADX0001130
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_GetNumberOfStringOnly (@String VARCHAR(8000)) -- ID du blob de la table CRQ_Blob qui contient les IDs 
RETURNS VARCHAR(8000)
AS
BEGIN
	DECLARE
		@NbChar INTEGER,
		@NewString VARCHAR(8000)

	SET @NewString = ''
	SET @NbChar = 1

	WHILE @NbChar <= LEN(@String)
	BEGIN
		IF SUBSTRING(@String,@NbChar,1) IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0')
			SET @NewString = @NewString + SUBSTRING(@String,@NbChar,1)
		SET @NbChar = @NbChar + 1
	END

	RETURN @NewString
END
