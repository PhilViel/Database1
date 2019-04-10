/****************************************************************************************************
	Renvoi l'historique des numéros d'assurance sociale d'un humain.
 ******************************************************************************
 	2003-10-14	Bruno Lapointe			Création #0768
	2004-06-07	Bruno Lapointe			Migration
	2015-07-24	Pierre-Luc Simard		Ajout du LoginName
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_HumanSocialNumber] (
	@ConnectID INTEGER, -- Id unique de la connection de l'usager
	@HumanID INTEGER) -- Id unique de l'humain
AS
BEGIN
	SELECT 
		SN.HumanSocialNumberID,
		SN.HumanID,
		SN.ConnectID,
		SN.EffectDate,
		SN.SocialNumber,     
		CASE WHEN SN.LoginName IS NULL THEN ISNULL(U.FirstName,'') ELSE '' END AS UserFirstName,
		ISNULL(SN.LoginName, ISNULL(U.LastName,'')) AS UserLastName
	FROM Un_HumanSocialNumber SN
	LEFT JOIN Mo_Connect C ON (C.ConnectID = SN.ConnectID)
	LEFT JOIN dbo.Mo_Human U ON (U.HumanID = C.UserID)
	WHERE SN.HumanID = @HumanID 
	ORDER BY SN.EffectDate DESC 
END


