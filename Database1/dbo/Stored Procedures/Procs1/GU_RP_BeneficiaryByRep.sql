/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_BeneficiaryByRep
Description         :	Procédure stockée du rapport : Liste des bénéficiaires et anniversaire par représentant (ancien rapport Excel de MacrosListesClientsBilingue.xls)
Valeurs de retours  :	Dataset
Note                :	2009-11-24  Donald Huppé	Création
                        2013-08-07  Maxime Martel	ajout de l'option "tous" pour les directeurs des agences
						            Donald Huppé	GLPI 13220 : ajout du courriel du souscripteur
                        2018-09-26  Pierre-Luc Simard   Ajout de l'audit dans la table tblGENE_AuditHumain

exec GU_RP_BeneficiaryByRep 1, 448581, 2

exec GU_RP_BeneficiaryByRep NULL, NULL, NULL

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_BeneficiaryByRep] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepID INTEGER,
	@UserID integer ) -- Limiter les résultats selon un représentant ou un directeur
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
        C.BeneficiaryID,
		Transert = CASE WHEN T.Transfert = 0 THEN 'Non' ELSE 'Oui' END, 
		T.Dvigueur, 
		T.DSignature,
		T.Nb_Unit, 
		NbPaiementAns = T.MAXDePmtByYearID, 
		T.Nb_Paiement, 
		T.MntSouscrit, 
		T.MntDepot, 
		BLastName = HB.LastName , 
		BFirstName = HB.FirstName , 
		BAddress = CASE WHEN B.bAddressLost = 0 THEN BAdr.Address ELSE '*** adresse perdue ***' END, 
		BCity = CASE WHEN B.bAddressLost = 0 THEN BAdr.City ELSE '' END, 
		BStateName = CASE WHEN B.bAddressLost = 0 THEN BAdr.StateName ELSE '' END , 
		BCountryID = CASE WHEN B.bAddressLost = 0 THEN BAdr.CountryID ELSE '' END ,
		BZipCode = CASE WHEN B.bAddressLost = 0 THEN BAdr.ZipCode ELSE '' END ,
		BPhone1 = CASE WHEN B.bAddressLost = 0 THEN BAdr.Phone1 ELSE '' END ,
		BPhone2 = CASE WHEN B.bAddressLost = 0 THEN BAdr.Phone2 ELSE '' END ,
		BSexID = HB.SexID , 
		BLangName = CASE BLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(BLang.LangName, 'Unknown') END , 
		BBirthDate = HB.BirthDate , 
		BSocialNumber = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						END,
		BEMail = CASE WHEN B.bAddressLost = 0 THEN BAdr.EMail ELSE '' END ,
		Bmois = month(HB.BirthDate),
		BAge = dbo.fn_Mo_Age(HB.BirthDate,getdate()),
		LaDate = getdate(),
		R.RepCode, 
		RLastName = HR.LastName , 
		RFirstName = HR.FirstName , 
		R.RepID
		,CourrielDesSousc = isnull(cr.CourrielDuSousc1,'') + case when isnull(cr.CourrielDuSousc2,'') <> isnull(cr.CourrielDuSousc1,'') then ';' + isnull(cr.CourrielDuSousc2,'') else '' END
    INTO #tGU_RP_BeneficiaryByRep
	FROM dbo.Un_Convention C 
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human hs on s.SubscriberID = hs.HumanID
	left JOIN 
		( -- si le benef a plus d'un souscrpteur, on en prend 2 différent. on prend comme aquis que ce sont le père et la mère
		select 
			c.BeneficiaryID
			,CourrielDuSousc1 = min(cr.vcCourriel)
			,CourrielDuSousc2 = max(cr.vcCourriel)
		from 
			Un_Convention c
			JOIN tblGENE_Courriel cr on cr.iID_Source = c.SubscriberID and getdate() BETWEEN cr.dtDate_Debut and isnull(cr.dtDate_Fin,'9999-12-31') and cr.bInvalide = 0
		GROUP by c.BeneficiaryID
		)cr on c.BeneficiaryID = cr.BeneficiaryID

	JOIN dbo.Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
	JOIN dbo.Mo_Human HB ON B.BeneficiaryID = HB.HumanID
	JOIN dbo.Mo_Adr BAdr ON BAdr.AdrID = HB.AdrID
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	JOIN Un_Rep R ON S.RepID = R.RepID 
	JOIN #tb_rep rr ON r.repid = rr.repid
	JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
	JOIN (
		SELECT 
			beneficiaryID, 
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
				C.beneficiaryID,
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
				C.beneficiaryID,
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
		GROUP BY UN.beneficiaryID
		) T ON C.beneficiaryID = T.beneficiaryID 
	LEFT JOIN Mo_Lang BLang ON HB.LangID = BLang.LangID 

	ORDER BY 
		HR.LastName, 
		HR.FirstName, 
		HB.LastName, 
		HB.FirstName 

    SELECT * FROM #tGU_RP_BeneficiaryByRep

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tGU_RP_BeneficiaryByRep', 
            @vcNom_ChampIdentifiant = 'BeneficiaryID', 
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