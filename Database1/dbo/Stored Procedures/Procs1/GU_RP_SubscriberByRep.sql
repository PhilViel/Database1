/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_SubscriberByRep
Description         :	Procédure stockée du rapport : Liste des souscripteurs et anniversaire par représentant (ancien rapport Excel de MacrosListesClientsBilingue.xls)
Valeurs de retours  :	Dataset
Note                :	            Donald Huppé	    Création
						2013-08-07  Maxime Martel	    Ajout de l'option "tous" pour les directeurs des agences
                        2018-09-26  Pierre-Luc Simard   Ajout de l'audit dans la table tblGENE_AuditHumain

exec GU_RP_SubscriberByRep 1, 149497

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_SubscriberByRep] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepID INTEGER,
	@UserID integer = null ) -- Limiter les résultats selon un représentant ou un directeur
AS
BEGIN

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

	SELECT DISTINCT 
        C.SubscriberID,
		Transert = CASE WHEN T.Transfert = 0 THEN 'Non' ELSE 'Oui' END, 
		T.Dvigueur, 
		T.DSignature,
		T.Nb_Unit, 
		NbPaiementAns = T.MAXDePmtByYearID, 
		T.Nb_Paiement, 
		T.MntSouscrit, 
		T.MntDepot, 
		SLastName = HS.LastName, 
		SFirstName = HS.FirstName , 
		SAddress = CASE WHEN S.AddressLost = 0 THEN SAdr.Address ELSE '*** adresse perdue ***' END, 
		SCity = CASE WHEN S.AddressLost = 0 THEN SAdr.City ELSE '' END, 
		SStateName = CASE WHEN S.AddressLost = 0 THEN SAdr.StateName ELSE '' END , 
		SCountryID = CASE WHEN S.AddressLost = 0 THEN SAdr.CountryID ELSE '' END ,
		SZipCode = CASE WHEN S.AddressLost = 0 THEN SAdr.ZipCode ELSE '' END ,
		SPhone1 = CASE WHEN S.AddressLost = 0 THEN SAdr.Phone1 ELSE '' END ,
		SPhone2 = CASE WHEN S.AddressLost = 0 THEN SAdr.Phone2 ELSE '' END ,
		SSexID = HS.SexID , 
		SLangName = CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Unknown') END, 
		SBirthDate = HS.BirthDate , 
		SSocialNumber = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, HS.IsCompany), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						END,
		SEMail = CASE WHEN S.AddressLost = 0 THEN SAdr.EMail ELSE '' END,
		Smois = month(HS.BirthDate),
		SAge = dbo.fn_Mo_Age(HS.BirthDate,getdate()),
		LaDate = getdate(),
		R.RepCode, 
		RLastName = HR.LastName , 
		RFirstName = HR.FirstName , 
		R.RepID
    INTO #tGU_RP_SubscriberByRep
	FROM dbo.Un_Convention C 
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN dbo.Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
	JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Adr SAdr ON HS.AdrID = SAdr.AdrID 
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	JOIN Un_Rep R ON S.RepID = R.RepID 
	JOIN #tb_rep rr ON r.repid = rr.repid
	JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
	JOIN (
		SELECT 
			SubscriberID, 
			MntSouscrit = SUM(	
				CASE 
					WHEN PlanTypeID = 'IND' THEN SommeCotisation 
					WHEN PmtEndConnectID IS NULL THEN (SommeFee + SommeCotisation)
					WHEN PmtQty = 1 THEN (SommeFee + SommeCotisation)
				ELSE (PmtQty * ROUND((UnitQty * PmtRate),2))
				END), 
			Transfert = MAX(
				CASE 
					WHEN UN.RepID <> UN.SRepID THEN 1
				ELSE 0
				END), 
			DSignature = MIN(SignatureDate), 
			Dvigueur = MAX(InForceDate),
			Nb_Unit = SUM(UnitQty), 
			Nb_Paiement = MAX(PmtQty), 
			MntDepot = SUM(
				CASE 
					WHEN PlanTypeID = 'IND' THEN SommeCotisation 
					WHEN PmtQty = 1 AND (PmtEndConnectID IS NULL) THEN (SommeFee + SommeCotisation)
				ELSE ROUND(UnitQty * PmtRate,2) + dbo.FN_CRQ_TaxRounding((SubscrInsur + BenefInsur) * (1+StateTaxPct))
				END), 
			MAXDePmtByYearID = MAX(PmtByYearID)  
		FROM (
			-- RETROUVE LES UNITÉS DE CONVENTION 
			SELECT 
				C.SubscriberID,
				U.ConventionID, 
				P.PlanTypeID, 
				U.SignatureDate, 
				U.InForceDate, 
				U.RepID, 
				SRepID = S.RepID,
				U.PmtEndConnectID, 
				M.PmtQty, 
				M.PmtByYearID, 
				U.UnitQty, 
				M.PmtRate,
				StateTaxPct = ISNULL(St.StateTaxPct,0), 
				SommeFee = ISNULL(SUM(CT.Fee),0), 
				SommeCotisation = ISNULL(SUM(CT.Cotisation),0),
				SubscrInsur =
					CASE
						WHEN U.WantSubscriberInsurance = 0 THEN 0
					ELSE ROUND(U.UnitQty * M.SubscriberInsuranceRate,2)
					END,
				BenefInsur = ISNULL(BI.BenefInsurRate,0)
			FROM dbo.Un_Unit U 
			JOIN Un_Modal M ON U.ModalID = M.ModalID
			LEFT JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
			JOIN Un_Plan P ON M.PlanID = P.PlanID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			JOIN #tb_rep rr ON s.repid = rr.repid
			LEFT JOIN Mo_State St ON St.StateID = S.StateID
			LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
			WHERE U.TerminatedDate IS NULL
			GROUP BY 
				C.SubscriberID,
				U.ConventionID, 
				U.UnitID, 
				U.SignatureDate, 
				U.InForceDate, 
				U.RepID, 
				U.PmtEndConnectID, 
				U.WantSubscriberInsurance,
				U.UnitQty, 
				M.PmtQty, 
				M.PmtByYearID, 
				M.PmtRate,
				M.SubscriberInsuranceRate,
				P.PlanTypeID, 
				St.StateTaxPct, 
				S.RepID,
				BI.BenefInsurRate
			) UN
		GROUP BY UN.SubscriberID
		) T ON C.SubscriberID = T.SubscriberID --C.ConventionID = T.ConventionID
	LEFT JOIN Mo_Lang SLang ON HS.LangID = SLang.LangID
	ORDER BY 
		HR.LastName, 
		HR.FirstName, 
		HS.LastName, 
		HS.FirstName 

    SELECT * FROM #tGU_RP_SubscriberByRep

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tGU_RP_SubscriberByRep', 
            @vcNom_ChampIdentifiant = 'SubscriberID', 
            @vcUtilisateur = @vcAudit_Utilisateur, 
            @vcContexte = @vcAudit_Contexte, 
            @bAcces_Courriel = 1, 
            @bAcces_Telephone = 1, 
            @bAcces_Adresse = 1
    --------------
    -- AUDIT - FIN
    --------------
    END 

END