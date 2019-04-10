/****************************************************************************************************
	Valide qu'un humain est un NAS.
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_CRQ_HumanHaveNAS] (
	@HumanID INTEGER) -- Id unique d'un humain (Souscripteur, bénéficiaire, représentant, etc.)
AS
BEGIN
	IF EXISTS (
		SELECT 
			HumanID
		FROM dbo.Mo_Human  
		WHERE HumanID = @HumanID 
		  AND ISNULL(SocialNumber,'') = '')
		RETURN -1 -- pas de NAS
	ELSE
		RETURN 1
END;


