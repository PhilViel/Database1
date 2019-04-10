-- Optimisé version 26
CREATE VIEW VUn_College
AS

  SELECT *
  FROM Un_College C 
  JOIN Mo_Company M ON (C.CollegeID = M.CompanyID)

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue sur la table Un_College', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VUn_College';

