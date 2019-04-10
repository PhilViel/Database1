
CREATE PROC DUn_RepTreatmentLast (
@ConnectID MoID)
AS
BEGIN

  DECLARE 
  @RepTreatmentID MoID,
  @RepTreatmentDate MoDate,
  @PreviousRepTreatmentDate MoDate;
  
  SELECT 
    @RepTreatmentID = MAX(RepTreatmentID) 
  FROM Un_RepTreatment

  SELECT 
    @RepTreatmentDate = RepTreatmentDate 
  FROM Un_RepTreatment
  WHERE (RepTreatmentID = @RepTreatmentID)

  SELECT
    @PreviousRepTreatmentDate = MAX(RepTreatmentDate)
  FROM Un_RepTreatment
  WHERE (RepTreatmentID < @RepTreatmentID)
   
  DELETE FROM Un_RepCommission 
  WHERE (RepTreatmentID = @RepTreatmentID)

  DELETE FROM Un_RepBusinessBonus 
  WHERE (RepTreatmentID = @RepTreatmentID)

  DELETE FROM Un_RepAccount 
  WHERE (RepTreatmentID = @RepTreatmentID)

  DELETE FROM Un_SpecialAdvance 
  WHERE (RepTreatmentID = @RepTreatmentID)

  DELETE FROM Un_RepCharge 
  WHERE ((RepChargeTypeID = 'FRF')  OR (RepChargeTypeID = 'AVR') OR (RepChargeTypeID = 'AVS'))
    AND (RepTreatmentID = @RepTreatmentID)

  UPDATE Un_RepCharge SET 
    RepTreatmentID = NULL 
  WHERE (RepTreatmentID = @RepTreatmentID)

  DELETE FROM Un_RepTreatment 
  WHERE (RepTreatmentID = @RepTreatmentID)

  DELETE FROM Un_Dn_RepTreatment 
  WHERE (RepTreatmentID = @RepTreatmentID)

  DELETE FROM Un_Dn_RepTreatmentSumary 
  WHERE (RepTreatmentID = @RepTreatmentID)

  DELETE FROM Un_UnitReductionRepException
  FROM Un_UnitReductionRepException U
    JOIN Un_RepException E ON (E.RepExceptionID = U.RepExceptionID)
    JOIN Un_RepExceptionType T ON (T.RepExceptionTypeID = E.RepExceptionTypeID)
  WHERE (E.RepExceptionDate > @PreviousRepTreatmentDate) 
    AND (E.RepExceptionDate <= @RepTreatmentDate)   
    AND (T.RepExceptionTypeVisible <> 1)
    
  DELETE FROM Un_RepException
  FROM Un_RepException E
    JOIN Un_RepExceptionType T ON (T.RepExceptionTypeID = E.RepExceptionTypeID)
  WHERE (E.RepExceptionDate > @PreviousRepTreatmentDate) 
    AND (E.RepExceptionDate <= @RepTreatmentDate)   
    AND (T.RepExceptionTypeVisible <> 1)

END;

