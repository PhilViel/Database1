/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psGENE_RapportStats_S150_EvolutionNombreBeneficiaires
Nom du service		: Évolution du nombre de bénéficiaires
But 				: JIRA PROD-10606 : Obtenir Évolution du nombre de bénéficiaires

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						

Exemple d’appel		:	

		EXECUTE psGENE_RapportStats_S150_EvolutionNombreBeneficiaires '2018-01-01', '2018-07-31', 0, 436381, 0, 'SA'

Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------- -----------------------------------------	------------
		2018-06-06		Donald Huppé		Création du service				

*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStats_S150_EvolutionNombreBeneficiaires]
    (
		@dtStartDate datetime
		,@dtEndDate datetime
		,@RepID INT	= 0
		,@BossID INT = 0
		,@iID_Regroupement_Regime INT
		,@Regroupement VARCHAR(30)
    )
AS 
BEGIN



--set ARITHABORT on





DECLARE 
	 @NomRegime VARCHAR(100)
	,@Dossier VARCHAR(1000) = '\\srvapp06\PlanDeClassification\1_GOUVERNANCE_ET_AFFAIRES_CORPO\107_BUREAU_PROJET\107-200_PROJETS_ACTIFS\PR2016-33_Outil_de_statistiques\7_NBRE_BENEF\'
	--,@Dossier VARCHAR(1000) = '\\srvapp06\PlanDeClassification\000_PANIER_DE_CLASSEMENT\000-100_TOUS\'
	,@dtDateGeneration DATETIME
	,@DossierFinal varchar(500)
	,@vcNomFichier VARCHAR(500)

	--SELECT T = 'AJOUTER LES INFO DE #tmpPlanFRM_PAE_Periode !!!'
	--RETURN

--select year(@dtStartDate)

	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'tblTEMP_RapportStats_S150_EvolutionNombreBeneficiaires')
		DROP TABLE tblTEMP_RapportStats_S150_EvolutionNombreBeneficiaires	


	SET	@dtDateGeneration = GETDATE()

	SET @vcNomFichier = 
				@Dossier +

				REPLACE(REPLACE(	REPLACE(LEFT(CONVERT(VARCHAR, @dtDateGeneration, 120), 25),'-',''),' ','_'),':','') + 
				'_S150_EvolutionNombreBeneficiaires_' +
				LEFT(CONVERT(VARCHAR, @dtStartDate, 120), 10) + '_au_' +
				LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10) + 
				'.CSV'


	IF @iID_Regroupement_Regime = 0
		SET @NomRegime = 'Tous'

	SELECT @NomRegime = vcDescription FROM tblCONV_RegroupementsRegimes WHERE iID_Regroupement_Regime = @iID_Regroupement_Regime


--SELECT @NomRegime 


		--IF OBJECT_ID('tempdb..#tUnite_T_IBEC')				IS NOT NULL DROP TABLE #tUnite_T_IBEC
		--IF OBJECT_ID('tempdb..#V2')							IS NOT NULL DROP TABLE #V2
		--IF OBJECT_ID('tempdb..#hist_Rep_sousc')				IS NOT NULL DROP TABLE #hist_Rep_sousc
		
		--IF OBJECT_ID('tempdb..#tmpPlanActif_Debut')			IS NOT NULL DROP TABLE #tmpPlanActif_Debut

		--IF OBJECT_ID('tempdb..#PlanActif_Debut')			IS NOT NULL DROP TABLE #PlanActif_Debut
		--IF OBJECT_ID('tempdb..#tmpPlanActif_Periode')		IS NOT NULL DROP TABLE #tmpPlanActif_Periode
		--IF OBJECT_ID('tempdb..#tmpPlan_RINComplet_Periode') IS NOT NULL DROP TABLE #tmpPlan_RINComplet_Periode
		--IF OBJECT_ID('tempdb..#tmpPlanActif_Fin')			IS NOT NULL DROP TABLE #tmpPlanActif_Fin
		--IF OBJECT_ID('tempdb..#PlanActif_Fin')				IS NOT NULL DROP TABLE #PlanActif_Fin
		--IF OBJECT_ID('tempdb..#PlanResil')					IS NOT NULL DROP TABLE #PlanResil
		--IF OBJECT_ID('tempdb..#tmpPlanFRM_PAE_Periode')		IS NOT NULL DROP TABLE #tmpPlanFRM_PAE_Periode
		
		--IF OBJECT_ID('tempdb..#tmpPlanFRMautre_Periode')	IS NOT NULL DROP TABLE #tmpPlanFRMautre_Periode
		--IF OBJECT_ID('tempdb..#FINAL')						IS NOT NULL DROP TABLE #FINAL
		--IF OBJECT_ID('tempdb..#PREFINAL')					IS NOT NULL DROP TABLE #PREFINAL
		

	select
		RangRep =  DENSE_RANK()  OVER (
							partition by SubscriberID
							ORDER BY SubscriberID,  logtime
								), 
		OldRepID = case when isnumeric(SecondRecord)=0 then -1 else cast(FirstRecord as int) end,
		NewRepID = case when isnumeric(SecondRecord)=0 then cast(FirstRecord as int) else cast(SecondRecord as int) end,
		SubscriberID,
		logtime
	into #V2 -- drop table #V2
	from (
	   SELECT DISTINCT
			SubscriberID = CRCS.iID_Souscripteur,
			FirstRecord = CRCS.iID_RepresentantOriginal,
			SecondRecord = CRC.iID_RepresentantCible,
			logtime = CR.dDate_Statut
		FROM tblCONV_ChangementsRepresentants CR
		JOIN tblCONV_ChangementsRepresentantsCibles CRC ON cr.iID_ChangementRepresentant = CRC.iID_ChangementRepresentant
		JOIN tblCONV_ChangementsRepresentantsCiblesSouscripteurs CRCS ON CRC.iID_ChangementRepresentantCible = CRCS.iID_ChangementRepresentantCible
		WHERE 
			ISNULL(CRCS.iID_RepresentantOriginal, '') <> ''
			AND ISNULL(crc.iID_RepresentantCible, '') <> ''
			AND CR.iID_Statut = 3 -- Exécuté

		) V1
	ORDER by SubscriberID, LogTime
		

	UPDATE #V2 SET 	OldRepID = NewRepID WHERE OldRepID = -1

	-- Transformer les info en plage de date et retenir ceux qui était associé en date demandée
	SELECT *
	INTO #hist_Rep_sousc -- drop table #hist_Rep_sousc
	from (		
		SELECT 
			subscriberid = isnull(v_deb.subscriberid, v_fin.subscriberid),
			RepID = isnull(V_deb.NewRepID,V_fin.OldRepID),
			Debut = isnull(v_deb.logtime,'1900-01-01'),
			Fin = v_fin.logtime 
		from 
			#V2 v_fin
			LEFT JOIN #V2 V_Deb ON v_deb.subscriberID = V_Fin.SubscriberID  AND v_deb.RangRep = V_Fin.RangRep - 1 -- AND v_deb.logtime < V_Fin.logtime AND V_Fin.oldRepID = V_Deb.NewRepID

		union all
		
		select 
			v.subscriberID,
			RepID = NewRepID,
			Debut =  v3.logtime,
			Fin = '3000-01-01' 
		from #V2 v
		JOIN (
			SELECT 
				subscriberID, 
				logtime = max(logTime)
			FROM #V2
			group by subscriberID
			) v3 ON v.subscriberID = v3.subscriberID	AND v.logtime = v3.logtime
		
		) Q

		
	INSERT INTO #hist_Rep_sousc
	SELECT distinct
		s.SubscriberID,
		s.RepID,
		debut = '1900-01-01',
		fin = '9999-12-31'
	from Un_Subscriber s
	where s.SubscriberID NOT IN (			
					SELECT SubscriberID
					from #hist_Rep_sousc		
								)		



		SELECT * 
		INTO #tUnite_T_IBEC
		FROM fntREPR_ObtenirUniteConvT (1) t		

		--DROP TABLE #tmpPlanActif_Debut
		SELECT 
			C.BeneficiaryID
			,C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,dtFirstDeposit = MIN(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit))
			,Cotisation = SUM(ISNULL(EPG.Cotisation,0))
			,Fee = SUM(ISNULL(EPG.Fee,0))
		INTO #tmpPlanActif_Debut
		FROM Un_Convention c
		JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtStartDate, NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('REE','TRA')
		JOIN Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
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
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
		GROUP BY C.BeneficiaryID
			,C.SubscriberID
			,c.ConventionID 
			,rr.vcDescription


	--	SELECT * FROM #tmpPlanActif_Debut
		--DROP TABLE #PlanActif_Debut



		SELECT DISTINCT
			 PA.BeneficiaryID
			,PA.SubscriberID
			,Regime = rr.vcDescription
			,PA.ConventionID
			--,DateRIEstimé = MIN(dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust))
			,PA.dtFirstDeposit
			,PA.Cotisation
			,PA.Fee
			,EstBenefAdmissibleDebut =		CASE 
											WHEN p.PlanTypeID = 'COL' AND c.YearQualif <= year(@dtStartDate) THEN c.BeneficiaryID 
											WHEN p.PlanTypeID = 'IND' AND dbo.fn_Mo_Age(hb.BirthDate,@dtStartDate) >= 16 THEN PA.BeneficiaryID
											ELSE NULL END

		INTO #PlanActif_Debut
		FROM #tmpPlanActif_Debut PA
		JOIN UN_CONVENTION C ON C.ConventionID = PA.ConventionID
		JOIN Mo_Human hb ON hb.HumanID = C.BeneficiaryID
		JOIN Un_Unit u ON U.ConventionID = PA.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime -- select * from un_plan


	--	SELECT * from #PlanActif_Debut where BeneficiaryID = 226886
	--	RETURN


		--DROP TABLE #tmpPlanActif_Periode
		SELECT 
			C.BeneficiaryID
			,C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,dtFirstDeposit = MIN(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit))
		INTO #tmpPlanActif_Periode
		FROM Un_Convention c
		JOIN Mo_Human hb on hb.HumanID = c.BeneficiaryID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN Un_Unit u ON c.ConventionID = u.ConventionID
		LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
		WHERE (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
		GROUP BY C.BeneficiaryID
			,C.SubscriberID
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


		--DROP TABLE #tmpPlanActif_Fin
		SELECT 
			C.BeneficiaryID
			,C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,dtFirstDeposit = MIN(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit))
			,Cotisation = SUM(ISNULL(EPG.Cotisation,0))
			,Fee = SUM(ISNULL(EPG.Fee,0))
		INTO #tmpPlanActif_Fin
		FROM Un_Convention c
		JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtEndDate, NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('REE','TRA')
		JOIN Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
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
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
		GROUP BY C.BeneficiaryID
			,C.SubscriberID
			,c.ConventionID 
			,rr.vcDescription


		
		--DROP TABLE #PlanActif_Fin
		SELECT DISTINCT
			 PA.BeneficiaryID
			,PA.SubscriberID
			,Regime = rr.vcDescription
			,PA.ConventionID
			,PA.dtFirstDeposit
			,PA.Cotisation
			,PA.Fee
			,EstBenefAdmissibleFin =		CASE 
											WHEN p.PlanTypeID = 'COL' AND c.YearQualif <= year(@dtEndDate) THEN PA.BeneficiaryID 
											WHEN p.PlanTypeID = 'IND' AND dbo.fn_Mo_Age(hb.BirthDate,@dtEndDate) >= 16 THEN PA.BeneficiaryID
											ELSE NULL END
		INTO #PlanActif_Fin
		FROM #tmpPlanActif_Fin PA
		JOIN UN_CONVENTION C ON C.ConventionID = PA.ConventionID
		JOIN Mo_Human HB on HB.HumanID = C.BeneficiaryID
		JOIN Un_Unit u ON U.ConventionID = PA.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		WHERE (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)


		--SELECT * FROM #PlanActif_Fin


		SELECT 
			C.BeneficiaryID
			,C.SubscriberID
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
		GROUP by C.BeneficiaryID
			,C.SubscriberID
			,c.ConventionID,RES.DateResil,rr.vcDescription
		HAVING SUM(u.UnitQty + ISNULL(urApresFin.QteRES,0)) = 0

		--SELECT * from #PlanResil


		SELECT DISTINCT
			C.BeneficiaryID
			,C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,DateFRM_PAE = css.startdate
		INTO #tmpPlanFRM_PAE_Periode -- drop table #tmpPlanFRM_PAE_Periode
		FROM Un_Convention c
		JOIN (
			SELECT DISTINCT s.ConventionID
			FROM Un_Scholarship S
			join Un_Convention c on c.ConventionID = s.ConventionID
			JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = S.ScholarshipID
			JOIN Un_Oper O ON O.OperID = SP.OperID
			LEFT JOIN Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
			LEFT JOIN Un_OperCancelation oc2 on o.OperID = oc2.OperID	
			WHERE 1=1
				AND oc1.OperSourceID is NULL
				AND oc2.OperID is NULL
				--and c.ConventionNo = 'R-20061201008'
			)pae on pae.ConventionID = c.ConventionID
		
		JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtEndDate, NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('FRM')
		LEFT JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtStartDate, NULL) cssDebut on cssDebut.ConventionID = c.ConventionID AND cssDebut.ConventionStateID IN ('FRM')
		--LEFT JOIN (
		--	SELECT ConventionID
		--	FROM dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtStartDate, NULL) 
		--	WHERE ConventionStateID IN ('FRM')
		--	) cssDebut on cssDebut.ConventionID = c.ConventionID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	
		WHERE 1=1
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
			AND cssDebut.conventionid IS NULL-- n'est pas déjà fermé au debut
			AND css.startdate BETWEEN @dtStartDate AND @dtEndDate -- fermé pendant la période
			--AND o.OperDate BETWEEN @dtStartDate AND @dtEndDate
			--and c.ConventionNo = 'R-20061201008'

			

		--SELECT * FROM #tmpPlanFRM_PAE_Periode


		SELECT DISTINCT
			C.BeneficiaryID
			,C.SubscriberID
			,Regime = rr.vcDescription
			,C.ConventionID
			,DateFRM = css.startdate
		INTO #tmpPlanFRMautre_Periode
		FROM Un_Convention c
		JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtEndDate, NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('FRM')
		LEFT JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtStartDate, NULL) cssDebut ON CSS.ConventionID = c.ConventionID AND cssDebut.ConventionStateID IN ('FRM')
		JOIN Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		LEFT JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		LEFT JOIN Un_Oper O ON O.OperID = CT.OperID AND o.operdate <= @dtEndDate
		LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
		LEFT JOIN #PlanResil R ON R.ConventionID = C.ConventionID AND R.DateResil BETWEEN  @dtStartDate AND @dtEndDate
		LEFT JOIN #tmpPlanFRM_PAE_Periode FP ON FP.ConventionID = C.ConventionID
		WHERE 1=1
			AND (RR.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)
			AND css.startdate BETWEEN @dtStartDate AND @dtEndDate
			AND ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') <= @dtEndDate
			AND R.ConventionID IS NULL -- N'EST PAS FERMÉ POUR CAUSE DE RES/OUT
			AND FP.ConventionID IS NULL -- N'EST PAS FERMÉ POUR CAUSE DE PAE
			AND cssDebut.conventionid is NULL-- n'est pas déjà fermé au debut
			



	SELECT DISTINCT
		Du = @dtStartDate
		,Au = @dtEndDate
		,RepID = HRS.Repid
		,R.RepCode
		,RepNom = HR.FirstName + ' ' + HR.LastName
		,Directeur = HBOSS.FirstName + ' ' + HBOSS.LastName
		,RegimeSelectionne = @NomRegime
		,Regime
		,V.BeneficiaryID
		,BeneficiaryPrenom = HB.FirstName
		,BeneficiaryNom = HB.LastName
		,BeneficiaryID_Debut = MAX(BeneficiaryID_Debut)
		,EstBenefAdmissibleDebut = SUM(EstBenefAdmissibleDebut)
		,NbPlansActifsDebut = SUM(NbPlansActifsDebut)
		,NbPlansAvantAdmissibiliteDebut = SUM(NbPlansAvantAdmissibiliteDebut)
		,NbPlansApresAdmissibiliteDebut = SUM(NbPlansApresAdmissibiliteDebut)
		,NbPlansActifsDepuisDebut = SUM(NbPlansActifsDepuisDebut)
		,NbPlansResOUTCompleteDepuisDebut = SUM(NbPlansResOUTCompleteDepuisDebut)
		,NbPlansFermePAE_Periode = SUM(NbPlansFermePAE_Periode)
		,NbPlansFermeAutreDepuisDebut = SUM(NbPlansFermeAutreDepuisDebut)
		--,EstBenefAdmissibleFin = SUM(EstBenefAdmissibleFin)
		,NbPlansActifsFin = SUM(NbPlansActifsFin)
		,NbPlansAvantAdmissibiliteFin = SUM(NbPlansAvantAdmissibiliteFin)
		,NbPlansApresAdmissibiliteFin = SUM(NbPlansApresAdmissibiliteFin)
		,BeneficiaryID_Fin = MAX(BeneficiaryID_Fin)
	INTO #FINAL
	FROM Un_Beneficiary B
	JOIN Mo_Human HB ON HB.HumanID = B.BeneficiaryID
	JOIN (

		SELECT
			 BeneficiaryID
			,SubscriberID
			,Regime
			,BeneficiaryID_Debut = BeneficiaryID
			,BeneficiaryID_Fin = NULL
			,EstBenefAdmissibleDebut = MAX(EstBenefAdmissibleDebut)
			,NbPlansActifsDebut = COUNT(DISTINCT ConventionID)
			,NbPlansAvantAdmissibiliteDebut = COUNT(DISTINCT CASE WHEN EstBenefAdmissibleDebut IS NULL THEN ConventionID ELSE NULL END )
			,NbPlansApresAdmissibiliteDebut = COUNT(DISTINCT CASE WHEN EstBenefAdmissibleDebut IS NOT NULL THEN ConventionID ELSE NULL END )
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermePAE_Periode = 0
			,NbPlansFermeAutreDepuisDebut = 0
			--,EstBenefAdmissibleFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantAdmissibiliteFin = 0
			,NbPlansApresAdmissibiliteFin = 0
		FROM #PlanActif_Debut
		GROUP BY BeneficiaryID
			,SubscriberID
			,Regime

		UNION ALL

		SELECT 
			BeneficiaryID
			,SubscriberID
			,Regime
			,BeneficiaryID_Debut = NULL
			,BeneficiaryID_Fin = NULL
			,EstBenefAdmissibleDebut = 0
			,NbPlansActifsDebut = 0
			,NbPlansAvantAdmissibiliteDebut = 0
			,NbPlansApresAdmissibiliteDebut = 0
			,NbPlansActifsDepuisDebut = COUNT(DISTINCT ConventionID)
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermePAE_Periode = 0
			,NbPlansFermeAutreDepuisDebut = 0
			--,EstBenefAdmissibleFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantAdmissibiliteFin = 0
			,NbPlansApresAdmissibiliteFin = 0
		FROM #tmpPlanActif_Periode
		GROUP BY BeneficiaryID
			,SubscriberID
			,Regime

		UNION ALL

		SELECT 
			 BeneficiaryID
			,SubscriberID
			,Regime
			,BeneficiaryID_Debut = NULL
			,BeneficiaryID_Fin = NULL
			,EstBenefAdmissibleDebut = 0
			,NbPlansActifsDebut = 0
			,NbPlansAvantAdmissibiliteDebut = 0
			,NbPlansApresAdmissibiliteDebut = 0
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = COUNT(DISTINCT ConventionID)
			,NbPlansFermePAE_Periode = 0
			,NbPlansFermeAutreDepuisDebut = 0
			--,NbPlansRinCompletDepuisDebut = 0
			--,EstBenefAdmissibleFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantAdmissibiliteFin = 0
			,NbPlansApresAdmissibiliteFin = 0
			
		FROM #PlanResil
		WHERE DateResil BETWEEN @dtStartDate AND @dtEndDate
		GROUP BY BeneficiaryID
			,SubscriberID
			,Regime

		UNION ALL

		SELECT 
			 BeneficiaryID
			,SubscriberID
			,Regime
			,BeneficiaryID_Debut = NULL
			,BeneficiaryID_Fin = NULL
			,EstBenefAdmissibleDebut = 0
			,NbPlansActifsDebut = 0
			,NbPlansAvantAdmissibiliteDebut = 0
			,NbPlansApresAdmissibiliteDebut = 0
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermePAE_Periode = COUNT(DISTINCT ConventionID)
			,NbPlansFermeAutreDepuisDebut = 0
			--,EstBenefAdmissibleFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantAdmissibiliteFin = 0
			,NbPlansApresAdmissibiliteFin = 0
			
		FROM #tmpPlanFRM_PAE_Periode
		WHERE DateFRM_PAE BETWEEN @dtStartDate AND @dtEndDate
		GROUP BY BeneficiaryID
			,SubscriberID
			,Regime

		UNION ALL

		SELECT 
			 BeneficiaryID
			,SubscriberID
			,Regime
			,BeneficiaryID_Debut = NULL
			,BeneficiaryID_Fin = NULL
			,EstBenefAdmissibleDebut = 0
			,NbPlansActifsDebut = 0
			,NbPlansAvantAdmissibiliteDebut = 0
			,NbPlansApresAdmissibiliteDebut = 0
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermePAE_Periode = 0
			,NbPlansFermeAutreDepuisDebut = COUNT(DISTINCT ConventionID)
			--,NbPlansRinCompletDepuisDebut = 0
		--	,EstBenefAdmissibleFin = NULL
			,NbPlansActifsFin = 0
			,NbPlansAvantAdmissibiliteFin = 0
			,NbPlansApresAdmissibiliteFin = 0

			
		FROM #tmpPlanFRMautre_Periode
		GROUP BY BeneficiaryID
			,SubscriberID
			,Regime

		UNION ALL
		--DECLARE @dtStartDate DATETIME = '2018-01-01'
		--DECLARE @dtEndDate DATETIME = '2018-04-30'		
		SELECT
			 BeneficiaryID
			,SubscriberID
			,Regime
			,BeneficiaryID_Debut = NULL
			,BeneficiaryID_Fin = BeneficiaryID
			,EstBenefAdmissibleDebut = 0
			,NbPlansActifsDebut = 0
			,NbPlansAvantAdmissibiliteDebut = 0
			,NbPlansApresAdmissibiliteDebut = 0
			,NbPlansActifsDepuisDebut = 0
			,NbPlansResOUTCompleteDepuisDebut = 0
			,NbPlansFermePAE_Periode = 0
			,NbPlansFermeAutreDepuisDebut = 0
			--,EstBenefAdmissibleFin = MAX(EstBenefAdmissibleFin)
			,NbPlansActifsFin = COUNT(DISTINCT ConventionID)
			,NbPlansAvantAdmissibiliteFin = COUNT(DISTINCT CASE WHEN EstBenefAdmissibleFin IS NULL THEN ConventionID ELSE NULL END )
			,NbPlansApresAdmissibiliteFin = COUNT(DISTINCT CASE WHEN EstBenefAdmissiblefin IS NOT NULL THEN ConventionID ELSE NULL END )
		FROM #PlanActif_Fin
		GROUP BY BeneficiaryID
			,SubscriberID
			,Regime
	)V ON V.BeneficiaryID = B.BeneficiaryID

	LEFT JOIN #hist_Rep_sousc HRS on HRS.SubscriberID = V.SubscriberID AND @dtEndDate BETWEEN HRS.debut and HRS.fin
	LEFT JOIN Mo_Human HR ON HR.HumanID	= HRS.REPID
	LEFT JOIN Un_Rep R ON R.RepID =  HRS.REPID
	LEFT JOIN (
		SELECT
			RB.RepID,
			BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
		FROM 
			Un_RepBossHist RB
			JOIN (
				SELECT
					RepID,
					RepBossPct = MAX(RepBossPct)
				FROM 
					Un_RepBossHist RB
				WHERE 
					RepRoleID = 'DIR'
					AND StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10)
					AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10)) 
				GROUP BY
						RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10)
				AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10))
			GROUP BY
				RB.RepID
		)BR ON BR.RepID = HRS.REPID
	LEFT JOIN Mo_Human HBOSS ON HBOSS.HumanID = BR.BossID

	WHERE 1=1
		AND (R.RepID =	 @RepID  OR @RepID = 0)
		AND (BR.BossID = @BossID OR @BossID = 0)

	GROUP BY 

		HRS.Repid
		,R.RepCode
		,HR.FirstName + ' ' + HR.LastName
		,HBOSS.FirstName + ' ' + HBOSS.LastName,

		 V.BeneficiaryID
		,HB.FirstName
		,HB.LastName
		,Regime
	ORDER BY V.BeneficiaryID
	
	--SELECT *
	--INTO #FINAL_NOREP
	--FROM #FINAL		

	SELECT *
	INTO tblTEMP_RapportStats_S150_EvolutionNombreBeneficiaires
	FROM #FINAL

	-- Table du détaillé
	--SELECT * from tblTEMP_RapportStats_S150_EvolutionNombreBeneficiaires 



--	RETURN

	IF @Regroupement = 'D'
	BEGIN

		CREATE TABLE #tOutPut (f1 varchar(2000))

		INSERT #tOutPut
		EXEC('exec master..xp_cmdshell ''del '+@vcNomFichier+'''')

		INSERT #tOutPut
		EXEC SP_ExportTableToExcelWithColumns 'UnivBase', 'tblTEMP_RapportStats_S150_EvolutionNombreBeneficiaires', @vcNomFichier, 'RAW', 1

		IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'tblTEMP_RapportStats_S150_EvolutionNombreBeneficiaires')
			DROP TABLE tblTEMP_RapportStats_S150_EvolutionNombreBeneficiaires	

		DROP TABLE #tOutPut
	END



	SELECT 

		Directeur
		,RepID
		,RepCode
		,RepNom
		,NbBeneficiaireDebut = COUNT(DISTINCT BeneficiaryID_Debut)
		,NbBeneficiairesAdmissiblesPAE = COUNT(DISTINCT EstBenefAdmissibleDebut)
		,NbPlansActifsDebut = SUM(NbPlansActifsDebut)
		,NbPlansAvantAdmissibiliteDebut = SUM(NbPlansAvantAdmissibiliteDebut)
		,NbPlansApresAdmissibiliteDebut = SUM(NbPlansApresAdmissibiliteDebut)
		,NbPlansActifsDepuisDebut = SUM(NbPlansActifsDepuisDebut)
		,NbPlansResOUTCompleteDepuisDebut = SUM(NbPlansResOUTCompleteDepuisDebut)
		,NbPlansFermePAE_Periode = SUM(NbPlansFermePAE_Periode)
		,NbPlansFermeAutreDepuisDebut = SUM(NbPlansFermeAutreDepuisDebut)
		,NbPlansActifsFin = SUM(NbPlansActifsFin)
		,NbPlansAvantAdmissibiliteFin = SUM(NbPlansAvantAdmissibiliteFin)
		,NbPlansApresAdmissibiliteFin = SUM(NbPlansApresAdmissibiliteFin)
		,NbBeneficiaireFin = COUNT(DISTINCT BeneficiaryID_Fin)
		,vcNomFichier = @vcNomFichier
		,Regroupement = @Regroupement

	INTO #PREFINAL
	FROM #FINAL F
	LEFT JOIN tblCONV_RegroupementsRegimes RR ON RR.vcDescription = F.Regime
	GROUP BY 
		Directeur
		,RepID
		,RepCode
		,RepNom
	ORDER BY 
		Directeur
		,RepID
		,RepCode
		,RepNom

	SELECT * from #PREFINAL



	--set ARITHABORT off

	END