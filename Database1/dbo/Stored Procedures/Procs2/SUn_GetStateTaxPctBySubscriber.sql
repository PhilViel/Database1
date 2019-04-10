
-- Optimisé version 26
CREATE PROCEDURE dbo.SUn_GetStateTaxPctBySubscriber (
@ConnectID MoID,     
@SubscriberID MoID)
AS
BEGIN

  SELECT 
    ISNULL(ST.StateTaxPct, 0) AS StateTaxPct
  FROM Mo_State ST 
  JOIN dbo.Un_Subscriber S ON (ST.StateID = S.StateID)
  WHERE (S.SubscriberID = @SubscriberID)

END;


