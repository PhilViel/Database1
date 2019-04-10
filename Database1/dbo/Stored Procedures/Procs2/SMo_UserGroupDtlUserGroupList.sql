CREATE PROCEDURE [dbo].[SMo_UserGroupDtlUserGroupList]
 (@ConnectID            MoID,
  @UserID               MoID)
AS
BEGIN
  SELECT 
    U.UserID,
    H.LastName+', '+H.FirstName AS UserName,
    G.UserGroupID,
    G.UserGroupDesc
  FROM Mo_User U
  JOIN dbo.Mo_Human H ON (H.HumanID = U.UserID)
  JOIN Mo_UserGroupDtl J ON (U.UserID = J.UserID)
  JOIN Mo_UserGroup G ON (G.UserGroupID = J.UserGroupID)
  WHERE (U.UserID = @UserID)
  ORDER BY G.UserGroupDesc;
END;


