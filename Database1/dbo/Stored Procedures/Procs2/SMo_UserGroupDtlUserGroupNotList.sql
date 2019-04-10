CREATE PROCEDURE [dbo].[SMo_UserGroupDtlUserGroupNotList]
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
  JOIN (
    SELECT  
			@UserID AS UserID,
      G.UserGroupID,
	    G.UserGroupDesc
    FROM Mo_UserGroup G
    LEFT JOIN Mo_UserGroupDtl J ON (G.UserGroupID = J.UserGroupID) AND (J.UserID = @UserID)
    WHERE J.UserGroupID IS NULL 
    ) G ON (G.UserID = U.UserID)
  ORDER BY G.UserGroupDesc;
END;


