/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service	: fntGENE_ObtenirDerniereAdresseConnue
Nom du service		: Déterminer quelle était la dernière adresse connue
But 				: Retourner la dernière adresse d’une personne ou d’une entreprise, dans le format abrégé ou non.
Facette			: GENE

Paramètres d’entrée	:   
        Paramètre               Description
        --------------------    -----------------------------------------------------------------
	  	iID_Humain              Identifiant de l’humain (personne ou entreprise).
	  	iID_Type                Type d'adresse demandé.
		dtDate                  Date pour laquelle l’adresse doit être déterminée.Si la date n’est pas fournie, on considère que c’est pour la date du jour.
		bFormatCourt            Format abrégé demandé

Exemple d’appel	:   select * from dbo.fntGENE_ObtenirDerniereAdresseConnue(DEFAULT, DEFAULT, '2014-12-31', DEFAULT)
				    select * from dbo.fntGENE_ObtenirDerniereAdresseConnue(250597, DEFAULT, '2014-12-31', 1)
				    select * from dbo.fntGENE_ObtenirDerniereAdresseConnue(DEFAULT, 1, '2014-12-31', DEFAULT)

Historique des modifications:
    Date		Programmeur	                Description
    ----------  ------------------------    ------------------------------------------------------
    2017-11-30  Steeve Picard               Création du service basé sur la function «fntGENE_ObtenirAdresseEnDate_PourTous»
*********************************************************************************************************************/
CREATE FUNCTION dbo.fntGENE_ObtenirDerniereAdresseConnue (
    @iID_Humain   INT,
    @iID_Type     INT      = 1,
    @dtDate_Debut DATETIME = NULL,
    @bFormatCourt BIT      = 0
)
RETURNS TABLE
AS RETURN
     SELECT 
            ADR.iID_Adresse,
            ADR.iID_Type,
            ADR.iID_Source,
            ADR.cType_Source,
            ADR.dtDate_Debut,
            ADR.dtDate_Fin,
            ADR.bInvalide,
            ADR.bNouveau_Format,
            vcNumero_Civique = CASE WHEN @bFormatCourt = 0 THEN ADR.vcNumero_Civique ELSE NULL END, 
            vcNom_Rue = CASE WHEN @bFormatCourt = 0 THEN ADR.vcNom_Rue 
                             ELSE
                                CASE WHEN NOT ADR.cID_Pays IN ('CAN', 'USA') AND ADR.bNouveau_Format = 1
                                          THEN ISNULL(ADR.vcInternationale1, '') + SubString(RTrim('_ ' + ISNULL(ADR.vcInternationale2, '')), 2, 100)
                                                                               + SubString(RTrim('_ ' + ISNULL(ADR.vcInternationale3, '')), 2, 100)
                                     ELSE 
                                        CASE WHEN Len(ISNULL(ADR.vcUnite, '')) > 0 THEN ADR.vcUnite+'-' ELSE '' END +
                                        CASE WHEN Len(ISNULL(ADR.vcNumero_Civique, '')) > 0 THEN ADR.vcNumero_Civique + ',' ELSE '' END + 
                                        CASE WHEN Len(ISNULL(ADR.vcNom_Rue, '')) > 0 THEN SPACE(1) + ADR.vcNom_Rue ELSE '' END + 
                                        CASE WHEN Len(ISNULL(ADR.vcBoite, '')) > 0 
                                                  THEN 
                                                       CASE ADR.iID_TypeBoite WHEN 1 THEN ' CP '
                                                                            WHEN 3 THEN ' RR '
                                                                            ELSE ''
                                                       END + ADR.vcBoite
                                             ELSE ''
                                        END
                                END
                        END,
            vcUnite = CASE WHEN @bFormatCourt = 0 THEN ADR.vcUnite ELSE NULL END,
            iID_Ville = COALESCE(ADR.iID_Ville, C1.CityID, C2.CityID, C3.CityID),
            vcVille = COALESCE(ADR.vcVille, C1.CityName, C2.CityName, C3.CityName),
            iID_Province = COALESCE(ADR.iID_Province, C1.StateID, C2.StateID, C3.StateID),
            vcProvinceCode = COALESCE(C1.StateCode, C2.StateCode, C3.StateCode, ADR.vcProvince),
            vcProvince = COALESCE(ADR.vcProvince, C1.StateName, C2.StateName, C3.StateName),
            ADR.cID_Pays,
            ADR.vcPays,
            ADR.vcCodePostal,
            iID_TypeBoite = CASE WHEN @bFormatCourt = 0 THEN ADR.iID_TypeBoite ELSE NULL END,
            vcBoite = CASE WHEN @bFormatCourt = 0 THEN ADR.vcBoite ELSE NULL END,
            vcInternationale1 = CASE WHEN @bFormatCourt = 0 THEN ADR.vcInternationale1 ELSE NULL END,
            vcInternationale2 = CASE WHEN @bFormatCourt = 0 THEN ADR.vcInternationale2 ELSE NULL END,
            vcInternationale3 = CASE WHEN @bFormatCourt = 0 THEN ADR.vcInternationale3 ELSE NULL END,
            ADR.bResidenceFaitCanada,
            ADR.bResidenceFaitQuebec,
            ADR.dtDate_Creation,
            ADR.vcLogin_Creation
     FROM
     (
        SELECT X.*, Row_Num = ROW_NUMBER() OVER(PARTITION BY X.iID_Source, X.cType_Source, X.iID_Type ORDER BY X.dtDate_Debut DESC)
          FROM (
             SELECT A.iID_Adresse, A.iID_Type, A.iID_Source, A.cType_Source, 
                    A.dtDate_Debut, dtDate_Fin = NULL, A.bInvalide, A.bNouveau_Format,
                    A.vcNumero_Civique, A.vcNom_Rue, A.vcUnite, A.iID_Ville, A.vcVille,
                    A.iID_Province, A.vcProvince, A.cID_Pays, A.vcPays, A.vcCodePostal,
                    A.iID_TypeBoite, A.vcBoite,
                    A.vcInternationale1, A.vcInternationale2, A.vcInternationale3,
                    A.bResidenceFaitCanada, A.bResidenceFaitQuebec,
                    A.dtDate_Creation, A.vcLogin_Creation
             FROM tblGENE_Adresse A
             WHERE A.iID_Source = ISNULL(@iID_Humain, A.iID_Source)
                   AND A.iID_Type = ISNULL(@iID_Type, A.iID_Type)
                   AND A.dtDate_Debut < ISNULL(@dtDate_Debut, GETDATE())
             UNION
             SELECT A.iID_Adresse, A.iID_Type, A.iID_Source, A.cType_Source, 
                    A.dtDate_Debut, A.dtDate_Fin, A.bInvalide, A.bNouveau_Format,
                    A.vcNumero_Civique, A.vcNom_Rue, A.vcUnite, A.iID_Ville, A.vcVille,
                    A.iID_Province, A.vcProvince, A.cID_Pays, A.vcPays, A.vcCodePostal,
                    A.iID_TypeBoite, A.vcBoite,
                    A.vcInternationale1, A.vcInternationale2, A.vcInternationale3,
                    A.bResidenceFaitCanada, A.bResidenceFaitQuebec,
                    A.dtDate_Creation, A.vcLogin_Creation
             FROM tblGENE_AdresseHistorique A
             WHERE A.iID_Source = ISNULL(@iID_Humain, A.iID_Source)
                   AND A.iID_Type = ISNULL(@iID_Type, A.iID_Type)
                   -- Date du jour si aucune date passée en paramètre
                   AND A.dtDate_Debut < ISNULL(@dtDate_Debut, GETDATE())
            ) X
     ) ADR
     LEFT JOIN (
            SELECT C.CityID, C.CityName, S.StateID, S.StateCode, S.StateName, Ct.CountryID, Ct.CountryName
              FROM dbo.Mo_City C
                   JOIN dbo.Mo_State S ON S.StateID = C.StateID And S.CountryID = C.CountryID
                   JOIN dbo.Mo_Country Ct ON Ct.CountryID = S.CountryID
        ) C1 ON C1.CityID = ADR.iID_Ville and C1.StateID = ADR.iID_Province and C1.CountryID = ADR.cID_Pays
     LEFT JOIN (
            SELECT C.CityID, C.CityName, S.StateID, S.StateCode, S.StateName, Ct.CountryID, Ct.CountryName
              FROM dbo.Mo_City C
                   JOIN dbo.Mo_State S ON S.StateID = C.StateID And S.CountryID = C.CountryID
                   JOIN dbo.Mo_Country Ct ON Ct.CountryID = S.CountryID
        ) C2 ON C2.CityName = ADR.vcVille and C2.StateCode = ADR.vcProvince and C2.CountryID = ADR.cID_Pays
     LEFT JOIN (
            SELECT C.CityID, C.CityName, S.StateID, S.StateCode, S.StateName, S.vcNomWeb_FRA, S.vcNomWeb_ENU, Ct.CountryID, Ct.CountryName
              FROM dbo.Mo_City C
                   JOIN dbo.Mo_State S ON S.StateID = C.StateID And S.CountryID = C.CountryID
                   JOIN dbo.Mo_Country Ct ON Ct.CountryID = S.CountryID
        ) C3 ON C3.CityName = ADR.vcVille and (C3.vcNomWeb_FRA = ADR.vcProvince OR C3.vcNomWeb_ENU = ADR.vcProvince) and C3.CountryID = ADR.cID_Pays
    WHERE ADR.Row_Num = 1
