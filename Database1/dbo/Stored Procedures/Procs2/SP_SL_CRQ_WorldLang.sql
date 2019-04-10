/****************************************************************************************************
	Procédure retournant les langues mondiales
*********************************************************************************
	26-05-2004 Dominic Létourneau
		Création de la stored procedure pour 10.53.01 (1.3)
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_WorldLang]
AS
BEGIN
	-- Retourne la liste des langues mondiales 
	SELECT 
		WorldLanguageCodeID,
		WorldLanguage
	FROM CRQ_WorldLang
	ORDER BY WorldLanguage
END
