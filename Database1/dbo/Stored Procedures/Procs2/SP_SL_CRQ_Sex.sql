/****************************************************************************************************

	PROCEDURE RETOURNANT LA SEXE

*********************************************************************************
	07-05-2004 Dominic Létourneau
		Création procedure pour CRQ-ACC-00153
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_Sex] (
	@ConnectID MoID, -- Identifiant unique de la connection
	@SexID MoSex = '', -- Identifiant unique du sexe
	@LangID MoOptionCode = '') -- Identifiant unique de la langue
AS

BEGIN

	-- Retourne les dossiers de la table de SEXE
	SELECT
		SexID, 
		LangID, 
		LongSexName, 
		ShortSexName, 
		SexName
	FROM Mo_Sex
	WHERE LangID = ISNULL(NULLIF(@LangID, ''), LangID) -- Selon la sexe (vide pour tous)
		AND SexID = ISNULL(NULLIF(@SexID, ''), SexID) -- Selon le sexe (vide pour tous)

END

