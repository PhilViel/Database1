/****************************************************************************************************
  Retourne le total d'une projection par représentant et le grand total d'une projection     

  2003-07-03   marcw   Création
  2003-08-14   Bruno   Correction (Les totaux n'incluait pas les retenus)
*******************************************************************************************/
CREATE PROC [dbo].[PUn_RepProjectionTotal] 
( @ConnectID MoID,            --ID unique de la connection
  @RepProjectionDate MoDate,  --Date de la projection
  @RepID MoID )               --ID unique du représentant ou si 0 de toutes les représentants 
AS
BEGIN

  SELECT
    P.RepProjectionDate,
    P.RepID,
    SUM(P.TotalFee) AS RepTotalFee,
    SUM(P.CoverdAdvance) AS RepCoveredAdvance,
    SUM(P.PeriodComm) AS RepPeriodComm,
    SUM(P.PeriodBusinessBonus) AS RepPeriodBusinessBonus,
    ISNULL(S.AVRAmount,0) + ISNULL(S.AVSAmount,0) AS RepSweepstakeTot,
    SUM(P.PaidAmount) + ISNULL(S.AVRAmount,0) + ISNULL(S.AVSAmount,0) AS RepPaidTotal,
    SUM(P.CommExpenses) AS RepExpensesTotal
  FROM Un_RepProjection P
  LEFT JOIN Un_RepProjectionSumary S ON (S.RepID = P.RepID) AND (S.RepProjectionDate = P.RepProjectionDate)
  WHERE ((@RepID = 0) OR (@RepID = P.RepID))
    AND (P.RepProjectionDate = @RepProjectionDate) 
  GROUP BY P.RepProjectionDate, P.RepID, S.AVRAmount, S.AVSAmount
    
END;

