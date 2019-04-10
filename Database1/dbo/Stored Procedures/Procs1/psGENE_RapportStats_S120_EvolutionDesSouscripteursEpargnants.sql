/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psGENE_RapportStats_S120_EvolutionDesSouscripteursEpargnants
Nom du service		: EvolutionDesSouscripteursEpargnants
But 				: JIRA PROD-9514 : Obtenir Evolution Des Souscripteurs Epargnants

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						

Exemple d’appel		:	

		EXECUTE psGENE_RapportStats_S120_EvolutionDesSouscripteursEpargnants '2018-04-01', '2018-04-30', 0, 'S'

Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------- -----------------------------------------	------------
		2018-06-06		Donald Huppé		Création du service				

*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStats_S120_EvolutionDesSouscripteursEpargnants]
    (
	@dtStartDate DATE-- = '2018-04-01'
	,@dtEndDate DATE-- = '2018-04-30'
	,@iID_Regroupement_Regime INT-- = 0  --SELECT * FROM tblCONV_RegroupementsRegimes
	,@Regroupement VARCHAR(30)-- = 'S'
    )
AS 
BEGIN


set ARITHABORT on

DECLARE 
	 @NomRegime VARCHAR(100)
	,@Dossier VARCHAR(1000) = '\\srvapp06\PlanDeClassification\1_GOUVERNANCE_ET_AFFAIRES_CORPO\107_BUREAU_PROJET\107-200_PROJETS_ACTIFS\PR2016-33_Outil_de_statistiques\6_NBRE_SOUSC\'
	--,@Dossier VARCHAR(1000) = '\\srvapp06\PlanDeClassification\000_PANIER_DE_CLASSEMENT\000-100_TOUS\'
	,@dtDateGeneration DATETIME
	,@DossierFinal varchar(500)
	,@vcNomFichier VARCHAR(500)


	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'tblTEMP_RapportStats_S120_EvolutionDesSouscripteursEpargnants')
		DROP TABLE tblTEMP_RapportStats_S120_EvolutionDesSouscripteursEpargnants	


	SET	@dtDateGeneration = GETDATE()

	SET @vcNomFichier = 
				@Dossier +

				REPLACE(REPLACE(	REPLACE(LEFT(CONVERT(VARCHAR, @dtDateGeneration, 120), 25),'-',''),' ','_'),':','') + 
				'_S120_EvolutionDesSouscripteursEpargnants_' +
				LEFT(CONVERT(VARCHAR, @dtStartDate, 120), 10) + '_au_' +
				LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10) + 
				'.CSV'


	IF @iID_Regroupement_Regime = 0
		SET @NomRegime = 'Tous'

	SELECT @NomRegime = vcDescription FROM tblCONV_RegroupementsRegimes WHERE iID_Regroupement_Regime = @iID_Regroupement_Regime


--SELECT @NomRegime 


		IF OBJECT_ID('tempdb..#tUnite_T_IBEC')				IS NOT NULL DROP TABLE #tUnite_T_IBEC
		IF OBJECT_ID('tempdb..#tmpPlanActif_Debut')			IS NOT NULL DROP TABLE #tmpPlanActif_Debut
		IF OBJECT_ID('tempdb..#PlanActif_Debut')			IS NOT NULL DROP TABLE #PlanActif_Debut
		IF OBJECT_ID('tempdb..#tmpPlanActif_Periode')		IS NOT NULL DROP TABLE #tmpPlanActif_Periode
		IF OBJECT_ID('tempdb..#tmpPlan_RINComplet_Periode') IS NOT NULL DROP TABLE #tmpPlan_RINComplet_Periode
		IF OBJECT_ID('tempdb..#tmpPlanActif_Fin')			IS NOT NULL DROP TABLE #tmpPlanActif_Fin
		IF OBJECT_ID('tempdb..#PlanActif_Fin')				IS NOT NULL DROP TABLE #PlanActif_Fin
		IF OBJECT_ID('tempdb..#PlanResil')					IS NOT NULL DROP TABLE #PlanResil
		IF OBJECT_ID('tempdb..#tmpPlanFRMautre_Periode')	IS NOT NULL DROP TABLE #tmpPlanFRMautre_Periode
		IF OBJECT_ID('tempdb..#FINAL')						IS NOT NULL DROP TABLE #FINAL


		SELECT * 
		INTO #tUnite_T_IBEC
		FROM fntREPR_ObtenirUniteConvT (1) t		

		--DROP TABLE #tmpPlanActif_Debut
		SELECT 
			C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,dtFirstDeposit = MIN(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit))
			,Cotisation = SUM(ISNULL(EPG.Cotisation,0))
			,Fee = SUM(ISNULL(EPG.Fee,0))
		INTO #tmpPlanActif_Debut
		FROM Un_Convention c
		JOIN (
			select 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			from 
				un_conventionconventionstate cs
				join (
					select 
					conventionid,
					startdate = max(startDate)
					from un_conventionconventionstate
					where startDate < DATEADD(d,1 ,@dtStartDate)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID in ('REE','TRA')
			) css on C.conventionid = css.conventionid
		JOIN Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		--LEFT JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		--LEFT JOIN Un_Oper O ON O.OperID = CT.OperID 
		LEFT JOIN (
			SELECT 
				CT1.UnitID
				,Cotisation = SUM(CT1.Cotisation)
				,Fee = SUM(CT1.Fee)
			FROM Un_Cotisation CT1
			JOIN Un_Oper O1 ON O1.OperID = CT1.OperID
			WHERE O1.OperDate <= @dtStartDate
			GROUP BY CT1.UnitID
			)EPG ON EPG.UnitID = U.UnitID
		LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
		WHERE 1=1
			AND ISNULL(
					ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)
					,'9999-12-31'
					) < @dtStartDate 
			--AND O.operdate <= @dtStartDate
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
		GROUP BY C.SubscriberID
			,c.ConventionID 
			,rr.vcDescription

	--	SELECT * FROM #tmpPlanActif_Debut
		--DROP TABLE #PlanActif_Debut
		SELECT
			 PA.SubscriberID
			,Regime = rr.vcDescription
			,PA.ConventionID
			,DateRIEstimé = MIN(dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust))
			,PA.dtFirstDeposit
			,PA.Cotisation
			,PA.Fee
		INTO #PlanActif_Debut
		FROM #tmpPlanActif_Debut PA
		JOIN UN_CONVENTION C ON C.ConventionID = PA.ConventionID
		JOIN Un_Unit u ON U.ConventionID = PA.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		GROUP BY 
			 PA.SubscriberID
			,PA.ConventionID 
			,PA.dtFirstDeposit
			,PA.Cotisation
			,PA.Fee
			,rr.vcDescription

		--SELECT * from #PlanActif_Debut


		--DROP TABLE #tmpPlanActif_Periode
		SELECT 
			C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,dtFirstDeposit = MIN(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit))
			--,DateREE_TRA = MIN(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)) -- MIN(css.StartDate) -- ON CONSIDÈRE QUE LE PLAN TOMBE ree OU TRA LE JOUR DU 1ER DÉPÔT. C'EST LOUCHE MAIS PAS LE CHOIX 
		INTO #tmpPlanActif_Periode
		FROM Un_Convention c
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		--JOIN un_conventionconventionstate css on C.conventionid = css.conventionid AND CSS.ConventionStateID IN ('REE','TRA')
		JOIN Un_Unit u ON c.ConventionID = u.ConventionID
		LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
		WHERE (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
		GROUP BY C.SubscriberID
			,c.ConventionID 
			,rr.vcDescription
		HAVING 1=1
			--AND MIN(css.StartDate) BETWEEN  @dtStartDate AND @dtEndDate
			AND MIN(
					ISNULL(
						ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)
						,'9999-12-31'
					)
					) BETWEEN  @dtStartDate AND @dtEndDate 

		--SELECT * from #tmpPlanActif_Periode

--DECLARE @dtStartDate DATETIME = '2018-01-01'
--DECLARE @dtEndDate DATETIME = '2018-04-30'

		--NbPlansRinCompletDepuisDebut
		--DROP TABLE #tmpPlan_RINComplet_Periode
		SELECT 
			C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,C.ConventionNo
		INTO #tmpPlan_RINComplet_Periode
		FROM Un_Convention c
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN(
			SELECT U1.ConventionID
			FROM Un_Unit U1
			JOIN Un_Cotisation CT1 ON CT1.UnitID = U1.UnitID
			JOIN Un_Oper O1 ON O1.OperID = CT1.OperID
			WHERE O1.OperDate <= @dtEndDate
			GROUP BY U1.ConventionID
			HAVING SUM(CT1.Cotisation + CT1.Fee) < 100
			)TOT100 ON TOT100.ConventionID = C.ConventionID
		JOIN Un_Unit u on c.ConventionID = u.ConventionID
		JOIN Un_Cotisation ct on u.UnitID = ct.UnitID
		JOIN Un_Oper o on ct.OperID = o.OperID
		LEFT JOIN Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
		LEFT JOIN Un_OperCancelation oc2 on o.OperID = oc2.OperID
		WHERE 
			o.OperDate BETWEEN @dtStartDate and @dtEndDate
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
			AND o.OperTypeID = 'RIN'
			AND oc1.OperSourceID IS NULL
			AND oc2.OperID IS NULL
		GROUP BY
			C.SubscriberID
			,C.ConventionID
			,C.ConventionNo
			,rr.vcDescription


		--DROP TABLE #tmpPlanActif_Fin
		SELECT 
			C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,dtFirstDeposit = MIN(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit))
			,Cotisation = SUM(ISNULL(EPG.Cotisation,0))
			,Fee = SUM(ISNULL(EPG.Fee,0))
		INTO #tmpPlanActif_Fin
		FROM Un_Convention c
		JOIN (
			select 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			from 
				un_conventionconventionstate cs
				join (
					select 
					conventionid,
					startdate = max(startDate)
					from un_conventionconventionstate
					where startDate < DATEADD(d,1 ,@dtEndDate)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID in ('REE','TRA')
			) css on C.conventionid = css.conventionid
		JOIN Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		--LEFT JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		--LEFT JOIN Un_Oper O ON O.OperID = CT.OperID 
		LEFT JOIN (
			SELECT 
				CT1.UnitID
				,Cotisation = SUM(CT1.Cotisation)
				,Fee = SUM(CT1.Fee)
			FROM Un_Cotisation CT1
			JOIN Un_Oper O1 ON O1.OperID = CT1.OperID
			WHERE O1.OperDate <= @dtEndDate
			GROUP BY CT1.UnitID
			)EPG ON EPG.UnitID = U.UnitID
		LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
		WHERE 1=1
			AND ISNULL(
					ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)
					,'9999-12-31'
					) <= @dtEndDate 
			--AND O.operdate <= @dtEndDate
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
		GROUP BY C.SubscriberID
			,c.ConventionID 
			,rr.vcDescription


		
		--DROP TABLE #PlanActif_Fin
		SELECT
			 PA.SubscriberID
			,Regime = rr.vcDescription
			,PA.ConventionID
			,DateRIEstimé = MIN(dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust))
			,PA.dtFirstDeposit
			,PA.Cotisation
			,PA.Fee
		INTO #PlanActif_Fin
		FROM #tmpPlanActif_Fin PA
		JOIN UN_CONVENTION C ON C.ConventionID = PA.ConventionID
		JOIN Un_Unit u ON U.ConventionID = PA.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		WHERE (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
		GROUP BY 
			 PA.SubscriberID
			,PA.ConventionID 
			,PA.dtFirstDeposit
			,PA.Cotisation
			,PA.Fee
			,rr.vcDescription

		--SELECT * FROM #PlanActif_Fin


		SELECT 
			C.SubscriberID
			,Regime = rr.vcDescription
			,c.ConventionID
			,QteuniteDebut = SUM(u.UnitQty + ISNULL(urApresDebut.QteRES,0))
			,QteuniteFin = SUM(u.UnitQty + ISNULL(urApresFin.QteRES,0))
			,RES.DateResil
		INTO #PlanResil
		FROM Un_Unit u
		JOIN Un_Convention c on c.ConventionID = u.ConventionID
		JOIN Un_Plan P on P.PlanID = c.PlanID
		JOIN (
				SELECT u.ConventionID, DateResil = MAX(o.OperDate)
				FROM Un_Unit U
				JOIN Un_Convention c on u.ConventionID = c.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
				JOIN Un_UnitReduction ur ON urc.UnitReductionID = ur.UnitReductionID
				left JOIN Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
				left JOIN Un_OperCancelation oc2 on o.OperID = oc2.OperID
				WHERE 	O.OperTypeID in ( 'RES','OUT')
					and oc1.OperSourceID is NULL
					and oc2.OperID is NULL
					AND o.OperDate BETWEEN @dtStartDate AND @dtEndDate
				GROUP BY  u.ConventionID
			)RES on RES.ConventionID = c.ConventionID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		LEFT JOIN (SELECT UnitID, QteRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtStartDate GROUP BY UnitID) urApresDebut on urApresDebut.UnitID = u.UnitID
		LEFT JOIN (SELECT UnitID, QteRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtEndDate GROUP BY UnitID) urApresFin on urApresFin.UnitID = u.UnitID
		LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
		WHERE 1=1
			AND ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') <= @dtEndDate
			AND RES.DateResil BETWEEN @dtStartDate AND @dtEndDate
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
			--AND c.ConventionNo = 'X-20150408054'
		GROUP by C.SubscriberID
			,c.ConventionID,RES.DateResil,rr.vcDescription
		HAVING SUM(u.UnitQty + ISNULL(urApresFin.QteRES,0)) = 0

/*
		--DROP TABLE #PlanResil
		SELECT C.SubscriberID, U.conventionid,DateResil , NbGrUnit = COUNT(*)
		INTO #PlanResil
		FROM Un_Unit U
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN (
			SELECT conventionid, nbResil = COUNT(*), DateResil = MAX(terminateddate)
			FROM Un_Unit un
			LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = un.UnitID
			WHERE terminateddate IS NOT NULL
			AND ISNULL(un.dtFirstDeposit,t.dtFirstDeposit) IS NOT NULL
			GROUP BY conventionid
			) Resil on U.conventionid = Resil.conventionid
		-- a déjà été actif AVANT LA RÉSIL
		JOIN (
			SELECT DISTINCT CSS.ConventionID,StartDate = MIN( css.StartDate) 
			FROM un_conventionconventionstate css
			WHERE CSS.ConventionStateID IN ('REE','TRA')
			GROUP BY CSS.ConventionID
			)CS ON CS.ConventionID = C.ConventionID AND CS.StartDate <= DateResil --AVANT LA RÉSIL
		LEFT JOIN #tUnite_T_IBEC t2 ON t2.UnitID = u.UnitID
		WHERE 1=1
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
			AND ISNULL(u.dtFirstDeposit,t2.dtFirstDeposit) IS NOT NULL
		GROUP BY C.SubscriberID,U.conventionid, Resil.nbResil,Resil.DateResil
		HAVING COUNT(*) = Resil.nbResil
*/



		SELECT 
			C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,DateFRM = css.startdate
		INTO #tmpPlanFRMautre_Periode
		FROM Un_Convention c
		JOIN (
			select 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			from 
				un_conventionconventionstate cs
				join (
					select 
					conventionid,
					startdate = max(startDate)
					from un_conventionconventionstate
					where startDate < DATEADD(d,1 ,@dtEndDate)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID in ('FRM')
			) css on C.conventionid = css.conventionid
		LEFT JOIN (
			select 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			from 
				un_conventionconventionstate cs
				join (
					select 
					conventionid,
					startdate = max(startDate)
					from un_conventionconventionstate
					where startDate < DATEADD(d,1 ,@dtStartDate)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID in ('FRM')
			) cssDebut on cssDebut.conventionid = C.conventionid

		JOIN Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		LEFT JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		LEFT JOIN Un_Oper O ON O.OperID = CT.OperID AND o.operdate <= @dtEndDate
		LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
		LEFT JOIN #PlanResil R ON R.ConventionID = C.ConventionID AND R.DateResil BETWEEN  @dtStartDate AND @dtEndDate
		WHERE 1=1
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
			AND css.startdate BETWEEN @dtStartDate AND @dtEndDate
			AND ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') <= @dtEndDate
			AND R.ConventionID IS NULL -- N'EST PAS FERMÉ POUR CAUSE DE RES/OUT
			AND cssDebut.conventionid is NULL-- n'est pas déjà fermé au debut
			



	SELECT DISTINCT
		Du = @dtStartDate
		,Au = @dtEndDate
		,RegimeSelectionne = @NomRegime
		,Regime
		,V.SubscriberID
		,SubscriberPrenom = HS.FirstName
		,SubscriberNom = HS.LastName
		,EstSouscripteurEpargnantDebut = SUM(EstSouscripteurEpargnantDebut)
		,NbPlansActifsDebut = SUM(NbPlansActifsDebut)
		,NbPlansAvantEcheanceDebut = SUM(NbPlansAvantEcheanceDebut)
		,NbPlansApresEcheanceDebut = SUM(NbPlansApresEcheanceDebut)
		,NbPlansActifsDepuisDebut = SUM(NbPlansActifsDepuisDebut)
		,NbPlansResOUTCompleteDepuisDebut = SUM(NbPlansResOUTCompleteDepuisDebut)
		,NbPlansFermeAutreDepuisDebut = SUM(NbPlansFermeAutreDepuisDebut)
		,NbPlansRinCompletDepuisDebut = SUM(NbPlansRinCompletDepuisDebut)
		,EstSouscripteurEpargnantFin = SUM(EstSouscripteurEpargnantFin)
		,NbPlansActifsFin = SUM(NbPlansActifsFin)
		,NbPlansAvantEcheanceFin = SUM(NbPlansAvantEcheanceFin)
		,NbPlansApresEcheanceFin = SUM(NbPlansApresEcheanceFin)
	INTO #FINAL
	FROM Un_Subscriber S
	JOIN Mo_Human HS ON HS.HumanID = S.SubscriberID
	JOIN (

		SELECT
			 SubscriberID
			,Regime
			,EstSouscripteurEpargnantDebut = MAX(
												CASE 
												WHEN DateRIEstimé > @dtStartDate  AND (Cotisation + FEE) >= 0   THEN SubscriberID --1
												WHEN DateRIEstimé <= @dtStartDate AND (Cotisation + FEE) >= 100 THEN SubscriberID --1
												ELSE NULL --0 
												END
												)
			,NbPlansActifsDebut = COUNT(DISTINCT ConventionID)
			,NbPlansAvantEcheanceDebut = COUNT(DISTINCT CASE WHEN DateRIEstimé > @dtStartDate THEN ConventionID ELSE NULL END )
			,NbPlansApresEcheanceDebut = COUNT(DISTINCT CASE WHEN DateRIEstimé <= @dtStartDate THEN ConventionID ELSE NULL END )
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermeAutreDepuisDebut = 0
			,NbPlansRinCompletDepuisDebut = 0
			,EstSouscripteurEpargnantFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantEcheanceFin = 0
			,NbPlansApresEcheanceFin = 0
		FROM #PlanActif_Debut
		GROUP BY SubscriberID
			,Regime

		UNION ALL

		SELECT 
			SubscriberID
			,Regime
			,EstSouscripteurEpargnantDebut = NULL
			,NbPlansActifsDepuisDebut = 0
			,NbPlansAvantEcheanceDebut = 0
			,NbPlansApresEcheanceDebut = 0
			,NbPlansActifsDepuisDebut = COUNT(DISTINCT ConventionID)
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermeAutreDepuisDebut = 0
			,NbPlansRinCompletDepuisDebut = 0
			,EstSouscripteurEpargnantFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantEcheanceFin = 0
			,NbPlansApresEcheanceFin = 0
		FROM #tmpPlanActif_Periode
		GROUP BY SubscriberID
			,Regime

		UNION ALL

		SELECT 
			 SubscriberID
			,Regime
			,EstSouscripteurEpargnantDebut = NULL
			,NbPlansActifsDebut = 0
			,NbPlansAvantEcheanceDebut = 0
			,NbPlansApresEcheanceDebut = 0
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = COUNT(DISTINCT ConventionID)
			,NbPlansFermeAutreDepuisDebut = 0
			,NbPlansRinCompletDepuisDebut = 0
			,EstSouscripteurEpargnantFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantEcheanceFin = 0
			,NbPlansApresEcheanceFin = 0
			
		FROM #PlanResil
		WHERE DateResil BETWEEN @dtStartDate AND @dtEndDate
		GROUP BY SubscriberID
			,Regime

		UNION ALL

		SELECT 
			 SubscriberID
			,Regime
			,EstSouscripteurEpargnantDebut = NULL
			,NbPlansActifsDebut = 0
			,NbPlansAvantEcheanceDebut = 0
			,NbPlansApresEcheanceDebut = 0
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermeAutreDepuisDebut = 0
			,NbPlansRinCompletDepuisDebut = COUNT(DISTINCT ConventionID)
			,EstSouscripteurEpargnantFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantEcheanceFin = 0
			,NbPlansApresEcheanceFin = 0
			
		FROM #tmpPlan_RINComplet_Periode
		GROUP BY SubscriberID
			,Regime

		UNION ALL

		SELECT 
			 SubscriberID
			,Regime
			,EstSouscripteurEpargnantDebut = NULL
			,NbPlansActifsDebut = 0
			,NbPlansAvantEcheanceDebut = 0
			,NbPlansApresEcheanceDebut = 0
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermeAutreDepuisDebut = COUNT(DISTINCT ConventionID)
			,NbPlansRinCompletDepuisDebut = 0
			,EstSouscripteurEpargnantFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantEcheanceFin = 0
			,NbPlansApresEcheanceFin = 0

			
		FROM #tmpPlanFRMautre_Periode
		GROUP BY SubscriberID
			,Regime

		UNION ALL
		--DECLARE @dtStartDate DATETIME = '2018-01-01'
		--DECLARE @dtEndDate DATETIME = '2018-04-30'		
		SELECT
			 SubscriberID
			,Regime
			,EstSouscripteurEpargnantDebut = NULL
			,NbPlansActifsDebut = 0
			,NbPlansAvantEcheanceDebut = 0
			,NbPlansApresEcheanceDebut = 0
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermeAutreDepuisDebut = 0
			,NbPlansRinCompletDepuisDebut = 0
			,EstSouscripteurEpargnantFin = MAX(
												CASE 
												WHEN DateRIEstimé > @dtEndDate  AND (Cotisation + FEE) >= 0   THEN SubscriberID --1
												WHEN DateRIEstimé <= @dtEndDate AND (Cotisation + FEE) >= 100 THEN SubscriberID --1
												ELSE NULL --0 
												END
												)
			,NbPlansActifsFin = COUNT(DISTINCT ConventionID)
			,NbPlansAvantEcheanceFin = COUNT(DISTINCT CASE WHEN DateRIEstimé > @dtEndDate THEN ConventionID ELSE NULL END )
			,NbPlansApresEcheanceFin = COUNT(DISTINCT CASE WHEN DateRIEstimé <= @dtEndDate THEN ConventionID ELSE NULL END )
		FROM #PlanActif_Fin
		GROUP BY SubscriberID
			,Regime
	)V ON V.SubscriberID = S.SubscriberID
	GROUP BY 
		 V.SubscriberID
		,HS.FirstName
		,HS.LastName
		,Regime
	ORDER BY V.SubscriberID
		

	SELECT *
	INTO tblTEMP_RapportStats_S120_EvolutionDesSouscripteursEpargnants
	FROM #FINAL


	IF @Regroupement <> 'S'
	BEGIN

		CREATE TABLE #tOutPut (f1 varchar(2000))

		INSERT #tOutPut
		EXEC('exec master..xp_cmdshell ''del '+@vcNomFichier+'''')

		INSERT #tOutPut
		EXEC SP_ExportTableToExcelWithColumns 'UnivBase', 'tblTEMP_RapportStats_S120_EvolutionDesSouscripteursEpargnants', @vcNomFichier, 'RAW', 1

		IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'tblTEMP_RapportStats_S120_EvolutionDesSouscripteursEpargnants')
			DROP TABLE tblTEMP_RapportStats_S120_EvolutionDesSouscripteursEpargnants	

	END



	SELECT 
		NoRegime = rr.iID_Regroupement_Regime
		,Regime
		,NbSouscripteurs = COUNT(DISTINCT SubscriberID)
		,NbSouscripteurEpargnantDebut =  COUNT(DISTINCT EstSouscripteurEpargnantDebut) --COUNT(DISTINCT CASE WHEN EstSouscripteurEpargnantDebut = 0 THEN NULL ELSE EstSouscripteurEpargnantDebut END )
		,NbPlansActifsDebut = SUM(NbPlansActifsDebut)
		,NbPlansAvantEcheanceDebut = SUM(NbPlansAvantEcheanceDebut)
		,NbPlansApresEcheanceDebut = SUM(NbPlansApresEcheanceDebut)
		,NbPlansActifsDepuisDebut = SUM(NbPlansActifsDepuisDebut)
		,NbPlansResOUTCompleteDepuisDebut = SUM(NbPlansResOUTCompleteDepuisDebut)
		,NbPlansFermeAutreDepuisDebut = SUM(NbPlansFermeAutreDepuisDebut)
		,NbPlansRinCompletDepuisDebut = SUM(NbPlansRinCompletDepuisDebut)
		,NbSouscripteurEpargnantFin =  COUNT(DISTINCT EstSouscripteurEpargnantFin)  --COUNT(DISTINCT CASE WHEN NbSouscripteurEpargnantFin = 0 THEN NULL ELSE NbSouscripteurEpargnantFin END )
		,NbPlansActifsFin = SUM(NbPlansActifsFin)
		,NbPlansAvantEcheanceFin = SUM(NbPlansAvantEcheanceFin)
		,NbPlansApresEcheanceFin = SUM(NbPlansApresEcheanceFin)
	INTO #PREFINAL
	FROM #FINAL F
	LEFT JOIN tblCONV_RegroupementsRegimes RR ON RR.vcDescription = F.Regime
	GROUP BY rr.iID_Regroupement_Regime,Regime

	IF @iID_Regroupement_Regime = 0
	BEGIN
		INSERT INTO #PREFINAL
		SELECT 
			NoRegime = 99
			,Regime = 'Tous'
			,NbSouscripteurs = COUNT(DISTINCT SubscriberID)
			,NbSouscripteurEpargnantDebut = COUNT(DISTINCT EstSouscripteurEpargnantDebut)
			,NbPlansActifsDebut = SUM(NbPlansActifsDebut)
			,NbPlansAvantEcheanceDebut = SUM(NbPlansAvantEcheanceDebut)
			,NbPlansApresEcheanceDebut = SUM(NbPlansApresEcheanceDebut)
			,NbPlansActifsDepuisDebut = SUM(NbPlansActifsDepuisDebut)
			,NbPlansResOUTCompleteDepuisDebut = SUM(NbPlansResOUTCompleteDepuisDebut)
			,NbPlansFermeAutreDepuisDebut = SUM(NbPlansFermeAutreDepuisDebut)
			,NbPlansRinCompletDepuisDebut = SUM(NbPlansRinCompletDepuisDebut)
			,NbSouscripteurEpargnantFin = COUNT(DISTINCT EstSouscripteurEpargnantFin)
			,NbPlansActifsFin = SUM(NbPlansActifsFin)
			,NbPlansAvantEcheanceFin = SUM(NbPlansAvantEcheanceFin)
			,NbPlansApresEcheanceFin = SUM(NbPlansApresEcheanceFin)
		FROM #FINAL
	END	


	SELECT 
		V.*
		,vcNomFichier = @vcNomFichier
		,Regroupement = @Regroupement
	FROM #PREFINAL V
	ORDER BY v.NoRegime


set ARITHABORT off

	END

