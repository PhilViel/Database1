/****************************************************************************************************
	Fonction qui retourne la description du Reason950ID passé en paramètre.
*********************************************************************************
	2004-10-18 Bruno Lapointe
		Création
*********************************************************************************/
CREATE FUNCTION dbo.FN_UN_GetReason950Desc (
	@Reason950ID INTEGER)
RETURNS VARCHAR(75)
AS
BEGIN
	RETURN
		CASE @Reason950ID
			WHEN 0 THEN 'Convention enregistrée'
			WHEN 1 THEN 'Manque infos sur souscripteur'
			WHEN 2 THEN 'Manque infos sur bénéficiaire'
			WHEN 3 THEN 'Manque infos sur souscripteur et bénéficiare'
			WHEN 4 THEN 'Transaction relative au contrat refusée'
		ELSE ''
		END
END

