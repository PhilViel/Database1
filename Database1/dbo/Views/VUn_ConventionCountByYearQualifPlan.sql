-- Optimisé version 26
CREATE VIEW VUn_ConventionCountByYearQualifPlan
AS

  SELECT
    COUNT(ConventionID) ConventionCount,
    YearQualif,
    PlanID
  FROM VUn_YearQualifUnitQty_SubView
  GROUP BY
    YearQualif,
    PlanID

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue sur la vue VUn_YearQualifUnitQty_SubView', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VUn_ConventionCountByYearQualifPlan';

