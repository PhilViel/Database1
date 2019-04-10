

-- Optimisé version 26
CREATE PROC SUn_ScholarshipList (
@ConnectID MoID,
@ConventionID MoID)
AS
BEGIN
  SELECT 
    ScholarshipID
  FROM Un_ScholarShip
  WHERE ConventionID = @ConventionID
  ORDER BY ScholarshipNo DESC
END

