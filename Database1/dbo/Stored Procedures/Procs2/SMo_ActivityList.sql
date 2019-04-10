CREATE PROCEDURE [dbo].[SMo_ActivityList]
  (@ConnectID         MoID,
   @DateFrom          MoDate,
   @DateTo            MoDate,
   @LogTableName      MoDesc,
   @LogCodeID         MoIDOption,
   @UserID            MoIDOption)
AS
BEGIN
  IF (NOT (@UserID IS NULL)) AND (@UserID <> 0)
  BEGIN
    SELECT
      L.LogID,
      L.LogTime,
      (H.LastName + ', ' + H.FirstName) AS UserName,
      C.StationName,
      C.IPAddress,
      L.LogTableName,
      L.LogCodeID,
      L.LogActionID,
      L.LogText
    FROM Mo_Log L
      JOIN Mo_Connect C ON (C.ConnectID = L.ConnectID)
      JOIN Mo_User U ON (U.UserID = C.UserID)
      JOIN dbo.Mo_Human H ON (H.HumanID = U.UserID)
    WHERE (CHARINDEX(L.LogTableName, @LogTableName, 0) > 0 )
      AND (L.LogCodeID = @LogCodeID)
      AND (L.LogTime BETWEEN @DateFrom AND (@DateTo + 1))
      AND (C.UserID = @UserID)
    ORDER BY L.LogTime
  END
  ELSE
  BEGIN
    SELECT
      L.LogID,
      L.LogTime,
      (H.LastName + ', ' + H.FirstName) AS UserName,
      C.StationName,
      C.IPAddress,
      L.LogTableName,
      L.LogCodeID,
      L.LogActionID,
      L.LogText
    FROM Mo_Log L
      JOIN Mo_Connect C ON (C.ConnectID = L.ConnectID)
      JOIN Mo_User U ON (U.UserID = C.UserID)
      JOIN dbo.Mo_Human H ON (H.HumanID = U.UserID)
    WHERE (CHARINDEX(L.LogTableName, @LogTableName, 0) > 0 )
      AND (L.LogCodeID = @LogCodeID)
      AND (L.LogTime BETWEEN @DateFrom AND (@DateTo + 1))
    ORDER BY L.LogTime, UserName
  END
END;



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_ActivityList] TO PUBLIC
    AS [dbo];

