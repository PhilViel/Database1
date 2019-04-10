/***********************************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc
Nom                 :	fntCONV_RechercheSouscripteur
Description         :	Recherche les souscripteur selon certains critères

Exemple d'appel:
    select * from dbo.fntGENE_SearchHuman('Bélanger',NULL,NULL,NULL,NULL,NULL,NULL)
    select * from dbo.fntGENE_SearchHuman(NULL,NULL,NULL,NULL,NULL,'Lévis',NULL)

    Date        Programmeur         Description
    ----------  ----------------    ----------------------------------------------------------------------------------
    2016-06-01  Steeve Picard       Création
    2017-03-15  Steeve Picard       Correction pour les EmptyStrings en paramètre
    2018-08-02  Steeve Picard       Concatenation du # civique avec la rue pour la recherche de l'adresse
***********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_SearchHuman] (
    @p_LastName     varchar(50) = NULL,
    @p_FirstName    varchar(50) = NULL,
    @p_Birthdate    date = NULL,
    @p_DateDebut    datetime = NULL,
    @p_Address	     varchar(200) = NULL,
    @p_City         varchar(100) = NULL,
    @p_ZipCode      varchar(10) = NULL
)
RETURNS TABLE
AS RETURN (
    SELECT 
        Limit2.HumanID, 
        Limit2.LastName,
        Limit2.FirstName, 
        Limit2.BirthDate , 
        Limit2.iID_Adresse, 
        Limit2.iID_Source, 
        Limit2.cType_Source, 
        Limit2.iID_Type, 
        Limit2.dtDate_Debut, 
        Limit2.bInvalide, 
        Limit2.dtDate_Creation, 
        Limit2.vcLogin_Creation, 
        Limit2.vcNumero_Civique, 
        Limit2.vcNom_Rue, 
        Limit2.vcUnite, 
        Limit2.vcCodePostal, 
        Limit2.vcBoite, 
        Limit2.iID_TypeBoite, 
        Limit2.iID_Ville, 
        Limit2.vcVille,
        Limit2.iID_Province,
        Limit2.vcProvince,
        Limit2.cID_Pays,
        Limit2.vcPays,
        Limit2.bNouveau_Format,
        Limit2.bResidenceFaitQuebec,
        Limit2.bResidenceFaitCanada,
        Limit2.vcInternationale1,
        Limit2.vcInternationale2,
        Limit2.vcInternationale3
        FROM ( 
                SELECT 
                    Project4.HumanID,
                    Project4.BirthDate,
                    Project4.LastName,
                    Project4.FirstName, 
                    Limit1.iID_Adresse,
                    Limit1.iID_Source,
                    Limit1.cType_Source,
                    Limit1.iID_Type,
                    Limit1.dtDate_Debut,
                    Limit1.bInvalide,
                    Limit1.dtDate_Creation,
                    Limit1.vcLogin_Creation,
                    Limit1.vcNumero_Civique,
                    Limit1.vcNom_Rue,
                    Limit1.vcUnite,
                    Limit1.vcCodePostal,
                    Limit1.vcBoite,
                    Limit1.iID_TypeBoite,
                    Limit1.iID_Ville,
                    Limit1.vcVille,
                    Limit1.iID_Province,
                    Limit1.vcProvince,
                    Limit1.cID_Pays,
                    Limit1.vcPays,
                    Limit1.bNouveau_Format,
                    Limit1.bResidenceFaitQuebec,
                    Limit1.bResidenceFaitCanada,
                    Limit1.vcInternationale1,
                    Limit1.vcInternationale2,
                    Limit1.vcInternationale3
                FROM (
                        SELECT 
                            H.HumanID, 
                            H.FirstName,
                            H.LastName,
                            H.BirthDate
                            FROM  dbo.Mo_Human AS H
                            WHERE (IsNull(@p_LastName, '') = '' OR dbo.fnGENE_RechercherTexteSansAccent(H.LastName, LTRIM(RTRIM(@p_LastName))) = 1)
                                AND (IsNull(@p_FirstName, '') = '' OR dbo.fnGENE_RechercherTexteSansAccent(H.FirstName, LTRIM(RTRIM(@p_FirstName))) = 1)
                                AND (IsNull(@p_Birthdate, H.BirthDate) = H.BirthDate)
                                AND EXISTS (
                                        SELECT TOP 1 *
                                        FROM dbo.tblGENE_Adresse AS A
                                        WHERE A.dtDate_Debut <= IsNull(@p_DateDebut, GetDate()) 
                                            AND A.iID_Source = H.HumanID
                                            AND (IsNull(@p_ZipCode, '') = '' OR A.vcCodePostal = Replace(@p_ZipCode, ' ', ''))
                                            AND (IsNull(@p_Address, '') = '' OR dbo.fnGENE_RechercherTexteSansAccent(ISNULL(A.vcNumero_Civique, '') + ' ' + A.vcNom_Rue, @p_Address) = 1)
                                            AND (IsNull(@p_City, '') = '' OR dbo.fnGENE_ComparerTexteSansAccent(A.vcVille, @p_City)= 1)
                                    )
                     ) AS Project4
                     OUTER APPLY  (
                        SELECT TOP (1) 
                            A.iID_Adresse, 
                            A.iID_Source, 
                            A.cType_Source, 
                            A.iID_Type, 
                            A.dtDate_Debut, 
                            A.bInvalide, 
                            A.dtDate_Creation AS dtDate_Creation, 
                            A.vcLogin_Creation AS vcLogin_Creation, 
                            A.vcNumero_Civique AS vcNumero_Civique, 
                            A.vcNom_Rue AS vcNom_Rue, 
                            A.vcUnite AS vcUnite, 
                            A.vcCodePostal AS vcCodePostal, 
                            A.vcBoite AS vcBoite, 
                            A.iID_TypeBoite AS iID_TypeBoite, 
                            A.iID_Ville AS iID_Ville, 
                            A.vcVille AS vcVille, 
                            A.iID_Province AS iID_Province, 
                            A.vcProvince AS vcProvince, 
                            A.cID_Pays AS cID_Pays, 
                            A.vcPays AS vcPays, 
                            A.bNouveau_Format AS bNouveau_Format, 
                            A.bResidenceFaitQuebec AS bResidenceFaitQuebec, 
                            A.bResidenceFaitCanada AS bResidenceFaitCanada, 
                            A.vcInternationale1 AS vcInternationale1, 
                            A.vcInternationale2 AS vcInternationale2, 
                            A.vcInternationale3 AS vcInternationale3
                        FROM dbo.tblGENE_Adresse AS A
                        WHERE A.dtDate_Debut <= IsNull(@p_DateDebut, GetDate()) 
                          AND Project4.HumanID = A.iID_Source
                     ) AS Limit1
             ) AS Limit2
)