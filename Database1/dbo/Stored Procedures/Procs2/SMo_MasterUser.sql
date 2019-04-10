CREATE PROCEDURE [dbo].[SMo_MasterUser]
 (@ConnectID            MoID,
  @UserID               MoID)
AS
BEGIN

  SELECT
    U.UserID,
    U.LoginNameID,
    dbo.fn_Mo_Decrypt(U.PassWordID) AS PassWordID,
    U.CodeID,
    U.PassWordDate,
    U.TerminatedDate,
    H.FirstName,
    H.OrigName,
    H.Initial,
    H.LastName,
    H.AdrID,
    H.SexID,
    H.LangID,
    H.CivilID,
    H.CourtesyTitle,
    H.CompanyName,
    H.BirthDate,
    H.DeathDate,
    H.SocialNumber,
    H.DriverLicenseNo,
    H.WebSite,
    H.UsingSocialNumber,
    H.SharePersonalInfo,
    H.MarketingMaterial,
    H.IsCompany,
    A.CountryID,
    A.AdrTypeID,
    A.InForce,
    A.SourceID,
    A.Address,
    A.City,
    A.StateName,
    A.ZipCode,
    A.Phone1,
    A.Phone2,
    A.Fax,
    A.Mobile,
    A.WattLine,
    A.OtherTel,
    A.Pager,
    A.EMail,
    D.UserGroupID
  FROM Mo_User U
    JOIN dbo.Mo_Human H ON (H.HumanID = U.UserID)
    LEFT JOIN dbo.Mo_Adr A ON (A.AdrID = H.AdrID)
    LEFT JOIN Mo_UserGroupDtl D ON (D.UserID = U.UserID)
  WHERE (U.UserID = @UserID);

  RETURN @@ROWCOUNT;
END;



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_MasterUser] TO PUBLIC
    AS [dbo];

