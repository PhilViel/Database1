CREATE VIEW VMo_Def
AS
  SELECT
    CompanyName,
    GeneralPath,
    DefaultStateID,
    DefaultCountryID,
    ModulexVersion,
    ApplicationVersion,
    PatchVersion,
    VersionDate
  FROM Mo_Def

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue sur la table Mo_DEF', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VMo_Def';

