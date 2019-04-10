CREATE PROCEDURE SMo_UserGroupSearch
 (@ConnectID            MoID,
  @SearchTypeID         MoOptionCode,
  @Search               MoDesc)
AS
BEGIN
  SELECT 
    UserGroupID,
    UserGroupDesc
  FROM Mo_UserGroup  
  WHERE ((UserGroupDesc LIKE @Search) AND (@SearchTypeID = 'UGN'))
  ORDER BY UserGroupDesc;
END
