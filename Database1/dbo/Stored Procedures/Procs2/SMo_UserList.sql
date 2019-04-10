
CREATE PROCEDURE [dbo].[SMo_UserList]
 (@ConnectID     MoID,
  @SearchTypeID  Char,
  @Search        MoCompanyName)
AS
BEGIN
  SET @Search = dbo.fn_Mo_FormatStringForSearch(@Search);

  IF (@SearchTypeID = 'L')
    SELECT
      U.UserID,
      U.LoginNameID,
      U.CodeID,
      U.TerminatedDate,
      H.FirstName,
      H.LastName
    FROM Mo_User U
      JOIN dbo.Mo_Human H ON (H.HumanID = U.UserID)
    WHERE (U.LoginNameID LIKE @Search)
    ORDER BY U.LoginNameID;
  ELSE
    SELECT
      U.UserID,
      U.LoginNameID,
      U.CodeID,
      U.TerminatedDate,
      H.FirstName,
      H.LastName
    FROM Mo_User U
      JOIN dbo.Mo_Human H ON (H.HumanID = U.UserID)
    WHERE (H.LastName LIKE @Search)
    ORDER BY H.LastName, H.FirstName;
END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_UserList] TO PUBLIC
    AS [dbo];

