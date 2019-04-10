

-- Optimisé version 26
CREATE PROC SUn_SearchExternalPlan (
@SearchType MoOptionCode,
@Search MoDesc)
AS
BEGIN
  IF @SearchType = 'ENa'
  BEGIN
    SELECT ExternalPlanID,
           CompanyName,
           ExternalPlanGovernmentRegNo,
           ExternalPlanTypeID
    FROM Un_ExternalPlan p
    JOIN Mo_Company c ON (c.CompanyID = p.ExternalPromoID)
    WHERE (CompanyName LIKE @Search)
    order BY CompanyName, ExternalPlanGovernmentRegNo
  END
  ELSE IF @SearchType = 'GNo'
    BEGIN
      SELECT ExternalPlanID,
             CompanyName,
             ExternalPlanGovernmentRegNo,
             ExternalPlanTypeID
      FROM Un_ExternalPlan p
      JOIN Mo_Company c ON (c.CompanyID = p.ExternalPromoID)
      WHERE (ExternalPlanGovernmentRegNo LIKE @Search)
      order BY CompanyName, ExternalPlanGovernmentRegNo
    END;
END;

