/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 : SP_SL_CRQ_User
Description         : Retourne les informations d'un ou tous les usagers
Valeurs de retours  : 
Note                :	ADX0001177	BR	2004-12-01	Bruno Lapointe			Création
						2008-08-18	Patrice Péau	Ajout de champs pour le module de securite en DOTNET 
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_User] (
	@UserID	MoID) -- ID unique de l'usager, 0 = tous
AS
BEGIN
	SELECT 
		U.UserID,
		U.LoginNameID,
		dbo.fn_Mo_Decrypt(U.PassWordID)  AS PassWordID,
		U.PassWordDate,
		U.CodeID,
		U.PassWordEndDate,
		U.TerminatedDate,
		H.FirstName,
		H.OrigName,
		H.Initial,
		H.LastName,
		H.BirthDate,
		H.DeathDate,
		H.SexID,
		H.LangID,
		H.CivilID,
		H.SocialNumber,
		H.ResidID,
		H.DriverLicenseNo,
		H.WebSite,
		H.CompanyName,
		H.CourtesyTitle,
		H.UsingSocialNumber,
		H.SharePersonalInfo,
		H.MarketingMaterial,
		H.IsCompany,
		A.InForce,
		A.Address,
		A.City,
		A.StateName,
		A.CountryID,
		A.ZipCode,
		A.Phone1,
		A.Phone2,
		A.Fax,
		A.Mobile,
		A.WattLine,
		A.OtherTel,
		A.Pager,
		A.EMail
	FROM Mo_User U
	JOIN dbo.Mo_Human H ON H.HumanID = U.UserID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	WHERE	@UserID = 0
		OR	@UserID = U.UserID
	ORDER BY H.LastName, H.FirstName
END


