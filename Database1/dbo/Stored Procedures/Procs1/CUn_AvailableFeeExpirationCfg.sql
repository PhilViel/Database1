
-- Optimisé version 26
CREATE PROC CUn_AvailableFeeExpirationCfg (
@ConnectID MoID,
@AvailableFeeExpirationCfgID MoID)
AS
BEGIN

  DECLARE
  @ResultID MoIDOption;

  SELECT 
    @ResultID = COUNT(1)
  FROM Un_AvailableFeeExpirationCfg
  WHERE (AvailableFeeExpirationCfgID = @AvailableFeeExpirationCfgID);

  RETURN (@ResultID);

END;

