/****************************************************************************************************

	Fonction QUI RETOURNE UNE DATE SANS L'HEURE

*********************************************************************************
	28-04-2004 Dominic Létourneau
		Migration de l'ancienne fonction selon les nouveaux standards
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_DateNoTime (@InputDate MoDate) -- Date avec heure
RETURNS MoDate
AS

BEGIN

	-- Si la date reçue est nulle
	IF dbo.FN_CRQ_IsDateNull(@InputDate) IS NULL
		RETURN(NULL) -- NULL est retourné
	
	-- Sinon, on enlève l'heure à la date
	RETURN(CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, @InputDate))))

END
