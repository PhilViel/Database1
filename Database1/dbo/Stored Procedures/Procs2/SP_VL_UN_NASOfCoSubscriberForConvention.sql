/****************************************************************************************************
	Valide que le co-souscripteur est un numéro d'assurance sociale.  Cette 
	validation est utilisé lors d'un changement ou de l'inscription d'un 
	co-souscripteur sur un convention.
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_NASOfCoSubscriberForConvention] (
	@CoSubscriberID INTEGER) -- Id unique du co-souscripteur
AS
BEGIN
	IF EXISTS (
		SELECT 
			HumanID
		FROM dbo.Mo_Human  
		WHERE HumanID = @CoSubscriberID 
		  AND ISNULL(SocialNumber,'') = '')
		RETURN -1 -- Co-souscripteur sans NAS
	ELSE
		RETURN 1
END;


