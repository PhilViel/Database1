
-- Optimisé version 26
CREATE PROCEDURE dbo.SUn_RepBossHistList (
@ConnectID MoID,
@RepID MoID)
AS
BEGIN
  SELECT 
    B.RepBossHistID,
    B.BossID,
    B.RepRoleID,
    ISNULL(B.RepBossPct, 0) AS RepBossPct,
    dbo.fn_Mo_DateNoTime(B.StartDate) AS StartDate,
    dbo.fn_Mo_DateNoTime(B.EndDate) AS EndDate,
    R.RepRoleDesc,
    H.LastName + ', ' + H.FirstName AS BossName
  FROM Un_RepBossHist B 
  JOIN Un_RepRole R ON (R.RepRoleID = B.RepRoleID)
  JOIN dbo.Mo_Human H ON (H.HumanID = B.BossID)
  WHERE B.RepID = @RepID
END;


