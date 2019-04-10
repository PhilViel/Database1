CREATE PROCEDURE [dbo].[SMo_UserActive]
AS
BEGIN
  SELECT
    U.UserID,
    H.FirstName,
    H.LastName
  FROM Mo_User U
    JOIN dbo.Mo_Human H ON (H.HumanID = U.UserID)
  WHERE U.TerminatedDate IS NULL OR U.TerminatedDate > GetDate();
END;



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_UserActive] TO PUBLIC
    AS [dbo];

