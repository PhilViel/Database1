/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRQ_FormatZipCode
Description 		:	Formate les codes postaux
Valeurs de retour	:	Code postal formaté
Note					:	ADX0001474	BR	2005-06-29	Bruno Lapointe		Création
************************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_FormatZipCode (
	@vcZipCode VARCHAR(75), -- Code postal à formater.
	@vcCountryID VARCHAR(4) ) -- Pays de l'adresse qui a le code postal.
RETURNS VARCHAR(75)
AS
BEGIN
	IF @vcZipCode IS NULL
		SET @vcZipCode = ''
	ELSE
	BEGIN
		SET @vcZipCode = UPPER(REPLACE(RTRIM(LTRIM(@vcZipCode)), ' ', ''))
		
		IF @vcCountryID = 'CAN' 
		AND DATALENGTH(@vcZipCode) = 6
			SET @vcZipCode = SUBSTRING(@vcZipCode, 1, 3) + SPACE(1) + SUBSTRING(@vcZipCode, 4, 3)
	END
	
	RETURN(@vcZipCode)
END
