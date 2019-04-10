CREATE VIEW VMo_Lang
AS
  SELECT
    LangID,
    LangName
  FROM Mo_Lang

GO
GRANT SELECT
    ON OBJECT::[dbo].[VMo_Lang] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue sur la table Mo_Lang', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VMo_Lang';

