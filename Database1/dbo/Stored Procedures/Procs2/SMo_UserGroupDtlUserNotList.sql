CREATE PROCEDURE [dbo].[SMo_UserGroupDtlUserNotList]
 (@ConnectID            MoID,
  @UserGroupID          MoID)
AS
BEGIN
  SELECT 
    U.UserID,
    U.UserName,
    G.UserGroupID,
    G.UserGroupDesc
  FROM Mo_UserGroup G 
  JOIN (
    SELECT  
			@UserGroupID AS UserGroupID,
      U.UserID,
	    H.LastName+', '+H.FirstName AS UserName
    FROM Mo_User U
    JOIN dbo.Mo_Human H ON (H.HumanID = U.UserID)
    LEFT JOIN Mo_UserGroupDtl J ON (U.UserID = J.UserID) AND (J.UserGroupID = @UserGroupID)
    WHERE J.UserID IS NULL 
    ) U ON (U.UserGroupID = G.UserGroupID)
  ORDER BY U.UserName;
END;


