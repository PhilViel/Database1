CREATE PROCEDURE SMo_RightOfUser
 (@ConnectID            MoID)
AS
BEGIN
  DECLARE @UserID MoID;

  SELECT @UserID = UserID FROM Mo_Connect WHERE ConnectID = @ConnectID;

  SELECT 
    R.RightID,
    R.RightCode,
    R.RightDesc,
    R.RightVisible,
    T.RightTypeID,
    T.RightTypeDesc
  FROM Mo_Right R
  JOIN Mo_RightType T ON (T.RightTypeID = R.RightTypeID)
  JOIN Mo_UserRight U ON (U.UserID = @UserID) AND (U.RightID = R.RightID) AND (U.Granted <> 0) 
  UNION 
  SELECT 
    R.RightID,
    R.RightCode,
    R.RightDesc,
    R.RightVisible,
    T.RightTypeID,
    T.RightTypeDesc
  FROM Mo_Right R
  JOIN Mo_RightType T ON (T.RightTypeID = R.RightTypeID)
  JOIN Mo_UserGroupRight GR ON (GR.RightID = R.RightID) 
  JOIN Mo_UserGroupDtl D ON (D.UserGroupID = GR.UserGroupID) AND (D.UserID = @UserID)
  LEFT JOIN Mo_UserRight U ON (U.UserID = @UserID) AND (U.RightID = R.RightID) AND (U.Granted = 0)
  WHERE U.UserID IS NULL
  ORDER BY R.RightCode
END;
