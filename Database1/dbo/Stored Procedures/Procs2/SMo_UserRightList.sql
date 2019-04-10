CREATE PROCEDURE SMo_UserRightList
 (@ConnectID            MoID,
  @UserID               MoID)
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
      WHEN ISNULL(U.UserID,0) = 0 THEN 
        CASE 
					WHEN ISNULL(G.RightID,0) = 0 THEN 0
          ELSE 1
        END
      ELSE
        CASE 
          WHEN ISNULL(U.Granted,1) = 0 THEN 3
          ELSE 2
				END
		END AS Status,
    CASE 
     	WHEN ISNULL(G.RightID,0) = 0 THEN 0
      ELSE 1
    END AS InheritedRight
  FROM Mo_Right R
  JOIN Mo_RightType T ON (T.RightTypeID = R.RightTypeID)
  LEFT JOIN Mo_UserRight U ON (U.UserID = @UserID) AND (U.RightID = R.RightID)
  LEFT JOIN (
    SELECT DISTINCT RightID
    FROM Mo_UserGroup G
    JOIN Mo_UserGroupDtl D ON (D.UserID = @UserID) AND (D.UserGroupID = G.UserGroupID)
    JOIN Mo_UserGroupRight R ON (R.UserGroupID = D.UserGroupID)
    ) G ON (R.RightID = G.RightID)
  ORDER BY T.RightTypeDesc, T.RightTypeID, R.RightDesc, R.RightCode
END;
