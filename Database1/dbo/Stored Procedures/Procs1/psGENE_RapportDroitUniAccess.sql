/****************************************************************************************************
Code de service :   psGENE_RapportDroitUniAccess
Nom du service  :   Rapport sur les droit d'accès dans UniAccès 
But             :   Rapport sur les droit d'accès dans UniAccès
Facette         :   GENE
Reférence       :        

Parametres d'entrée :   
        Parametres              Description
        ----------              ----------------
        @ListOfUserOrGroup      Liste des LoginNameId ou nom de groupe séparés par des virgules (si NULL, retourne tous les usagers/groupes)
        @RightDate              Date de création du droit d'accès
        @ListOfRightTypeID      Liste des RightTypeID (groupe de droit d'accès) (si NULL, retourne tous les droits)

Exemple d'appel:
        EXEC psGENE_RapportDroitUniAccess 'Directeurs d''agence,Comptabilité,Communications,Sdupere' , '2010-05-01'
        EXEC psGENE_RapportDroitUniAccess 'Directeurs d''agence,Administration' , NULL, '4'
        EXEC psGENE_RapportDroitUniAccess 'Administration' , NULL, '4'

Parametres de sortie :
        Table               Champs              Description
        -----------------   ----------------    -----------------------------
                            RightType           Extraction de la partie francophone du champ Mo_RightType.RightTypeDesc
        Mo_Right            RightID             
                            RightDesc           Extraction de la partie francophone du champ Mo_Right.RightDesc
                            UserOrGroup         LoginNameId OU UserGroupDesc
                            Ordre               valeur = 1 (pour LoginNameId) ou 2  pour(UserGroupDesc). utilisé pour le tri dans le rapport
                            AccesType           valeur = 0 : Associé à chaque droit
                                                         1 : Associé à un LoginNameId OU UserGroupDesc qui a ce droit
                                                         2 : Associé à un LoginNameId qui a ce droit via un groupe
                                                         Dans le tableau croisé, la somme de cette valeur donne 1, 2 ou 3 (explication dans le rapport)
                   
Historique des modifications :
        Date        Programmeur             Description
        ----------  --------------------    -------------------------------------------
        2010-05-11  Donald Huppé            Création du service
        2011-01-31  Donald Huppé            GLPI 4983 - Remplacer les doubles appostrophes (reçus en paramètres) par un simple appostrophe. 
                                                Ex : "Directeur d''agence devient "Directeur d'agence"
        2012-08-23  Donald Huppé            Dans la section "Accès par Mo_UserRight", mettre la clause where suivante : UR.Granted = 1
        2018-02-26  Steeve Picard           Utilisation de la fonction «fntGENE_SplitIntoTable» sur les listes en paramètre
                                            Rendre optionel tous les paramètres de liste afin de tout récupérer
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportDroitUniAccess] (
    @ListOfUserOrGroup varchar(5000) = NULL,
    @RightDate DATETIME = NULL,
    @ListOfRightTypeID varchar(5000) = NULL
)
AS
BEGIN
    
    DECLARE @Item VARCHAR(255)
    DECLARE @i INT
    DECLARE @NbOfItem INT
    DECLARE @ItemPos INT
    DECLARE @ItemPosPrec INT
    DECLARE @Lang VARCHAR(3)

    SET @Lang = 'FRA'
    
    -- Mettre @ListOfUserOrGroup dans une table
    CREATE TABLE #UserOrGroupList (UserOrGroupName VARCHAR(255)) -- drop table #UserOrGroupList

    IF @ListOfUserOrGroup NOT LIKE '%,'
        SET @ListOfUserOrGroup = @ListOfUserOrGroup + ','

    IF @ListOfUserOrGroup <> ','
        INSERT INTO #UserOrGroupList 
        SELECT X.strField FROM dbo.fntGENE_SplitIntoTable(@ListOfUserOrGroup, ',') X WHERE LEN(ISNULL(X.strField, '')) > 0
    ELSE
        INSERT INTO #UserOrGroupList 
        SELECT LoginNameID FROM dbo.Mo_User
        UNION
        SELECT UserGroupDesc FROM dbo.Mo_UserGroup

    -- Remplacer les double appostrophes (reçus en paramètres) par un simple appostrophe. Ex : "Directeur d''agence devient "Directeur d'agence"
    update #UserOrGroupList set UserOrGroupName = replace(UserOrGroupName,'''''','''')

    -- Mettre @ListOfRightTypeID dans une table
    CREATE TABLE #RightTypeIDList (RightTypeID INT) -- drop table #UserOrGroupList

    IF ISNULL(@ListOfRightTypeID, '') NOT LIKE '%,'
        SET @ListOfRightTypeID = ISNULL(@ListOfRightTypeID, '') + ','

    IF @ListOfRightTypeID <> ','
        INSERT INTO #RightTypeIDList 
        SELECT X.strField FROM dbo.fntGENE_SplitIntoTable(@ListOfRightTypeID, ',') X WHERE LEN(ISNULL(X.strField, '')) > 0
    ELSE
        INSERT INTO #RightTypeIDList 
        SELECT RightTypeID FROM Mo_RightType

    -- tous les accès
    SELECT
        RightType = CASE WHEN @Lang = 'FRA' AND RightTypeDesc LIKE '%@@ENU%' then SUBSTRING ( RightTypeDesc ,   PATINDEX('%@@FRA%',RightTypeDesc) + 5    ,    CHARINDEX ( '@' , RightTypeDesc , PATINDEX('%@@FRA%',RightTypeDesc) + 5) - PATINDEX('%@@FRA%',RightTypeDesc) - 5 )  
                        WHEN @Lang = 'FRA' AND RightTypeDesc NOT LIKE '%@@ENU%' then  SUBSTRING ( RightTypeDesc ,   PATINDEX('%@@FRA%',RightTypeDesc) + 5   ,  LEN(RightTypeDesc) - PATINDEX('%@@FRA%',RightTypeDesc) + 5 )end,
        RightID,
        RightDesc = CASE WHEN @Lang = 'FRA' AND RightDesc LIKE '%@@ENU%' then SUBSTRING ( RightDesc ,   PATINDEX('%@@FRA%',RightDesc) + 5    ,    CHARINDEX ( '@' , RightDesc , PATINDEX('%@@FRA%',RightDesc) + 5) - PATINDEX('%@@FRA%',RightDesc) - 5 )  
                        WHEN @Lang = 'FRA' AND RightDesc NOT LIKE '%@@ENU%' then  SUBSTRING ( RightDesc ,   PATINDEX('%@@FRA%',RightDesc) + 5   ,  LEN(RightDesc) - PATINDEX('%@@FRA%',RightDesc) + 5 )end
        ,UserOrGroup = cast(NULL as varchar(255))
        ,Ordre = 0
        ,AccesType = 0
    FROM 
        Mo_Right R -- SELECT * FROM Mo_RightType
        JOIN Mo_RightType RT ON RT.RightTypeID = R.RightTypeID
        JOIN #RightTypeIDList RL on RT.RightTypeID = RL.RightTypeID
    where 
        @RightDate IS NULL 
        OR (@RightDate IS NOT NULL AND RightDate >= @RightDate)

    UNION ALL

    -- Accès par Mo_UserRight
    SELECT 
        RightType = CASE WHEN @Lang = 'FRA' AND RightTypeDesc LIKE '%@@ENU%' then SUBSTRING ( RightTypeDesc ,   PATINDEX('%@@FRA%',RightTypeDesc) + 5    ,    CHARINDEX ( '@' , RightTypeDesc , PATINDEX('%@@FRA%',RightTypeDesc) + 5) - PATINDEX('%@@FRA%',RightTypeDesc) - 5 )  
                        WHEN @Lang = 'FRA' AND RightTypeDesc NOT LIKE '%@@ENU%' then  SUBSTRING ( RightTypeDesc ,   PATINDEX('%@@FRA%',RightTypeDesc) + 5   ,  LEN(RightTypeDesc) - PATINDEX('%@@FRA%',RightTypeDesc) + 5 )end,
        R.RightID,
        RightDesc = CASE WHEN @Lang = 'FRA' AND RightDesc LIKE '%@@ENU%' then SUBSTRING ( RightDesc ,   PATINDEX('%@@FRA%',RightDesc) + 5    ,    CHARINDEX ( '@' , RightDesc , PATINDEX('%@@FRA%',RightDesc) + 5) - PATINDEX('%@@FRA%',RightDesc) - 5 )  
                        WHEN @Lang = 'FRA' AND RightDesc NOT LIKE '%@@ENU%' then  SUBSTRING ( RightDesc ,   PATINDEX('%@@FRA%',RightDesc) + 5   ,  LEN(RightDesc) - PATINDEX('%@@FRA%',RightDesc) + 5 )end
        ,UserOrGroup = UG.UserOrGroupName
        ,Ordre = 2
        ,AccesType = 1
    FROM 
        Mo_Right R 
        JOIN Mo_RightType RT ON RT.RightTypeID = R.RightTypeID
        JOIN #RightTypeIDList RL on RT.RightTypeID = RL.RightTypeID
        JOIN Mo_UserRight UR ON UR.RightID = R.RightID 
        JOIN Mo_User U ON UR.UserID = U.UserID
        JOIN #UserOrGroupList UG ON U.LoginNameID = UG.UserOrGroupName
    where 
        UR.Granted = 1
        AND (
            @RightDate IS NULL 
            OR (@RightDate IS NOT NULL AND RightDate >= @RightDate)
        )

    UNION ALL
    
    -- Accès des user demandés via un groupe auquel il appartient
    SELECT 
        DISTINCT
        RightType = CASE WHEN @Lang = 'FRA' AND RightTypeDesc LIKE '%@@ENU%' then SUBSTRING ( RightTypeDesc ,   PATINDEX('%@@FRA%',RightTypeDesc) + 5    ,    CHARINDEX ( '@' , RightTypeDesc , PATINDEX('%@@FRA%',RightTypeDesc) + 5) - PATINDEX('%@@FRA%',RightTypeDesc) - 5 )  
                        WHEN @Lang = 'FRA' AND RightTypeDesc NOT LIKE '%@@ENU%' then  SUBSTRING ( RightTypeDesc ,   PATINDEX('%@@FRA%',RightTypeDesc) + 5   ,  LEN(RightTypeDesc) - PATINDEX('%@@FRA%',RightTypeDesc) + 5 )end,
        R.RightID,
        RightDesc = CASE WHEN @Lang = 'FRA' AND RightDesc LIKE '%@@ENU%' then SUBSTRING ( RightDesc ,   PATINDEX('%@@FRA%',RightDesc) + 5    ,    CHARINDEX ( '@' , RightDesc , PATINDEX('%@@FRA%',RightDesc) + 5) - PATINDEX('%@@FRA%',RightDesc) - 5 )  
                        WHEN @Lang = 'FRA' AND RightDesc NOT LIKE '%@@ENU%' then  SUBSTRING ( RightDesc ,   PATINDEX('%@@FRA%',RightDesc) + 5   ,  LEN(RightDesc) - PATINDEX('%@@FRA%',RightDesc) + 5 )end
        ,UserOrGroup = UG.UserOrGroupName
        ,Ordre = 2
        ,AccesType = 2
    FROM 
        Mo_Right R
        JOIN Mo_RightType RT ON RT.RightTypeID = R.RightTypeID
        JOIN #RightTypeIDList RL on RT.RightTypeID = RL.RightTypeID
        LEFT JOIN Mo_UserGroupRight UGR ON UGR.RightID = R.RightID
        LEFT JOIN Mo_UserGroupDtl UGD ON UGD.UserGroupID = UGR.UserGroupID  --SELECT * FROM Mo_UserGroupDtl
        JOIN Mo_User U ON UGD.UserID = U.UserID
        JOIN #UserOrGroupList UG ON U.LoginNameID = UG.UserOrGroupName
    where 
        @RightDate IS NULL 
        OR (@RightDate IS NOT NULL AND RightDate >= @RightDate)

    UNION ALL

    -- Accès des groupes demandés
    SELECT 
        DISTINCT
        RightType = CASE WHEN @Lang = 'FRA' AND RightTypeDesc LIKE '%@@ENU%' then SUBSTRING ( RightTypeDesc ,   PATINDEX('%@@FRA%',RightTypeDesc) + 5    ,    CHARINDEX ( '@' , RightTypeDesc , PATINDEX('%@@FRA%',RightTypeDesc) + 5) - PATINDEX('%@@FRA%',RightTypeDesc) - 5 )  
                        WHEN @Lang = 'FRA' AND RightTypeDesc NOT LIKE '%@@ENU%' then  SUBSTRING ( RightTypeDesc ,   PATINDEX('%@@FRA%',RightTypeDesc) + 5   ,  LEN(RightTypeDesc) - PATINDEX('%@@FRA%',RightTypeDesc) + 5 )end,
        R.RightID,
        RightDesc = CASE WHEN @Lang = 'FRA' AND RightDesc LIKE '%@@ENU%' then SUBSTRING ( RightDesc ,   PATINDEX('%@@FRA%',RightDesc) + 5    ,    CHARINDEX ( '@' , RightDesc , PATINDEX('%@@FRA%',RightDesc) + 5) - PATINDEX('%@@FRA%',RightDesc) - 5 )  
                        WHEN @Lang = 'FRA' AND RightDesc NOT LIKE '%@@ENU%' then  SUBSTRING ( RightDesc ,   PATINDEX('%@@FRA%',RightDesc) + 5   ,  LEN(RightDesc) - PATINDEX('%@@FRA%',RightDesc) + 5 )end
        ,UserOrGroup = UGL.UserOrGroupName
        ,Ordre = 1
        ,AccesType = 1
    FROM 
        Mo_Right R
        JOIN Mo_RightType RT ON RT.RightTypeID = R.RightTypeID
        JOIN #RightTypeIDList RL on RT.RightTypeID = RL.RightTypeID
        JOIN Mo_UserGroupRight UR ON UR.RightID = R.RightID 
        JOIN Mo_UserGroup UG ON UR.UserGroupID = UG.UserGroupID -- SELECT * FROM Mo_UserGroup
        JOIN #UserOrGroupList UGL ON UGL.UserOrGroupName = UG.UserGroupDesc
    where 
        @RightDate IS NULL 
        OR (@RightDate IS NOT NULL AND RightDate >= @RightDate)
END