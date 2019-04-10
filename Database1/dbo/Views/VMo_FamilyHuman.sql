CREATE VIEW [dbo].[VMo_FamilyHuman]
AS
  SELECT
    F.FamilyID,
    F.FamilyName,
    FD.FamilyDtlID,
    FD.HumanID,
    FD.FamilyRoleID,
    H.FirstName,
    H.LastName,
    H.OrigName,
    H.SexID,
    H.AdrID,
    H.SocialNumber,
    A.Address,
    A.Phone1,
    A.City,
    A.StateName
  FROM Mo_Family F
    JOIN Mo_FamilyDtl FD ON (FD.FamilyID = F.FamilyID)
    JOIN dbo.Mo_Human H ON (H.HumanID = FD.HumanID)
    LEFT JOIN dbo.Mo_Adr A ON (A.AdrID = H.AdrID)



GO
GRANT SELECT
    ON OBJECT::[dbo].[VMo_FamilyHuman] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue retournant des informations provenant des table Mo_Family', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VMo_FamilyHuman';

