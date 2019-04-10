-- Optimisé version 26
CREATE VIEW dbo.VUn_UnitByConvention
AS

  SELECT 
    C.ConventionID, 
    SUM(U.UnitQty) AS UnitQty
  FROM dbo.Un_Convention C 
  JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID) 
  GROUP BY 
    C.ConventionID



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue retournant la somme des unités par convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VUn_UnitByConvention';

