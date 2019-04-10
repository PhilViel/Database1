CREATE PROCEDURE SMo_FirmList
 (@ConnectID    MoID,
  @FirmID       MoID)
AS
BEGIN
  SELECT
    F.FirmID,
    C.CompanyName AS FirmName
  FROM Mo_Firm F
    JOIN Mo_Company C ON (C.CompanyID = F.FirmID)
  WHERE (F.FirmID > 1)
    AND (F.FirmStatusID = 'A')
  ORDER BY FirmName;
END
