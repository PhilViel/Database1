/****************************************************************************************************
  Description : Élimination des modules inutiles pour Universitas

 ******************************************************************************
  02-09-2003 André
*******************************************************************************/
CREATE PROCEDURE [dbo].[CMo_UserGroup]
  (@ConnectID       MoID,
   @UserGroupID     MoID)
AS
BEGIN
  DECLARE
    @ResultID    MoIDOption;

  SELECT @ResultID = COUNT(RightID)
  FROM Mo_UserGroupRight
  WHERE (UserGroupID = @UserGroupID);

  IF @ResultID <= 0
    SELECT @ResultID = COUNT(UserID)
    FROM Mo_UserGroupDtl
    WHERE (UserGroupID = @UserGroupID);

--  SELECT @ResultID = @ResultID + COUNT(*)
--  FROM Mo_ContactUserGroup
--  WHERE (UserGroupID = @UserGroupID);

  RETURN (@ResultID);
END;
