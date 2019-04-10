CREATE PROCEDURE [dbo].[SMo_UserGroupDtlUserList]
 (@ConnectID            MoID,
  @UserGroupID          MoID)
AS
BEGIN
  SELECT 
    U.UserID,
    H.LastName+', '+H.FirstName AS UserName,
    G.UserGroupID,
    G.UserGroupDesc
  FROM Mo_UserGroup G
  JOIN Mo_UserGroupDtl J ON (G.UserGroupID = J.UserGroupID)
  JOIN Mo_User U ON (U.UserID = J.UserID)
  JOIN dbo.Mo_Human H ON (H.HumanID = U.UserID)
  WHERE (G.UserGroupID = @UserGroupID)
  ORDER BY H.LastName, H.FirstName;
END;


