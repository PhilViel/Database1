/********************************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_BeneficiaryAdmCommByRep
Description         :	Procédure stockée du rapport : Liste de souscripteurs avec bénéficiaire de 6 ans et plus
Valeurs de retours  :	Dataset

exec GU_RP_BeneficiaryAdmCommByRep 149497, NULL

Historique des modifications:
		Date			Programmeur			Description
		----------	------------------	-----------------------------------------	
		2016-06-17	Steve Bélanger		Création du service	
        2016-07-07  Pierre-Luc Simard   Valider l'état de la convention en date du jour au lieu de la date passée en paramètre
        2018-09-26  Pierre-Luc Simard   Ajout de l'audit dans la table tblGENE_AuditHumain
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_BeneficiaryAdmCommByRep](	
	@RepID INTEGER,	
	@EnDateDu DATETIME = NULL) 
AS
BEGIN
	SET @EnDateDu = COALESCE(@EnDateDu , CONVERT(DATE, GETDATE(), 101))
	CREATE TABLE #TB_Rep (RepID INTEGER PRIMARY KEY)
	DECLARE @ParametreAge INTEGER = dbo.fnGENE_ObtenirParametre('CONV_AGE_MIN_BENEF_COMM_ACTIF', NULL, NULL, NULL, NULL, NULL, NULL)
	DECLARE @ParametreAgeFin INTEGER = 16
	INSERT INTO #TB_Rep SELECT @RepID	

	SELECT DISTINCT
		T.Nb_Unit, 			
		T.MntSouscrit,	
		SHumainID = HS.HumanID,
		SLastName = HS.LastName, 
		SFirstName = HS.FirstName,
		SSexID = HS.SexID,  	
		SLangName = CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Inconnu') END, 	
		STelephone = dbo.fnGENE_TelephoneEnDate (HS.HumanID, 1, NULL, 1, 1),
		SCellulaire = dbo.fnGENE_TelephoneEnDate (HS.HumanID, 2, NULL, 1, 1),
		SCourriel = dbo.fnGENE_CourrielEnDate (HS.HumanID, 1, NULL, 1),
		BHumainID = HB.HumanID,	
		BLastName = HB.LastName, 
		BFirstName = HB.FirstName,
		BSexID = HB.SexID, 
		BLangName = CASE BLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(BLang.LangName, 'Inconnu') END, 
		BBirthDate = HB.BirthDate,
		BMonthDiff = CASE WHEN MONTH(HB.BirthDate) < MONTH(@EnDateDu) THEN MONTH(HB.BirthDate) - MONTH(@EnDateDu) + 12 ELSE MONTH(HB.BirthDate) - MONTH(@EnDateDu) END,
		BJulianDate = DATEPART(dy, HB.BirthDate),
		BAge = dbo.fn_Mo_Age(HB.BirthDate, @EnDateDu),
		RLastName = HR.LastName, 
		RFirstName = HR.FirstName,
		RCode = R.RepCode, 
		RStatut = CASE WHEN @EnDateDu >= R.BusinessStart AND (@EnDateDu > R.BusinessEnd OR R.BusinessEnd IS NULL) THEN 'Actif' ELSE 'Inactif' END,		
		ParametreAge = @ParametreAge,
		LaDate = @EnDateDu
    INTO #tGU_RP_BeneficiaryAdmCommByRep		
	FROM dbo.Un_Convention C 
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN dbo.Un_Beneficiary B ON C.BeneficiaryID = B.BeneficiaryID
	JOIN dbo.Un_Rep R ON S.RepID = R.RepID 	
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID	
	JOIN dbo.Mo_Human HB ON B.BeneficiaryID = HB.HumanID	
	JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
	JOIN dbo.Mo_Lang BLang ON HB.LangID = BLang.LangID	
	JOIN dbo.Mo_Lang SLang ON HS.LangID = SLang.LangID	
	JOIN #TB_Rep RR ON R.RepID = RR.RepID
	JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON C.ConventionID = CS.conventionID
	JOIN (
		SELECT
			BeneficiaryID, 
			MntSouscrit = SUM(
				CASE 
					WHEN PlanTypeID = 'IND' THEN SommeCotisation 
					WHEN PmtEndConnectID IS NOT NULL OR PmtQty = 1 THEN (SommeFee + SommeCotisation)					
				ELSE (PmtQty * ROUND((UnitQty * PmtRate),2))
				END), 			
			Nb_Unit = SUM(UnitQty)		
		FROM (			
			SELECT 
				C.BeneficiaryID,			
				P.PlanTypeID,				
				U.PmtEndConnectID, 
				M.PmtQty, 				
				U.UnitQty, 
				M.PmtRate,				
				SommeFee = ISNULL(SUM(CT.Fee),0), 
				SommeCotisation = ISNULL(SUM(CT.Cotisation),0)				
			FROM dbo.Un_Unit U 
			JOIN Un_Modal M ON U.ModalID = M.ModalID
			LEFT JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
			JOIN Un_Plan P ON M.PlanID = P.PlanID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID			
			WHERE U.TerminatedDate IS NULL
			GROUP BY C.BeneficiaryID, U.ConventionID, U.UnitID, U.SignatureDate, U.InForceDate, U.RepID, U.PmtEndConnectID, U.WantSubscriberInsurance,
				U.UnitQty, M.PmtQty, M.PmtByYearID, M.PmtRate,M.SubscriberInsuranceRate,P.PlanTypeID
			) UN
		GROUP BY UN.BeneficiaryID
		) T ON C.BeneficiaryID = T.BeneficiaryID 			
	WHERE dbo.fn_Mo_Age(HB.BirthDate, @EnDateDu) BETWEEN @ParametreAge 
        AND @ParametreAgeFin 
        AND (CS.ConventionStateID = 'REE' 
            OR CS.ConventionStateID = 'TRA')
	ORDER BY 
		BMonthDiff,	
		BAge,
		BJulianDate,
		HR.LastName, 
		HR.FirstName, 
		HB.LastName, 
		HB.FirstName

    SELECT * FROM #tGU_RP_BeneficiaryAdmCommByRep

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tGU_RP_BeneficiaryAdmCommByRep', 
            @vcNom_ChampIdentifiant = 'SHumainID', 
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