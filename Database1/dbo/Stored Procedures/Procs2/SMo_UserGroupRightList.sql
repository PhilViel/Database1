CREATE PROCEDURE SMo_UserGroupRightList
 (@ConnectID            MoID,
  @UserGroupID          MoID)
AS
BEGIN
  SELECT 
    R.RightID,
    R.RightCode,
    R.RightDesc,
    R.RightVisible,
    T.RightTypeID,
    T.RightTypeDesc,
    CASE 
      WHEN ISNULL(G.UserGroupID,0) = 0 THEN 0
      ELSE 2
		END AS Status
  FROM Mo_Right R
  JOIN Mo_RightType T ON (T.RightTypeID = R.RightTypeID)
  LEFT JOIN Mo_UserGroupRight G ON (G.UserGroupID = @UserGroupID) AND (G.RightID = R.RightID)
  ORDER BY T.RightTypeDesc, T.RightTypeID, R.RightDesc, R.RightCode
END;
