/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Nom                 :	psOPER_RapportVenteBruteEtNette
Description         :	Rapport des vente brute et nette
Valeurs de retours  :	Dataset de données

Note                :	
					2016-09-21	Donald Huppé	Création
					2018-09-07	Maxime Martel	JIRA MP-699 Ajout de OpertypeID COU

exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-01-25', 0, 'X-20140710039', 721785
exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-01-25', 0, 'X-20140710039', 721785
exec psOPER_RapportVenteBruteEtNette '2016-01-24', '2016-01-26', 0, 'X-20140710039', 721785
exec psOPER_RapportVenteBruteEtNette '2015-01-01', '2016-10-16', 0, 'X-20150826061', NULL
exec psOPER_RapportVenteBruteEtNette '2016-02-24', '2016-02-26', 545043, NULL, NULL
exec psOPER_RapportVenteBruteEtNette '2016-01-08', '2016-01-09',424870, NULL, NULL
exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-12-31',0, 'X-20160128063', NULL
exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-12-31',0, 'X-20150424003', NULL

exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-12-31',0, 'R-20081210049', NULL

exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-12-31',0, 'R-20060221021', NULL -- TIN TIO

exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-12-31',0, 'T-20161101004', NULL

exec psOPER_RapportVenteBruteEtNette '2016-03-19', '2016-03-25',0, 'X-20150424003', NULL

exec psOPER_RapportVenteBruteEtNette '2015-03-19', '2016-12-25',0, 'X-20150424003', NULL -- 2 cpa LE MÊME JOUR ET 2 nSF LE MEME JOURS

exec psOPER_RapportVenteBruteEtNette '2016-09-20', '2016-09-22',0, 'U-20060927067', NULL -- 2 cpa LE MÊME JOUR ET 2 nSF LE MEME JOURS

exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-12-31',0, 'R-20051012009', NULL


exec psOPER_RapportVenteBruteEtNette '2016-10-01', '2016-10-31',149489

exec psOPER_RapportVenteBruteEtNette '2016-09-20', '2016-10-30',0, 'X-20160923023', NULL
exec psOPER_RapportVenteBruteEtNette '2016-11-01', '2016-11-30',0, 'R-20050930026', NULL
exec psOPER_RapportVenteBruteEtNette '2016-09-01', '2016-11-30',0, null, 740328, 0

exec psOPER_RapportVenteBruteEtNette '2016-09-01', '2016-11-30',0, 'U-20101006034', null, 0

exec psOPER_RapportVenteBruteEtNette '2016-09-01', '2016-11-30',0, 'X-20161024019', null, 0

exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-11-30',0, 'U-20160628001', null, 0

exec psOPER_RapportVenteBruteEtNette '2016-11-01', '2016-11-30',0, 'X-20160915067', null, 0

exec psOPER_RapportVenteBruteEtNette '2016-11-01', '2016-11-30',0, 'X-20161121106', null, 0

exec psOPER_RapportVenteBruteEtNette '1950-01-01', '2016-12-30',0, 'X-20160704115', null, 0

exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-11-30',0, 'X-20160704115', null, 0

exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-12-30',0, 'U-20101101029' , null, 0

exec psOPER_RapportVenteBruteEtNette '2015-12-01', '2016-05-30',0, 'U-20061219030' , null, 0

exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-05-01',0, 'U-20080318035' , null, 0

exec psOPER_RapportVenteBruteEtNette '2001-01-01', '2016-12-31',0, 'C-20010420026' , null, 0


exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-12-27',0, 'I-20160405004' , null, 0
exec psOPER_RapportVenteBruteEtNette '2016-01-01', '2016-12-27',0, 'I-20160401001' , null, 0

exec psOPER_RapportVenteBruteEtNette '2015-01-01', '2016-12-31',0,NULL,NULL
exec psOPER_RapportVenteBruteEtNette '2017-01-01', '2017-05-19',0,NULL,NULL


exec psOPER_RapportVenteBruteEtNette '2011-04-30', '2011-05-27',0, 'x-20110318021' , null, 0

SrvName=SRVSQL20&DbName=UnivBase_donald&dtDateFrom=2016-10-24 00:00:00&dtDateTo=2016-10-30 00:00:00&LoginNameID=UNIVERSITAS\pagirard&Rightid=171&IncludeAll=1&IncludeActifInactif=0&RepID=149891&ConventionNo:isnull=true&UnitID:isnull=true
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportVenteBruteEtNette] (
	@dtDateFrom DATETIME -- Date de fin de l'intervalle des opérations
	,@dtDateTo DATETIME -- Date de fin de l'intervalle des opérations
	,@RepID INT
	,@ConventionNo varchar(30) = NULL
	,@UnitID INT = NULL
	,@iID_Regroupement_Regime INT = 0
	)
AS
BEGIN



set ARITHABORT ON

	PRINT 'DÉBUT : ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

	/*
	Retrouver pour tous les gr. d'unité, la date du 1er dépot non renversé

	-- ##### Ne pas mettre de clause where sur le OperDate ##### car si un gr d'untié a juste des annulation depuis le début alors il ne sortira pas

	*/

			--SELECT 
			--	ct.UnitID, 
			--	MIN_OperDate = MIN(o.OperDate)
			--INTO #TBLMIN_OperDate
			--FROM 
			--	Un_Cotisation CT
			--	JOIN Un_Oper O ON O.OperID = CT.OperID
			--	LEFT JOIN Un_OperCancelation OC11 ON OC11.OperSourceID = O.OperID
			--	LEFT JOIN Un_OperCancelation OC21 ON OC21.OperID = O.OperID
			--WHERE 1=1
			--	AND CharIndex(O.OperTypeID, 'PRD,CPA,CHQ,RDI,TIN', 1) > 0 --o.OperTypeID IN ('PRD','CPA','CHQ','RDI','TIN')
			--	AND (oc11.OperSourceID IS NULL OR o.OperTypeID = 'CPA')
			--	AND oc21.OperID IS NULL
			--GROUP by ct.UnitID

			--CREATE INDEX #IND123 ON #TBLMIN_OperDate(UnitID,MIN_OperDate)

	SELECT 
		ct.UnitID, 
		md.MIN_OperDate,
		MIN_OperID = MIN(o.OperID)
	INTO #tblDate1erDepotNonRenverse -- drop table #tblDate1erDepotNonRenverse
	FROM 
		Un_Oper O
		JOIN Un_Cotisation CT ON CT.OperID = O.OperID
		--JOIN #TBLMIN_OperDate md on md.MIN_OperDate = o.OperDate and md.UnitID = ct.UnitID
		JOIN (
			SELECT 
				ct.UnitID, 
				MIN_OperDate = MIN(o.OperDate)
			FROM 
				Un_Oper O
				JOIN Un_Cotisation CT ON CT.OperID = O.OperID
				LEFT JOIN Un_OperCancelation OC11 ON OC11.OperSourceID = O.OperID
				LEFT JOIN Un_OperCancelation OC21 ON OC21.OperID = O.OperID
			WHERE 1=1
				AND CharIndex(O.OperTypeID, 'PRD,CPA,CHQ,RDI,TIN,COU', 1) > 0 --o.OperTypeID IN ('PRD','CPA','CHQ','RDI','TIN')
				AND (oc11.OperSourceID IS NULL OR o.OperTypeID = 'CPA')
				AND oc21.OperID IS NULL
			GROUP by ct.UnitID
			/*-- Ne pas faire ceci*/ --HAVING MIN(o.OperDate) >= @dtDateFrom -- Ne pas faire ceci
			) md on md.MIN_OperDate = o.OperDate and md.UnitID = ct.UnitID
		LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
		LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
	WHERE 1=1
		AND CharIndex(O.OperTypeID, 'PRD,CPA,CHQ,RDI,TIN,COU', 1) > 0 --o.OperTypeID IN ('PRD','CPA','CHQ','RDI','TIN')
		AND (oc1.OperSourceID IS NULL OR o.OperTypeID = 'CPA')
		AND oc2.OperID IS NULL
	GROUP by ct.UnitID,md.MIN_OperDate


	PRINT 'APRES #tblDate1erDepotNonRenverse : ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)
	--SELECT * FROM #tblDate1erDepotNonRenverse WHERE UNITID = 560371


	
	SELECT 
		ct.UnitID
		,o.OperDate
		,o.OperTypeID
		,Cancellee = case when oc1.OperSourceID is not NULL then 1 else 0 end
		,Cancellation = case when oc2.OperID is not NULL then 1 else 0 end
		--,MAXOperIDByOperTypeID = MAX(o.OperID)
		,MINOperIDByOperTypeID = MIN(o.OperID)
	into #MAXOperIDByOperTypeIDByDay
	from Un_Oper o
	join Un_Cotisation CT on o.OperID = CT.OperID
	LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
	LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
	where 
		o.OperDate BETWEEN @dtDateFrom and @dtDateTo
		AND (ct.Cotisation <> 0 OR ct.Fee <> 0)
	GROUP BY ct.UnitID, o.OperDate, o.OperTypeID
		,case when oc1.OperSourceID is not NULL then 1 else 0 end
		,case when oc2.OperID is not NULL then 1 else 0 end
	--HAVING COUNT(*) > 1

	--SELECT * FROM #MAXOperIDByOperTypeIDByDay WHERE UNITID = 560371

	PRINT 'APRES #MAXOperIDByOperTypeIDByDay : ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)


	select
		VV.UnitID, 
		VV.UnitModalHistoryID,
		mh.ModalID,
		StartDate = VV.StartDate --LEFT(CONVERT(VARCHAR, VV.StartDate, 120), 10)
		,EndDate = isnull(min(EndDate),'3000-12-31')
	INTO #tblModalhist
	from (	
		select
			mhDebut.UnitModalHistoryID, mhDebut.UnitID, StartDate = mhDebut.StartDate, EndDate = mhFin.StartDate
		from 
			Un_UnitModalHistory mhDebut
			left join Un_UnitModalHistory mhFin ON mhDebut.UnitID = mhFin.UnitID AND mhFin.StartDate >= mhDebut.StartDate  AND mhFin.UnitModalHistoryID > mhDebut.UnitModalHistoryID
		) VV
	join Un_UnitModalHistory mh ON vv.UnitModalHistoryID = mh.UnitModalHistoryID
	--where VV.UnitID = 696220
	group by 
		VV.UnitID,
		VV.UnitModalHistoryID,mh.ModalID,
		VV.StartDate


	PRINT 'APRES #tblModalhist : ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

	---NOUVELLES VENTES TFR
	select DISTINCT
		Section = '2-Nouvelles Ventes - AVEC TFR'
		,u.RepID
		,C.ConventionNo
		,U.UnitID
		,Date1ereOperFin = CAST(o.OperDate AS DATE)
		,o.OperID
		,QteUnite = U.UnitQty + ISNULL(UR.QTERES,0)
		,EpargeSouscrit =	
						CASE
						WHEN P.PlanTypeID = 'COL' THEN
							-- COLLECTIF		
							CAST(
								ROUND(
									  ROUND((U.UnitQty + ISNULL(UR.QTERES,0)) * m.PmtRate,2) * m.PmtQty -- Épargne et Frais souscrit total
									- ROUND((U.UnitQty + ISNULL(UR.QTERES,0)) * m.FeeByUnit,2)  -- moins les frais souscrit
									/*- ct.Fee*/
									,2)
							AS MONEY)
						ELSE
							-- INDIVIDUEL
							CT.Cotisation
						END
		,FraisSouscrit = 
						CASE
						WHEN P.PlanTypeID = 'COL' THEN
							(U.UnitQty + ISNULL(UR.QTERES,0)) * m.FeeByUnit - ct.Fee --les frais souscrit
						ELSE
							m.FeeByUnit - ct.Fee
						END
		,Comment = ''

	INTO #TFR
	FROM 
		Un_Cotisation CT
		JOIN Un_Unit U ON U.UnitID = CT.UnitID
		--JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Convention C ON U.ConventionID = C.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		join Un_Oper O ON O.OperID = CT.OperID
		JOIN (
			SELECT 
				u.UnitID
				,FirstOperID = MIN(o.OperID)
			from Un_Unit u
			JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = CT.OperID
			JOIN (
				SELECT 
					u.UnitID
					,OperDate = MIN(o.OperDate)
				FROM Un_Unit U
				JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = CT.OperID
				WHERE CharIndex(O.OperTypeID, 'PRD,CPA,CHQ,RDI,TIN,TFR,COU', 1) > 0 --O.OperTypeID IN ('PRD','CPA','CHQ','RDI','TIN','TFR')
				GROUP by 
					U.UnitID
				HAVING MIN(o.OperDate) BETWEEN @dtDateFrom and @dtDateTo
					)mo ON mo.UnitID = u.UnitID and o.OperDate = mo.OperDate
			WHERE CharIndex(O.OperTypeID, 'PRD,CPA,CHQ,RDI,TIN,TFR,COU', 1) > 0 --O.OperTypeID IN ('PRD','CPA','CHQ','RDI','TIN','TFR')
			GROUP BY u.UnitID
		)FO ON FO.FirstOperID = O.OperID
		LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
		LEFT JOIN Un_Oper oCancel ON oCancel.OperID = OC1.OperID
		LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
		LEFT JOIN (SELECT UnitID,QTERES=SUM(UnitQty) FROM Un_UnitReduction GROUP BY UnitID )UR ON UR.UnitID = U.UnitID

		LEFT JOIN #tblModalhist MH ON MH.UnitID = U.UnitID AND O.OperDate BETWEEN MH.StartDate AND MH.EndDate
		LEFT JOIN Un_Modal M ON M.ModalID = ISNULL(MH.ModalID,U.ModalID)	

	WHERE 
			O.OperTypeID = 'TFR'
		AND CT.Fee > 0 -- EST UNE COTISATION
		AND OC2.OperID IS NULL -- N'EST PAS UNE CANCELLATION
		AND ISNULL(oCancel.OperDate,'9999-12-31') NOT BETWEEN @dtDateFrom and @dtDateTo -- N'EST PAS CANCELÉ DANS LA PÉRIODE
		AND (C.ConventionNo = @ConventionNo OR @ConventionNo IS NULL)
		AND (U.UnitID = @UnitID OR @UnitID IS NULL)


	PRINT 'APRES #TFR : ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

--	select t = '#TFR',* from #TFR



	SELECT DISTINCT 
		Section = '1-Nouvelles Ventes - SANS TFR'
		,u.RepID
		,C.ConventionNo
		,u.UnitID
		,Date1ereOperFin = CAST(o.OperDate AS DATE)
		,o.OperID
		,QteUnite =			(U.UnitQty + ISNULL(UR.QTERES,0))
							* CASE WHEN OC2.OperID IS NOT NULL /*OR o.OperTypeID = 'NSF'*/ THEN -1 ELSE 1 END

		,EpargeSouscrit =	
						CASE
						WHEN P.PlanTypeID = 'COL' THEN
							-- COLLECTIF
							CAST(
								ROUND(
										(ROUND((U.UnitQty + ISNULL(UR.QTERES,0)) * m.PmtRate,2) * m.PmtQty) + u.SubscribeAmountAjustment -- On veut le souscrit réel, alors on additionne SubscribeAmountAjustment
									- ( U.UnitQty + ISNULL(UR.QTERES,0)) * m.FeeByUnit
									,2)
							AS MONEY)
							* CASE WHEN OC2.OperID IS NOT NULL /*OR o.OperTypeID = 'NSF'*/ THEN -1 ELSE 1 END
						ELSE
							-- INDIVIDUEL
							CT.Cotisation
						END

		,FraisSouscrit =
						CASE
						WHEN P.PlanTypeID = 'COL' THEN
							-- COLLECTIF
							(U.UnitQty + ISNULL(UR.QTERES,0)) * m.FeeByUnit
							* CASE WHEN OC2.OperID IS NOT NULL /*OR o.OperTypeID = 'NSF'*/ THEN -1 ELSE 1 END
						ELSE
							-- INDIVIDUEL
							CT.Fee
						END

		,Comment = O.OperTypeID

	into #NouvelleVente
	FROM 
		Un_Unit U
		JOIN Un_Convention c ON c.ConventionID = u.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = CT.OperID
		
		LEFT JOIN #tblDate1erDepotNonRenverse NR ON NR.UnitID = U.UnitID

		LEFT JOIN #tblModalhist MH ON MH.UnitID = U.UnitID AND O.OperDate BETWEEN MH.StartDate AND MH.EndDate
		LEFT JOIN Un_Modal M ON M.ModalID = ISNULL(MH.ModalID,U.ModalID)		

		LEFT JOIN #MAXOperIDByOperTypeIDByDay mo ON 
				mo.UnitID = u.UnitID 
				AND mo.OperDate = o.OperDate 
				AND mo.OperTypeID = o.OperTypeID 
		
		
		

		LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
		--LEFT JOIN Mo_BankReturnLink BRL2 on BRL2.BankReturnSourceCodeID = O.OperID
		
		LEFT JOIN (SELECT UnitID,QTERES=SUM(UnitQty) FROM Un_UnitReduction GROUP BY UnitID )UR ON UR.UnitID = U.UnitID
	
		LEFT JOIN #TFR TFR ON TFR.UnitID = U.UnitID

		LEFT JOIN UN_TIO TIO ON TIO.iTINOperID = O.OperID

	WHERE 1=1
		--Parmis les opération fait entre la première et la dernière NON renversé ....
		AND CAST(o.OperDate AS DATE) BETWEEN cast(u.dtFirstDeposit AS DATE) AND CAST(ISNULL(NR.MIN_OperDate,'9999-01-01') AS DATE)
		-- ... on retrouve celles dans la plage de date
		AND O.OperDate BETWEEN @dtDateFrom and @dtDateTo

		AND (O.OperID <= NR.MIN_OperID OR NR.MIN_OperID IS NULL) -- AU CAS OÙ IL Y A 2 CPA LE DERNIER JOUR, ON SORT LE 1ER DE CE JOUR.

		AND CharIndex(O.OperTypeID, 'PRD,CPA,CHQ,RDI,TIN,COU', 1) > 0 --O.OperTypeID IN ('PRD','CPA','CHQ','RDI','TIN'/*,'NSF'*/)
		AND (CT.Cotisation <> 0 OR CT.Fee <> 0) -- EST UNE COTISATION
		
		AND TIO.iTIOID IS NULL -- EXCLURE LES TIN TIO

		AND TFR.UnitID IS NULL -- N'EST PAS UNE NOUVELLE VENTE TFR

		AND (C.ConventionNo = @ConventionNo OR @ConventionNo IS NULL)
		AND (U.UnitID = @UnitID OR @UnitID IS NULL)

		-- s'IL Y A UN DOUBLON D'OPERTYPE DANS CETTE JOURNEE, ON PREND LE 1ER
		AND O.OperID = ISNULL(MO.MINOperIDByOperTypeID,O.OperID) 



	UNION ALL

	-- les cotisations subséquent dans un plan individuel
	SELECT

		Section = '1-Nouvelles Ventes - SANS TFR'
		,u.RepID
		,C.ConventionNo
		,u.UnitID
		,Date1ereOperFin = CAST(o.OperDate AS DATE)
		,o.OperID
		,QteUnite =			0
							--(U.UnitQty + ISNULL(UR.QTERES,0))
							--* CASE WHEN OC2.OperID IS NOT NULL /*OR o.OperTypeID = 'NSF'*/ THEN -1 ELSE 1 END

		,EpargeSouscrit =	CT.Cotisation

		,FraisSouscrit = CT.Fee

		,Comment = 'Cotisation suppl. dans IND: ' + O.OperTypeID

	--into #NouvelleVente
	FROM 
		Un_Unit U
		JOIN Un_Convention c ON c.ConventionID = u.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = CT.OperID
		
		LEFT JOIN #tblDate1erDepotNonRenverse NR ON NR.UnitID = U.UnitID

		LEFT JOIN #tblModalhist MH ON MH.UnitID = U.UnitID AND O.OperDate BETWEEN MH.StartDate AND MH.EndDate
		LEFT JOIN Un_Modal M ON M.ModalID = ISNULL(MH.ModalID,U.ModalID)		

		LEFT JOIN #MAXOperIDByOperTypeIDByDay mo ON 
				mo.UnitID = u.UnitID 
				AND mo.OperDate = o.OperDate 
				AND mo.OperTypeID = o.OperTypeID 
		
		
		

		LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
		--LEFT JOIN Mo_BankReturnLink BRL2 on BRL2.BankReturnSourceCodeID = O.OperID
		
		LEFT JOIN (SELECT UnitID,QTERES=SUM(UnitQty) FROM Un_UnitReduction GROUP BY UnitID )UR ON UR.UnitID = U.UnitID
	
		--LEFT JOIN #TFR TFR ON TFR.UnitID = U.UnitID

		LEFT JOIN UN_TIO TIO ON TIO.iTINOperID = O.OperID

	WHERE 1=1
		AND P.PlanTypeID = 'IND'

		AND (O.OperID > NR.MIN_OperID AND NR.MIN_OperID IS NOT NULL)

		--Parmis les opération fait entre la première et la dernière NON renversé ....
		--AND CAST(o.OperDate AS DATE) BETWEEN cast(u.dtFirstDeposit AS DATE) AND CAST(ISNULL(NR.MIN_OperDate,'9999-01-01') AS DATE)
		-- ... on retrouve celles dans la plage de date
		AND O.OperDate BETWEEN @dtDateFrom and @dtDateTo

		

		AND CharIndex(O.OperTypeID, 'PRD,CPA,CHQ,RDI,TIN,COU', 1) > 0 --O.OperTypeID IN ('PRD','CPA','CHQ','RDI','TIN'/*,'NSF'*/)
		AND (CT.Cotisation <> 0 OR CT.Fee <> 0) -- EST UNE COTISATION
		
		AND TIO.iTIOID IS NULL -- EXCLURE LES TIN TIO

		--AND TFR.UnitID IS NULL -- N'EST PAS UNE NOUVELLE VENTE TFR -- ON CHECK PAS ÇA POUR LES COTISATION SUBSÉQUENTE POUR UNE IND

		AND (C.ConventionNo = @ConventionNo OR @ConventionNo IS NULL)
		AND (U.UnitID = @UnitID OR @UnitID IS NULL)

		-- s'IL Y A UN DOUBLON D'OPERTYPE DANS CETTE JOURNEE, ON PREND LE 1ER
		--AND O.OperID = ISNULL(MO.MINOperIDByOperTypeID,O.OperID) 


	--select * from #NouvelleVente where ConventionNo = 'X-20151029037'

	PRINT 'APRES #NouvelleVente : ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)



	SELECT *
	INTO #TIO
	from (

		SELECT DISTINCT

			Section = '3 - TIO '/* + CAST(TIO.iTIOID AS VARCHAR )*/ + ' - Out'
			,Uout.RepID
			,Cout.ConventionNo
			,Uout.UnitID
			,Date1ereOperFin = CAST(Oout.OperDate AS DATE)
			,Oout.OperID
			,QteUnite = -1 * URout.UnitQty
			--,EpargeSouscrit = cast(-1 *
			--					ROUND(
			--						CASE
			--						WHEN Pout.PlanTypeID = 'IND' THEN CTout.Cotisation + CTout.Fee
			--						ELSE ROUND(URout.UnitQty * ModalOut.PmtRate,2) * ModalOut.PmtQty
			--						END
			--					  ,2)
			--					as MONEY )
			,EpargeSouscrit = cast(-1 *
								ROUND(
									CASE
									WHEN Pout.PlanTypeID = 'IND' THEN CTout.Cotisation /*+ CTout.Fee*/
									ELSE 
										ROUND(
											  (ROUND(URout.UnitQty * ModalOut.PmtRate,2) * ModalOut.PmtQty) + Uout.SubscribeAmountAjustment -- On veut le souscrit réel, alors on additionne SubscribeAmountAjustment
											- ( URout.UnitQty * ModalOut.FeeByUnit)
											,2)
									END
								  ,2)
								as MONEY )
			,FraisSouscrit = 0 --Frais toujours à 0$ puisque soit transféré au nouveau contrat, soit transféré aux frais disponibles. Donc n'affecte pas les revenus de GUI
			--,FraisSouscrit = -1 * URout.UnitQty * ModalOut.FeeByUnit  --test jamais mis en prod
			,Comment = 'Vers ' + Ctin.ConventionNo

	/*
			,TIO.iTIOID	
			,Oout.OperID
			,OperTypeID = Oout.OperTypeID
			,Oout.OperDate
			,Cout.ConventionNo
			,Uout.InForceDate
			,Uout.dtFirstDeposit
			,Uout.UnitQty
			,CTout.Cotisation
			,CTout.Fee
			,QtyUnitFromTIO = -1 * URout.UnitQty
			,MontantSouscritOut =  cast(-1 *
											CASE
											WHEN Pout.PlanTypeID = 'IND' THEN CTout.Cotisation + CTout.Fee
											ELSE URout.UnitQty * ModalOut.PmtRate * ModalOut.PmtQty
											END
										as MONEY )
			,Rout.RepCode
			,Representant = HRout.FirstName + ' ' + HRout.LastName
	*/		

		FROM	 
			Un_TIO TIO	
			JOIN UN_OPER Oout ON Oout.OperID = TIO.iOUTOperID
			JOIN Un_Cotisation CTout ON Oout.OperID = CTout.OperID
			JOIN Un_Unit Uout ON CTout.UnitID = Uout.UnitID
			JOIN Un_Convention Cout ON Uout.ConventionID = Cout.ConventionID
			JOIN Un_Plan Pout ON Pout.PlanID = Cout.PlanID
			LEFT JOIN Un_UnitReductionCotisation URCout ON URCout.CotisationID = CTout.CotisationID
			LEFT JOIN Un_UnitReduction URout ON URout.UnitReductionID = URCout.UnitReductionID

			--LEFT JOIN Un_Oper Otfr ON Otfr.OperID = TIO.iTFROperID
			--LEFT JOIN Un_Cotisation CTtfr ON CTtfr.OperID = Otfr.OperID
			LEFT JOIN #tblModalhist MHout ON MHout.UnitID = Uout.UnitID AND Oout.OperDate BETWEEN MHout.StartDate AND MHout.EndDate
			LEFT JOIN Un_Modal ModalOut ON ModalOut.ModalID = ISNULL(MHout.ModalID,Uout.ModalID)
			LEFT JOIN Un_Rep Rout ON Rout.RepID = Uout.RepID
			LEFT JOIN Mo_Human HRout ON HRout.HumanID = Rout.RepID


			JOIN Un_Oper Otin ON Otin.OperID = TIO.iTINOperID
			JOIN Un_Cotisation CTtin ON CTtin.OperID = Otin.OperID
			JOIN Un_Unit Utin ON Utin.UnitID = CTtin.UnitID
			JOIN Un_Convention Ctin ON Utin.ConventionID = Ctin.ConventionID
			LEFT JOIN #tblModalhist MHtin ON MHtin.UnitID = Utin.UnitID AND Otin.OperDate BETWEEN MHtin.StartDate AND MHtin.EndDate
			LEFT JOIN (SELECT UnitID, qtyRES = sum(UnitQty) FROM Un_UnitReduction GROUP BY UnitID) URtin ON URtin.UnitID = Utin.UnitID


			LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = Oout.OperID
			LEFT JOIN Un_Oper oCancelOut ON oCancelOut.OperID = OC1.OperID
			LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = Oout.OperID

		where 1=1
			AND Oout.OperDate BETWEEN @dtDateFrom AND @dtDateTo
			AND (CTout.Cotisation <> 0 OR CTtin.Cotisation <> 0)
			AND (Cout.ConventionNo = @ConventionNo OR @ConventionNo IS NULL
				OR Ctin.ConventionNo = @ConventionNo
				)
			AND (Uout.UnitID = @UnitID OR @UnitID IS NULL)	
	
	
			--AND OC2.OperID IS NULL -- on affiche les CANCELLATION
			--AND ISNULL(oCancelOut.OperDate,'9999-12-31') NOT BETWEEN @dtDateFrom AND @dtDateTo -- N'EST PAS CANCELÉ DANS LA PÉRIODE

			--AND Uout.RepID <> Utin.RepID
			--AND Oout.OperDate > Utin.dtFirstDeposit -- sans génération d'unité
			--AND URout.UnitQty <> CASE WHEN Utin.dtFirstDeposit = Otin.OperDate THEN Utin.UnitQty + ISNULL(URtin.qtyRES,0) ELSE 0	END
			--and Cout.ConventionNo = 'U-20101101029'
			--and MHout.ModalID is null

		UNION ALL


		SELECT *

		FROM (


			SELECT DISTINCT	
				Section = '3 - TIO '/* + CAST(TIO.iTIOID AS VARCHAR )*/ + ' - Tin'
				,Utin.RepID
				,Ctin.ConventionNo
				,Utin.UnitID
				,Date1ereOperFin = CAST(Otin.OperDate AS DATE)
				,Otin.OperID
				,QteUnite = CASE WHEN Utin.dtFirstDeposit = Otin.OperDate THEN Utin.UnitQty + ISNULL(URtin.qtyRES,0) ELSE 0	END	
				,EpargeSouscrit = cast(
									ROUND(
										CASE
										WHEN PTIN.PlanTypeID = 'IND' THEN CTtin.Cotisation + CTtin.Fee
										ELSE	(
												CASE WHEN Utin.dtFirstDeposit = Otin.OperDate THEN Utin.UnitQty + ISNULL(URtin.qtyRES,0) ELSE 0	END
											*	ROUND(ModalTIN.PmtQty * ModalTIN.PmtRate,2)
												)
											-	CASE WHEN Utin.dtFirstDeposit = Otin.OperDate THEN ( (Utin.UnitQty + ISNULL(URtin.qtyRES,0))  * ModalTIN.FeeByUnit  ) ELSE 0 END
										END
									  ,2)
									as MONEY )
				,FraisSouscrit = 0 --Frais toujours à 0$ puisque soit transféré au nouveau contrat, soit transféré aux frais disponibles. Donc n'affecte pas les revenus de GUI 
				,Comment = 'De ' + Cout.ConventionNo
			/*	
				,TIO.iTIOID	
				,Otin.OperID
				,OperTypeID = Otin.OperTypeID
				,Otin.OperDate
				,Ctin.ConventionNo
				,Utin.InForceDate
				,Utin.dtFirstDeposit
				,Utin.UnitQty
				,CTtin.Cotisation
				,CTtin.Fee
				,QtyUnitFromTIO = CASE WHEN Utin.dtFirstDeposit = Otin.OperDate THEN Utin.UnitQty + ISNULL(URtin.qtyRES,0) ELSE 0	END	
				,MontantSouscrit = 
								cast(
										CASE
										WHEN PTIN.PlanTypeID = 'IND' THEN CTtin.Cotisation + CTtin.Fee
										ELSE 
											CASE WHEN Utin.dtFirstDeposit = Otin.OperDate THEN Utin.UnitQty + ISNULL(URtin.qtyRES,0) ELSE 0	END
											* ModalTIN.PmtRate * ModalTIN.PmtQty
										END
								as MONEY )
				,Rtin.RepCode
				,Representant = HRtin.FirstName + ' ' + HRtin.LastName
			*/

			FROM	 
				Un_TIO TIO	
				JOIN UN_OPER Oout ON Oout.OperID = TIO.iOUTOperID
				JOIN Un_Cotisation CTout ON Oout.OperID = CTout.OperID
				JOIN Un_Unit Uout ON CTout.UnitID = Uout.UnitID
				JOIN Un_Convention Cout ON Uout.ConventionID = Cout.ConventionID

				LEFT JOIN Un_UnitReductionCotisation URCout ON URCout.CotisationID = CTout.CotisationID
				LEFT JOIN Un_UnitReduction URout ON URout.UnitReductionID = URCout.UnitReductionID

				--LEFT JOIN Un_Oper Otfr ON Otfr.OperID = TIO.iTFROperID
				--LEFT JOIN Un_Cotisation CTtfr ON CTtfr.OperID = Otfr.OperID
				LEFT JOIN #tblModalhist MHout ON MHout.UnitID = Uout.UnitID AND Oout.OperDate BETWEEN MHout.StartDate AND MHout.EndDate
				LEFT JOIN Un_Modal ModalOut ON ModalOut.ModalID = ISNULL(MHout.ModalID,Uout.ModalID)

				JOIN Un_Oper Otin ON Otin.OperID = TIO.iTINOperID
				JOIN Un_Cotisation CTtin ON CTtin.OperID = Otin.OperID
				JOIN Un_Unit Utin ON Utin.UnitID = CTtin.UnitID
				JOIN Un_Convention Ctin ON Utin.ConventionID = Ctin.ConventionID
				JOIN UN_PLAN Ptin ON Ptin.PlanID = Ctin.PlanID
				LEFT JOIN #tblModalhist MHtin ON MHtin.UnitID = Utin.UnitID AND Otin.OperDate BETWEEN MHtin.StartDate AND MHtin.EndDate
				LEFT JOIN Un_Modal ModalTIN ON ModalTIN.ModalID = ISNULL(MHtin.ModalID,Utin.ModalID)
				LEFT JOIN (SELECT UnitID, qtyRES = sum(UnitQty) FROM Un_UnitReduction GROUP BY UnitID) URtin ON URtin.UnitID = Utin.UnitID
				LEFT JOIN Un_Rep Rtin ON Rtin.RepID = Utin.RepID
				LEFT JOIN Mo_Human HRtin ON HRtin.HumanID = Rtin.RepID

				LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = Oout.OperID
				LEFT JOIN Un_Oper oCancelOut ON oCancelOut.OperID = OC1.OperID
				LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = Oout.OperID

			where 1=1
				AND Oout.OperDate BETWEEN @dtDateFrom AND @dtDateTo
				AND (CTout.Cotisation <> 0 OR CTtin.Cotisation <> 0)
				AND (Ctin.ConventionNo = @ConventionNo OR @ConventionNo IS NULL
					OR Cout.ConventionNo = @ConventionNo
					)
				AND (Utin.UnitID = @UnitID OR @UnitID IS NULL)	

				--AND OC2.OperID IS NULL -- N'EST PAS UNE CANCELLATION
				--AND ISNULL(oCancelOut.OperDate,'9999-12-31') NOT BETWEEN @dtDateFrom AND @dtDateTo -- N'EST PAS CANCELÉ DANS LA PÉRIODE

				--AND Uout.RepID <> Utin.RepID
				--AND Oout.OperDate > Utin.dtFirstDeposit -- sans génération d'unité
				--AND URout.UnitQty <> CASE WHEN Utin.dtFirstDeposit = Otin.OperDate THEN Utin.UnitQty + ISNULL(URtin.qtyRES,0) ELSE 0	END
				--and Cout.ConventionNo = 'U-20101101029'
				--and MHout.ModalID is null
			)V1
		WHERE 1=1	
			AND (V1.QteUnite <> 0 OR V1.EpargeSouscrit <> 0)
		)v

	PRINT 'APRES #tio : ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

	SELECT 
		U.UnitID 
		--,c.ConventionNo
		,DateResiliation
		,V.RESOperID
		,SoldeDepotAvantRES = sum(CT.Cotisation + CT.Fee)
	INTO #SoldeDepotAvantRES
	FROM UN_UNIT U
	JOIN Un_Convention C on C.ConventionID = U.ConventionID
	JOIN (
		select DISTINCT
			u.UnitID
			,c.ConventionID
			,QteUniteResiliee = ur.UnitQty
			,RESOperID = o.OperID
			,DateResiliation = cast(ur.ReductionDate as date)
			,OUtvsRES = o.OperTypeID
		from 
			Un_Convention c
			JOIN Un_Unit u on c.ConventionID = u.ConventionID
			JOIN Un_UnitReduction ur on u.UnitID = ur.UnitID
			JOIN Un_UnitReductionCotisation urc on ur.UnitReductionID = urc.UnitReductionID
			JOIN Un_Cotisation ct on urc.CotisationID = ct.CotisationID
			JOIN un_oper o on ct.OperID = o.OperID 
			left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
			left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
			left join Un_OperCancelation oc1 on o.OperID = oc1.OperID
			left join Un_OperCancelation oc2 on o.OperID = oc2.OperSourceID

		where  1=1
			and ur.ReductionDate BETWEEN @dtDateFrom AND @dtDateTo
			and o.OperTypeID in ('OUT','RES')
			and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			--and oc1.OperID is NULL
			--and oc2.OperSourceID is NULL
			) V ON V.UnitID = U.UnitID
	JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
	JOIN Un_Oper O ON CT.OperID = O.OperID AND O.OperID < V.RESOperID
	WHERE CharIndex(O.OperTypeID, 'PRD,CPA,CHQ,RDI,TIN,COU', 1) > 0 --O.OperTypeID IN ('PRD','CHQ','CPA','RDI','TIN')
	GROUP BY
		U.UnitID 
		--,c.ConventionNo
		,DateResiliation
		,V.RESOperID

	PRINT 'APRES #SoldeDepotAvantRES : ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)

	--SELECT * FROM #tblModalhist WHERE UNITID = 697743

	--- RES ou OUT
	SELECT DISTINCT
		Section = '4- RES et OUT'
		,u.RepID
		,C.ConventionNo
		,u.UnitID
		,Date1ereOperFin = CAST(o.OperDate AS DATE)
		,O.OperID
		,QteUnite = -1 * ur.UnitQty
		,EpargeSouscrit = -1 * CAST(
									ROUND(
											  (
												(
													ROUND(UR.UnitQty * m.PmtRate,2) * m.PmtQty
												) 
											
												+ (CASE WHEN UR.UnitQty < 0 THEN -1 ELSE 1 END * u.SubscribeAmountAjustment) -- + OU - CE MONTANT SELON UNE RES OU UN RENVERSEMENT DE RES
											  ) 
											- ( UR.UnitQty * m.FeeByUnit) -- MOINS LES FRAIS
										,2)
								AS MONEY)
		,FraisSouscrit = -1 * ((m.FeeByUnit * ur.UnitQty) +  isnull(ct2.Fee,0))
		,Comment = urr.UnitReductionReason + ' - affecte Taux = ' + case when urr.bReduitTauxConservationRep = 1 then 'OUI' ELSE 'NON' end
	/*
		c.ConventionNo,
		c.ConventionID,
		u.UnitID,
		u.UnitQty,
		o.OperTypeID,
		DateRES = o.OperDate,
		--O.OperID,
		--o.OperTypeID,
		--O2.OperID,
		QteUniteRES = ur.UnitQty,
		MontantEpargneRES = ct.Cotisation,
		MontantFraisRES = ct.Fee,
		MontantFRaisTFR = isnull(ct2.Fee,0),
		RaisonRES = urr.UnitReductionReason
		--,ur.FeeSumByUnit
		,ur.FeeSumByUnit
		,FraisARecevoir = (200 * ur.UnitQty) - (abs(ct.Fee) + abs( isnull(ct2.Fee,0)))
		*/
	into #RES
	FROM Un_Unit U
	--JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN Un_Convention c on u.ConventionID = c.ConventionID
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
	JOIN Un_UnitReduction ur ON urc.UnitReductionID = ur.UnitReductionID
	LEFT join Un_UnitReductionReason urr on ur.UnitReductionReasonID = urr.UnitReductionReasonID
	
	LEFT JOIN #tblModalhist MH ON MH.UnitID = U.UnitID AND O.OperDate BETWEEN MH.StartDate AND MH.EndDate
	LEFT JOIN Un_Modal M ON M.ModalID = ISNULL(MH.ModalID,U.ModalID)		
	
	LEFT JOIN Un_TIO T ON T.iOUTOperID = O.OperID
	LEFT JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID AND URC2.CotisationID <> Ct.CotisationID
	LEFT JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
	LEFT JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperTypeID = 'TFR'
	LEFT JOIN Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
	LEFT JOIN Un_Oper oCancel ON oCancel.OperID = OC1.OperID
	LEFT JOIN Un_OperCancelation oc2 on o.OperID = oc2.OperID
	LEFT JOIN #SoldeDepotAvantRES SDA ON O.OperID = SDA.RESOperID
	WHERE 1=1
		AND o.OperDate BETWEEN @dtDateFrom AND @dtDateTo
		AND T.iOUTOperID IS NULL -- NON INCLUS DANS UN TIO
		AND CharIndex(O.OperTypeID, 'RES,OUT', 1) > 0 --O.OperTypeID in ( 'RES', 'OUT')
		AND (C.ConventionNo = @ConventionNo OR @ConventionNo IS NULL)
		AND (U.UnitID = @UnitID OR @UnitID IS NULL)	

		-- IL Y A EU DES encaissements de COTISATIONS AVANT LA RES
		-- Pour éviter d'afficher ls RES à zéro
		AND ISNULL(SDA.SoldeDepotAvantRES,0) > 0 -- critère "SoldeDepotAvantRES" --2016-12-15

		-- remplacé par critère "SoldeDepotAvantRES"
		--AND (CT.Cotisation <> 0 OR CT.Fee <> 0 OR CT2.Fee <> 0) -- RÉSILIATION AVEC UNE COTISATION OU UN TFR SINON CE N'EST PAS UNE RÉSILIATION SUR UN CONTRAT QUI AVAIT DÉBUTÉ SES COTISATIONS (EX : IL N'Y A EU QUE DES NSF, SUIVI D'UNE RES)


		--AND OC2.OperID IS NULL -- N'EST PAS UNE CANCELLATION
		--AND ISNULL(oCancel.OperDate,'9999-12-31') NOT BETWEEN @dtDateFrom AND @dtDateTo -- N'EST PAS CANCELÉ DANS LA PÉRIODE

	PRINT 'APRES #RES : ' + LEFT(CONVERT(VARCHAR, GETDATE(), 120), 30)		


	SELECT 
		r.RepCode
		,RepName = hr.FirstName + ' ' + hr.LastName
		,Directeur = HB.FirstName +  ' ' + HB.LastName
		,Regime  = p.PlanDesc
		,v.*
	--INTO VENTENEW
	FROM (
		SELECT * FROM #TFR
		
		UNION ALL

		SELECT * FROM #NouvelleVente

		UNION ALL

		SELECT * FROM #TIO

		UNION ALL

		SELECT * FROM #RES

		)V
		JOIN Un_Convention c on c.ConventionNo = v.ConventionNo
		JOIN Un_Plan P on c.PlanID = P.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON P.iID_Regroupement_Regime = RR.iID_Regroupement_Regime
		JOIN un_rep r on v.repid = r.RepID
		JOIN Mo_Human hr on r.RepID = hr.HumanID
		LEFT JOIN (
			SELECT 
				M.UnitID,
				BossID = MAX(RBH.BossID)
			FROM (
				SELECT 
					U.UnitID,
					U.RepID,
					RepBossPct = MAX(RBH.RepBossPct)
				FROM Un_Unit U
				JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
				JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
				JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
				GROUP BY U.UnitID, U.RepID
				) M
			JOIN Un_Unit U ON U.UnitID = M.UnitID
			JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
			GROUP BY 
				M.UnitID
				)bu on bu.UnitID = V.UnitID
		LEFT JOIN Mo_Human HB ON HB.HumanID = BU.BossID
	where 
		(v.repid = @RepID OR ISNULL(BU.BossID,-1) = @RepID or @RepID = 0)
		AND (P.iID_Regroupement_Regime = @iID_Regroupement_Regime OR @iID_Regroupement_Regime = 0)

	ORDER BY 
		SECTION,UNITID, Date1ereOperFin

set ARITHABORT OFF

END