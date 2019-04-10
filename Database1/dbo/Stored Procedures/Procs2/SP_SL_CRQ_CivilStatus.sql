/****************************************************************************************************

	PROCEDURE RETOURNANT LES STATUTS CIVILS

*********************************************************************************
	07-05-2004 Dominic Létourneau
		Création procedure pour CRQ-ACC-00153
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_CivilStatus] (
	@ConnectID MoID, -- Identifiant unique de la connection
	@LangID MoOptionCode = '', -- Identifiant unique de la langue
	@SexID MoSex = '') -- Identifiant unique du sexe
AS
BEGIN

	-- Retourne les dossiers de la table de statuts civils
	SELECT 
		CivilStatusID = RTRIM(CivilStatusID),
		LangID,
		SexID = RTRIM(SexID),
		CivilStatusName
	FROM Mo_CivilStatus
	WHERE LangID = ISNULL(NULLIF(@LangID, ''), LangID) -- Selon la langue (vide pour tous)
		AND SexID = ISNULL(NULLIF(@SexID, ''), SexID) -- Selon le sexe (vide pour tous)

END
