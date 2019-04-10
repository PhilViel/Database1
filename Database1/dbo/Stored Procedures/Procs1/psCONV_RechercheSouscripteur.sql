/***********************************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc
Nom                 :	psCONV_RechercheSouscripteur
Description         :	Recherche les souscripteur selon certains critères

Exemple d'appel:
    EXEC dbo.psCONV_RechercheSouscripteur @p_LastName = 'Bélanger', @p_NbMax=0
    EXEC dbo.psCONV_RechercheSouscripteur @p_City = 'Lévis'
    EXEC dbo.psCONV_RechercheSouscripteur @p_RepID = 436381
    EXEC dbo.psCONV_RechercheSouscripteur @p_HumanID = 681116
    EXEC dbo.psCONV_RechercheSouscripteur @p_LastName = 'Martel', @p_FirstName = 'Alain', @p_Telephone = '5147721928'
    EXEC dbo.psCONV_RechercheSouscripteur @p_Telephone = '5147721928'     

    Date        Programmeur         Description
    ----------  ----------------    ----------------------------------------------------------------------------------
    2016-06-01  Steeve Picard       Création
    2016-07-26  Steeve Picard       Ajout du paramètre @p_HumanID pour la recherche par ID
    2016-11-03  Steeve Picard       Ajout du paramètre @p_Telephone pour filtrer dans le iPad
    2016-11-23  Steeve Picard       Correction si le @p_HumanID n'a pas de téléphone
    2016-12-20  Pierre-Luc Simard   Ne pas retourner les souscripteurs sans téléphone si un paramètre est saisi JIRA PROD-3951
    2017-06-20  Steeve Picard       Ne pas retourner les souscripteur n'appartenant au représentant si le ID est passé (Jira: PROD-5676)
    2017-07-12  Pierre-Luc Simard   Ajouter le numéro de téléphone et le courriel résidentiel
    2017-08-03  Steeve Picard       Déplacement du filtre du # téléphone
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RechercheSouscripteur] (
    @p_HumanID      int = NULL,
    @p_LastName     varchar(50) = NULL,
    @p_FirstName    varchar(50) = NULL,
    @p_Birthdate    date = NULL,
    @p_DateDebut    datetime = NULL,
    @p_Address	     varchar(200) = NULL,
    @p_City         varchar(100) = NULL,
    @p_ZipCode      varchar(10) = NULL,
    @p_Telephone    varchar(27) = NULL,
    @p_RepID        int = NULL,
    @p_NbMax        smallint = 100
) AS
BEGIN
    SET NoCount ON

    IF @p_DateDebut IS NULL
        SET @p_DateDebut = GetDate()

    IF len(@p_Telephone) = 0
        SET @p_Telephone = NULL

    DECLARE @TB_Subscriber TABLE (
                SubscriberID INT NOT NULL,
                LastName VARCHAR(75),
                FirstName VARCHaR(50),
                Birthdate DATE,
                RepID INT
            )

    INSERT INTO @TB_Subscriber (SubscriberID, LastName, FirstName, Birthdate, RepID)
    SELECT DISTINCT S.SubscriberID, H.LastName, H.FirstName, H.BirthDate, S.RepID
      FROM dbo.fntGENE_SearchHuman(@p_LastName, @p_FirstName, @p_Birthdate, @p_DateDebut, @p_Address, @p_City, @p_ZipCode) H
           JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
           LEFT JOIN dbo.fntGENE_TelephoneEnDate_PourTous(@p_DateDebut, NULL, NULL, DEFAULT, 0) T ON T.iID_Source = S.SubscriberID
     WHERE HumanID = IsNull(@p_HumanID, HumanID)
       AND (
             (@p_RepID IS NULL OR S.RepID = @p_RepID)
             OR (@p_RepID IS NOT NULL 
                  AND EXISTS (
                    SELECT TOP 1 * FROM dbo.Un_RepBossHist RBH
                     WHERE RBH.RepID = S.RepID
                       AND RBH.RepRoleID = 'DIR'
                       AND RBH.StartDate < @p_DateDebut And IsNull(RBH.EndDate, '9999-12-31') > @p_DateDebut
                       AND RBH.BossID = @p_RepID
                       AND RBH.RepID <> RBH.BossID
                  )
                )
      --AND COALESCE(@p_Telephone, T.vcTelephone, '') LIKE '%' + IsNull(T.vcTelephone, '')
      AND CASE 
            WHEN @p_Telephone IS NULL THEN 1
            WHEN @p_Telephone LIKE '%' + T.vcTelephone THEN 1 
            ELSE 0 
          END = 1   
           )

    IF @p_NbMax > 0
        SET ROWCOUNT @p_NbMax

    SELECT DISTINCT --TOP (@p_NbMax)
        S.SubscriberID, 
        S.LastName,
        S.FirstName, 
        S.RepID, 
        S.BirthDate , 
        A.iID_Adresse AS iID_Adresse, 
        A.iID_Source AS iID_Source, 
        A.cType_Source AS cType_Source, 
        A.iID_Type AS iID_Type, 
        A.dtDate_Debut AS dtDate_Debut, 
        A.bInvalide AS bInvalide, 
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
        A.vcInternationale3 AS vcInternationale3,
        TR.vcTelephone AS Tel_Residence,
        CP.vcCourriel AS Courriel_Personnel
    FROM 
        @TB_Subscriber S
        LEFT JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(NULL, NULL, @p_DateDebut, DEFAULT) A ON A.iID_Source = S.SubscriberID AND A.cType_Source = 'H'
        LEFT JOIN dbo.fntGENE_TelephoneEnDate_PourTous(@p_DateDebut, NULL, 1, DEFAULT, 0) TR ON TR.iID_Source = S.SubscriberID
        LEFT JOIN dbo.fntGENE_CourrielEnDate_PourTous(@p_DateDebut, NULL, 1, DEFAULT) CP ON CP.iID_Source = S.SubscriberID
        
         /*
         OUTER APPLY  (
            SELECT TOP (1) 
                A.[iID_Adresse] AS [iID_Adresse], 
                A.[iID_Source] AS [iID_Source], 
                A.[cType_Source] AS [cType_Source], 
                A.[iID_Type] AS [iID_Type], 
                A.[dtDate_Debut] AS [dtDate_Debut], 
                A.[bInvalide] AS [bInvalide], 
                A.[dtDate_Creation] AS [dtDate_Creation], 
                A.[vcLogin_Creation] AS [vcLogin_Creation], 
                A.[vcNumero_Civique] AS [vcNumero_Civique], 
                A.[vcNom_Rue] AS [vcNom_Rue], 
                A.[vcUnite] AS [vcUnite], 
                A.[vcCodePostal] AS [vcCodePostal], 
                A.[vcBoite] AS [vcBoite], 
                A.[iID_TypeBoite] AS [iID_TypeBoite], 
                A.[iID_Ville] AS [iID_Ville], 
                A.[vcVille] AS [vcVille], 
                A.[iID_Province] AS [iID_Province], 
                A.[vcProvince] AS [vcProvince], 
                A.[cID_Pays] AS [cID_Pays], 
                A.[vcPays] AS [vcPays], 
                A.[bNouveau_Format] AS [bNouveau_Format], 
                A.[bResidenceFaitQuebec] AS [bResidenceFaitQuebec], 
                A.[bResidenceFaitCanada] AS [bResidenceFaitCanada], 
                A.[vcInternationale1] AS [vcInternationale1], 
                A.[vcInternationale2] AS [vcInternationale2], 
                A.[vcInternationale3] AS [vcInternationale3]
            FROM [dbo].[tblGENE_Adresse] AS A
            WHERE A.[iID_Source] = S.[SubscriberID]
              AND A.[dtDate_Debut] <= IsNull(@p_DateDebut, GetDate()) 
         ) AS A
         */
END