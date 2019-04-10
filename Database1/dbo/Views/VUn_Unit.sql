-- Optimisé version 26
/* Inutile */
CREATE VIEW dbo.VUn_Unit
AS

  SELECT *
  FROM dbo.Un_Unit 



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue sur la table Un_Unit', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VUn_Unit';

