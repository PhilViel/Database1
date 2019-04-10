-- Optimisé version 26
CREATE VIEW [dbo].[VUn_Beneficiary]
AS

  SELECT 
    B.BeneficiaryID,
    B.TutorName,
    B.GovernmentGrantForm,
    H.FirstName,
    H.OrigName,
    H.Initial,
    H.LastName,
    H.SexID,
    H.AdrID,
    H.BirthDate,
    H.DeathDate,
    H.LangID,
    H.CivilID,
    H.SocialNumber,
    H.ResidID,
    A.InForce,
    A.AdrTypeID,
    A.SourceID,
    A.Address,
    A.City,
    A.StateName,
    A.ZipCode,
    A.Phone1,
    A.Phone2,
    A.Fax,
    A.Mobile,
    A.Pager,
    A.EMail
  FROM dbo.Un_Beneficiary B
  JOIN dbo.Mo_Human H ON (H.HumanID = B.BeneficiaryID)
  JOIN dbo.Mo_Adr A ON (A.AdrID = H.AdrID) 



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue sur la table Un_Benericiary', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'VUn_Beneficiary';

