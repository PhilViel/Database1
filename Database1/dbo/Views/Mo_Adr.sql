

CREATE VIEW [dbo].[Mo_Adr]
AS
SELECT
	AdrID= A.iID_Adresse,
    CountryID = A.cID_Pays,
    AdrTypeID = A.cType_Source,
    InForce = CAST(A.dtDate_Debut AS DATETIME),
    SourceID = A.iID_Source,
    Address = LTRIM(RTRIM(
					 CASE WHEN A.cID_Pays <> 'CAN' AND A.bNouveau_Format = 1 THEN 
						ISNULL(A.vcInternationale1, '') 
						+ CASE WHEN ISNULL(A.vcInternationale2, '') <> '' THEN SPACE(1) + A.vcInternationale2 ELSE '' END 
						+ CASE WHEN ISNULL(A.vcInternationale3, '') <> '' THEN SPACE(1) + A.vcInternationale3 ELSE '' END
					ELSE 
						CASE WHEN ISNULL(A.vcUnite, '') <> '' THEN A.vcUnite + '-' ELSE '' END
						+ CASE WHEN ISNULL(A.vcNumero_Civique, '') <> '' THEN A.vcNumero_Civique + '' ELSE '' END
						+ CASE WHEN ISNULL(A.vcNom_Rue, '') <> '' THEN SPACE(1) + A.vcNom_Rue ELSE '' END
						+ CASE WHEN A.iID_TypeBoite = 1 AND ISNULL(A.vcBoite, '') <> '' THEN SPACE(1) + ' CP ' + A.vcBoite ELSE '' END
						+ CASE WHEN A.iID_TypeBoite = 2 AND ISNULL(A.vcBoite, '') <> '' THEN SPACE(1) + ' RR ' + A.vcBoite ELSE '' END
					END)),					
    City = A.vcVille,
    StateName = A.vcProvince,
    ZipCode = A.vcCodePostal,
    Phone1 = dbo.fnGENE_TelephoneEnDate (A.iID_Source, 1, NULL, 0, 0),
    Phone2 = dbo.fnGENE_TelephoneEnDate (A.iID_Source, 4, NULL, 0, 0),
    Fax = dbo.fnGENE_TelephoneEnDate (A.iID_Source, 8, NULL, 0, 0),
    Mobile = dbo.fnGENE_TelephoneEnDate (A.iID_Source, 2, NULL, 0, 0),
    WattLine = NULL,
    OtherTel = dbo.fnGENE_TelephoneEnDate (A.iID_Source, 16, NULL, 0, 0), 
    Pager = NULL,
    EMail = dbo.fnGENE_CourrielEnDate (A.iID_Source, 1, NULL, 0),
    ConnectID = 2,
    InsertTime = A.dtDate_Creation,
    iCheckSum = NULL,
    iStateId = iID_Province,
    vcEmailPersonnel = NULL,
    bIndAdrResidence = NULL,
    iCityId = iID_Ville,
    iAdrTypeId = A.iID_Type 
FROM tblGENE_Adresse A
WHERE A.dtDate_Debut <= GETDATE()



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue utilisée suite aux changements apportés à la gestion des adresses pour les anciens systèmes qui utilise encore la table Mo_Adr (Renommée tblGENE_Adresse)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Mo_Adr';

