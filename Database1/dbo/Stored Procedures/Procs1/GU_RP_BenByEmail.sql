/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_BenByEmail
Description         :	Procédure stockée du rapport : Liste des Courriels avec le nom des Bénéficiaires (ancien rapport Excel de MacrosListesClientsBilingue.xls)
Valeurs de retours  :	Dataset
Note                :	2009-11-24  Donald Huppé	    Création	
						2013-08-07  Maxime Martel	    Ajout de l'option "tous" pour les directeurs des agences
                        2018-09-29  Pierre-Luc Simard   Ajout de l'audit dans la table tblGENE_AuditHumain

exec GU_RP_BenByEmail 1, 149497

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_BenByEmail] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepID INTEGER, -- Limiter les résultats selon un représentant ou un directeur
	@userID integer = null ) 
AS
BEGIN

    CREATE TABLE #tb_rep (
        repID INTEGER PRIMARY KEY)
	
    DECLARE @rep BIT = 0

    IF @userID IS NOT NULL
        BEGIN
		-- Insère tous les représentants sous un rep dans la table temporaire			
            SELECT
                @rep = COUNT(DISTINCT RepID)
            FROM
                Un_Rep
            WHERE
                @userID = RepID
	
            IF @rep = 1
                BEGIN
                    INSERT  #tb_rep
                            EXEC SL_UN_BossOfRep @userID;
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
                END;
            ELSE
                BEGIN
                    INSERT  INTO #tb_rep
                            SELECT
                                RepID
                            FROM
                                Un_Rep
                END
        END

	-- Les bénéficiaires
	SELECT  
		R.RepCode, 
		RLastName = HR.LastName , 
		RFirstName = HR.FirstName ,
		-- Le rang du bénéficiaire par adresse - sert à la colonne bénéficiaire dans le tableau croisé 
		RANKBen = RANK() OVER (PARTITION BY BAdr.Email ORDER BY C.BeneficiaryID),
		C.BeneficiaryID,
        LastName = HB.LastName, 
		FirstName = HB.FirstName , 
		Email = BAdr.email,
		LangName = CASE BLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(BLang.LangName, 'Unknown') END
    INTO #tGU_RP_BenByEmail
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
	JOIN dbo.Mo_Human HB ON C.beneficiaryID = HB.HumanID
	JOIN dbo.Mo_Adr BAdr ON HB.AdrID = BAdr.AdrID 
	JOIN Un_Rep R ON S.RepID = R.RepID 
	JOIN #tb_rep rr ON r.repid = rr.repid
	JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
	LEFT JOIN Mo_Lang BLang ON HB.LangID = BLang.LangID
	WHERE BAdr.email IS NOT NULL 
	GROUP BY
		C.BeneficiaryID,
		HB.LastName, 
		HB.FirstName, 
		BAdr.email, 
		CASE BLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(BLang.LangName, 'Unknown') END,
		R.RepCode, 
        HR.LastName, 
		HR.FirstName, 
		R.RepID
	ORDER BY 		
		R.RepCode, 
		BAdr.email

    SELECT * FROM #tGU_RP_BenByEmail TR

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tGU_RP_BenByEmail', 
            @vcNom_ChampIdentifiant = 'BeneficiaryID', 
            @vcUtilisateur = @vcAudit_Utilisateur, 
            @vcContexte = @vcAudit_Contexte, 
            @bAcces_Courriel = 1, 
            @bAcces_Telephone = 0, 
            @bAcces_Adresse = 0
    --------------
    -- AUDIT - FIN
    --------------
    END

END