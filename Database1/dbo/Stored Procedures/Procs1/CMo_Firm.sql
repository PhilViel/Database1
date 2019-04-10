CREATE PROCEDURE CMo_Firm
  (@ConnectID  MoID,
   @FirmID     MoID)
AS
BEGIN
  DECLARE
    @ResultID    MoIDOption;

  SELECT @ResultID = COUNT(*)
  FROM Mo_Cheque
  WHERE (FirmID = @FirmID);

--  SELECT @ResultID = @ResultID + COUNT(*)
--  FROM Mo_Task
--  WHERE (FirmID = @FirmID);

  RETURN (@ResultID);
END;

