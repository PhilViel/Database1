/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service	: fntGENE_ObtenirAdresseEnDate_PourTous
Nom du service		: Déterminer l’adresse à une date
But 				: Retourner l’adresse d’une personne ou d’une entreprise à une date donnée, dans le format abrégé ou non.
Facette			: GENE

Paramètres d’entrée	:   Paramètre					Description
				    --------------------------	-----------------------------------------------------------------
	  			    iID_Humain				Identifiant de l’humain (personne ou entreprise).
	  			    iID_Type					Type d'adresse demandé.
				    dtDate					Date pour laquelle l’adresse doit être déterminée.Si la date n’est pas fournie, on considère que c’est pour la date du jour.
				    bFormatCourt				Format abrégé demandé

Exemple d’appel	:   select * from dbo.fntGENE_ObtenirAdresseEnDate_PourTous(DEFAULT, DEFAULT, DEFAULT, DEFAULT)
				    select * from dbo.fntGENE_ObtenirAdresseEnDate_PourTous(250597, DEFAULT, DEFAULT, 1)
				    select * from dbo.fntGENE_ObtenirAdresseEnDate_PourTous(DEFAULT, 1, DEFAULT, DEFAULT)

Historique des modifications:
        Date		Programmeur			        Description
        ----------  -------------------     ------------------------------------------------------
        2016-02-02  Steeve Picard           Création du service basé sur la function «fntGENE_ObtenirAdresseEnDate»
        2016-09-19  Steeve Picard           Ajout de la jointure à la table Mo_State
        2016-12-13  Steeve Picard           Changement sur la façon de joindre sur Mo_City/Mo_State/Mo_Country
        2017-02-01  Steeve Picard           Correctif pour exclure la date de fin
        2018-10-03  Pierre-Luc Simard       Ajout des TRIM et retrait du USA pour les adresses internationnal
        2018-11-27  Pierre-Luc Simard       Date de début en DATE au lieu de DATETIME
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_ObtenirAdresseEnDate_PourTous] (
    @iID_Humain   INT = NULL,
    @iID_Type     INT = NULL,
    @dtDate_Debut DATE = NULL,
    @bFormatCourt BIT = 0
)
RETURNS TABLE
AS RETURN
     SELECT ADR.iID_Adresse,
            ADR.iID_Type,
            ADR.iID_Source,
            ADR.cType_Source,
            ADR.dtDate_Debut,
            ADR.dtDate_Fin,
            ADR.bInvalide,
            ADR.bNouveau_Format,
            vcNumero_Civique = CASE WHEN @bFormatCourt = 0 THEN ADR.vcNumero_Civique ELSE NULL END, 
            vcNom_Rue = LTRIM(RTRIM(CASE WHEN @bFormatCourt = 0 THEN ADR.vcNom_Rue 
                             ELSE
                                CASE WHEN ADR.cID_Pays <> 'CAN' AND ADR.bNouveau_Format = 1
                                --CASE WHEN NOT (ADR.cID_Pays IN ('CAN', 'USA')) AND ADR.bNouveau_Format = 1
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
                        END)),
            vcUnite = CASE WHEN @bFormatCourt = 0 THEN ADR.vcUnite ELSE NULL END,
            iID_Ville = IsNull(ADR.iID_Ville, C.CityID),
            vcVille = IsNull(ADR.vcVille, C2.CityName),
            iID_Province = IsNull(ADR.iID_Province, C.StateID),
            vcProvinceCode = IsNull(C.StateCode, ADR.vcProvince),
            vcProvince = IsNull(ADR.vcProvince, C2.StateName),
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
         SELECT A.iID_Adresse,
                A.iID_Type,
                A.iID_Source,
                A.cType_Source,
                A.dtDate_Debut,
                dtDate_Fin = NULL,
                A.bInvalide,
                A.bNouveau_Format,
                A.vcNumero_Civique,
                A.vcNom_Rue,
                A.vcUnite,
                A.iID_Ville,
                A.vcVille,
                A.iID_Province,
                A.vcProvince,
                A.cID_Pays,
                A.vcPays,
                A.vcCodePostal,
                A.iID_TypeBoite,
                A.vcBoite,
                A.vcInternationale1,
                A.vcInternationale2,
                A.vcInternationale3,
                A.bResidenceFaitCanada,
                A.bResidenceFaitQuebec,
                A.dtDate_Creation,
                A.vcLogin_Creation
         FROM tblGENE_Adresse A
         WHERE A.iID_Source = ISNULL(@iID_Humain, A.iID_Source)
               AND A.iID_Type = ISNULL(@iID_Type, A.iID_Type)
               AND A.dtDate_Debut <= ISNULL(@dtDate_Debut, GETDATE())
         UNION
         SELECT A.iID_Adresse,
                A.iID_Type,
                A.iID_Source,
                A.cType_Source,
                A.dtDate_Debut,
                A.dtDate_Fin,
                A.bInvalide,
                A.bNouveau_Format,
                A.vcNumero_Civique,
                A.vcNom_Rue,
                A.vcUnite,
                A.iID_Ville,
                A.vcVille,
                A.iID_Province,
                A.vcProvince,
                A.cID_Pays,
                A.vcPays,
                A.vcCodePostal,
                A.iID_TypeBoite,
                A.vcBoite,
                A.vcInternationale1,
                A.vcInternationale2,
                A.vcInternationale3,
                A.bResidenceFaitCanada,
                A.bResidenceFaitQuebec,
                A.dtDate_Creation,
                A.vcLogin_Creation
         FROM tblGENE_AdresseHistorique A
         WHERE A.iID_Source = ISNULL(@iID_Humain, A.iID_Source)
               AND A.iID_Type = ISNULL(@iID_Type, A.iID_Type)
               -- Date du jour si aucune date passée en paramètre
               AND ISNULL(@dtDate_Debut, GETDATE()) Between A.dtDate_Debut AND DateAdd(day, -1, IsNull(A.dtDate_Fin, '9999-12-31'))
     ) ADR
     LEFT JOIN (
            SELECT C.CityID, C.CityName, S.StateID, S.StateCode, S.StateName, Ct.CountryID, Ct.CountryName
              FROM dbo.Mo_City C
                   JOIN dbo.Mo_State S ON S.StateID = C.StateID And S.CountryID = C.CountryID
                   JOIN dbo.Mo_Country Ct ON Ct.CountryID = S.CountryID
        ) C ON C.CityName = ADR.vcVille and C.StateCode = ADR.vcProvince and C.CountryID = ADR.cID_Pays
     LEFT JOIN (
            SELECT C.CityID, C.CityName, S.StateID, S.StateCode, S.StateName, Ct.CountryID, Ct.CountryName
              FROM dbo.Mo_City C
                   JOIN dbo.Mo_State S ON S.StateID = C.StateID And S.CountryID = C.CountryID
                   JOIN dbo.Mo_Country Ct ON Ct.CountryID = S.CountryID
        ) C2 ON C2.CityID = ADR.iID_Ville and C2.StateID = ADR.iID_Province and C2.CountryID = ADR.cID_Pays