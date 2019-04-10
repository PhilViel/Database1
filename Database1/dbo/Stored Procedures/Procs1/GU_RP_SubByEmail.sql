/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_SubByEmail
Description         :	Procédure stockée du rapport : Liste des Courriels avec le nom des souscripteurs (ancien rapport Excel de MacrosListesClientsBilingue.xls)
Valeurs de retours  :	Dataset
Note                :	2009-11-24  Donald Huppé	    Création 
						2013-08-07  Maxime Martel	    Ajout de l'option "tous" pour les directeurs des agences 
                                    Maxime Martel       Ajout de l'indicateur inscrit à l'espace client 
                        2018-09-26  Pierre-Luc Simard   Ajout de l'audit dans la table tblGENE_AuditHumain

exec GU_RP_SubByEmail 1, 0
exec GU_RP_SubByEmail 1, 149497
exec GU_RP_SubByEmail 1, 149593

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_SubByEmail] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepID INTEGER,
	@UserID integer = null ) -- Limiter les résultats selon un représentant ou un directeur
AS
BEGIN

    DECLARE @SQL VARCHAR(2000)
   
    CREATE TABLE #tb_rep (
        repID INTEGER PRIMARY KEY)
	
    DECLARE @rep BIT = 0

    IF @UserID IS NOT NULL
        BEGIN
		-- Insère tous les représentants sous un rep dans la table temporaire			
            SELECT
                @rep = COUNT(DISTINCT RepID)
            FROM
                Un_Rep
            WHERE
                @UserID = RepID
	
            IF @rep = 1
                BEGIN
                    INSERT  #tb_rep
                            EXEC SL_UN_BossOfRep @UserID
                END
            ELSE
                BEGIN
                    INSERT  #tb_rep
                            SELECT
                                RepID
                            FROM
                                Un_Rep
                END

            IF @RepID <> 0
                BEGIN
                    DELETE
                        #tb_rep
                    WHERE
                        repID <> @RepID
                END

        END
    ELSE
        BEGIN
            IF @RepID <> 0
                BEGIN
                    INSERT  INTO #tb_rep
                            EXEC SL_UN_BossOfRep @RepID
                END
            ELSE
                BEGIN
                    INSERT  INTO #tb_rep
                            SELECT
                                RepID
                            FROM
                                Un_Rep
                END
        END

    -- Les souscripteurs

    CREATE TABLE #Tmp
    (
      output nvarchar(max)
    )
   
    SET @SQL = 'sqlcmd -q "SELECT CAST(UserName as varchar) + '','' + CAST(CASE WHEN CONVERT(VARCHAR(10), ISNULL(LastLoginDate,''1900-01-01''), 120) <> ''1900-01-01'' AND ISNULL(CAST(comment AS VARCHAR),'''') = '''' THEN 1 ELSE 0 END AS varchar) FROM ' + dbo.fnGENE_ObtenirParametre('GENE_BD_USER_PORTAIL', NULL, NULL, NULL, NULL, NULL, NULL) + '.dbo.vwInscriptionsPortail"'
    INSERT INTO #Tmp
    EXEC xp_cmdshell @SQL;  

    SELECT 
        SUBSTRING(output, 1,Charindex(',', output)-1) as SouscripteurId,
        CAST(Substring(output, Charindex(',', output)+1, LEN(output)) as int)  as  Inscrit
    INTO #temp
    FROM #Tmp
    WHERE output is not null and output like '[0-9]%'

    SELECT  
	    R.RepCode, 
	    RLastName = HR.LastName , 
	    RFirstName = HR.FirstName ,
	    RANKSub = RANK() OVER (PARTITION BY Co.VcCourriel ORDER BY s.subscriberid),      
        SouscripteurId = S.SubscriberId,
        LastName = HS.LastName, 
	    FirstName = HS.FirstName , 
	    Email = Co.vcCourriel,
        Telephone = CASE WHEN TM.vcTelephone is NULL THEN CASE WHEN TT.vcTelephone is not NULL THEN TT.vcTelephone ELSE TC.vcTelephone END ELSE TM.vcTelephone END,
	    LangName = CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Unknown') END,
        PourcentageInscrit = CAST(SUM(T.Inscrit) over (partition by R.repid) as numeric) / CAST(COUNT(S.SubscriberID) over (partition by R.repid) as numeric),
        Inscrit = CASE WHEN T.Inscrit IS NULL or T.Inscrit = 0 THEN 'Non-Inscrit' ELSE 'Inscrit' END
    INTO #tGU_RP_SubByEmail
    FROM dbo.Un_Convention C 
	    JOIN (
		    SELECT 
			    Cs.conventionid ,
			    ccs.startdate,
			    cs.ConventionStateID
		    FROM 
			    un_conventionconventionstate cs
			    JOIN (
				    SELECT 
				    conventionid,
				    startdate = max(startDate)
				    FROM un_conventionconventionstate
				    GROUP BY conventionid
				    ) ccs ON ccs.conventionid = cs.conventionid 
					    AND ccs.startdate = cs.startdate 
					    AND cs.ConventionStateID in ('REE','TRA')
		    ) css ON css.conventionid = c.conventionid
	    JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	    JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
	    JOIN Un_Rep R ON S.RepID = R.RepID 
	    JOIN #tb_rep rr ON r.repid = rr.repid
	    JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
        LEFT JOIN #temp T on T.SouscripteurId = s.SubscriberID
        LEFT JOIN dbo.fntGENE_TelephoneEnDate_PourTous(NULL,NULL,1,0,1) TM ON TM.iID_Source = S.SubscriberID 
        LEFT JOIN dbo.fntGENE_TelephoneEnDate_PourTous(NULL,NULL,2,0,1) TC ON TC.iID_Source = S.SubscriberID 
        LEFT JOIN dbo.fntGENE_TelephoneEnDate_PourTous(NULL,NULL,4,0,1) TT ON TT.iID_Source = S.SubscriberID 
        LEFT JOIN dbo.fntGENE_CourrielEnDate_PourTous(NULL,NULL,1,1) Co on CO.iID_Source = S.SubscriberID
	    LEFT JOIN Mo_Lang SLang ON HS.LangID = SLang.LangID
    WHERE Co.vcCourriel is not null
    GROUP BY
	    s.subscriberid,
	    HS.LastName, 
	    HS.FirstName , 
	    Co.vcCourriel, 
	    CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Unknown') END,
	    R.RepCode, 
	    HR.LastName , 
	    HR.FirstName , 
	    R.RepID,
        TM.vcTelephone,
        TT.vcTelephone,
        TC.vcTelephone,
        T.Inscrit
    ORDER BY 
	    R.RepCode, 
		Co.vcCourriel

    SELECT * FROM #tGU_RP_SubByEmail TR

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tGU_RP_SubByEmail', 
            @vcNom_ChampIdentifiant = 'SouscripteurId', 
            @vcUtilisateur = @vcAudit_Utilisateur, 
            @vcContexte = @vcAudit_Contexte, 
            @bAcces_Courriel = 1, 
            @bAcces_Telephone = 1, 
            @bAcces_Adresse = 0
    --------------
    -- AUDIT - FIN
    --------------
    END 
    
END