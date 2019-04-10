/****************************************************************************************************
Code de service		:		psGENE_RapportDroitProAccess
Nom du service		:		Rapport sur les droit d'accès dans ProAccess 
But					:		Rapport sur les droit d'accès dans ProAccess
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
								----------						----------------
								
Exemple d'appel:
                
                EXEC psGENE_RapportDroitProAccess
				
Parametres de sortie :	Table						Champs										Description
						-----------------			---------------------------					-----------------------------
													RightType									Extraction de la partie francophone du champ Mo_RightType.RightTypeDesc
						Mo_Right				RightID										
													RightDesc									Extraction de la partie francophone du champ Mo_Right.RightDesc
													UserOrGroup									LoginNameId OU UserGroupDesc
													Ordre										valeur = 1 (pour LoginNameId) ou 2  pour(UserGroupDesc). utilisé pour le tri dans le rapport
													AccesType									valeur = 
																										0 : Associé à chaque droit
																										1 : Associé à un LoginNameId OU UserGroupDesc qui a ce droit
																										2 : Associé à un LoginNameId qui a ce droit via un groupe
																								Dans le tableau croisé, la somme de cette valeur donne 1, 2 ou 3 (explication dans le rapport)
                   
Historique des modifications :
			
						Date						Programmeur					Description							Référence
						----------				--------------------------	----------------------------		---------------
						2015-10-13			Pierre-Luc Simard			Création du service
						
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportDroitProAccess] 
AS
BEGIN
	
	-- Description de la permission
	-- Catégorie/Contexte de la permission
	-- DEV/PROD pour afficher ou nom des groupes de DEV
	-- Comptes en DEV
	-- BD différente pour comparer deux environnements

	-- Liste des rôles de l'AD
	DECLARE
        @vcEnvironnement VARCHAR(100) = 'PROD',
        @vcPath VARCHAR(255) = 'OU=Proacces,OU=Utilisateurs,DC=gestion,DC=universitas',
        @cmd VARCHAR(255)

    IF DB_Name() <> 'UnivBase' and @@SERVERNAME <> 'SRVSQL12'
        SET @vcEnvironnement = Replace(Right(DB_Name(), CharIndex('_', Reverse(DB_Name()))-1), 'DATA', '')

    --SELECT TOP 1 @vcEnvironnement = SubString(X.EnvName, 2, 100) --, count(*)
    --  FROM (
    --    SELECT EnvName = Right(D.[name], CharIndex('_', Reverse(D.[name]))) 
    --      FROM sys.databases D WHERE D.[name] like '%[_]%'
    --    ) X
    -- GROUP BY X.EnvName
    -- ORDER BY count(*) DESC

    PRINT @vcEnvironnement

    --SET @vcEnvironnement = Replace(@vcEnvironnement, 'PreProd', 'Prod')
    --SET @vcEnvironnement = Replace(@vcEnvironnement, 'Prod', '')
    --SET @vcEnvironnement = Replace(@vcEnvironnement, 'Acce', 'Dev')
    --SET @vcEnvironnement = Replace(@vcEnvironnement, 'Fonc', 'Dev')
    SET @vcEnvironnement = Replace(@vcEnvironnement, 'DevData', 'Dev')

    PRINT @vcEnvironnement

    DECLARE @TB_Groupe TABLE (
            AD_Name VARCHAR(255),
            GroupeNom VARCHAR(255)
        )
	
    DECLARE @TB_Usager TABLE (
            UserID varchar(50), 
            UsagerNom VARCHAR(255), 
            Inactif bit DEFAULT(0),
            GroupeNom VARCHAR(100),
            AD_data varchar(255)
        )

    CREATE TABLE #Output (
            Id int identity(1,1),
            Data VARCHAR(255)
        )
	
    SET @cmd = 'dsget group "CN=ProAcces_Environnement_'+ @vcEnvironnement + ',' + @vcPath + '" -members'
    PRINT @cmd
    INSERT INTO #Output (Data)
           EXEC xp_cmdshell @cmd

    DELETE FROM #Output WHERE NOT (Data LIKE '%OU=ProAcces%' OR Data LIKE '"CN=%') OR Data IS NULL

    ;WITH CTE_AD as (
        SELECT SubString(Data, 5, CharIndex(',', Data) - 5) as AdName
          FROM #Output
         WHERE Data LIKE '%OU=ProAcces%' OR Data LIKE '"CN=%'
    ),
    CTE_GRP as (
        SELECT AdName, Replace(Replace(AdName, 'ProAcces_', ''), ' test', '') as GrpName
          FROM CTE_AD
    )
    INSERT INTO @TB_Groupe (AD_Name, GroupeNom)
    SELECT AdName, GrpName
      FROM CTE_GRP X JOIN dbo.Role R ON R.Nom = X.GrpName

    CREATE TABLE #TB_Member (
            Groupe varchar(100),
            Data VARCHAR(255)
        )

    TRUNCATE TABLE #Output

	-- Liste des utilisateurs
    DECLARE @Groupe VARCHAR(100), @Member VARCHAR(255), @ID int
              		
	-- Retrouver les Utilisateurs associés aux Groupes 
    DECLARE crGroupe CURSOR
        FOR SELECT DISTINCT AD_Name, GroupeNom 
              FROM @TB_Groupe M JOIN dbo.[Role] R ON R.Nom = M.GroupeNom

    OPEN crGroupe
    FETCH NEXT FROM crGroupe INTO @Member, @Groupe

    DECLARE @Value varchar(255),
            @Header varchar(255),
            @UserID varchar(50),
            @UserName varchar(100),
            @Inactif varchar(5),
            @StartPos int,
            @EndPos int

    WHILE @@FETCH_STATUS = 0
    BEGIN
        TRUNCATE TABLE #TB_Member

        PRINT 'Group : ' + @Member
        SET @cmd = '    dsget group "CN=' + Replace(@Member, ' ', '') + ',' + @vcPath + '" -members -expand'
        PRINT @cmd
        INSERT INTO #TB_Member (Data)
               EXEC xp_cmdshell @cmd

        DECLARE crUser CURSOR
            FOR SELECT DISTINCT Data FROM #TB_Member WHERE Data Like '"CN=%'

        OPEN crUser
        FETCH NEXT FROM crUser INTO @Member

        WHILE @@FETCH_STATUS = 0
        BEGIN
            TRUNCATE TABLE #Output

            PRINT '    Member : ' + IsNull(@Member, '')
            SET @cmd = '        dsget user ' + @Member + ' -samid -disabled -display'
            PRINT @cmd
            INSERT INTO #Output (Data)
                   EXEC xp_cmdshell @cmd

            SELECT @Header = LTrim(Data) FROM #Output WHERE ID = 1
            SELECT @Value = LTrim(Data) FROM #Output WHERE ID = 2

            SET @StartPos = CharIndex('samid', @Header)
            SET @EndPos = CharIndex(' ', @Value, @StartPos)
            SET @UserID = SubString(@Value, @StartPos, @EndPos - @StartPos)

            SET @StartPos = CharIndex('disabled', @Header)
            SET @EndPos = CharIndex(' ', @Value, @StartPos)
            SET @Inactif = SubString(@Value, @StartPos, @EndPos - @StartPos)

            SET @UserName = LTrim(RTrim(Replace(Replace(@Value, @UserID, ''), @Inactif, '')))

            IF @UserID IS NULL
                PRINT 'Erreur'
            ELSE
                INSERT INTO @TB_Usager (UserID, UsagerNom, GroupeNom, Inactif)
                SELECT @UserID, @UserName, @Groupe, Cast(Case @Inactif WHEN 'no' THEN 0 ELSE 1 END as bit)

            FETCH NEXT FROM crUser INTO @Member
        END
        CLOSE crUser
        DEALLOCATE crUser	

        PRINT '----------------------------------------'

        FETCH NEXT FROM crGroupe INTO @Member, @Groupe
    END
    CLOSE crGroupe
    DEALLOCATE crGroupe	

    TRUNCATE TABLE #Output

    
    SELECT DISTINCT U.UserID, U.UsagerNom, U.Inactif, P.Nom_Role, Nom_GroupePermission, Nom_Permission
      FROM @TB_Usager U
           LEFT JOIN ProAcces.vwListeDesPermissions P ON P.Nom_Role = U.GroupeNom
    ORDER BY U.UsagerNom, P.Nom_Role

    DROP TABLE #Output
    DROP TABLE #TB_Member
	
END
