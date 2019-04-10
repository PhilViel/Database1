

-- Optimisé version 26
CREATE PROC SUn_Plan (
@PlanID MoID,
@PlanTypeID UnPlanType OUTPUT,
@PlanDesc MoDesc OUTPUT,
@PlanScholarshipQty MoOrder OUTPUT,
@PlanOrderID MoOrder OUTPUT,
@PlanGovernmentRegNo MoDesc OUTPUT,
@IntReimbAge MoOrder OUTPUT)
AS
BEGIN

  SELECT
    @PlanTypeID = ISNULL(PlanTypeID, ''),
    @PlanDesc = ISNULL(PlanDesc, ''),
    @PlanScholarshipQty = ISNULL(PlanScholarshipQty, 1),
    @PlanOrderID = ISNULL(PlanOrderID, 5),
    @PlanGovernmentRegNo = ISNULL(PlanGovernmentRegNo, ''),
    @IntReimbAge = ISNULL(IntReimbAge, 17) 
  FROM Un_Plan
  WHERE (PlanID = @PlanID);

  IF EXISTS (SELECT 
               PlanID 
             FROM Un_Plan 
             WHERE (PlanID = @PlanID))
    RETURN(@PlanID)
  ELSE 
    RETURN(0);

END;

