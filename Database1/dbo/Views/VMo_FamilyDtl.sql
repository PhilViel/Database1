CREATE VIEW VMo_FamilyDtl
AS
  SELECT
    D.FamilyDtlID,
    D.FamilyID,
    D.HumanID,
    D.FamilyRoleID,
    F.FamilyName
  FROM Mo_FamilyDtl D
    JOIN Mo_Family F ON (F.FamilyID = D.FamilyID)

GO
GRANT SELECT
    ON OBJECT::[dbo].[VMo_FamilyDtl] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue sur la table Mo_FamilyDtl', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VMo_FamilyDtl';

