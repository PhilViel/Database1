/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psGENE_RapportStats_S130_StatistiqueBEC
Nom du service		: Statistique BEC
But 				: JIRA PROD-9961 : Obtenir les statistique de BEC 

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						

Exemple d’appel		:	EXECUTE psGENE_RapportStats_S130_StatistiqueBEC '2018-01-01', '2018-01-31', 0, 436381
						EXECUTE psGENE_RapportStats_S130_StatistiqueBEC '2018-01-01', '2018-01-31', 149573, 0
						EXECUTE psGENE_RapportStats_S130_StatistiqueBEC '2018-07-01', '2018-07-31', 0, 0
				

Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------- -----------------------------------------	------------
		2018-08-15		Donald Huppé		Création du service				

*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStats_S130_StatistiqueBEC]
    (
		@dtStartDate datetime -- = '2018-01-01'
		,@dtEndDate datetime --= '2018-07-31'
		,@RepID INT	= 0
		,@BossID INT = 0
    )
AS 
BEGIN

--set ARITHABORT ON


		--IF OBJECT_ID('tempdb..#tUnite_T_IBEC')				IS NOT NULL DROP TABLE #tUnite_T_IBEC

		--IF OBJECT_ID('tempdb..#V2')							IS NOT NULL DROP TABLE #V2
		--IF OBJECT_ID('tempdb..#hist_Rep_sousc')				IS NOT NULL DROP TABLE #hist_Rep_sousc
		--IF OBJECT_ID('tempdb..#ratio')						IS NOT NULL DROP TABLE #ratio

		--IF OBJECT_ID('tempdb..#tmpVariationBEC')			IS NOT NULL DROP TABLE #tmpVariationBEC

		--IF OBJECT_ID('tempdb..#EPG')						IS NOT NULL DROP TABLE #EPG
		--IF OBJECT_ID('tempdb..#SCEE')						IS NOT NULL DROP TABLE #SCEE
		--IF OBJECT_ID('tempdb..#IQEE')						IS NOT NULL DROP TABLE #IQEE

		--IF OBJECT_ID('tempdb..#tmpPlanActif_Debut')			IS NOT NULL DROP TABLE #tmpPlanActif_Debut
		--IF OBJECT_ID('tempdb..#PlanActif_Debut')			IS NOT NULL DROP TABLE #PlanActif_Debut
		--IF OBJECT_ID('tempdb..#tmpPlanActif_Periode')		IS NOT NULL DROP TABLE #tmpPlanActif_Periode
		--IF OBJECT_ID('tempdb..#tmpPlan_RINComplet_Periode') IS NOT NULL DROP TABLE #tmpPlan_RINComplet_Periode
		--IF OBJECT_ID('tempdb..#tmpPlanActif_Fin')			IS NOT NULL DROP TABLE #tmpPlanActif_Fin
		--IF OBJECT_ID('tempdb..#PlanActif_Fin')				IS NOT NULL DROP TABLE #PlanActif_Fin
		
		--IF OBJECT_ID('tempdb..#tmpPlanFRMautre_Periode')	IS NOT NULL DROP TABLE #tmpPlanFRMautre_Periode
		--IF OBJECT_ID('tempdb..#FINAL')						IS NOT NULL DROP TABLE #FINAL




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



	SELECT 
		RatioNbBeneficiaireAvEchBec = 1.0 * COUNT(DISTINCT BeneficiaryID_AvecSoldeBEC) / COUNT(DISTINCT BeneficiaryID)
	INTO #ratio
	FROM (
		SELECT
			--HRS.RepID
			C.BeneficiaryID
			,BeneficiaryID_AvecSoldeBEC = CASE WHEN ISNULL(BEC.SoldeBECFin,0) > 0 THEN c.BeneficiaryID ELSE NULL END
		FROM Un_Convention c
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		JOIN Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Subscriber S on S.SubscriberID = c.SubscriberID
		LEFT JOIN (
			SELECT CE.ConventionID, SoldeBECFin =  SUM(CE.fCLB)
			FROM un_cesp CE
			JOIN Un_Oper o on o.OperID = CE.OperID
			WHERE O.OperDate <= @dtEndDate
			GROUP BY CE.ConventionID
			HAVING SUM(CE.fCLB) > 0
			)BEC ON BEC.ConventionID = C.ConventionID
		JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtEndDate, NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('REE','TRA') 
		GROUP BY
			--HRS.RepID, 
			C.BeneficiaryID,
			BEC.SoldeBECFin
		HAVING MIN(dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust)) > @dtEndDate 
	)V


	SELECT * 
	INTO #tUnite_T_IBEC
	FROM fntREPR_ObtenirUniteConvT (1) t		


	SELECT 
		c.SubscriberID,
		c.BeneficiaryID,
		c.ConventionID,
		c.ConventionNo,
		SoldeBecDateDebut = sum(SoldeBecDateDebut),
		SoldeBecDateFin = sum(SoldeBecDateFin)
	INTO #tmpVariationBEC
	FROM (
		SELECT 
			CE.ConventionID, 
			SoldeBecDateDebut =	SUM(CASE WHEN o.OperDate <= @dtStartDate THEN CE.fCLB ELSE 0 END) ,
			SoldeBecDateFin =	SUM(CE.fCLB)
		FROM Un_CESP CE
		JOIN Un_Oper O ON O.OperID = CE.OperID
		WHERE O.OperDate <= @dtEndDate
		GROUP BY CE.ConventionID
		)V
	JOIN Un_Convention C on C.ConventionID = V.ConventionID
	GROUP BY
		c.SubscriberID,
		c.BeneficiaryID,
		c.ConventionID,
		c.ConventionNo
	HAVING 1=1
		AND sum(SoldeBecDateDebut) <> sum(SoldeBecDateFin)

	CREATE INDEX #IND1 ON #tmpVariationBEC (ConventionID)

	SELECT 
		u1.ConventionID
		,SoldeCotisation_Fin = SUM(CT1.Cotisation + CT1.Fee)
	INTO #EPG
	FROM Un_Cotisation CT1
	JOIN Un_Oper O1 ON O1.OperID = CT1.OperID
	JOIN Un_Unit U1 on U1.UnitID = CT1.UnitID
	JOIN #tmpVariationBEC t on t.ConventionID = U1.ConventionID
	WHERE O1.OperDate <= @dtEndDate
	GROUP BY u1.ConventionID

	SELECT CE.ConventionID, 
		SoldeBEC_Fin = SUM(CE.fCLB),
		SoldeSCEE_Fin = SUM(CE.fCESG + CE.fACESG),
		OpSubBecNouvellesVentes_TMP = SUM(CASE WHEN O.OperDate BETWEEN @dtStartDate AND @dtEndDate AND O.OperTypeID = 'SUB' THEN CE.fCLB ELSE 0 END),
		OpPaeBecTousPlans_TMP = SUM(CASE WHEN O.OperDate BETWEEN @dtStartDate AND @dtEndDate AND O.OperTypeID = 'PAE' THEN CE.fCLB ELSE 0 END),
		AutresOpBecTousPlans_TMP = SUM(CASE WHEN O.OperDate BETWEEN @dtStartDate AND @dtEndDate AND O.OperTypeID NOT IN ('SUB','PAE') THEN CE.fCLB ELSE 0 END)
	INTO #SCEE
	FROM Un_CESP CE
	JOIN #tmpVariationBEC t on t.ConventionID = CE.ConventionID
	JOIN Un_Oper O ON O.OperID = CE.OperID
	WHERE O.OperDate <= @dtEndDate
	GROUP BY CE.ConventionID

	SELECT	
		CO.ConventionID
		,SoldeIQEE_Fin = SUM(CASE WHEN CO.ConventionOperTypeID IN ('CBQ','MMQ') THEN CO.ConventionOperAmount ELSE 0 END)
		,SoldeRendement_Fin = SUM(CASE WHEN CO.ConventionOperTypeID IN ('IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','MIM','IQI','ITR') THEN CO.ConventionOperAmount ELSE 0 END)
	INTO #IQEE
	FROM Un_ConventionOper CO
	JOIN #tmpVariationBEC t on t.ConventionID = CO.ConventionID
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE O.OperDate <= @dtEndDate
	AND CO.ConventionOperTypeID IN ( 'CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','MIM','IQI','ITR')
	GROUP BY CO.ConventionID



	SELECT 

		C.SubscriberID
		,C.BeneficiaryID
		,RepID = HRS.Repid
		,R.RepCode
		,RepNom = HR.FirstName + ' ' + HR.LastName
		,Directeur = HBOSS.FirstName + ' ' + HBOSS.LastName
		,Regime = rr.vcDescription
		,bec.SoldeBecDateDebut
		,bec.SoldeBecDateFin
		,OpSubBecNouvellesVentes =	CASE WHEN MIN(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)) BETWEEN @dtStartDate AND @dtEndDate THEN ISNULL(SCEE.OpSubBecNouvellesVentes_TMP,0) ELSE 0 END
		,OpSubBecAnciennesVentes =	CASE WHEN MIN(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)) < @dtStartDate						 THEN ISNULL(SCEE.OpSubBecNouvellesVentes_TMP,0) ELSE 0 END
		,OpPaeBecTousPlans =		ISNULL(SCEE.OpPaeBecTousPlans_TMP,0)
		,AutresOpBecTousPlans =		ISNULL(SCEE.AutresOpBecTousPlans_TMP,0)
				
		,SoldeBEC_Fin =		ISNULL(SCEE.SoldeBEC_Fin,0)
		,SoldeCotisation_Fin = ISNULL(SoldeCotisation_Fin,0)
		,SoldeSubvention_Fin =	ISNULL(SCEE.SoldeSCEE_Fin,0) + ISNULL(IQEE.SoldeIQEE_Fin,0)
		,SoldeRendement_Fin = ISNULL(SoldeRendement_Fin,0)
		,NbNouveauxSouscripteurBec = CASE WHEN bec.SoldeBecDateDebut = 0 AND bec.SoldeBecDateFin > 0 THEN 1 /*C.SubscriberID*/ ELSE 0 END
		,NbNouveauxBeneficiaireBec = CASE WHEN bec.SoldeBecDateDebut = 0 AND bec.SoldeBecDateFin > 0 THEN 1 /*C.BeneficiaryID*/ ELSE 0 END

		
	INTO #tmpPlanActif_fin
	FROM Un_Convention c
	JOIN Un_Subscriber S on S.SubscriberID = c.SubscriberID
	JOIN #tmpVariationBEC bec on c.ConventionID = bec.ConventionID
	JOIN (
		SELECT 
			SubscriberID,
			BeneficiaryID,
			SoldeBecDateDebut = sum(SoldeBecDateDebut),
			SoldeBecDateFin = sum(SoldeBecDateFin)
		FROM #tmpVariationBEC
		GROUP BY
			SubscriberID,
			BeneficiaryID
		)bec2 on bec2.SubscriberID = c.SubscriberID AND bec2.BeneficiaryID = c.BeneficiaryID
	JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtEndDate, NULL) CSS ON CSS.ConventionID = c.ConventionID 
	JOIN Un_Unit u ON c.ConventionID = u.ConventionID
	JOIN Un_Modal m ON u.ModalID = m.ModalID
	JOIN Un_Plan p ON c.PlanID = p.PlanID
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	LEFT JOIN #EPG EPG ON EPG.ConventionID = c.ConventionID
	LEFT JOIN #SCEE SCEE ON SCEE.ConventionID = C.ConventionID
	LEFT JOIN #IQEE IQEE on IQEE.ConventionID = c.ConventionID
	LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
	LEFT JOIN #hist_Rep_sousc HRS on HRS.SubscriberID = c.SubscriberID AND @dtEndDate BETWEEN HRS.debut and HRS.fin
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
		AND ISNULL(
				ISNULL(u.dtFirstDeposit,t.dtFirstDeposit)
				,'9999-12-31'
				) < @dtEndDate 
		AND ( HRS.RepID =			@RepID	OR	@RepID = 0 )
		AND ( BR.BossID =			@BossID OR  @BossID = 0)	


	GROUP BY 
		C.SubscriberID
		,C.BeneficiaryID
		,R.RepID
		,R.RepCode
		,HR.FirstName
		,HR.LastName
		,HBOSS.FirstName
		,HBOSS.LastName
		,S.repID
		,HRS.Repid
		--,c.ConventionID 
		--,C.ConventionNo
		,rr.vcDescription
		,bec.SoldeBecDateDebut
		,bec.SoldeBecDateFin
		,ISNULL(SCEE.SoldeBEC_Fin,0)
		,ISNULL(SCEE.SoldeSCEE_Fin,0)
		,ISNULL(IQEE.SoldeIQEE_Fin,0)
		,ISNULL(SoldeRendement_Fin,0)
		,ISNULL(SoldeCotisation_Fin,0)
		,ISNULL(SCEE.OpSubBecNouvellesVentes_TMP,0)
		,ISNULL(SCEE.OpPaeBecTousPlans_TMP,0)
		,ISNULL(SCEE.AutresOpBecTousPlans_TMP,0)


	SELECT t.*, r.RatioNbBeneficiaireAvEchBec
	FROM #tmpPlanActif_fin t
	JOIN #ratio r on 1=1	
	ORDER BY RepCode, OpSubBecNouvellesVentes DESC



--set ARITHABORT OFF

END