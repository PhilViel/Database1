-- Optimisé version 26
CREATE VIEW dbo.VUn_YearQualifUnitQty_SubView
AS

  SELECT DISTINCT
    C.YearQualif,
    P.PlanID,
    C.ConventionID
  FROM dbo.Un_Unit U
  JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
  JOIN Un_Modal M ON (M.ModalID = U.ModalID)
  JOIN Un_Plan P ON (P.PlanID = M.PlanID)



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue retournant l`année de qualification par plan par convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VUn_YearQualifUnitQty_SubView';

