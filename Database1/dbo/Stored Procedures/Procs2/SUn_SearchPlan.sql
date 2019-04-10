

-- Optimisé version 26
CREATE PROC SUn_SearchPlan (
@SearchType MoOptionCode,
@Search MoDesc)
AS
BEGIN
  IF @SearchType = 'Nam'
  BEGIN
    SELECT PlanID, 
           PlanDesc,
           PlanTypeID,
           PlanGovernmentRegNo
    FROM Un_Plan
    WHERE (PlanDesc LIKE @Search)
    ORDER BY PlanDesc, PlanGovernmentRegNo, PlanTypeID;
  END
  ELSE IF @SearchType = 'GRN'
    BEGIN
      SELECT PlanID, 
             PlanDesc,
             PlanTypeID,
             PlanGovernmentRegNo
      FROM Un_Plan
      WHERE (PlanGovernmentRegNo LIKE @Search)
      ORDER BY PlanGovernmentRegNo, PlanDesc, PlanTypeID;
    END;
END;

