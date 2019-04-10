/****************************************************************************************************

	Fonction VÉRIFIANT SI UNE DATE EST NULLE

*********************************************************************************
	27-04-2004 Dominic Létourneau
		Migration de l'ancienne fonction selon les nouveaux standards
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_IsDateNull (@InputDate MoDate) -- Description Param1
RETURNS MoDate
AS

BEGIN

	-- Si la date est nulle ou plus petite que 1
	IF ISNULL(@InputDate,0) < 1
		RETURN(NULL) -- Retourne NULL

	-- Sinon retourne la date reçue
	RETURN(@InputDate) 

END

