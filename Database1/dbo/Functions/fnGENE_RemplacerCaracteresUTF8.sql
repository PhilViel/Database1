create FUNCTION [dbo].[fnGENE_RemplacerCaracteresUTF8] (@String VarChar(8000)) RETURNS VarChar(8000)
AS
BEGIN
	/* Remplace les caractères spéciaux d'une string par les mêmes caractères sans encodage */
	RETURN (
		SELECT
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			REPLACE(
			@String, 
			'Ãˆ','È'),
			'àˆ','È'),
			'Ã', 'Â'),
			'Ã', 'À'),
			'â', '€'),
			'Å', 'œ'),
			'Ã§', 'ç'),
			'Ã¼', 'ü'),
			'Ã»', 'û'),
			'Ã¹', 'ù'),
			'Ã¶', 'ö'),
			'Ã´', 'ô'),
			'Ã¯', 'ï'),
			'Ã®', 'î'),
			'Ã«', 'ë'),
			'Ãª', 'è'),
			'Ã¨', 'è'),
			'Ã©', 'é'),
			'Ã¢', 'à'),
			'Ã', 'É'),
			'Ã', 'È'),
			'Ã', 'Ê'),
			'Ã', 'Ë'),
			'Ã', 'Î'),
			'Ã', 'Ï'),
			'Ã', 'Ô'),
			'Ã', 'Ö'),
			'Ã', 'Ù'),
			'Ã', 'Û'),
			'Ã', 'Ü'),
			'Ã', 'Ç'),
			'Å', 'Œ'),
			'â€“','-'),
			'à€','à'),
			'Ã', 'à'),
			'€',''),
			'â€™','''')
		)
END
