/****************************************************************************************************

	PROCEDURE RETOURNANT LA LANGUE

*********************************************************************************
	07-05-2004 Dominic Létourneau
		Création procedure pour CRQ-ACC-00153
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_Lang] (
	@ConnectID MoID, -- Identifiant unique de la connection
	@LangID MoOptionCode = '') -- Identifiant unique de la langue
AS

BEGIN

	-- Retourne les dossiers de la table de langue
	SELECT 
		LangID, 
		LangName
	FROM Mo_Lang
	WHERE LangID = ISNULL(NULLIF(@LangID, ''), LangID) -- Selon la langue (vide pour tous)

END

