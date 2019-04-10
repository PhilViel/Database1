/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas Inc.
Nom                 :	psREPR_Rapport_DepenseDeCommissionParUnite
Description         :	Tableau des commission sommaire et détaillé par untié et par rep dans une même tableau
Valeurs de retours  :	
Note                :	2018-05-24	Donald Huppé Création
						2018-12-06	Donald Huppé RepName dans Un_Dn_RepTreatment provient de mo_human

-------------------
DECLARE 
	@RepTreatmentIDFrom INTEGER,
	@RepTreatmentIDTo INTEGER,
	@DateTraitementDebut DATE,
	@DateTraitementFin DATE

SELECT @RepTreatmentIDTo = MAX(RepTreatmentID) FROM Un_RepTreatment	
SELECT @DateTraitementFin = RepTreatmentDate  FROM Un_RepTreatment WHERE RepTreatmentID = @RepTreatmentIDTo
SELECT @RepTreatmentIDFrom = MIN(RepTreatmentID) FROM Un_RepTreatment WHERE YEAR(RepTreatmentDate) = YEAR(@DateTraitementFin)

SELECT @RepTreatmentIDTo
SELECT @DateTraitementFin
SELECT @RepTreatmentIDFrom

EXEC psREPR_Rapport_DepenseDeCommissionParUnite  @RepTreatmentIDFrom, @RepTreatmentIDTo, '509-214'


------------------
select	* from tblTEMP_DepenseDeCommissionParUnite

exec psREPR_Rapport_DepenseDeCommissionParUnite  801, 823, '000-100'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_Rapport_DepenseDeCommissionParUnite] (
	@RepTreatmentIDFrom INTEGER,
	@RepTreatmentIDTo INTEGER,
	@Dossier VARCHAR(255) = '000-100' --'509-214'
	
	)
AS
BEGIN

DECLARE 
	@DateDebut DATETIME
	,@DateFin DATETIME
	,@DateTraitementDebut DATE
	,@DateTraitementFin DATE
	,@DateTraitementFinAnneePrec DATETIME
	,@DateFinCT DATE
	,@LastRepTreatmentDate DATE
	,@vcNomFichier VARCHAR(500)
	,@dtDateGeneration DATETIME
	,@DossierFinal varchar(500)
	,@DB_NAME varchar(30)

	SELECT @DB_NAME = DB_NAME()

	SET @DossierFinal = 
			CASE 
			WHEN @Dossier = '000-100' THEN '\\srvapp06\PlanDeClassification\000_PANIER_DE_CLASSEMENT\000-100_TOUS\' 
			WHEN @Dossier = '509-214' THEN '\\srvapp06\PlanDeClassification\5_COMPTABILITE_ET_INFO_FINANCIERES\509_PAIE_ET_DEPENSES_DU_PERS\509-200_PAIEMENT_COMMISSION\509-210_COMMISSION\509-214_CONCILIATION_COMMISSION\2018\'
			ELSE ''
			END

	SET	@dtDateGeneration = GETDATE()

	SET @vcNomFichier = 
				@DossierFinal +

				REPLACE(REPLACE(	REPLACE(LEFT(CONVERT(VARCHAR, @dtDateGeneration, 120), 25),'-',''),' ','_'),':','') + 
				'_DepenseDeCommissionParUnite_' +
				CONVERT(VARCHAR, @RepTreatmentIDFrom) + '_à_' +
				CONVERT(VARCHAR, @RepTreatmentIDTo) + 
				'.CSV'

	--SELECT @vcNomFichier
	--RETURN
	

	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'tblTEMP_DepenseDeCommissionParUnite')
		DROP TABLE tblTEMP_DepenseDeCommissionParUnite


	-----------------------------------------------

	SELECT @LastRepTreatmentDate = MAX(RepTreatmentDate) FROM Un_RepTreatment

	SELECT @DateTraitementDebut = RepTreatmentDate FROM Un_RepTreatment WHERE RepTreatmentID = @RepTreatmentIDFrom 
	SELECT @DateTraitementFin =	RepTreatmentDate FROM Un_RepTreatment WHERE RepTreatmentID = @RepTreatmentIDTo
	SELECT @DateTraitementFinAnneePrec = DATEADD(DAY,-1, DATEADD(yy, DATEDIFF(yy,0,@DateTraitementFin), 0))
	--SELECT DateTraitementFinAnneePrec = @DateTraitementFinAnneePrec

	SELECT @DateDebut = RepTreatmentDate FROM Un_RepTreatment WHERE RepTreatmentID = @RepTreatmentIDFrom - 1
	SELECT @DateFin =	RepTreatmentDate FROM Un_RepTreatment WHERE RepTreatmentID = @RepTreatmentIDTo

	SELECT @DateFinCT = DATEADD(YEAR,1,  DATEADD(DAY,-1 ,  DATEADD(mm, DATEDIFF(mm,0,@DateTraitementFin) + 1, 0) ))



	----------------------- ENREGISTRER LE FuturCOM_CT_LT au 31 déc LORSQUE CE TRAITMEENT EST DISPONIBLE CAR ON VEUT LE GARDER TOUTE L'ANNÉE POUR AFFICHER L'INFO
	IF MONTH(@LastRepTreatmentDate) = 12 AND DAY(@LastRepTreatmentDate) = 31 
		BEGIN

		IF NOT EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'tblREPR_Rapport_DepenseDeCommissionParUnite_FuturCOM_31DecPrec')
			BEGIN
			CREATE TABLE tblREPR_Rapport_DepenseDeCommissionParUnite_FuturCOM_31DecPrec ( -- SELECT * FROM tblREPR_Rapport_DepenseDeCommissionParUnite_FuturCOM_31DecPrec
				RepTreatmentDate DATE
				,UnitID INT
				,RepID INT
				,RepRoleDesc VARCHAR(75)
				,FuturCOM_CT_LT_31DecPrec MONEY )
			END

		IF NOT EXISTS (SELECT 1 FROM tblREPR_Rapport_DepenseDeCommissionParUnite_FuturCOM_31DecPrec WHERE RepTreatmentDate = @LastRepTreatmentDate)
			BEGIN
			INSERT INTO tblREPR_Rapport_DepenseDeCommissionParUnite_FuturCOM_31DecPrec
			SELECT 
				RepTreatmentDate = @LastRepTreatmentDate
				,P.UnitID
				,P.RepID
				,p.RepRoleDesc
				,FuturCOM_CT_LT_31DecPrec = SUM(P.PeriodComm)
			FROM Un_RepProjection P
			GROUP BY	
				P.UnitID
				,P.RepID
				,p.RepRoleDesc		
			END

		-- SUPPRIMER LES DONNÉES PLUS VIEIILE QUE 2 ANS CAR PLUS NÉCESSAIRE
		DELETE FROM tblREPR_Rapport_DepenseDeCommissionParUnite_FuturCOM_31DecPrec WHERE RepTreatmentDate <= DATEADD(YEAR,-2,@DateTraitementFinAnneePrec)

		END



---- futurCOM CT LT ---------------------------------------

	CREATE TABLE #FuturCOM_CT_LT (
		UnitID INT
		,RepID INT
		,RepRoleDesc VARCHAR (255)
		,DateFinCT DATETIME
		,FuturCOM_CT MONEY
		,FuturCOM_LT MONEY
		,FuturCOM_CT_LT MONEY
		)

	INSERT INTO #FuturCOM_CT_LT
	SELECT 
		P.UnitID
		,P.RepID
		,p.RepRoleDesc
		,DateFinCT = @DateFinCT
		,FuturCOM_CT = SUM(CASE WHEN P.RepProjectionDate <= @DateFinCT THEN P.PeriodComm ELSE 0 END)
		,FuturCOM_LT = SUM(CASE WHEN P.RepProjectionDate >  @DateFinCT THEN P.PeriodComm ELSE 0 END)
		,FuturCOM_CT_LT = SUM(P.PeriodComm)
	FROM Un_RepProjection P
	--WHERE 1 = 0
	GROUP BY	
		P.UnitID
		,P.RepID
		,p.RepRoleDesc



--- SOMMAIRE  -------------------------------------------------------------------------


print ' 1 - ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

	SELECT
		S.repTreatmentID,
		S.RepTreatmentDate,
		S.RepID,
		R.RepCode,
		RepName = h.lastname + ' ' + h.firstname, -- On prend le nom du rep dans human car il arrive que des rep change de nom dans Un_Dn_RepTreatmentSumary
		R.businessStart,
		R.businessEnd,
		Avance = SUM(S.NewAdvance),
		ComServBoni = SUM(S.CommAndBonus),
		Futurcom = SUM(S.Futurcom),
		BoniConAju = SUM(S.Adjustment),
		Retenu = SUM(S.Retenu),
		--Net = SUM(S.ChqNet),
		AvACouvrir = SUM(S.Advance), --Advance
		AvResil = SUM(ISNULL(AVR.AVRAmount,0)), -- TerminatedAdvance
		AvSpecial = SUM(ISNULL(SA.Amount,0)) , -- SpecialAdvance
		AvTotal = SUM(ISNULL(S.Advance,0) + ISNULL(SA.Amount,0)  + ISNULL(AVR.AVRAmount,0)) , -- TotalAdvance
		AvCouv = SUM(S.CoveredAdvance), -- CoveredAdvance
		DepCom = SUM(S.CommAndBonus + S.Adjustment + S.CoveredAdvance) -- CommissionFee
		,Commission = ISNULL(BC.Commission,0)
		,Boni = ISNULL(BC.Boni,0)
		,RepcodeINT = cast(R.RepCode as int)

	INTO #tmp_jiraprod9515

	FROM Un_Dn_RepTreatmentSumary S
	JOIN Un_Rep R ON S.RepId = R.RepID 
	JOIN dbo.mo_human h on r.repid = h.humanid
	JOIN (-- Retrouve tous les représentants ayant eu des commissions de chaque traitement de l'année à ce jour 
				SELECT DISTINCT
					ReptreatmentID,
					RepID
				FROM Un_Dn_RepTreatment 
				-----
				UNION
				-----
				-- Retrouve aussi tous les représentants ayant eu des charges de chaque traitement des commissions de l'année à ce jour 
				SELECT DISTINCT
					RepTreatmentID,
					RepID
				FROM Un_RepCharge
			) T 
		ON S.RepTreatmentID = T.RepTreatmentID AND S.RepID = T.RepID
	JOIN Un_RepTreatment RT ON RT.RepTreatmentID = S.RepTreatmentID AND RT.RepTreatmentDate = S.RepTreatmentDate
	LEFT JOIN (-- Retrouve les montants d'avances sur résiliations par représentant 
				SELECT
					rt.RepTreatmentID,
					r.RepID,
					AVRAmount = SUM(ISNULL(RepChargeAmount,0))
				FROM un_reptreatment rt 
					left join Un_RepCharge r on rt.RepTreatmentID  >=  r.RepTreatmentID
				WHERE RepChargeTypeID = 'AVR'
					AND rt.RepTreatmentID between @RepTreatmentIDFrom and @RepTreatmentIDTo
				GROUP BY r.RepID,
					rt.RepTreatmentID
			) AVR ON AVR.RepID = S.RepID and AVR.RepTreatmentID = S.RepTreatmentID
	LEFT JOIN (-- Retrouve les montants d'avance spéciale par représentants 
				SELECT
					rt.RepTreatmentID,
					rs.RepID,
					Amount = SUM(ISNULL(Amount,0))
				FROM un_reptreatment rt 
					left join Un_SpecialAdvance rs on rt.RepTreatmentDate  >=  rs.EffectDate 
				WHERE rt.RepTreatmentID between @RepTreatmentIDFrom and @RepTreatmentIDTo
				GROUP BY rt.RepTreatmentID, rs.RepID
			) SA ON SA.RepID = S.RepID and SA.RepTreatmentID = S.RepTreatmentID
			
	LEFT JOIN (
			SELECT 
				T.RepID,
				T.RepTreatmentID,
				Commission = SUM(T.PeriodComm),
				Boni = SUM(T.PeriodBusinessBonus),
				ComServBoni = SUM(T.PeriodComm + T.PeriodBusinessBonus)
			FROM Un_Dn_RepTreatment T
			JOIN dbo.Mo_Human hr ON T.RepID = hr.HumanID
			WHERE T.RepTreatmentID between @RepTreatmentIDFrom and  @RepTreatmentIDTo
			GROUP BY
				T.RepID,
				T.RepTreatmentID,T.RepCode
			)BC ON BC.RepID = S.RepID AND BC.RepTreatmentID = S.RepTreatmentID		
			
	WHERE RT.RepTreatmentID between @RepTreatmentIDFrom and  @RepTreatmentIDTo
	GROUP BY
		S.repTreatmentID,
		S.RepTreatmentDate,
		S.RepID,
		R.RepCode,
		h.lastname + ' ' + h.firstname,
		R.businessStart,
		R.businessEnd
		,ISNULL(BC.Commission,0)
		,ISNULL(BC.Boni,0)
		,cast(R.RepCode as int)
	ORDER BY
		R.RepCode,
		S.RepTreatmentDate


print ' 2 - ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

	SELECT
		RepID,
		RepcodeINT,
		RepCode,
		RepName,
		businessStart,
		businessEnd,
		BoniConAju =	SUM(BoniConAju),
		Retenu =		SUM(Retenu),
	--	Net =			SUM(Net),
		AvResil =		SUM(CASE WHEN  repTreatmentID = @RepTreatmentIDTo THEN AvResil ELSE 0 END ),
		AvSpecial =		SUM(CASE WHEN  repTreatmentID = @RepTreatmentIDTo THEN AvSpecial ELSE 0 END ),
		AvTotal =		SUM(CASE WHEN  repTreatmentID = @RepTreatmentIDTo THEN AvTotal ELSE 0 END )
	INTO #tmpSommaire
	FROM #tmp_jiraprod9515
	GROUP BY

		RepID,
		RepcodeINT,
		RepCode,
		RepName,
		businessStart,
		businessEnd

print ' 3 - ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)


--- DETAIL  -------------------------------------------------------------------------


	create table #GrossANDNetUnits (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT) 

	-- Les données des Rep
	INSERT #GrossANDNetUnits -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits --@ReptreatmentID, NULL, NULL, @RepID, 0
		@ReptreatmentID = NULL,--@ReptreatmentID, -- ID du traitement de commissions
		@StartDate = @DateDebut, -- Date de début
		@EndDate = @DateFin, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 

	SELECT 
		GNU.UnitID
		,Net = SUM( (Brut) - ( (Retraits) - (Reinscriptions) ) )
	INTO #tUniteNette -- drop table #tUniteNette
	from #GrossANDNetUnits gnu
	JOIN Un_Unit U ON U.UnitID = GNU.UnitID
	JOIN Un_Convention C ON C.ConventionID = U.ConventionID
	GROUP BY GNU.UnitID

print ' 4 - ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

	SELECT  
		DN.UnitID,
		DN.RepID, 
		RepName = h.lastname + ' ' + h.firstname, -- On prend le nom du rep dans human car il arrive que des rep change de nom dans Un_Dn_RepTreatment
		--RepName = CAST(REPLACE(DN.RepName,',','') AS VARCHAR(100)),
		DN.RepRoleDesc,
		DN.LevelShortDesc, 
		DN.RepCode,
				
		TotalFee =		MAX(CASE WHEN DN.RepTreatmentID = @RepTreatmentIDTo THEN DN.TotalFee		ELSE 0 END),
		QteUniteFin =	MAX(CASE WHEN DN.RepTreatmentID = @RepTreatmentIDTo THEN DN.UnitQty		ELSE 0 END),
		AvACouvrir =	MAX(CASE WHEN DN.RepTreatmentID = @RepTreatmentIDTo THEN DN.CumAdvance	ELSE 0 END),
				
		Avances =		SUM( DN.PeriodAdvance),
		AvCouv =		SUM( DN.CoverdAdvance),
		BoniConAju =	SUM( DN.SweepstakeBonusAjust),
		Commission =	SUM( DN.PeriodComm),
		Boni =			SUM( DN.PeriodBusinessBonus),

		FuturCom =		MAX(CASE WHEN DN.RepTreatmentID = @RepTreatmentIDTo THEN DN.FuturComm		ELSE 0 END),

		RepriseCOMsurNSF =		SUM(CASE WHEN LTRIM(RTRIM(DN.Notes)) = 'NSF' THEN DN.PeriodComm ELSE 0 END),
		RepriseAVANCEsurNSF =	SUM(CASE WHEN LTRIM(RTRIM(DN.Notes)) = 'NSF' THEN DN.PeriodAdvance ELSE 0 END),

		NoteTFR = MAX(CASE WHEN LTRIM(RTRIM(DN.Notes)) = 'TFR' THEN 'TFR' ELSE '' END)
	into #Un_Dn_RepTreatment
	FROM Un_Dn_RepTreatment DN
	JOIN Mo_Human h on h.humanid = DN.RepID
	WHERE RepTreatmentID BETWEEN @RepTreatmentIDFrom AND @RepTreatmentIDTo
	GROUP BY
		DN.UnitID,
		DN.RepID, 
		h.lastname + ' ' + h.firstname,
		DN.RepRoleDesc,
		DN.LevelShortDesc, 
		DN.RepCode

print ' 5 - ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

	SELECT 
		 DateTraitementDebut = @DateTraitementDebut
		,DateTraitementFin = @DateTraitementFin
		,U.UnitID
		,C.ConventionNo
		,UU.RepID
		,UU.RepCode
		,RepcodeINT = CAST(CASE WHEN ISNUMERIC(UU.RepCode) = 1 THEN UU.RepCode ELSE 0 END AS INT)
		,UU.RepName
		,UU.RepRoleDesc
		,UU.LevelShortDesc
		,DateDebutOperFIN = CAST(u.InForceDate AS DATE)
		,TauxDeRemun = ISNULL(TOMBEE.TauxDeRemun,0)
				
		,UU.TotalFee
		,VariationQteUnite = ISNULL(NET.NET,0)
		,QteUniteFin = CASE WHEN UU.FuturCom <> 0 THEN UU.QteUniteFin ELSE 0 END
		,UU.AvACouvrir
				
		,UU.Avances
		,UU.AvCouv
		,UU.BoniConAju
		,UU.Commission 
		,UU.Boni
		,FuturCom_Sommaire = UU.FuturCom

		,FuturCOM_CT = ISNULL(FuturCOM_CT,0)
		,FuturCOM_LT = ISNULL(FuturCOM_LT,0)
		,FuturCOM_CT_LT = ISNULL(FuturCOM_CT_LT,0)
		,FuturCOM_CT_LT_31DecPrec = ISNULL(FC31dec.FuturCOM_CT_LT_31DecPrec,0)
		,UU.RepriseCOMsurNSF
		,UU.RepriseAVANCEsurNSF
		,UU.NoteTFR
		,TFR = ISNULL(TransferedUnits.TFR_Montant,0) --,QteUniteFin =
	INTO #TMPDetail
	FROM 
		Un_Unit U
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN #Un_Dn_RepTreatment UU ON UU.UnitID = U.UnitID
		LEFT JOIN #FuturCOM_CT_LT FC ON FC.UnitID = UU.UnitID AND FC.RepID = UU.RepID AND UU.RepRoleDesc = FC.RepRoleDesc
		LEFT JOIN tblREPR_Rapport_DepenseDeCommissionParUnite_FuturCOM_31DecPrec FC31dec ON FC31dec.UnitID = UU.UnitID AND FC31dec.RepID = UU.RepID AND FC31dec.RepRoleDesc = UU.RepRoleDesc AND CAST(FC31dec.RepTreatmentDate AS DATE) = CAST(@DateTraitementFinAnneePrec AS DATE)
		LEFT JOIN #tUniteNette NET ON NET.UnitID = U.UnitID
		LEFT JOIN (
			SELECT 
				U1.UnitID,
				NbUnitesAjoutees = (U1.UnitQty  + ISNULL(UR2.UnitQty,0) )- SUM(A.fUnitQtyUse),
	    		fUnitQtyUse = SUM(A.fUnitQtyUse),
				TFR_Montant = SUM(C.Fee)
				
			FROM Un_AvailableFeeUse A 
			JOIN Un_Oper O ON O.OperID = A.OperID
			JOIN Un_Cotisation C ON C.OperID = O.OperID
			JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
			JOIN dbo.Un_Convention Cv ON U1.conventionid = Cv.conventionid
			JOIN Un_UnitReduction UR ON A.unitreductionid = UR.unitreductionid 
			JOIN dbo.Un_Unit Uori ON UR.unitid = Uori.unitid --and Uori.repID = U1.repid -- doit être le même Rep -- Incompatible avec Nouvelle vente validée (FeeTransferUnitQty : transfert de frais)
			JOIN dbo.Un_Convention CvOri ON Uori.conventionid = CvOri.conventionid 
											--AND CvOri.SubscriberID = Cv.SubscriberID -- doit être le même Souscripteur 	--and CvOri.BeneficiaryID = Cv.BeneficiaryID -- On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert 2009-04-15
			LEFT JOIN (
				SELECT 
					UR.UnitID,
					UnitQty = SUM(UR.UnitQty)
				FROM Un_UnitReduction UR
				GROUP BY UR.UnitID
				) UR2 ON UR2.UnitID = U1.UnitID
			WHERE O.OperTypeID = 'TFR'
				--AND ( (U1.UnitQty + ISNULL(UR2.UnitQty,0) )- A.fUnitQtyUse) >= 0
				AND U1.dtFirstDeposit >= @DateDebut 
				AND U1.dtFirstDeposit <= @DateFin
			GROUP BY
				U1.UnitID,
				U1.RepID,
				U1.UnitQty,
				UR2.UnitQty,
				U1.dtFirstDeposit
			)TransferedUnits ON TransferedUnits.UnitID = U.UnitID
		LEFT JOIN (
				SELECT 
					UnitID
					,RepID
					,RepRoleDesc
					,LevelShortDesc
					,TauxDeRemun = SUM(TauxDeRemun)
				FROM (
					SELECT DISTINCT 
						U1.UnitID
						,UU1.RepID
						,RR.RepRoleDesc
						,RL.LevelShortDesc
						,TauxDeRemun = RLB.AdvanceByUnit
						,rlb.RepLevelBracketID -- pour avoir tous les enr de la table RLB afin de faire une SUM 
					FROM 
						Un_Unit U1
						JOIN Un_Convention C1 ON C1.ConventionID = U1.ConventionID
						JOIN #Un_Dn_RepTreatment UU1 ON UU1.UnitID = U1.UnitID
						JOIN Un_RepLevelHist RLH ON RLH.RepID = UU1.RepID AND U1.InForceDate BETWEEN RLH.StartDate AND ISNULL(RLH.EndDate,'9999-12-31')
						JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID
						JOIN Un_RepRole RR ON RR.RepRoleID = RL.RepRoleID
						JOIN Un_RepLevelBracket RLB ON RLB.RepLevelID = RLH.RepLevelID AND U1.InForceDate BETWEEN RLB.EffectDate AND ISNULL(RLB.TerminationDate,'9999-12-31')  AND RLB.PlanID = C1.PlanID
					WHERE RLB.RepLevelBracketTypeID IN ('COM','ADV') --='COM'=Commission de service, 'ADV'=Avances
					)V1
				GROUP BY
					UnitID
					,RepID
					,RepRoleDesc
					,LevelShortDesc
			)TOMBEE ON	
				TOMBEE.UnitID = U.UnitID AND 
				TOMBEE.RepID = UU.RepID AND 
				TOMBEE.RepRoleDesc = UU.RepRoleDesc AND
				TOMBEE.LevelShortDesc = UU.LevelShortDesc

		
	WHERE 1=1
		
	ORDER BY C.ConventionNo, U.UnitID


--- SOMMAIRE ET DETAIL -------------------------------------------------------------------------
		
print ' 6 - ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

SELECT *
INTO #tblTEMP_DepenseDeCommissionParUnite
FROM (

	SELECT 
		Sort = 1
		,DateDebut = CAST (@DateTraitementDebut AS DATE)
		,DateFin = CAST(@DateTraitementFin AS DATE)
		,UnitID
		,ConventionNo

		,RepID
		,RepcodeINT
		,RepName

		,RepRoleDesc
		,LevelShortDesc
		,RoleNiveau = RepRoleDesc + ' ' + LevelShortDesc
		,DateDebutOperFIN
		,TauxDeRemun
				
		,TotalFee
		,VariationQteUnite
		,QteUniteFin
		,UniteSurRepresentant = CASE WHEN RepRoleDesc = 'Représentant' THEN VariationQteUnite ELSE 0 END

		,AvACouvrir
		,Avances
		,AvCouv

		,AvResil = 0
		,AvSpecial = 0
		,AvTotal = 0


		
		,Commission 
		,Boni
		
		--,BoniConAju

		,BoniConAju = 0
		,Retenu = 0
	--	,Net = 0

		,FuturCom_Sommaire

		,FuturCOM_CT
		,FuturCOM_LT
		,FuturCOM_CT_LT
		,EcartFuturCom = FuturCom_Sommaire - FuturCOM_CT_LT
		,FuturCOM_CT_LT_31DecPrec
		,RepriseCOMsurNSF
		,RepriseAVANCEsurNSF
		,NoteTFR
		,TFR,
		DateFinCT = @DateFinCT

	FROM #TMPDetail

	UNION

	SELECT
		Sort = 2,
		DateDebut = CAST (@DateTraitementDebut AS DATE), 
		DateFin = CAST(@DateTraitementFin AS DATE),
		UnitID = 0,
		ConventionNo = '',

		RepID,
		RepcodeINT,
		RepName,

		RepRoleDesc = '',
		LevelShortDesc = '',
		RoleNiveau = '',
		DateDebutOperFIN = '1900-01-01',
		TauxDeRemun = 0,
		TotalFee = 0,
		VariationQteUnite = 0,
		QteUniteFin = 0,
		UniteSurRepresentant = 0,

		AvACouvrir = 0,
		Avances = 0,
		AvCouv = 0,

		AvResil,
		AvSpecial,
		AvTotal,

		Commission = 0,
		Boni = 0,

		BoniConAju,
		Retenu,
	--	Net,

		FuturCom_Sommaire = 0,

		FuturCOM_CT = 0,
		FuturCOM_LT = 0,
		FuturCOM_CT_LT = 0,
		EcartFuturCom  = 0,
		FuturCOM_CT_LT_31DecPrec = 0,
		RepriseCOMsurNSF = 0,
		RepriseAVANCEsurNSF = 0,
		NoteTFR = '',
		TFR = 0,
		DateFinCT = @DateFinCT

	FROM #tmpSommaire
	)V
ORDER BY Sort, UnitID

print ' 7 - ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

--RETURN


/*
	SELECT
	
		Sort,
		DateDebut = CAST (@DateTraitementDebut AS DATE), 
		DateFin = CAST(@DateTraitementFin AS DATE),
		UnitID,
		ConventionNo,

		RepID,
		RepcodeINT,
		RepName,

		RepRoleDesc,
		LevelShortDesc,
		RoleNiveau,
		DateDebutOperFIN,
		TauxDeRemun,
		TotalFee,
		VariationQteUnite,
		QteUniteFin,
		UniteSurRepresentant,
		AvACouvrir,
		Avances,
		AvCouv,

		AvResil,
		AvSpecial,
		AvTotal,

		Commission,
		Boni,

		BoniConAju,
		Retenu,
		--Net,

		FuturCom_Sommaire,

		FuturCOM_CT,
		FuturCOM_LT,
		FuturCOM_CT_LT,
		EcartFuturCom,
		FuturCOM_CT_LT_31DecPrec,
		RepriseCOMsurNSF,
		RepriseAVANCEsurNSF,
		NoteTFR,
		TFR,
		DateFinCT


	
	INTO tblTEMP_DepenseDeCommissionParUnite
	FROM #tblTEMP_DepenseDeCommissionParUnite

	SELECT * from #tblTEMP_DepenseDeCommissionParUnite

	RETURN
	*/
	SELECT 
	
		Sort,

		DateDebut = CAST (@DateTraitementDebut AS DATE), 
		DateFin = CAST(@DateTraitementFin AS DATE),

		UnitID,
		
		ConventionNo,

		RepID,
		
		RepcodeINT,
		
		RepName,

		RepRoleDesc ,
		
		LevelShortDesc,

		RoleNiveau,

		DateDebutOperFIN,

		TauxDeRemun = REPLACE(CAST(ROUND(		TauxDeRemun /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),

		TotalFee = REPLACE(CAST(ROUND(		TotalFee /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		VariationQteUnite = REPLACE(CAST(ROUND(	1.0*	VariationQteUnite /**/ ,3/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		QteUniteFin = REPLACE(CAST(ROUND( 1.0*		QteUniteFin /**/ ,3/*round*/) as VARCHAR(30)),'.',/**/'.'),

		UniteSurRepresentant = REPLACE(CAST(ROUND( 1.0*		UniteSurRepresentant /**/ ,3/*round*/) as VARCHAR(30)),'.',/**/'.'),

		AvACouvrir = REPLACE(CAST(ROUND(		AvACouvrir /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		Avances = REPLACE(CAST(ROUND(		Avances /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		AvCouv = REPLACE(CAST(ROUND(		AvCouv /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),

		AvResil = REPLACE(CAST(ROUND(		AvResil /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		AvSpecial = REPLACE(CAST(ROUND(		AvSpecial /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		AvTotal = REPLACE(CAST(ROUND(		AvTotal /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),

		Commission = REPLACE(CAST(ROUND(		Commission /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		Boni = REPLACE(CAST(ROUND(		Boni /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),

		BoniConAju = REPLACE(CAST(ROUND(		BoniConAju /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		Retenu = REPLACE(CAST(ROUND(		Retenu /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
	--	Net = REPLACE(CAST(ROUND(		Net /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),

		FuturCom_Sommaire = REPLACE(CAST(ROUND(		FuturCom_Sommaire /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),

		FuturCOM_CT = REPLACE(CAST(ROUND(		FuturCOM_CT /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		FuturCOM_LT = REPLACE(CAST(ROUND(		FuturCOM_LT /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		FuturCOM_CT_LT = REPLACE(CAST(ROUND(		FuturCOM_CT_LT /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		EcartFuturCom  = REPLACE(CAST(ROUND(		EcartFuturCom /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),

		FuturCOM_CT_LT_31DecPrec = REPLACE(CAST(ROUND(		FuturCOM_CT_LT_31DecPrec /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),

		RepriseCOMsurNSF = REPLACE(CAST(ROUND(		RepriseCOMsurNSF /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		RepriseAVANCEsurNSF = REPLACE(CAST(ROUND(		RepriseAVANCEsurNSF /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		NoteTFR,
		
		TFR = REPLACE(CAST(ROUND(		TFR /**/ ,2/*round*/) as VARCHAR(30)),'.',/**/'.'),
		
		DateFinCT
	
	INTO tblTEMP_DepenseDeCommissionParUnite
	FROM #tblTEMP_DepenseDeCommissionParUnite

	SELECT * FROM #tblTEMP_DepenseDeCommissionParUnite

--	RETURN
	--------------------------------------------------------------------------------------------------------------------
	CREATE TABLE #tOutPut (f1 varchar(2000))

	INSERT #tOutPut
	EXEC('exec master..xp_cmdshell ''del '+@vcNomFichier+'''')

	INSERT #tOutPut
	EXEC SP_ExportTableToExcelWithColumns @DB_NAME, 'tblTEMP_DepenseDeCommissionParUnite', @vcNomFichier, 'RAW', 1,','

	--IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'tblTEMP_DepenseDeCommissionParUnite')
	--	DROP TABLE tblTEMP_DepenseDeCommissionParUnite	

	--SELECT * from #tOutPut
	--------------------------------------------------------------------------------------------------------------------




	
	/*
	SELECT 
		Du = cast(@RepTreatmentIDFrom as VARCHAR),
		Au = cast(@RepTreatmentIDTo as VARCHAR),
		NomFichier = @vcNomFichier
	*/

END


