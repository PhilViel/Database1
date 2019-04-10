CREATE VIEW VMo_Family
AS
  SELECT FamilyID, FamilyName
  FROM Mo_Family

GO
GRANT SELECT
    ON OBJECT::[dbo].[VMo_Family] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue sur la table Mo_Family', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VMo_Family';

