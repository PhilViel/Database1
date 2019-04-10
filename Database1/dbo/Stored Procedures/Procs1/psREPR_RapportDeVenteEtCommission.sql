/****************************************************************************************************
Code de service		:		psREPR_RapportDeVenteEtCommission
Nom du service		:		
But					:		
Facette				:		REPR 
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						

Exemple d'appel:

EXEC psREPR_RapportDeVenteEtCommission
					@StartDate = '2017-09-01', -- Date de début
					@EndDate = '2017-09-17', -- Date de fin
					@RepID = 149593 --691759 -- -- -- --691759 --  -- --476221 --416305 -- ID du représentant
					,@Type = 'AG'

EXEC psREPR_RapportDeVenteEtCommission
					@StartDate = '2017-10-09', -- Date de début
					@EndDate = '2017-10-15', -- Date de fin
					@RepID = 149593 --691759 -- -- -- --691759 --  -- --476221 --416305 -- ID du représentant
					,@Type = 'REP'
					,@Data_DetailOuSommaire = 'D'

EXEC psREPR_RapportDeVenteEtCommission
					@StartDate = '2018-10-31', -- Date de début
					@EndDate = '2018-11-18', -- Date de fin
					@RepID = 149497 --691759 -- --476221 --416305 -- ID du représentant
					,@Type = 'REP'
					,@Data_DetailOuSommaire = 'D'

EXEC psREPR_RapportDeVenteEtCommission
					@StartDate = '2016-05-01', -- Date de début
					@EndDate = '2017-05-31', -- Date de fin
					@RepID = 0 -- --476221 --416305 -- ID du représentant

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
SrvName=SRVSQLPROD&DbName=UnivBase&StartDate=10/30/2017 00:00:00&EndDate=11/05/2017 00:00:00&vcLangID=FRA&LoginNameID=UNIVERSITAS\dhuppe&Rightid=171&IncludeAll=0&IncludeActifInactif=0&RepID=476221&Type=REP&AfficherTotauxDuDetailSeulement=False&AfficherSommaireSeulement=True&Data_DetailOuSommaire=S

Historique des modifications :			
						Date		Programmeur			Description							Référence
						2017-08-29	Donald Huppé		Création du service
						2017-11-09	Donald Huppé		Modification pour performance : utiliser @ThisRepID au lieu d'une table temporaire de RepID. Sortir un select de com du gros unnion
						2017-11-10	Donald Huppé		Modification pour performance : @iPremierTraitComm
						2017-12-28	Donald Huppé		jira prod-7129
						2018-01-05	Donald Huppé		Corrrection du calcul de #tTransferedUnits
						2018-09-07	Maxime Martel		JIRA MP-699 Ajout de OpertypeID COU
						2018-11-16	Donald Huppé		JIRA mp-2144 ajout de mMontant_ComBEC_Verse et mMontant_ComBEC_Repris
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportDeVenteEtCommission]
	(	
	@StartDate		DATETIME,
	@EndDate			DATETIME,
	@RepID				INT,
	@Type				VARCHAR(3), --REP, AG, ALL
	@Data_DetailOuSommaire	VARCHAR(1) = 'D' -- D ou S
    )
AS
	BEGIN


	DECLARE 
		@Type_Param						VARCHAR(3),
		@Data_DetailOuSommaire_Param	VARCHAR(1)


	SET	@Type_Param = @Type
	SET @Data_DetailOuSommaire_Param = @Data_DetailOuSommaire

	--set ARITHABORT ON

    DECLARE @DateDebutRatio DATETIME = '2014-10-06' -- Ne pas changer cette date
	DECLARE	@ThisRepID INT
	DECLARE	@EstDirecteur INT

	CREATE table #Dataset (

		EstDirecteur INT,
        RepCode VARCHAR(15),
		Representant VARCHAR(200),
		ConventionNo VARCHAR(30),
		UnitID INT,
		Regime VARCHAR(30),
		DateNaissanceBenef DATETIME,
		SubscriberID INT,
		BeneficiaryID INT,
		NomSouscripteur VARCHAR(200),
		NouveauClient  VARCHAR(10),
		TelSousc VARCHAR(30),
		CodePostalSousc VARCHAR(15),
		DateDebutOperFin DATETIME,
		Date1erDepot DATETIME,
		NbUniteActuel FLOAT,
		UniteAssure FLOAT,
		FraisCumululatif MONEY,
		NiveauRep1erDepot VARCHAR(100),

		Brut FLOAT,
		Reinscriptions FLOAT,
		Retraits_Partiel FLOAT,
		Retraits FLOAT,
		Net FLOAT,
		TFR FLOAT,
		Retraits_NON_ReduitTaux FLOAT,

		RepID_COM INT,
		RepCOM VARCHAR(200),
		RepRoleDesc VARCHAR(100),
		PeriodAdvance MONEY,
		CoverdAdvance MONEY,
		PeriodAdvanceResiliation MONEY,
		CumAdvance MONEY,
		ServiceComm MONEY,
		PeriodComm MONEY,
		PeriodCommResiliation MONEY,
		FuturComm MONEY,
		BusinessBonus MONEY,
		PeriodBusinessBonus MONEY,
		FuturBusinessBonus MONEY,
		mEpargne_SoldeDebutActif MONEY,
		mEpargne_PeriodeActif MONEY,
		mEpargne_SoldeFinActif MONEY,
		mEpargne_CalculActif MONEY,
		dTaux_CalculActif MONEY,
		mMontant_ComActif MONEY,
		mEpargne_SoldeDebutSuivi MONEY,
		mEpargne_PeriodeSuivi MONEY,
		mEpargne_SoldeFinSuivi MONEY,
		mEpargne_CalculSuivi MONEY,
		dTaux_CalculSuivi MONEY,
		mMontant_ComSuivi MONEY,
		BusinessBonusToPay INT,
		mMontant_ComBEC_Verse MONEY,
		mMontant_ComBEC_Repris MONEY
		)

	IF @Data_DetailOuSommaire_Param = 'S'
		BEGIN
		
		SELECT	* FROM #Dataset
		RETURN

		END

	--if exists (select 1 from sysobjects where name = 'tboCOM_New')
	--	drop table tboCOM_New

	DECLARE 
		@vcRepRoleDesc VARCHAR(100), -- Rôle du représentant
		@vcDefaultRepRoleDesc VARCHAR(100) -- Rôle du représentant

	CREATE TABLE #ListeRep (RepID INT, RepDir VARCHAR(3) ,RepBossPct FLOAT)


	IF @Type_Param = 'REP'
		BEGIN --[1]
		
		INSERT INTO #ListeRep
		SELECT DISTINCT *
		FROM (
			-- liste des rep du directeur passé en paramètre si c'est le cas
			SELECT DISTINCT
				Repid = B.RepID,
						-- si le rep demandé est tagué "DIR" si c'est le cas
				RepDir = CASE WHEN B.RepID = @RepID THEN 'DIR' ELSE 'REP' END
				,RepBossPct
			FROM 
				Un_RepBossHist B 
				JOIN dbo.Mo_Human H ON H.HumanID = B.RepID
				JOIN Un_Rep R ON R.RepID = H.HumanID
			WHERE 1=1
				AND B.RepRoleID IN ('DIR')
				AND B.BossID = @RepID
				AND B.StartDate <= GETDATE()
				AND ISNULL(B.EndDate,'9999-12-31') > GETDATE()

			UNION
			
			-- Le rep passé en paramètre
			SELECT
				RepID = @RepID,
				RepDir = 'REP'
				,RepBossPct = 0
			)V		
		order by RepID


		SET @EstDirecteur = 0

		IF EXISTS (select 1 FROM #ListeRep WHERE RepDir = 'DIR')
			-- IL DOIT Y AVOIR AU MOINS UN DIRECTEUR À PLUS DE 50%, SINON C'EST PLUTOT UN REP
			AND EXISTS (select 1 FROM #ListeRep WHERE RepDir = 'REP' AND RepBossPct > 50)
			BEGIN
			SET @EstDirecteur = 1
			DELETE FROM #ListeRep WHERE RepDir = 'REP'
			END
		ELSE
			BEGIN
			SET @EstDirecteur = 0
			DELETE FROM #ListeRep WHERE RepID <> @RepID OR RepDir = 'DIR'
			END


	END--[1] --@Type_Param = 'REP'




	IF @Type_Param = 'AG'
		BEGIN --[2]

		INSERT INTO #ListeRep
		SELECT DISTINCT
			b.RepID,
			RepDir = 'REP'
			,B.RepBossPct
		FROM 
			Un_RepBossHist B 
			JOIN (
				SELECT DISTINCT
					b.RepID,
					max_RepBossPct = max(b.RepBossPct)
				FROM 
					Un_RepBossHist B 
					JOIN dbo.Mo_Human H ON H.HumanID = B.RepID
					JOIN Un_Rep R ON R.RepID = H.HumanID
				WHERE 1=1
					AND B.RepRoleID IN ('DIR')
					and getdate() BETWEEN b.StartDate and isnull(b.EndDate,'9999-12-31')
				GROUP BY B.RepID
				) max_boss on max_boss.RepID = b.RepID and max_boss.max_RepBossPct = b.RepBossPct
			JOIN dbo.Mo_Human H ON H.HumanID = B.RepID
			JOIN Un_Rep R ON R.RepID = H.HumanID
		WHERE 1=1
			AND B.RepRoleID IN ('DIR')
			and B.BossID = @RepID
			and getdate() BETWEEN b.StartDate and isnull(b.EndDate,'9999-12-31')

		SET @EstDirecteur = 0

	END -- [2]



	IF @EstDirecteur = 1
		SET @vcDefaultRepRoleDesc = 'Directeur d''agence'

	IF @EstDirecteur = 0
		SET @vcDefaultRepRoleDesc = 'Représentant'


	SELECT @ThisRepID = RepID from #ListeRep
	

	--SELECT RepID /*into tmpListeRep*/  FROM #ListeRep

	--RETURN

    CREATE TABLE #tMaxPctBoss (
		UnitID INTEGER PRIMARY KEY,
		BossID INTEGER NOT NULL )

	INSERT INTO #tMaxPctBoss
		SELECT 
			M.UnitID,
			BossID = MAX(RBH.BossID)
		FROM (
			SELECT 
				U.UnitID,
				U.UnitQty,
				U.RepID,
				RepBossPct = MAX(RBH.RepBossPct)
			FROM dbo.Un_Unit U
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
			JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
			JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
			GROUP BY U.UnitID, U.RepID, U.UnitQty
			) M
		JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
		JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
		GROUP BY 
			M.UnitID
 

  	CREATE TABLE #UniteConvT (
		UnitID INT PRIMARY KEY, 
		RepID INT, 
        BossID INT,
		dtFirstDeposit DATETIME,
        vcTypeConv VARCHAR(10))
	
	INSERT INTO #UniteConvT
	SELECT 
        T.UnitID,
        T.RepID,
        T.BossID,
        T.dtFirstDeposit,
        vcTypeConv  = CASE WHEN C.ConventionNo LIKE 'T%' THEN 'TFRS' ELSE 'IBEC' END
    FROM fntREPR_ObtenirUniteConvT(1) T
	JOIN Un_Unit U ON U.UnitID = T.UnitID
	JOIN Un_Convention C ON C.ConventionID = U.ConventionID


	------------------------------------------------ COM
	DECLARE 
		--@vcRepRoleDesc VARCHAR(100), -- Rôle du représentant
		--@vcDefaultRepRoleDesc VARCHAR(100), -- Rôle du représentant

		@iPremierTraitComm INT, -- Identifiant du dernier traitement de commissions
		@iDernierTraitComm INT, -- Identifiant du dernier traitement de commissions
        @iPremierTraitCommActif INT, -- Identifiant du premier traitement de commissions
		@iPremierTraitCommSuivi INT, -- Identifiant du premier traitement de commissions
		@iDernierTraitCommActif INT, -- Identifiant du dernier traitement de commissions
		@iDernierTraitCommSuivi INT -- Identifiant du dernier traitement de commissions

	--SET @vcRepRoleDesc = 'Représentant'

	-- Récupérer le dernier traitement de commissions pour la période demandée
	SELECT --TOP 1
		@iPremierTraitComm = MIN( RT.RepTreatmentID), --2017-11-10
		@iDernierTraitComm = MAX( RT.RepTreatmentID)
	FROM Un_RepTreatment RT
	WHERE RT.RepTreatmentDate BETWEEN @StartDate AND @EndDate
	--ORDER BY 
	--	RT.RepTreatmentDate DESC,
	--	RT.RepTreatmentID DESC


	-- Récupérer le dernier traitement de commissions sur l'actif pour la période demandée
	SELECT --TOP 1
        @iPremierTraitCommActif = MIN(RT.RepTreatmentID),
		@iDernierTraitCommActif = MAX(RT.RepTreatmentID)
	FROM tblREPR_CommissionsSurActif CSA
	JOIN Un_RepTreatment RT ON RT.RepTreatmentID = CSA.RepTreatmentID
	WHERE RT.RepTreatmentDate BETWEEN @StartDate AND @EndDate
	--ORDER BY 
	--	RT.RepTreatmentDate DESC,
	--	RT.RepTreatmentID DESC

	-- Récupérer le dernier traitement de commissions de suivis pour la période demandée
	SELECT --TOP 1
		@iPremierTraitCommSuivi = MIN(RT.RepTreatmentID),
        @iDernierTraitCommSuivi = MAX(RT.RepTreatmentID)
	FROM tblREPR_CommissionsSuivi CS
	JOIN Un_RepTreatment RT ON RT.RepTreatmentID = CS.RepTreatmentID
	WHERE RT.RepTreatmentDate BETWEEN @StartDate AND @EndDate
	--ORDER BY 
	--	RT.RepTreatmentDate DESC,
	--	RT.RepTreatmentID DESC


--RETURN

	PRINT '1 - ' + LEFT(CONVERT(VARCHAR, getdate(), 120), 30)


	SELECT *
	INTO #tRepComm
	from (
		SELECT		
			CS.UnitID,
			RepID_COM,
			RepRoleDesc,
			PeriodAdvance = SUM(CS.PeriodAdvance),
			CoverdAdvance = SUM(CS.CoverdAdvance),
			PeriodAdvanceResiliation = SUM(CS.PeriodAdvanceResiliation),
			CumAdvance = SUM(CS.CumAdvance),
			ServiceComm = SUM(CS.ServiceComm),
			PeriodComm = SUM(CS.PeriodComm),
			PeriodCommResiliation = SUM(CS.PeriodCommResiliation),
			FuturComm = SUM(CS.FuturComm),
			BusinessBonus = SUM(CS.BusinessBonus),
			PeriodBusinessBonus = SUM(CS.PeriodBusinessBonus),
			FuturBusinessBonus  = SUM(CS.FuturBusinessBonus),
			mEpargne_SoldeDebutActif = SUM(CS.mEpargne_SoldeDebutActif),
			mEpargne_PeriodeActif = SUM(CS.mEpargne_SoldeFinActif) - SUM(CS.mEpargne_SoldeDebutActif), --SUM(CS.mEpargne_PeriodeActif),
			mEpargne_SoldeFinActif = SUM(CS.mEpargne_SoldeFinActif),
			mEpargne_CalculActif = (SUM(CS.mEpargne_SoldeDebutActif) + SUM(CS.mEpargne_SoldeFinActif)) / 2, --SUM(CS.mEpargne_CalculActif),
			dTaux_CalculActif = MAX(CS.dTaux_CalculActif),
			mMontant_ComActif = SUM(CS.mMontant_ComActif), 
			mEpargne_SoldeDebutSuivi = SUM(CS.mEpargne_SoldeDebutSuivi),
			mEpargne_PeriodeSuivi = SUM(CS.mEpargne_SoldeFinSuivi) - SUM(CS.mEpargne_SoldeDebutSuivi), --SUM(CS.mEpargne_PeriodeSuivi),
			mEpargne_SoldeFinSuivi = SUM(CS.mEpargne_SoldeFinSuivi),
			mEpargne_CalculSuivi = (SUM(CS.mEpargne_SoldeDebutSuivi) + SUM(CS.mEpargne_SoldeFinSuivi)) / 2, --SUM(CS.mEpargne_CalculSuivi),
			dTaux_CalculSuivi = MAX(CS.dTaux_CalculSuivi),
			mMontant_ComSuivi = SUM(CS.mMontant_ComSuivi),
			mMontant_ComBEC_Verse = SUM(mMontant_ComBEC_Verse),
			mMontant_ComBEC_Repris = SUM(mMontant_ComBEC_Repris)
		--INTO #tRepComm
		FROM (
			-- Récupérer les soldes du dernier traitement de commissions pour les colonnes que l'on ne peut pas additionner

			SELECT 
				RepID_COM = rt.RepID,
				RT.UnitID,
				RT.RepRoleDesc,
				PeriodAdvance = 0,
				CoverdAdvance = 0,
				PeriodAdvanceResiliation = 0,
				RT.CumAdvance,
				RT.ServiceComm,
				PeriodComm = 0,
				PeriodCommResiliation = 0,
				RT.FuturComm,
				RT.BusinessBonus,
				PeriodBusinessBonus = 0,
				RT.FuturBusinessBonus,
				mEpargne_SoldeDebutActif = 0,
				mEpargne_PeriodeActif = 0,
				mEpargne_SoldeFinActif = 0,
				mEpargne_CalculActif = 0,
				dTaux_CalculActif = 0,
				mMontant_ComActif = 0,
				mEpargne_SoldeDebutSuivi = 0,
				mEpargne_PeriodeSuivi = 0,
				mEpargne_SoldeFinSuivi = 0,
				mEpargne_CalculSuivi = 0,
				dTaux_CalculSuivi = 0,
				mMontant_ComSuivi = 0,
				mMontant_ComBEC_Verse = 0,
				mMontant_ComBEC_Repris = 0     
			FROM Un_Dn_RepTreatment RT
			--JOIN #ListeRep LR on LR.RepID = RT.RepID
			WHERE rt.RepID = @ThisRepID
				and  RT.RepTreatmentID = @iDernierTraitComm
				--AND @Data_DetailOuSommaire = 'D'
				--AND RT.RepRoleDesc = @vcRepRoleDesc

			UNION ALL
  
			-- Récupérer les sommes des traitements de commissions de la période demandée
			SELECT 
				RepID_COM = rt.RepID,
				RT.UnitID,
				RT.RepRoleDesc,
				--PeriodAdvance = SUM(CASE WHEN RT.PeriodAdvance < 0 AND ISNULL(RT.Notes, '') = 'RES' THEN 0 ELSE RT.PeriodAdvance END),
				PeriodAdvance = SUM(CASE WHEN RT.PeriodAdvance < 0 THEN 0 ELSE RT.PeriodAdvance END),
				CoverdAdvance = SUM(RT.CoverdAdvance),
				--PeriodAdvanceResiliation = SUM(CASE WHEN RT.PeriodAdvance < 0 AND ISNULL(RT.Notes, '') = 'RES' THEN RT.PeriodAdvance ELSE 0 END),
				PeriodAdvanceResiliation = SUM(CASE WHEN RT.PeriodAdvance < 0 THEN RT.PeriodAdvance ELSE 0 END),
				CumAdvance = 0,
				ServiceComm = 0,
				--PeriodComm = SUM(CASE WHEN RT.PeriodComm < 0  AND ISNULL(RT.Notes, '') = 'RES' THEN 0 ELSE RT.PeriodComm END),
				PeriodComm = SUM(CASE WHEN RT.PeriodComm < 0 THEN 0 ELSE RT.PeriodComm END),
				--PeriodCommResiliation = SUM(CASE WHEN RT.PeriodComm < 0 AND ISNULL(RT.Notes, '') = 'RES' THEN RT.PeriodComm ELSE 0 END),
				PeriodCommResiliation = SUM(CASE WHEN RT.PeriodComm < 0 THEN RT.PeriodComm ELSE 0 END),
				FuturComm = 0,
				BusinessBonus = 0,
				PeriodBusinessBonus = SUM(RT.PeriodBusinessBonus),
				FuturBusinessBonus = 0,
				mEpargne_SoldeDebutActif = 0,
				mEpargne_PeriodeActif = 0,
				mEpargne_SoldeFinActif = 0,
				mEpargne_CalculActif = 0,
				dTaux_CalculActif = 0,
				mMontant_ComActif = 0,
				mEpargne_SoldeDebutSuivi = 0,
				mEpargne_PeriodeSuivi = 0,
				mEpargne_SoldeFinSuivi = 0,
				mEpargne_CalculSuivi = 0,
				dTaux_CalculSuivi = 0,
				mMontant_ComSuivi = 0,
				mMontant_ComBEC_Verse = 0,
				mMontant_ComBEC_Repris = 0 
			FROM Un_Dn_RepTreatment RT
			--JOIN #ListeRep LR on LR.RepID = RT.RepID
			WHERE rt.RepID = @ThisRepID
				--and RT.RepTreatmentDate BETWEEN @StartDate AND @EndDate
				AND RT.RepTreatmentID BETWEEN @iPremierTraitComm AND @iDernierTraitComm -- 2017-11-10

			GROUP BY RT.RepRoleDesc, RT.UnitID,rt.RepID

			UNION ALL
    
			-- Récupérer le solde de début du premier traitement de commissions sur l'actif
			SELECT 
				RepID_COM = CSA.RepID,
				CSA.UnitID,
				RepRoleDesc = @vcDefaultRepRoleDesc,
				PeriodAdvance = 0,
				CoverdAdvance = 0,
				PeriodAdvanceResiliation = 0,
				CumAdvance = 0,
				ServiceComm = 0,
				PeriodComm = 0,
				PeriodCommResiliation = 0,
				FuturComm = 0,
				BusinessBonus = 0,
				PeriodBusinessBonus = 0,
				FuturBusinessBonus = 0,
				mEpargne_SoldeDebutActif = CSA.mEpargne_SoldeDebut,
				mEpargne_PeriodeActif = 0,
				mEpargne_SoldeFinActif = 0,
				mEpargne_CalculActif = 0,
				dTaux_CalculActif = 0,
				mMontant_ComActif = 0,
				mEpargne_SoldeDebutSuivi = 0,
				mEpargne_PeriodeSuivi = 0,
				mEpargne_SoldeFinSuivi = 0,
				mEpargne_CalculSuivi = 0,
				dTaux_CalculSuivi = 0,
				mMontant_ComSuivi = 0,
				mMontant_ComBEC_Verse = 0,
				mMontant_ComBEC_Repris = 0 
			FROM tblREPR_CommissionsSurActif CSA
			--JOIN #ListeRep LR on LR.RepID = CSA.RepID
			WHERE CSA.RepID = @ThisRepID
				and CSA.RepTreatmentID = @iPremierTraitCommActif

			UNION ALL

			-- Récupérer le solde de fin et le taux du dernier traitement de commissions sur l'actif 
			SELECT 
				RepID_COM = CSA.RepID,
				CSA.UnitID,
				RepRoleDesc = @vcDefaultRepRoleDesc,
				PeriodAdvance = 0,
				CoverdAdvance = 0,
				PeriodAdvanceResiliation = 0,
				CumAdvance = 0,
				ServiceComm = 0,
				PeriodComm = 0,
				PeriodCommResiliation = 0,
				FuturComm = 0,
				BusinessBonus = 0,
				PeriodBusinessBonus = 0,
				FuturBusinessBonus = 0,
				mEpargne_SoldeDebutActif = 0,
				mEpargne_PeriodeActif = 0,
				mEpargne_SoldeFinActif = CSA.mEpargne_SoldeFin,
				mEpargne_CalculActif = 0,
				dTaux_CalculActif = CSA.dTaux_Calcul,
				mMontant_ComActif = 0,
				mEpargne_SoldeDebutSuivi = 0,
				mEpargne_PeriodeSuivi = 0,
				mEpargne_SoldeFinSuivi = 0,
				mEpargne_CalculSuivi = 0,
				dTaux_CalculSuivi = 0,
				mMontant_ComSuivi = 0,
				mMontant_ComBEC_Verse = 0,
				mMontant_ComBEC_Repris = 0 
			FROM tblREPR_CommissionsSurActif CSA
			--JOIN #ListeRep LR on LR.RepID = CSA.RepID
			WHERE CSA.RepID = @ThisRepID
				and CSA.RepTreatmentID = @iDernierTraitCommActif

			UNION ALL 
        
			 -- Récupérer les sommes des traitements de commissions sur l'actif de la période demandée
			SELECT 
				RepID_COM = CSA.RepID,
				CSA.UnitID,
				RepRoleDesc = @vcDefaultRepRoleDesc,
				PeriodAdvance = 0,
				CoverdAdvance = 0,
				PeriodAdvanceResiliation = 0,
				CumAdvance = 0,
				ServiceComm = 0,
				PeriodComm = 0,
				PeriodCommResiliation = 0,
				FuturComm = 0,
				BusinessBonus = 0,
				PeriodBusinessBonus = 0,
				FuturBusinessBonus = 0,
				mEpargne_SoldeDebutActif = 0,
				mEpargne_PeriodeActif = 0,
				mEpargne_SoldeFinActif = 0,
				mEpargne_CalculActif = 0,
				dTaux_CalculActif = 0,
				mMontant_ComActif = SUM(CSA.mMontant_ComActif),
				mEpargne_SoldeDebutSuivi = 0,
				mEpargne_PeriodeSuivi = 0,
				mEpargne_SoldeFinSuivi = 0,
				mEpargne_CalculSuivi = 0,
				dTaux_CalculSuivi = 0,
				mMontant_ComSuivi = 0,
				mMontant_ComBEC_Verse = 0,
				mMontant_ComBEC_Repris = 0  
			FROM tblREPR_CommissionsSurActif CSA
			JOIN Un_RepTreatment RT ON RT.RepTreatmentID = CSA.RepTreatmentID
			--JOIN #ListeRep LR on LR.RepID = CSA.RepID
			WHERE CSA.RepID = @ThisRepID
				and RT.RepTreatmentDate BETWEEN @StartDate AND @EndDate
			GROUP BY CSA.UnitID,CSA.RepID

			UNION ALL
    
			-- Récupérer les soldes de début du premier traitement de commissions de suivis
			SELECT 
				RepID_COM = CS.RepID,
				CS.UnitID,
				RepRoleDesc = @vcDefaultRepRoleDesc,
				PeriodAdvance = 0,
				CoverdAdvance = 0,
				PeriodAdvanceResiliation = 0,
				CumAdvance = 0,
				ServiceComm = 0,
				PeriodComm = 0,
				PeriodCommResiliation = 0,
				FuturComm = 0,
				BusinessBonus = 0,
				PeriodBusinessBonus = 0,
				FuturBusinessBonus = 0,
				mEpargne_SoldeDebutActif = 0,
				mEpargne_PeriodeActif = 0,
				mEpargne_SoldeFinActif = 0,
				mEpargne_CalculActif = 0,
				dTaux_CalculActif = 0,
				mMontant_ComActif = 0,
				mEpargne_SoldeDebutSuivi = CS.mEpargne_SoldeDebut,
				mEpargne_PeriodeSuivi = 0,
				mEpargne_SoldeFinSuivi = 0,
				mEpargne_CalculSuivi = 0,
				dTaux_CalculSuivi = 0,
				mMontant_ComSuivi = 0,
				mMontant_ComBEC_Verse = 0,
				mMontant_ComBEC_Repris = 0 
			FROM tblREPR_CommissionsSuivi CS
			--JOIN #ListeRep LR on LR.RepID = CS.RepID
			WHERE CS.RepID = @ThisRepID
				and CS.RepTreatmentID = @iPremierTraitCommSuivi

			UNION ALL 

			-- Récupérer le solde de fin et le taux du dernier traitement de commissions de suivis
			SELECT 
				RepID_COM = CS.RepID,
				CS.UnitID,
				RepRoleDesc = @vcDefaultRepRoleDesc,
				PeriodAdvance = 0,
				CoverdAdvance = 0,
				PeriodAdvanceResiliation = 0,
				CumAdvance = 0,
				ServiceComm = 0,
				PeriodComm = 0,
				PeriodCommResiliation = 0,
				FuturComm = 0,
				BusinessBonus = 0,
				PeriodBusinessBonus = 0,
				FuturBusinessBonus = 0,
				mEpargne_SoldeDebutActif = 0,
				mEpargne_PeriodeActif = 0,
				mEpargne_SoldeFinActif = 0,
				mEpargne_CalculActif = 0,
				dTaux_CalculActif = 0,
				mMontant_ComActif = 0,
				mEpargne_SoldeDebutSuivi = 0,
				mEpargne_PeriodeSuivi = 0,
				mEpargne_SoldeFinSuivi = CS.mEpargne_SoldeFin,
				mEpargne_CalculSuivi = 0,
				dTaux_CalculSuivi = CS.dTaux_Calcul,
				mMontant_ComSuivi = 0,
				mMontant_ComBEC_Verse = 0,
				mMontant_ComBEC_Repris = 0 
			FROM tblREPR_CommissionsSuivi CS
			--JOIN #ListeRep LR on LR.RepID = CS.RepID
			WHERE CS.RepID = @ThisRepID
				and CS.RepTreatmentID = @iDernierTraitCommSuivi

			UNION ALL 
        
			 -- Récupérer les sommes des traitements de commissions de suivi de la période demandée
			SELECT 
				RepID_COM = CS.RepID,
				CS.UnitID,
				RepRoleDesc = @vcDefaultRepRoleDesc,
				PeriodAdvance = 0,
				CoverdAdvance = 0,
				PeriodAdvanceResiliation = 0,
				CumAdvance = 0,
				ServiceComm = 0,
				PeriodComm = 0,
				PeriodCommResiliation = 0,
				FuturComm = 0,
				BusinessBonus = 0,
				PeriodBusinessBonus = 0,
				FuturBusinessBonus = 0,
				mEpargne_SoldeDebutActif = 0,
				mEpargne_PeriodeActif = 0,
				mEpargne_SoldeFinActif = 0,
				mEpargne_CalculActif = 0,
				dTaux_CalculActif = 0,
				mMontant_ComActif = 0,
				mEpargne_SoldeDebutSuivi = 0,
				mEpargne_PeriodeSuivi = 0,
				mEpargne_SoldeFinSuivi = 0,
				mEpargne_CalculSuivi = 0,
				dTaux_CalculSuivi = 0,
				mMontant_ComSuivi = SUM(CS.mMontant_ComSuivi),
				mMontant_ComBEC_Verse = 0,
				mMontant_ComBEC_Repris = 0 
			FROM tblREPR_CommissionsSuivi CS
			--JOIN #ListeRep LR on LR.RepID = CS.RepID
			JOIN Un_RepTreatment RT ON RT.RepTreatmentID = CS.RepTreatmentID
			WHERE CS.RepID = @ThisRepID
				and RT.RepTreatmentDate BETWEEN @StartDate AND @EndDate
			GROUP BY CS.UnitID,CS.RepID

			UNION ALL

			 -- Récupérer les sommes des traitements de commissions de BEC de la période demandée
			SELECT 
				RepID_COM = CB.RepID,
				CB.UnitID,
				RepRoleDesc = RR.RepRoleDesc,--@vcDefaultRepRoleDesc,
				PeriodAdvance = 0,
				CoverdAdvance = 0,
				PeriodAdvanceResiliation = 0,
				CumAdvance = 0,
				ServiceComm = 0,
				PeriodComm = 0,
				PeriodCommResiliation = 0,
				FuturComm = 0,
				BusinessBonus = 0,
				PeriodBusinessBonus = 0,
				FuturBusinessBonus = 0,
				mEpargne_SoldeDebutActif = 0,
				mEpargne_PeriodeActif = 0,
				mEpargne_SoldeFinActif = 0,
				mEpargne_CalculActif = 0,
				dTaux_CalculActif = 0,
				mMontant_ComActif = 0,
				mEpargne_SoldeDebutSuivi = 0,
				mEpargne_PeriodeSuivi = 0,
				mEpargne_SoldeFinSuivi = 0,
				mEpargne_CalculSuivi = 0,
				dTaux_CalculSuivi = 0,
				mMontant_ComSuivi = 0,
				mMontant_ComBEC_Verse = SUM(CASE WHEN mMontant_ComBEC >= 0 THEN mMontant_ComBEC ELSE 0 END),
				mMontant_ComBEC_Repris =  SUM(CASE WHEN mMontant_ComBEC < 0 THEN mMontant_ComBEC ELSE 0 END)
			FROM tblREPR_CommissionsBEC CB
			JOIN Un_RepRole RR on RR.RepRoleID = CB.RepRoleID
			--JOIN #ListeRep LR on LR.RepID = CB.RepID
			JOIN Un_RepTreatment RT ON RT.RepTreatmentID = CB.RepTreatmentID
			WHERE CB.RepID = @ThisRepID
				and RT.RepTreatmentDate BETWEEN @StartDate AND @EndDate
			GROUP BY CB.UnitID,CB.RepID, RR.RepRoleDesc

			) CS
		GROUP BY CS.UnitID, CS.RepRoleDesc, CS.RepID_COM
		-- ceci empèche de sortir des groupes d'unité avec 1er dépot aprrès la période choisie --2017-09-14

		)v
	WHERE 
			PeriodAdvance <> 0 OR
			CoverdAdvance  <> 0 OR
			PeriodAdvanceResiliation <> 0 OR
			CumAdvance <> 0 OR
			ServiceComm  <> 0 OR
			PeriodComm <> 0 OR
			PeriodCommResiliation <> 0 OR
			FuturComm  <> 0 OR
			BusinessBonus  <> 0 OR
			PeriodBusinessBonus <> 0 OR
			FuturBusinessBonus <> 0 OR
			mEpargne_SoldeDebutActif <> 0 OR
			mEpargne_PeriodeActif <> 0 OR
			mEpargne_SoldeFinActif <> 0 OR
			mEpargne_CalculActif <> 0 OR
			dTaux_CalculActif <> 0 OR
			mMontant_ComActif <> 0 OR
			mEpargne_SoldeDebutSuivi <> 0 OR
			mEpargne_PeriodeSuivi <> 0 OR
			mEpargne_SoldeFinSuivi <> 0 OR
			mEpargne_CalculSuivi <> 0 OR
			dTaux_CalculSuivi <> 0 OR
			mMontant_ComSuivi <> 0 OR
			mMontant_ComBEC_Verse <> 0 OR
			mMontant_ComBEC_Repris <> 0
	
	
	-- QUAND ON DEMANDE PAR AGENCE, ON  NE SORT PAS LES COM DE DIRECTEUR QUI NE SONT PAS LE DIRECTEUR DE CETTE AGENCE
	-- Aucun commission de directeur quand on sort une agence
	DELETE FROM #tRepComm
	WHERE @Type_Param = 'AG'
		AND	RepRoleDesc LIKE '%DIRECTEUR%'
		--AND RepID_COM <> @RepID
	

	PRINT '2 - ' + LEFT(CONVERT(VARCHAR, getdate(), 120), 30)

	SELECT 

		C.ConventionNo,
		U.UnitID,
		RepID = ISNULL(UT.RepID, U.RepID),
		BossID = ISNULL(UT.BossID,MP.BossID),
		Regime =	CASE 
					WHEN RR.vcCode_Regroupement = 'IND' AND ISNULL(UT.vcTypeConv, '') = 'TFRS' THEN RR.vcDescription + '-T' -- + ISNULL(UT.vcTypeConv, '')
					WHEN RR.vcCode_Regroupement = 'IND' AND ISNULL(UT.vcTypeConv, '') = 'IBEC' THEN RR.vcDescription + '-' + ISNULL(UT.vcTypeConv, '')
					ELSE RR.vcDescription
					END,
		DateNaissanceBenef = cast( HB.BirthDate as date),
		C.SubscriberID,
		BeneficiaryID = HB.HumanID,
		NomSouscripteur = HS.FirstName + ' ' + HS.LastName,
		NouveauClient = CASE 
							WHEN NouvClient.MIN_dtFirstDeposit IS NOT NULL THEN 'Oui' 
							ELSE 'Non' 
						END,
		TelSousc = cast('' as varchar(100)) ,
		CodePostalSousc = cast('' as varchar(100)) ,
		DateDebutOperFin = cast( U.InForceDate as date),
		Date1erDepot = cast(U.dtFirstDeposit as date),
		NbUniteActuel = u.UnitQty + ISNULL(UR.UnitQtyRESAfter,0),
		UniteAssure = CASE WHEN u.WantSubscriberInsurance = 1 AND M.SubscriberInsuranceRate > 0 THEN u.UnitQty + ISNULL(UR.UnitQtyRESAfter,0) ELSE 0 END,
		FraisCumululatif = ISNULL(FraisCumul,0),
		NiveauRep1erDepot = isnull(NiveauRep.LevelDesc,''),

		Brut = 0,
		Reinscriptions = 0,
		Retraits_Partiel = 0,
		Retraits = 0,
		Net = 0,
		TFR = 0,
		Retraits_NON_ReduitTaux = 0,

		RepID_COM,
		RepRoleDesc,
		PeriodAdvance,
		CoverdAdvance,
		PeriodAdvanceResiliation,
		CumAdvance,
		ServiceComm,
		PeriodComm,
		PeriodCommResiliation,
		FuturComm,
		BusinessBonus,
		PeriodBusinessBonus,
		FuturBusinessBonus,
		mEpargne_SoldeDebutActif,
		mEpargne_PeriodeActif,
		mEpargne_SoldeFinActif,
		mEpargne_CalculActif,
		dTaux_CalculActif,
		mMontant_ComActif, 
		mEpargne_SoldeDebutSuivi,
		mEpargne_PeriodeSuivi,
		mEpargne_SoldeFinSuivi,
		mEpargne_CalculSuivi,
		dTaux_CalculSuivi,
		mMontant_ComSuivi,
		mMontant_ComBEC_Verse,
		mMontant_ComBEC_Repris
	into #tCOM	
	from 
		#tRepComm Com
		JOIN Un_Unit U ON U.UnitID = Com.UnitID
		join Un_Modal m on m.ModalID = u.ModalID
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Mo_Human HS ON HS.HumanID = C.SubscriberID
		JOIN Un_Plan P ON P.PlanID = c.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		LEFT JOIN #UniteConvT UT ON UT.UnitID = U.UnitID

		LEFT JOIN (
			SELECT UnitID, UnitQtyRESAfter = SUM(UnitQty)
			FROM Un_UnitReduction
			WHERE ReductionDate > @EndDate
			GROUP BY UnitID
			)UR ON UR.UnitID = Com.UnitID

		LEFT JOIN (
			SELECT U.UnitID, LevelDesc = MAX(rlRep.LevelDesc)
			FROM Un_Unit U
			JOIN Un_Replevelhist lhRep on u.repid = lhRep.repid AND U.InForceDate BETWEEN lhRep.startdate AND ISNULL(lhRep.enddate,'3000-01-01')
			JOIN Un_Replevel rlRep on rlRep.RepLevelID = lhRep.RepLevelID AND rlRep.RepRoleID = 'REP'
			GROUP BY U.UnitID
			)NiveauRep on NiveauRep.UnitID = Com.UnitID


		LEFT JOIN #tMaxPctBoss MP ON MP.UnitID = U.UnitID
		LEFT JOIN (
			SELECT C.SubscriberID,MIN_dtFirstDeposit = MIN(U.dtFirstDeposit)
			FROM Un_Unit U 
			JOIN Un_Convention C ON C.ConventionID = U.ConventionID
			GROUP BY C.SubscriberID
				)NouvClient ON NouvClient.SubscriberID = c.SubscriberID AND NouvClient.MIN_dtFirstDeposit = u.dtFirstDeposit
		LEFT JOIN (
			SELECT 
				u.UnitID
				,FraisCumul = sum(ct.Fee)
			FROM Un_Unit U 
			JOIN Un_Cotisation ct on ct.UnitID = u.UnitID
			join Un_Oper o on o.OperID = ct.OperID
			where o.OperDate <= @EndDate
			GROUP BY u.UnitID
				)FraisCumul ON FraisCumul.UnitID = u.UnitID

		LEFT JOIN (
				select cbAvant.iID_Convention, cbAvant.iID_Nouveau_Beneficiaire, DateDu = cbAvant.dtDate_Changement_Beneficiaire, DateAu = isnull(CBapres.dtDate_Changement_Beneficiaire,'9999-12-31')
				from (
					select cb.iID_Convention, cb.iID_Changement_Beneficiaire, MIN_iID_Changement_Beneficiaire = min(CB2.iID_Changement_Beneficiaire)
					from tblCONV_ChangementsBeneficiaire CB
						JOIN Un_Unit U ON U.ConventionID = CB.iID_Convention
						JOIN #tRepComm G1 ON G1.UnitID = U.UnitID
						left join tblCONV_ChangementsBeneficiaire CB2 on cb.iID_Convention = CB2.iID_Convention and CB2.iID_Changement_Beneficiaire > cb.iID_Changement_Beneficiaire
					GROUP by cb.iID_Convention, cb.iID_Changement_Beneficiaire
					)t
				JOIN tblCONV_ChangementsBeneficiaire cbAvant on t.iID_Changement_Beneficiaire = cbAvant.iID_Changement_Beneficiaire
				LEFT JOIN tblCONV_ChangementsBeneficiaire CBapres on t.MIN_iID_Changement_Beneficiaire = CBapres.iID_Changement_Beneficiaire
				--order by cbAvant.iID_Convention
			)HIST_BENEF ON HIST_BENEF.iID_Convention = C.ConventionID AND @EndDate BETWEEN HIST_BENEF.DateDu AND HIST_BENEF.DateAu
		LEFT JOIN Mo_Human HB ON HB.HumanID = HIST_BENEF.iID_Nouveau_Beneficiaire


PRINT '3 - ' + LEFT(CONVERT(VARCHAR, getdate(), 120), 30)

	UPDATE Com
		SET 
			TelSousc = dbo.fn_Mo_FormatPhoneNo( ISNULL(ADR.Phone1,ISNULL(ADR.Mobile,ADR.Phone2)),adr.CountryID),
			CodePostalSousc = dbo.fn_Mo_FormatZIP( adr.ZipCode,adr.CountryID)
	from #tCOM com
	join Mo_Human hs on hs.HumanID = com.subscriberid
	join mo_adr adr on adr.AdrID = hs.AdrID



	--------------------------------------------------Fin COM


    CREATE TABLE #tTFRInclutDansBRUT (		
		UnitID INTEGER PRIMARY KEY,
		RepID INT,
		NbUnitesAjoutees MONEY NOT NULL,
		fUnitQtyUse MONEY NOT NULL,
		DateUnite DATETIME)

	-- Unités disponibles transférées (rétention de client) sur les unités de la période
	INSERT INTO #tTFRInclutDansBRUT
		SELECT 
			U1.UnitID,
			U1.RepID,
			NbUnitesAjoutees = (U1.UnitQty  + ISNULL(UR2.UnitQty,0) )- SUM(A.fUnitQtyUse),
	    	fUnitQtyUse = SUM(A.fUnitQtyUse),
			DateUnite = U1.dtFirstDeposit
		FROM Un_AvailableFeeUse A 
		JOIN Un_Oper O ON O.OperID = A.OperID
		JOIN Un_Cotisation C ON C.OperID = O.OperID
		JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
		JOIN dbo.Un_Convention Cv ON U1.conventionid = Cv.conventionid
		JOIN Un_UnitReduction UR ON A.unitreductionid = UR.unitreductionid 
		JOIN dbo.Un_Unit Uori ON UR.unitid = Uori.unitid
		JOIN dbo.Un_Convention CvOri ON Uori.conventionid = CvOri.conventionid 
		LEFT JOIN (
			SELECT 
				UR.UnitID,
				UnitQty = SUM(UR.UnitQty)
			FROM Un_UnitReduction UR
			GROUP BY UR.UnitID
			) UR2 ON UR2.UnitID = U1.UnitID					                
		WHERE O.OperTypeID = 'TFR'
		    AND ( (U1.UnitQty + ISNULL(UR2.UnitQty,0) )- A.fUnitQtyUse) >= 0
		    AND U1.dtFirstDeposit >= @StartDate 
            AND U1.dtFirstDeposit <= @EndDate
			AND (
					Uori.repID <> U1.repid 
				OR	CvOri.SubscriberID <> Cv.SubscriberID
				)
		GROUP BY
			U1.UnitID,
			U1.RepID,
			U1.UnitQty,
			UR2.UnitQty,
			U1.dtFirstDeposit

	--SELECT * from #tTFRInclutDansBRUT

	CREATE TABLE #tTransferedUnits (		
		UnitID INTEGER PRIMARY KEY,
		RepID INT,
		NbUnitesAjoutees MONEY NOT NULL,
		fUnitQtyUse MONEY NOT NULL,
		DateUnite DATETIME)

	-- Unités disponibles transférées (rétention de client) sur les unités de la période
	INSERT INTO #tTransferedUnits
		SELECT 
			U1.UnitID,
			U1.RepID,
			NbUnitesAjoutees = (U1.UnitQty  + ISNULL(UR2.UnitQty,0) )- SUM(A.fUnitQtyUse),
	    	fUnitQtyUse = SUM(A.fUnitQtyUse),
			DateUnite = U1.dtFirstDeposit
		FROM Un_AvailableFeeUse A 
		JOIN Un_Oper O ON O.OperID = A.OperID
		JOIN Un_Cotisation C ON C.OperID = O.OperID
		JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
		JOIN dbo.Un_Convention Cv ON U1.conventionid = Cv.conventionid
		JOIN Un_UnitReduction UR ON A.unitreductionid = UR.unitreductionid 
		JOIN dbo.Un_Unit Uori ON UR.unitid = Uori.unitid and Uori.repID = U1.repid -- doit être le même Rep -- Incompatible avec Nouvelle vente validée (FeeTransferUnitQty : transfert de frais)
		JOIN dbo.Un_Convention CvOri ON Uori.conventionid = CvOri.conventionid 
						                AND CvOri.SubscriberID = Cv.SubscriberID -- doit être le même Souscripteur 	--and CvOri.BeneficiaryID = Cv.BeneficiaryID -- On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert 2009-04-15
		LEFT JOIN (
			SELECT 
				UR.UnitID,
				UnitQty = SUM(UR.UnitQty)
			FROM Un_UnitReduction UR
			GROUP BY UR.UnitID
			) UR2 ON UR2.UnitID = U1.UnitID
		WHERE O.OperTypeID = 'TFR'
		    AND ( (U1.UnitQty + ISNULL(UR2.UnitQty,0) )- A.fUnitQtyUse) >= 0
		    AND U1.dtFirstDeposit >= @StartDate 
            AND U1.dtFirstDeposit <= @EndDate
		GROUP BY
			U1.UnitID,
			U1.RepID,
			U1.UnitQty,
			UR2.UnitQty,
			U1.dtFirstDeposit



 	CREATE TABLE #tReinscriptions (
		UnitID INTEGER,
    	fUnitQtyUse MONEY NOT NULL,
		DateUnite DATETIME)

	INSERT INTO #tReinscriptions
		SELECT 
			U1.UnitID,
	    	fUnitQtyUse = SUM(A.fUnitQtyUse * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END),
			DateUnite = u1.dtFirstDeposit
		FROM Un_AvailableFeeUse A
		JOIN Un_Oper O ON O.OperID = A.OperID
		JOIN Un_Cotisation C ON C.OperID = O.OperID
		JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
		JOIN Un_Rep R ON U1.repid = R.Repid
		JOIN dbo.Un_Convention Cv ON U1.conventionid = Cv.conventionid
        JOIN Un_UnitReduction UR ON a.unitreductionid = UR.unitreductionid 
        JOIN dbo.Un_Unit Uori ON UR.unitid = Uori.unitid AND Uori.repID = U1.repid -- doit être le même Rep
		JOIN dbo.Un_Convention CvOri ON Uori.conventionid = CvOri.conventionid 
						AND CvOri.SubscriberID = Cv.SubscriberID -- doit être le même Souscripteur 	--and CvOri.BeneficiaryID = Cv.BeneficiaryID -- On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert 2009-04-15
		LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
		JOIN Un_Modal M ON M.ModalID = Uori.ModalID	
		WHERE U1.dtFirstDeposit >= @StartDate
            AND U1.dtFirstDeposit <= @EndDate
            AND  UR.FeeSumByUnit < M.FeeByUnit
			AND ISNULL(URR.bReduitTauxConservationRep, 1) = 1 -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
		GROUP BY
			U1.UnitID,
			u1.dtFirstDeposit
		
 	CREATE TABLE #tNewSales (
		UnitID INTEGER,
		RepID INTEGER,
		UnitQty FLOAT,
		DateUnite DATETIME)

	--Unites brutes REP
	INSERT INTO #tNewSales
	SELECT 
		U.UnitID,
		U.RepID,
		UnitQty = SUM(	CASE
							WHEN TU.NbUnitesAjoutees > 0 THEN
								TU.NbUnitesAjoutees
							ELSE 
						--		qté actuel+	Qté réduite = qté vendue,	- qté vendue qui est de la rétention
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END), -- Unites brutes
		DateUnite = U.dtFirstDeposit
	FROM dbo.Un_Unit U 
	LEFT JOIN #tTransferedUnits TU ON (TU.UnitID = U.UnitID)
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID
	LEFT JOIN #UniteConvT UT ON U.UnitID = UT.UnitID
	WHERE U.dtFirstDeposit >= @StartDate
        AND U.dtFirstDeposit <= @EndDate
        AND UT.UnitID IS NULL -- exclure les unité conv T. On va les chercher dans le insert suivant
	GROUP BY 
		U.UnitID,
		U.RepID,
		U.dtFirstDeposit
		
	--Unites brutes Convention T
	INSERT INTO #tNewSales
	SELECT 
		U.UnitID,
		UT.RepID,
		UnitQty = SUM(
					CASE
						WHEN UT.dtFirstDeposit >= @StartDate THEN
							CASE
								WHEN TU.NbUnitesAjoutees > 0 THEN
									TU.NbUnitesAjoutees
								ELSE 
							--		qté actuel+	Qté réduite = qté vendue,	- qté vendue qui est de la rétention
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
							END
					ELSE 0
					END), -- Unites brutes
		DateUnite = UT.dtFirstDeposit
	FROM dbo.Un_Unit U
	JOIN #UniteConvT UT ON U.UnitID = UT.UnitID 
	LEFT JOIN #tTransferedUnits TU ON (TU.UnitID = U.UnitID)
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID
	WHERE UT.dtFirstDeposit >= @StartDate 
        AND UT.dtFirstDeposit <= @EndDate
	GROUP BY 
		U.UnitID,
		UT.RepID,
		UT.dtFirstDeposit

    DELETE FROM #tNewSales WHERE UnitQty = 0 

	CREATE TABLE #Un_UnitReductionTMP (
		UnitReductionID INT,
		UnitID INT,
		ReductionConnectID INT,
		ReductionDate DATETIME,
		UnitQty MONEY,
		FeeSumByUnit MONEY,
		SubscInsurSumByUnit MONEY,
		UnitReductionReasonID INT,
		NoChequeReasonID MONEY )


	INSERT INTO #Un_UnitReductionTMP
	SELECT
		UnitReductionID,
		UR.UnitID,
		ReductionConnectID,
		ReductionDate,
		UnitQty,
		FeeSumByUnit,-- = CASE WHEN DEPOT.UnitID IS NULL THEN 0 ELSE FeeSumByUnit END ,
		SubscInsurSumByUnit,
		UnitReductionReasonID,
		NoChequeReasonID
	FROM Un_UnitReduction UR	
	LEFT JOIN (
		SELECT DISTINCT CT.UnitID
		FROM Un_Unit U
		-- ON FILTRE SUR CECI AFIN DE GAGNER DE LA VITESSE
		JOIN (SELECT DISTINCT UnitID FROM Un_UnitReduction WHERE ReductionDate >= @StartDate AND ReductionDate <= @EndDate )R ON R.UnitID = U.UnitID
		JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = CT.OperID
		WHERE CharIndex(O.OperTypeID, 'PRD,CPA,NSF,RDI,CHQ,COU', 1) > 0
		)DEPOT ON DEPOT.UnitID = UR.UnitID
	WHERE UR.ReductionDate >= @StartDate
        AND UR.ReductionDate <= @EndDate		

 	CREATE TABLE #tTerminated (
		UnitID INTEGER,
		RepID INTEGER,
		UnitQtyReductFraisCouvert FLOAT,
        UnitQtyReductPart FLOAT, 
		UnitQtyRes FLOAT,
		UnitQtyRes_NON_ReduitTaux FLOAT,
		DateUnite DATETIME)

	-- Retraits frais non couverts REP pendant la période
	INSERT INTO #tTerminated
	SELECT 
		U.UnitID,
		U.RepID,

        UnitQtyReductFraisCouvert = /*correspond à TerminatedUnitQty dans "Nouvelles ventes validées" */
			SUM(
				CASE 
					WHEN ISNULL(U.TerminatedDate,0) = UR.ReductionDate AND ISNULL(URR.bReduitTauxConservationRep, 1) = 1 AND M.FeeByUnit <= UR.FeeSumByUnit THEN 
                    		UR.UnitQty
					ELSE 0
				END), 


        UnitQtyReductPart = -- ce sont les Réduction dans nouvelle vente validée
			SUM(
				CASE 
					WHEN ISNULL(U.TerminatedDate,0) <> UR.ReductionDate AND ISNULL(URR.bReduitTauxConservationRep, 1) = 1 AND UR.FeeSumByUnit < M.FeeByUnit /*ceci n'est pas validé dans "Nouvelles ventes validées" */ THEN 
                    		UR.UnitQty * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END
					ELSE 0
				END), 
		UnitQtyRes = 
			SUM(
				CASE 
                    WHEN ISNULL(U.TerminatedDate,0) = UR.ReductionDate AND ISNULL(URR.bReduitTauxConservationRep, 1) = 1 AND UR.FeeSumByUnit < M.FeeByUnit THEN 
					       	UR.UnitQty * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END
					ELSE 0
				END), 
		UnitQtyRes_NON_ReduitTaux = 
			SUM(
				CASE 
					WHEN ISNULL(URR.bReduitTauxConservationRep, 1) = 0 
						AND NOT (UR.UnitReductionReasonID = 29 AND M.FeeByUnit = UR.FeeSumByUnit)  -- EXCLURE LES TIO FRAIS COUVERT
							THEN UR.UnitQty -- /*pas de ratio puisque ne sert pas pour le taux */  * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END
					ELSE 0
				END), 
		DateUnite = ur.ReductionDate
	FROM #Un_UnitReductionTMP UR 
	JOIN dbo.Un_Unit U  ON U.UnitID = UR.UnitID
	JOIN Un_Modal M  ON M.ModalID = U.ModalID	
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	LEFT JOIN #UniteConvT UT ON U.UnitID = UT.UnitID
	WHERE UR.ReductionDate >= @StartDate
        AND UR.ReductionDate <= @EndDate
		AND U.dtFirstDeposit IS NOT NULL -- jira prod-7129 : IL DOIT Y AVOIR EU UN 1ER DÉPÔT
		AND UT.UnitID IS NULL -- exclure les unité convv T. On va les chercher dans le insert suivant
	GROUP BY 
		U.UnitID,
		U.RepID,
		UR.ReductionDate,
		UR.ReductionDate
		
	--SELECT * FROM #tTerminated WHERE UnitID = 764376

 	-- Supprimer les enregistrements dont les qté sont 0
	DELETE FROM #tTerminated WHERE UnitQtyReductPart = 0 AND UnitQtyRes = 0 AND UnitQtyRes_NON_ReduitTaux = 0 and UnitQtyReductPart = 0 and UnitQtyReductFraisCouvert = 0

 	-- Réutilisation de frais disponibles 
	CREATE TABLE #tReused (
		UnitID INTEGER,
		RepID INTEGER,
		UnitQtyReused FLOAT,
		DateUnite DATETIME)

	INSERT INTO #tReused
	SELECT 
		TU.UnitID, -- Le nouveau UnitID pour séparation de la qty originale en plusieur gr d'unité et donc planID
		U.RepID,
		UnitQtyReused = SUM(fUnitQtyUse), 
		DateUnite = U.dtFirstDeposit
	FROM #tReinscriptions TU 
    JOIN dbo.Un_Unit U ON U.UnitID = TU.UnitID
	WHERE U.dtFirstDeposit >= @StartDate
        AND U.dtFirstDeposit <= @EndDate
	GROUP BY  
		TU.unitid,
		U.RepID,
		U.dtFirstDeposit
		
	--SELECT * FROM #tReused WHERE UNITID = 760825

 	DELETE FROM #tReused WHERE UnitQtyReused = 0 

	CREATE TABLE #GrossANDNetUnitsByUnit  (
		UnitID INTEGER,
		BossID INTEGER,
		RepID INTEGER,
		Brut FLOAT,
		RetraitCompletFraisCouvert FLOAT,
        Retraits_Partiel FLOAT,
		Retraits FLOAT,
		Retraits_NON_ReduitTaux FLOAT,
		Reinscriptions FLOAT,
		TFR FLOAT,
		DateUnite DATETIME
		)


	PRINT '4 - ' + LEFT(CONVERT(VARCHAR, getdate(), 120), 30)

 	INSERT INTO #GrossANDNetUnitsByUnit
	SELECT
	    V.UnitID,
		MPB.BossID,
		V.RepID,
        Brut = SUM(Brut),
		RetraitCompletFraisCouvert = SUM(RetraitCompletFraisCouvert),
        Retraits_Partiel = SUM(Retraits_Partiel),
		Retraits = SUM(Retraits),
		Retraits_NON_ReduitTaux = SUM(Retraits_NON_ReduitTaux),
 		Reinscriptions = SUM(Reinscriptions),
		TFR = SUM(TFR),
		DateUnite
	FROM ( 
		SELECT
			NS.UnitID,
			NS.RepID,
		    Brut = NS.UnitQty,
			RetraitCompletFraisCouvert = 0,
            Retraits_Partiel = 0,
			Retraits = 0,
			Retraits_NON_ReduitTaux = 0,
 			Reinscriptions = 0,
			TFR = 0,
			DateUnite
		FROM #tNewSales NS
		---------
		UNION ALL
		---------
		SELECT 
			T.UnitID,
			T.RepID,
			Brut = 0,
			RetraitCompletFraisCouvert = T.UnitQtyReductFraisCouvert,
            Retraits_Partiel = T.UnitQtyReductPart,
			Retraits = T.UnitQtyRes,
			Retraits_NON_ReduitTaux = T.UnitQtyRes_NON_ReduitTaux,
			Reinscriptions = 0,
			TFR = 0,
			DateUnite
		FROM #tTerminated T 
		---------
		UNION ALL
		---------
		SELECT 
			R.UnitID,
			R.RepID,
			Brut = 0,
			RetraitCompletFraisCouvert = 0,
            Retraits_Partiel = 0,
			Retraits = 0,
			Retraits_NON_ReduitTaux = 0,
			Reinscriptions = R.UnitQtyReused,
			TFR = 0,
			DateUnite
		FROM #tReused R 


	-- ceci est une erreur. doit être retiré
		-----------
		UNION ALL
		-----------
		SELECT 
			TU.UnitID,
			TU.RepID,
			Brut = 0,
			RetraitCompletFraisCouvert = 0,
            Retraits_Partiel = 0,
			Retraits = 0,
			Retraits_NON_ReduitTaux = 0,
			Reinscriptions = 0,
			TFR = TU.fUnitQtyUse,
			DateUnite
		FROM #tTransferedUnits TU 
		WHERE TU.DateUnite BETWEEN @StartDate AND @EndDate

		-----------
		UNION ALL
		-----------
		SELECT 
			TB.UnitID,
			TB.RepID,
			Brut = 0,
			RetraitCompletFraisCouvert = 0,
            Retraits_Partiel = 0,
			Retraits = 0,
			Retraits_NON_ReduitTaux = 0,
			Reinscriptions = 0,
			TFR = TB.fUnitQtyUse,
			DateUnite
		FROM #tTFRInclutDansBRUT TB 
		WHERE TB.DateUnite BETWEEN @StartDate AND @EndDate
    ) V
	LEFT JOIN #tMaxPctBoss MPB ON MPB.UnitID = V.UnitID
	--GLPI 7399 : On exclu les unité provenant d'un RIO. Elles sont associé au rep "Siège social".
    LEFT JOIN tblOPER_OperationsRIO rio ON rio.iID_Unite_Destination = V.UnitID and rio.bRIO_QuiAnnule = 0 and rio.bRIO_Annulee = 0
    -- Exclure les unités de convention de catégorie R17
    LEFT JOIN dbo.Un_Unit U ON V.UnitId = U.UnitID
    LEFT JOIN dbo.tblCONV_ConventionConventionCategorie CCC ON ccC.ConventionId = U.ConventionID
    LEFT JOIN dbo.tblCONV_ConventionCategorie CC ON CCC.ConventionCategorieId = CC.ConventionCategoreId AND CC.CategorieCode = 'R17'
    LEFT JOIN #UniteConvT UT ON v.UnitID = UT.UnitID
    WHERE rio.iID_Unite_Destination IS NULL
		AND (
			CC.ConventionCategoreId IS NULL
			    OR UT.UnitID IS NOT NULL
			)
    ----------------------------------
	GROUP BY 
		V.UnitID,
		V.RepID,
		MPB.BossID,
		V.DateUnite
	ORDER BY 
		V.RepID
	
    -- Faire un Merge des Rep Corpo vers le Rep Original
	UPDATE G
	SET G.repid = LR.RepID
	FROM #GrossANDNetUnitsByUnit G
	JOIN tblREPR_Lien_Rep_RepCorpo LR ON LR.repid_Corpo = G.repid

	PRINT '5 - ' + LEFT(CONVERT(VARCHAR, getdate(), 120), 30)


	SELECT  
		c.ConventionNo,
		
		Regime =	CASE 
					WHEN RR.vcCode_Regroupement = 'IND' AND ISNULL(UT.vcTypeConv, '') = 'TFRS' THEN RR.vcDescription + '-T'-- + ISNULL(UT.vcTypeConv, '')
					WHEN RR.vcCode_Regroupement = 'IND' AND ISNULL(UT.vcTypeConv, '') = 'IBEC' THEN RR.vcDescription + '-' + ISNULL(UT.vcTypeConv, '')
					ELSE RR.vcDescription
					END,
		DateNaissanceBenef = cast( HB.BirthDate as date),
		C.SubscriberID,
		BeneficiaryID = HB.HumanID,
		NomSouscripteur = HS.FirstName + ' ' + HS.LastName,
		NouveauClient = CASE 
							WHEN NouvClient.MIN_dtFirstDeposit IS NOT NULL /*AND SUM(G.Brut) > 0*/ THEN 'Oui' 
							--WHEN NouvClient.MIN_dtFirstDeposit IS NULL AND SUM(G.Brut) > 0 THEN 'Non' 
							ELSE 'Non' 
						END,
		DateDebutOperFin = CAST( U.InForceDate AS DATE),
		Date1erDepot = CAST(ISNULL(U.dtFirstDeposit,UT.dtFirstDeposit) AS DATE),
        NbUniteActuel = u.UnitQty + ISNULL(UR.UnitQtyRESAfter,0),
		UniteAssure = CASE WHEN u.WantSubscriberInsurance = 1 AND M.SubscriberInsuranceRate > 0 THEN U.UnitQty + ISNULL(UR.UnitQtyRESAfter,0) ELSE 0 END,
		FraisCumululatif = ISNULL(FraisCumul,0),
		NiveauRep1erDepot = isnull(NiveauRep.LevelDesc,''), -- rlRep.LevelDesc,

		Brut = SUM(G.Brut),
		Reinscriptions = SUM(G.Reinscriptions),
		Retraits_Partiel = SUM(Retraits_Partiel),
		Retraits = SUM(G.Retraits),
		Net = SUM(G.Brut) +  SUM(G.Reinscriptions) - SUM(Retraits_Partiel) - SUM(G.Retraits),

		TFR = SUM(TFR),
		Retraits_NON_ReduitTaux = SUM(Retraits_NON_ReduitTaux),
		

		G.UnitID,
		RepID = ISNULL(UT.RepID, G.RepID),
		BossID = ISNULL(UT.BossID, MP.BossID),
        C.PlanID,
		
		RetraitCompletFraisCouvert = SUM(RetraitCompletFraisCouvert),
		
		HIST_BENEF.iID_Nouveau_Beneficiaire,
		
		HS.AdrID

		,RepID_COM = case when  @Type_Param= 'REP' then @RepID else  G.RepID end -- si on demande pour un rep ou directeur on inscrit son id, si c'Est pour une agence ou tous, on inscrit le rep id de la vente

		,RepRoleDesc = ISNULL(RepRoleDesc_DIR_Unit.vcDefaultRepRoleDesc, @vcDefaultRepRoleDesc)

	into #tblVente
	FROM #GrossANDNetUnitsByUnit G
    JOIN Un_Unit U ON U.UnitID = G.UnitID
	join Un_Modal m on m.ModalID = u.ModalID
    JOIN Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN Un_Plan P ON P.PlanID = c.PlanID
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
    LEFT JOIN #UniteConvT UT ON UT.UnitID = U.UnitID

	LEFT JOIN (
		SELECT UnitID, UnitQtyRESAfter = SUM(UnitQty)
		FROM Un_UnitReduction
		WHERE ReductionDate > @EndDate
		GROUP BY UnitID
		)UR ON UR.UnitID = G.UnitID

	LEFT JOIN (
		SELECT U.UnitID, LevelDesc = MAX(rlRep.LevelDesc)
		FROM #GrossANDNetUnitsByUnit G
		JOIN Un_Unit U ON U.UnitID = G.UnitID
		JOIN Un_Replevelhist lhRep on u.repid = lhRep.repid AND U.InForceDate BETWEEN lhRep.startdate AND ISNULL(lhRep.enddate,'3000-01-01')
		JOIN Un_Replevel rlRep on rlRep.RepLevelID = lhRep.RepLevelID AND rlRep.RepRoleID = 'REP'
		GROUP BY U.UnitID
		)NiveauRep on NiveauRep.UnitID = G.UnitID

	LEFT JOIN #tMaxPctBoss MP ON MP.UnitID = G.UnitID
	LEFT JOIN (
		SELECT C.SubscriberID,MIN_dtFirstDeposit = MIN(U.dtFirstDeposit)
		FROM Un_Unit U 
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		GROUP BY C.SubscriberID
			)NouvClient ON NouvClient.SubscriberID = c.SubscriberID AND NouvClient.MIN_dtFirstDeposit = u.dtFirstDeposit
	LEFT JOIN (
		SELECT 
			u.UnitID
			,FraisCumul = SUM(ct.Fee)
		FROM Un_Unit U 
		JOIN Un_Cotisation ct on ct.UnitID = u.UnitID
		JOIN Un_Oper o on o.OperID = ct.OperID
		WHERE o.OperDate <= @EndDate
		GROUP BY u.UnitID
			)FraisCumul ON FraisCumul.UnitID = u.UnitID

	LEFT JOIN (
			select cbAvant.iID_Convention, cbAvant.iID_Nouveau_Beneficiaire, DateDu = cbAvant.dtDate_Changement_Beneficiaire, DateAu = isnull(CBapres.dtDate_Changement_Beneficiaire,'9999-12-31')
			from (
				select cb.iID_Convention, cb.iID_Changement_Beneficiaire, MIN_iID_Changement_Beneficiaire = min(CB2.iID_Changement_Beneficiaire)
				from tblCONV_ChangementsBeneficiaire CB
					JOIN Un_Unit U ON U.ConventionID = CB.iID_Convention
					JOIN #GrossANDNetUnitsByUnit G1 ON G1.UnitID = U.UnitID
					left join tblCONV_ChangementsBeneficiaire CB2 on cb.iID_Convention = CB2.iID_Convention and CB2.iID_Changement_Beneficiaire > cb.iID_Changement_Beneficiaire
				GROUP by cb.iID_Convention, cb.iID_Changement_Beneficiaire
				)t
			JOIN tblCONV_ChangementsBeneficiaire cbAvant on t.iID_Changement_Beneficiaire = cbAvant.iID_Changement_Beneficiaire
			LEFT JOIN tblCONV_ChangementsBeneficiaire CBapres on t.MIN_iID_Changement_Beneficiaire = CBapres.iID_Changement_Beneficiaire
			--order by cbAvant.iID_Convention
		)HIST_BENEF ON HIST_BENEF.iID_Convention = C.ConventionID AND @EndDate BETWEEN HIST_BENEF.DateDu AND HIST_BENEF.DateAu
	LEFT JOIN Mo_Human HB ON HB.HumanID = HIST_BENEF.iID_Nouveau_Beneficiaire

	-- Retrouver s'il y a des COM sur un de ces 2 rôles pour ce groupe D'unité. Si oui, alors on va mettre les unité brutes et nettes sous un de ces rôles. 
	-- Normalement, seulement un de ces 2 rôles va sortir
	LEFT JOIN (
		SELECT UnitID ,vcDefaultRepRoleDesc = MAX(RepRoleDesc)
		FROM #tCOM
		WHERE RepRoleDesc IN ('Directeur d''agence plus de 36 mois','Directeur d''agence moins de 36 mois')	
		GROUP BY UnitID
			) RepRoleDesc_DIR_Unit on RepRoleDesc_DIR_Unit.UnitID = U.UnitID AND @EstDirecteur = 1

    WHERE 
			@RepID = 0
            OR 
				(
					 ISNULL(UT.RepID, G.RepID)		IN (SELECT RepID FROM #ListeRep) 
					 OR
					 ISNULL(UT.BossID, MP.BossID)	IN (SELECT RepID FROM #ListeRep)  

				)
			
	GROUP BY 
		C.ConventionNo,
		G.UnitID,
        U.dtFirstDeposit,
		UT.dtFirstDeposit,
        U.InForceDate,
        C.PlanID,
		NiveauRep.LevelDesc,
        UT.vcTypeConv,
		G.RepID,
		UT.RepID,
		UT.BossID,
		MP.BossID,
		RR.vcCode_Regroupement,
		RR.vcDescription,
		u.UnitQty,
		UR.UnitQtyRESAfter,
		u.WantSubscriberInsurance,M.SubscriberInsuranceRate,
		NouvClient.MIN_dtFirstDeposit
		,FraisCumul
		,HIST_BENEF.iID_Nouveau_Beneficiaire
		,HB.BirthDate
		,HS.FirstName + ' ' + HS.LastName
		,C.SubscriberID
		,HB.HumanID
		,HS.AdrID
		,RepRoleDesc_DIR_Unit.vcDefaultRepRoleDesc

		PRINT '6 - ' + LEFT(CONVERT(VARCHAR, getdate(), 120), 30)

	SELECT
		EstDirecteur = @EstDirecteur,
        R.RepCode,
		Representant = HR.FirstName + ' ' + HR.LastName,
		ConventionNo,
		V.UnitID,
		Regime,
		DateNaissanceBenef,
		SubscriberID,
		BeneficiaryID,
		NomSouscripteur,
		NouveauClient,
		TelSousc,
		CodePostalSousc,
		DateDebutOperFin,
		Date1erDepot,
		NbUniteActuel,
		UniteAssure,
		FraisCumululatif,
		NiveauRep1erDepot,

		Brut = SUM(Brut),
		Reinscriptions = SUM(Reinscriptions ),
		Retraits_Partiel = SUM(Retraits_Partiel ),
		Retraits = SUM(Retraits ),
		Net = SUM(Net ),
		TFR = SUM(TFR) - SUM(Reinscriptions ) ,
		Retraits_NON_ReduitTaux = SUM(Retraits_NON_ReduitTaux ),

		RepID_COM,
		RepCOM = hc.FirstName + ' ' + hc.LastName,
		RepRoleDesc = ISNULL(RepRoleDesc,'N/A'), --2017-09-14
		PeriodAdvance = SUM(PeriodAdvance ),
		CoverdAdvance = SUM(CoverdAdvance ),
		PeriodAdvanceResiliation = SUM(PeriodAdvanceResiliation ),
		CumAdvance = SUM(CumAdvance ),
		ServiceComm = SUM(ServiceComm ),
		PeriodComm = SUM(PeriodComm ),
		PeriodCommResiliation = SUM(PeriodCommResiliation ),
		FuturComm = SUM(FuturComm ),
		BusinessBonus = SUM(BusinessBonus ),
		PeriodBusinessBonus = SUM(PeriodBusinessBonus ),
		FuturBusinessBonus = SUM(FuturBusinessBonus ),
		mEpargne_SoldeDebutActif = SUM(mEpargne_SoldeDebutActif ),
		mEpargne_PeriodeActif = SUM(mEpargne_PeriodeActif ),
		mEpargne_SoldeFinActif = SUM(mEpargne_SoldeFinActif ),
		mEpargne_CalculActif = SUM(mEpargne_CalculActif ),
		dTaux_CalculActif = SUM(dTaux_CalculActif ),
		mMontant_ComActif = SUM(mMontant_ComActif ), 
		mEpargne_SoldeDebutSuivi = SUM(mEpargne_SoldeDebutSuivi ),
		mEpargne_PeriodeSuivi = SUM(mEpargne_PeriodeSuivi ),
		mEpargne_SoldeFinSuivi = SUM(mEpargne_SoldeFinSuivi ),
		mEpargne_CalculSuivi = SUM(mEpargne_CalculSuivi ),
		dTaux_CalculSuivi = SUM(dTaux_CalculSuivi ),
		mMontant_ComSuivi  = SUM(mMontant_ComSuivi ),
		BusinessBonusToPay = cast(m.BusinessBonusToPay as INT),
		mMontant_ComBEC_Verse = SUM(mMontant_ComBEC_Verse),
		mMontant_ComBEC_Repris = SUM(mMontant_ComBEC_Repris)


	FROM (

		SELECT 
			--Partie = 1,
			ConventionNo,
			RepID,
			BossID,
			UnitID,
			Regime,
			DateNaissanceBenef,
			SubscriberID,
			BeneficiaryID,
			NomSouscripteur,
			NouveauClient,
			TelSousc = dbo.fn_Mo_FormatPhoneNo( ISNULL(ADR.Phone1,ISNULL(ADR.Mobile,ADR.Phone2)),adr.CountryID),
			CodePostalSousc = dbo.fn_Mo_FormatZIP( adr.ZipCode,adr.CountryID),
			DateDebutOperFin,
			Date1erDepot,
			NbUniteActuel,
			UniteAssure,
			FraisCumululatif,
			NiveauRep1erDepot,

			

			--------------------------

			Brut,
			Reinscriptions,
			Retraits_Partiel,
			Retraits,
			Net,
			TFR,
			Retraits_NON_ReduitTaux,

			---------
			RepID_COM,
			RepRoleDesc,
			PeriodAdvance = 0,
			CoverdAdvance = 0,
			PeriodAdvanceResiliation = 0,
			CumAdvance = 0,
			ServiceComm = 0,
			PeriodComm = 0,
			PeriodCommResiliation = 0,
			FuturComm = 0,
			BusinessBonus = 0,
			PeriodBusinessBonus = 0,
			FuturBusinessBonus = 0,
			mEpargne_SoldeDebutActif = 0,
			mEpargne_PeriodeActif = 0,
			mEpargne_SoldeFinActif = 0,
			mEpargne_CalculActif = 0,
			dTaux_CalculActif = 0,
			mMontant_ComActif = 0, 
			mEpargne_SoldeDebutSuivi = 0,
			mEpargne_PeriodeSuivi = 0,
			mEpargne_SoldeFinSuivi = 0,
			mEpargne_CalculSuivi = 0,
			dTaux_CalculSuivi = 0,
			mMontant_ComSuivi = 0,
			mMontant_ComBEC_Verse = 0,
			mMontant_ComBEC_Repris = 0

		FROM 
			#tblVente T
			LEFT JOIN Mo_Adr ADR ON ADR.AdrID = T.AdrID
		where 
			Brut <> 0
			OR Reinscriptions <> 0
			OR Retraits_Partiel <> 0
			OR Retraits <> 0
			OR Net <> 0
			OR TFR <> 0
			OR Retraits_NON_ReduitTaux <> 0


		UNION ALL


		SELECT 
			--Partie = 2,
			ConventionNo,
			RepID,
			BossID,
			UnitID,
			Regime,
			DateNaissanceBenef,
			SubscriberID,
			BeneficiaryID,
			NomSouscripteur,
			NouveauClient,
			TelSousc,
			CodePostalSousc,
			DateDebutOperFin,
			Date1erDepot,
			NbUniteActuel,
			UniteAssure,
			FraisCumululatif,
			NiveauRep1erDepot,

			Brut,
			Reinscriptions,
			Retraits_Partiel,
			Retraits,
			Net,
			TFR,
			Retraits_NON_ReduitTaux,

			RepID_COM,
			RepRoleDesc,
			PeriodAdvance,
			CoverdAdvance,
			PeriodAdvanceResiliation,
			CumAdvance,
			ServiceComm,
			PeriodComm,
			PeriodCommResiliation,
			FuturComm,
			BusinessBonus,
			PeriodBusinessBonus,
			FuturBusinessBonus,
			mEpargne_SoldeDebutActif,
			mEpargne_PeriodeActif,
			mEpargne_SoldeFinActif,
			mEpargne_CalculActif,
			dTaux_CalculActif,
			mMontant_ComActif, 
			mEpargne_SoldeDebutSuivi,
			mEpargne_PeriodeSuivi,
			mEpargne_SoldeFinSuivi,
			mEpargne_CalculSuivi,
			dTaux_CalculSuivi,
			mMontant_ComSuivi,
			mMontant_ComBEC_Verse,
			mMontant_ComBEC_Repris
		FROM #tCOM	

		)V
	JOIN Un_Unit u on u.UnitID = v.UnitID
	LEFT JOIN Un_Rep R on R.RepID = v.RepID
	LEFT JOIN Mo_Human HR ON HR.HumanID = v.RepID
	LEFT JOIN Un_Modal m on m.ModalID = u.ModalID

	LEFT JOIN Mo_Human HC ON HC.HumanID = V.RepID_COM

	--where v.UnitID = 767244
	--where v.ConventionNo in ( 'U-20070516014','R-20040304010','R-20041208015')

	GROUP BY
		ConventionNo,
		v.UnitID,
		Regime,
		DateNaissanceBenef,
		SubscriberID,
		BeneficiaryID,
		NomSouscripteur,
		NouveauClient,
		TelSousc,
		CodePostalSousc,
		DateDebutOperFin,
		Date1erDepot,
		NbUniteActuel,
		UniteAssure,
		FraisCumululatif,
		NiveauRep1erDepot
		,RepRoleDesc
		,m.BusinessBonusToPay
		,R.RepCode
		,HR.FirstName
		,HR.LastName

		,RepID_COM,
		hc.FirstName,
		hc.LastName



	ORDER BY
		Date1erDepot DESC, V.SubscriberID , V.ConventionNo

	--	set ARITHABORT OFF
  
END
-- À faire:
-- Ajouter la colonne Rôle dans le dataset et dédoubler les unités
-- Renommer les colonnes PeriodAdvanceResiliation et PeriodCommResiliation
-- Ajouter le paramètre pour le cumulatif annuel afin de ne pas dédoubler les unités et calculer les commissisons avec les vue pour arrondir les montants
-- Si le rapport est demandé pour une agence ou pour Tous, on ne doit pas retourner de données pour le détaillé.
-- Voir ce que l'on fais avec les unités assurées.

-- Les réductions sur le rapport des nouvelles ventes validées sont uniquement celles affectant le taux. C'est ce que l'on veut ou on devrait toutes les afficher dans cette colonne?
-- Voulons-nous affecter le taux de conservation avec les changements apportés à l'affichage des résiliations?
-- VALIDER LA PLAGE DE DATE DU 24 MOIS. VS +/- UN JOUR
-- Que fait on avec les résiliation selon le ratio de frais couvert ? On les affiche comment ?
-- #tTransferedUnits : Les transfert de frais Incompatible avec Nouvelle vente validée (FeeTransferUnitQty : transfert de frais) ex : R-20090512038 (0.835 unité) : est un brut ici (car subscriberID différent) mais un TFR dans nouvelle vente validé
-- Remettre les Boss puisque différent pour les conventions T (Souscripteur)
-- Filtrer la requête pour la table tMaxPctBoss selon les groupes d'unités du rapport
-- Ajout du Boss ID à partir de la table #tMaxPctBoss 


--exec RP_UN_RepNewValidatedSales 1,'REP', '2016-01-01' , '2017-08-16', 476221

/*
select * INTO Un_Dn_RepTreatment2016EtPlus from Un_Dn_RepTreatment where RepTreatmentDate >= '2016-01-01'

CREATE NONCLUSTERED INDEX [IX_Un_Dn_RepTreatment2016EtPlus_RepID] ON [dbo].[Un_Dn_RepTreatment2016EtPlus]
(
	[RepID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
GO


CREATE NONCLUSTERED INDEX [IX_Un_Dn_RepTreatment2016EtPlus_RepTreatmentID] ON [dbo].[Un_Dn_RepTreatment2016EtPlus]
(
	[RepTreatmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
GO


CREATE NONCLUSTERED INDEX [IX_Un_Dn_RepTreatment2016EtPlus_RepTreatmentID_RepID] ON [dbo].[Un_Dn_RepTreatment2016EtPlus]
(
	[RepTreatmentID] ASC,
	[RepID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
GO
*/