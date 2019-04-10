/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	GU_RP_SACExcelStatsRES
Description         :	Dataset pour la création du fichier Excel des statistiques sur les résiliations.
						
Valeurs de retours  :	Dataset 
Note                :	2008-03-18 Pierre-Luc Simard    Création
						2010-06-30 Donald Huppé         Refait selon les spec du glpi 1140 et 3338
						2010-09-29 Donald Huppé	        GLPI 4264
						2011-05-11 Donald Huppé	        GLPI 5501 ajout du montant d'épargne remboursée
						2011-05-18 Donald Huppé	        (suite du glpi 5501) Ajout du montant d'épargne remboursée du transfert OUT
						2014-09-18 Donald Huppé         glpi 12447
						2016-04-04 Donald Huppé	        ajout de MontantTFR
						2017-07-05 Donald Huppé	        Ajout de DISTINCT À LA SECTION:	-- les groupes d'unité non touchés par des résiliation
                        2017-08-29 Pierre-Luc Simard    Ajout des RDI
						2018-09-07 Maxime Martel		JIRA MP-699 Ajout de OpertypeID COU

exec GU_RP_SACStatistiqueResiliation '2014-01-01','2014-08-30' 4040
exec GU_RP_SACStatistiqueResiliation '2017-01-01','2017-07-02'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_SACStatistiqueResiliation] (
	@StartDate DATETIME, -- Date de début de l'interval pour la date des réductions d'unités
	@EndDate DATETIME ) -- Date de fin de l'interval pour la date des réductions d'unités
AS
BEGIN

--DECLARE 
--	@StartDate DATETIME, -- Début de la période
--	@EndDate DATETIME -- Fin de la période

	--SET @StartDate = '2010-01-01'
	--SET @EndDate = '2010-06-30'

	-- Va chercher la date de réduction d'unités
	CREATE TABLE #tUnitReduction ( 
		UnitID INTEGER ,
		dtReduct DATETIME NOT NULL,
		UnitReductionID INT NOT NULL Primary key,
		UnitReductionReason varchar(255),
		EpargneRemboursee money )
	INSERT INTO #tUnitReduction -- select * from Un_UnitReductionReason
		SELECT
			UR.UnitID, 
			dtFirstReduct = UR.ReductionDate,
			FirstUnitReductionID = UR.UnitReductionID,
			URR.UnitReductionReason,
			EpargneRemboursee = sum(EpargneRemboursee)
		FROM Un_UnitReduction UR
		LEFT join (
			SELECT ct.UnitID, o.OperDate, EpargneRemboursee = sum(ct.Cotisation * -1) 
			FROM Un_Oper o
			JOIN Un_Cotisation ct on o.OperID = ct.OperID
			where OperTypeID IN ('RES' , 'OUT')
			GROUP BY ct.UnitID, o.OperDate
			) res on UR.unitID = Res.Unitid AND UR.ReductionDate = res.OperDate
		left join Un_UnitReductionReason URR on UR.UnitReductionReasonId = URR.UnitReductionReasonId
		WHERE 
			UR.ReductionDate BETWEEN @StartDate AND @EndDate
			--and UR.UnitReductionReasonID NOT IN (6, 24) -- Ne pas inclure les transferts OUT
			and UnitQty <> 0
		GROUP BY
			UR.UnitID, 
			UR.ReductionDate,
			UR.UnitReductionID,
			URR.UnitReductionReason



		SELECT

			u.UnitID,
			u.UnitQty,
			UR.UnitReductionID,
			dtReduct = UR.ReductionDate,
			MontantTFR = isnull(ct2.Fee,0) * -1
		into #tmpRES
		FROM Un_Unit U
		JOIN Un_Convention c on u.ConventionID = c.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReduction ur ON urc.UnitReductionID = ur.UnitReductionID
		join Un_UnitReductionReason urr on ur.UnitReductionReasonID = urr.UnitReductionReasonID
		JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID AND URC2.CotisationID <> Ct.CotisationID
		JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND	O2.OperTypeID = 'TFR'
		LEFT JOIN Un_TIO T ON T.iOUTOperID = O2.OperID
		left JOIN Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
		left JOIN Un_OperCancelation oc2 on o.OperID = oc2.OperID

		WHERE 	O.OperTypeID in ( 'RES','OUT')
			and UR.ReductionDate BETWEEN @StartDate AND @EndDate


--select * from #tUnitReduction

--return

	-- Va chercher les frais la journée avant la réductions d'unités
	CREATE TABLE #tUnitFeeReduction ( 
		UnitReductionID INTEGER Primary key,
		UnitID INTEGER,-- PRIMARY KEY,
		FeeReduct MONEY NOT NULL)
	INSERT INTO #tUnitFeeReduction
	SELECT 
		UnitReductionID,
		UR.UnitID, 
		FeeReduct = SUM(CASE WHEN CO.EffectDate < UR.dtReduct THEN CO.Fee ELSE 0 END)
	FROM #tUnitReduction UR 
	LEFT JOIN Un_Cotisation CO ON CO.UnitID = UR.UnitID
	GROUP BY 	
		UR.UnitID ,UnitReductionID

	-- La modalité avant la réduction
	Create table #tUnitModalBefore (
		unitreductionid integer Primary key,
		modalid integer
		)
	insert into #tUnitModalBefore
	select ur1.unitreductionid, mh1.modalid
	from un_unitreduction ur1
	join (
		select ur.unitreductionid, ModStartDate = max(mh.startdate)
		from un_unitreduction ur
		join un_unitmodalhistory mh on ur.unitid = mh.unitid and mh.startdate < ur.reductiondate
		group by ur.unitreductionid
		) v on ur1.unitreductionid = V.unitreductionid
	join un_unitmodalhistory mh1 on ur1.unitid = mh1.unitid and mh1.startdate = v.ModStartDate

	-- La modalité après la réduction
	Create table #tUnitModalAfter (
		unitreductionid integer Primary key,
		modalid integer
		)
	insert into #tUnitModalAfter
	select ur1.unitreductionid, mh1.modalid
	from un_unitreduction ur1
	join (
		select ur.unitreductionid, ModStartDate = min (mh.startdate)
		from un_unitreduction ur
		join un_unitmodalhistory mh on ur.unitid = mh.unitid and mh.startdate >= ur.reductiondate
		group by ur.unitreductionid
		) v on ur1.unitreductionid = V.unitreductionid
	join un_unitmodalhistory mh1 on ur1.unitid = mh1.unitid and mh1.startdate = v.ModStartDate

	-- Va chercher les unités la journée avant la réductions d'unités
	CREATE TABLE #tUnitQtyReduction ( 
		UnitReductionID INTEGER Primary key,
		UnitID INTEGER,
		UQtyBeforeReduct MONEY NOT NULL,
		UQtyReduct MONEY NOT NULL )
	INSERT INTO #tUnitQtyReduction
	SELECT 
		ur.unitreductionid,
		UFR.UnitID, 
		UQtyBeforeReduct = U.UnitQty + ReductToComme.Reductqty,
		UQtyReduct = UR.UnitQty
	FROM #tUnitReduction UFR 
	left join (	
		-- total des réductions à venir après chaque réduction
		select ur1.unitreductionid, ur1.reductiondate,ur1.unitid, Reductqty = sum(ur2.unitqty) 
		from un_unitreduction ur1
		join un_unitreduction ur2 on ur1.unitid = ur2.unitid and ur1.unitreductionid <= ur2.unitreductionid -- and ur1.reductiondate <= ur2.reductiondate 
		--where ur1.unitid = 278080
		group by ur1.unitreductionid,ur1.reductiondate,ur1.unitid
			) ReductToComme on UFR.unitreductionid = ReductToComme.unitreductionid
	LEFT JOIN Un_UnitReduction UR ON UR.unitreductionid = UFR.unitreductionid
	JOIN dbo.Un_Unit U ON U.UnitID = UFR.UnitID

	-- Va chercher les unités la journée avant la réductions d'unités
	CREATE TABLE #tNbDepotBeforeReduct ( 
		UnitReductionID INTEGER Primary key,
		UnitID INTEGER,-- PRIMARY KEY,
		NbDepot integer)
	INSERT INTO #tNbDepotBeforeReduct
	select V.FirstUnitReductionID , ct.unitid, nbDepot = count(*) 
	from un_cotisation ct
	join un_oper op on ct.operid = op.operid
	join (
			SELECT
				UR.UnitID, 
				dtFirstReduct = UR.ReductionDate,
				FirstUnitReductionID = UR.UnitReductionID
			FROM Un_UnitReduction UR
			left join Un_UnitReductionReason URR on UR.UnitReductionReasonId = URR.UnitReductionReasonId
			WHERE UnitQty <> 0
		) V on ct.unitid = V.unitid and ct.effectdate <= V.dtFirstReduct
	where op.opertypeid in('PRD', 'CHQ', 'CPA', 'RDI', 'COU')
	group by ct.unitid, V.FirstUnitReductionID

	SELECT 
		--C.ConventionID,
		C.ConventionNo,
		cs1.ConventionStateID,
		U.UnitID, 
		DateDeVigueur = U.InforceDate, --convert(Char(10),U.InforceDate,111),
		--TerminatedDate = dbo.fn_Mo_DateToShortDateStr(ISNULL(U.TerminatedDate, ''),'FRA'),
		DateResilComplete = case when DteResil.LastTerminated = UFR.dtReduct then DteResil.LastTerminated else NULL end, --convert(Char(10),DteResil.LastTerminated,111)
		DateResilPartielle = UFR.dtReduct,--convert(Char(10),UFR.dtReduct,111),
		RaisonResilPartielle = UFR.UnitReductionReason,
		DepassBareme = CASE 
						WHEN PS.iID_Depassement_Bareme = 0 THEN 'Non' 
						WHEN PS.iID_Depassement_Bareme is NULL THEN 'NA' 
						ELSE 'Oui'
						END,
		Justifications = CASE WHEN PS.iID_Depassement_Bareme = 1 THEN PS.vcDepassementBaremeJustification ELSE '' END,

		Q.UQtyBeforeReduct,
		UQtyAfterReduct = Q.UQtyBeforeReduct - Q.UQtyReduct,
		UFR.EpargneRemboursee,

		MntDepotAvantResil = CAST(
						((Q.UQtyBeforeReduct * MB.PmtRate + (Q.UQtyBeforeReduct * MB.SubscriberInsuranceRate + (Q.UQtyBeforeReduct * MB.SubscriberInsuranceRate) * st.StateTaxPct) * u.WantSubscriberInsurance ))
							+
						(  (ISNULL(BI.BenefInsurRate,0)  + ( ISNULL(BI.BenefInsurRate,0) * st.StateTaxPct)) * u.WantSubscriberInsurance * (case when (Q.UQtyBeforeReduct ) > 0 then 1 else 0 end ))

						AS MONEY),

		MntDepotApresResil = CAST(
						((Q.UQtyBeforeReduct - Q.UQtyReduct) * case when UFR.UnitReductionID <> 22 then MB.PmtRate else MA.PmtRate end + ((Q.UQtyBeforeReduct - Q.UQtyReduct) * case when UFR.UnitReductionID <> 22 then MB.SubscriberInsuranceRate else MA.SubscriberInsuranceRate end  + ((Q.UQtyBeforeReduct - Q.UQtyReduct) * case when UFR.UnitReductionID <> 22 then MB.SubscriberInsuranceRate else MA.SubscriberInsuranceRate end) * st.StateTaxPct) * u.WantSubscriberInsurance   )
							+
						(	 ( (  ISNULL(BI.BenefInsurRate,0))+ ( ISNULL(BI.BenefInsurRate,0) * st.StateTaxPct))   * u.WantSubscriberInsurance  * (case when (Q.UQtyBeforeReduct - Q.UQtyReduct) > 0 then 1 else 0 end ) )
							as MONEY),

		--mb.modalid,
		ModeDepot = case 
					when Mb.PmtByYearID = 12 and Mb.PmtQty > 1 then 'Mensuel'
					when Mb.PmtByYearID = 1 and Mb.PmtQty > 1 then 'Annuel'-- select * from un_modal
					when Mb.PmtByYearID = 1 and Mb.PmtQty = 1 then 'Forfait'
					end,
		mb.PmtByYearID,
		NbDepotAvantReduct = mb.pmtQty, -- nb de dépôt de la modalité avant la réduction
		FraisCombles = CASE WHEN (Q.UQtyBeforeReduct * MB.FeeByUnit) - FeeReduct = 0 THEN 1 ELSE 0 END,
		MontantTFR = ISNULL(MontantTFR,0),
		MoisEcouleDeVigueurAResil = DATEDIFF(MONTH, U.InforceDate, UFR.dtReduct),
		--F.FeeReduct,	
		--DepotReduct = CAST(Q.UQtyBeforeReduct * PmtRate AS MONEY),
		--FraisAPayerReduct = Q.UQtyBeforeReduct * FeeByUnit,
		--M.FeeByUnit,
		--PmtRate = CAST(M.PmtRate AS MONEY),
		Sousc = HS.LastName + ' ' + HS.FirstName, --Souscripteur
		UnitDir = HD.LastName + ' ' + HD.FirstName,--Directeur (Unit)
		UnitRep = HR.LastName + ' ' + HR.FirstName, --Représentant (Unit)
		Age31dec2008 = dbo.fn_Mo_Age(HB.birthDate,'2008-12-31')
		--SDLastName = SHD.LastName, --Directeur (Souscripteur)
		--SDFirstName = SHD.FirstName, 
		--SRLastName = SHR.LastName, --Représentant (Souscripteur)
		--SRFirstName = SHR.FirstName
		,BreakingStartDate
	into #tmpResult
	FROM dbo.Un_Convention C -- select * FROM dbo.Un_Convention where conventionno = '1184533'

 -- si on veut seulement les conventions qui sont encore active à la fin de l'année demandée

	join (
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
				from un_conventionconventionstate -- select min(startDate) from un_conventionconventionstate
				where startDate <= @EndDate -- Si je veux l'état à une date précise
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					--and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
			)cs1 on cs1.conventionid = c.conventionid

	JOIN dbo.Mo_Human HB on HB.humanID = C.beneficiaryID -- select * FROM dbo.Mo_Human 
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN #tUnitReduction UFR ON UFR.UnitID = U.UnitID 
	JOIN #tUnitQtyReduction Q ON Q.UnitID = U.UnitID  and UFR.unitreductionid = Q.unitreductionid
	JOIN #tUnitFeeReduction F ON F.UnitID = U.UnitID  and UFR.unitreductionid = F.unitreductionid
	left join #tmpRES TFR ON TFR.UnitID  = U.UnitID  and UFR.unitreductionid = TFR.unitreductionid

	left join #tNbDepotBeforeReduct ND on UFR.unitreductionid = ND.unitreductionid

	left join #tUnitModalBefore UMB on UMB.unitreductionid = UFR.unitreductionid
	left join #tUnitModalAfter UMA on UMA.unitreductionid = UFR.unitreductionid

	left JOIN Un_Modal MB ON MB.ModalID = UMB.ModalID
	left JOIN Un_Modal MA ON MA.ModalID = UMA.ModalID

	LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID and BI.BenefInsurDate <= UFR.dtReduct

	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN dbo.Un_Subscriber SS on SS.SubscriberID = C.SubscriberID
	join mo_state st on SS.stateid = st.stateid
	JOIN Un_Rep R ON R.RepID = U.RepID
	JOIN dbo.Mo_Human HR ON HR.HumanID = U.RepID
	LEFT JOIN (
		SELECT 
			RB.RepID, 
			BossID = MAX(BossID)
		FROM Un_RepBossHist RB
		JOIN (
			SELECT 
				RB.RepID, 
				RepBossPct = MAX(RB.RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
				AND RB.StartDate <= @EndDate
				AND ISNULL(RB.EndDate,@EndDate) >= @EndDate
			GROUP BY 
				RB.RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE RB.RepRoleID = 'DIR'
			AND RB.StartDate <= @EndDate
			AND ISNULL(RB.EndDate,@EndDate) >= @EndDate
		GROUP BY 
			RB.RepID
		) RD ON RD.RepID = R.RepID
	LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = RD.BossID
	LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	LEFT JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = S.SubscriberID
	LEFT JOIN dbo.Mo_Human SHR ON SHR.HumanID = S.RepID
	LEFT JOIN (-- Directeur du représentant au niveau du souscripteur
		SELECT 
			RB.RepID, 
			BossID = MAX(BossID)
		FROM Un_RepBossHist RB
		JOIN (
			SELECT 
				RB.RepID, 
				RepBossPct = MAX(RB.RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
				AND RB.StartDate <= GETDATE()
				AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
			GROUP BY 
				RB.RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE RB.RepRoleID = 'DIR'
			AND RB.StartDate <= GETDATE()
			AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
		GROUP BY 
			RB.RepID
		) SRD ON SRD.RepID = SHR.HumanID
	LEFT JOIN dbo.Mo_Human SHD ON SHD.HumanID = SRD.BossID
	left join (
		select 
			un.conventionid, 
			LastTerminated = max(terminatedDate),
			NbGrUnitResil = count(*)
		from 
			un_unit un
			join (
				select conventionid, NbGrUnite = count(*)
				FROM dbo.Un_Unit 
				group by conventionid
				) CN on un.conventionid = CN.conventionid
		where un.TerminatedDate is not null
		group by un.conventionid,CN.NbGrUnite
		having count(*) = CN.NbGrUnite
		) DteResil on c.conventionid = DteResil.conventionid
	left join (
		select ConventionID, BreakingStartDate = max(BreakingStartDate) from Un_Breaking group by ConventionID
		)br on c.ConventionID = br.ConventionID

	-- Pour les fénéficiaires âgés entre 15 et 17 ans
--	WHERE 	dbo.fn_Mo_Age(HB.birthDate,'2008-12-31') between 15 and 17
	--where c.conventionno in ('1349714 ') --'U-20020322031',
	
	order by C.ConventionNo,convert(Char(12),UFR.dtReduct,111)

	--select conventionno,modedepot from #tmpResult group by conventionno,modedepot having count(*) > 1 order by conventionno

	--select * from #tmpResult where conventionno = 'U-20090416023' order by ConventionNo, unitid

	select 
		ConventionNo,
		--ÉtatAu31déc = MAX(ConventionStateID),
		--nbResilunit = sum(nbResilunit),
		BreakingStartDate = convert(Char(10),min(BreakingStartDate),111),
		DateDeVigueur = convert(Char(10),min(DateDeVigueur),111),  
		DateResilComplete = convert(Char(10),max(DateResilComplete),111),
		DateResilPartielle = convert(Char(10),max(DateResilPartielle),111),
		UQtyBeforeReduct = sum(UQtyBeforeReduct),
		UQtyAfterReduct = sum(UQtyAfterReduct),
		EpargneRemboursee = sum(EpargneRemboursee),
		MntDepotAvantResil = sum(case when ModeDepot <> 'Forfait' then MntDepotAvantResil else 0 end),
		MntDepotApresResil = sum(case when ModeDepot <> 'Forfait' then MntDepotApresResil else 0 end),
					-- On prend le MIN entre les cas possible suivant
					-- Forfait(s) = Forfait
					-- Annuel(s) = Annuel
					-- Mensuel(s) = Mensuel
					-- Forfait(s) et Annuel(s) = Annuel
					-- Forfait(s) et Mensuel(s) = Mensuel
					-- NB : Le cas Mensuel et Annuel est impossible
		ModeDepot = replace(replace(replace(min(case 
						when ModeDepot = 'Forfait' then '3Forfait'
						when ModeDepot = 'Annuel' then '1Annuel'
						when ModeDepot = 'Mensuel' then '2Mensuel'
						end ),'1',''),'2',''),'3',''),--min(ModeDepot),
		NbDepotAvantReduct = max(case when ModeDepot is not null then NbDepotAvantReduct else 0 end),
		FraisCombles = min(FraisCombles), --sum(case when ModeDepot is not null then FraisCombles else 0 end),
		MontantTFR = min(MontantTFR),
		--MoisEcouleDeVigueurAResil = min(case when ModeDepot is not null then MoisEcouleDeVigueurAResil else 0 end),
		MoisEcouleDeVigueurAResil = DATEDIFF(MONTH, min(DateDeVigueur), max(DateResilPartielle)), 
		RaisonResilPartielle = max(RaisonResilPartielle), 
		Sousc = max(Sousc),
		UnitDir = max(UnitDir),
		UnitRep = max(UnitRep),
		DepassBareme = max(DepassBareme),
		Justifications = max(Justifications)
		
	into #TmpResil
	from (

		select
			ConventionNo, 
			ConventionStateID,
			unitid,
			nbResilunit,
			BreakingStartDate,
			DateDeVigueur,
			DateResilComplete = max(DateResilComplete),
			DateResilPartielle = max(DateResilPartielle),
			DepassBareme,
			Justifications,
			Sousc,
			UnitDir = max(case when ModeDepot = 'Forfait' then NULL else UnitDir end),
			UnitRep = max(case when ModeDepot = 'Forfait' then NULL else UnitRep end),

			RaisonResilPartielle = max(RaisonResilPartielle),
			NbDepotAvantReduct = max(NbDepotAvantReduct),
			FraisCombles = min(FraisCombles), --max(FraisCombles),
			MontantTFR = min(MontantTFR),
			ModeDepot = max(ModeDepot), --max(case when ModeDepot = 'Forfait' then NULL else ModeDepot end),
			MoisEcouleDeVigueurAResil= max(MoisEcouleDeVigueurAResil),
			UQtyBeforeReduct = max(UQtyBeforeReduct),
			UQtyAfterReduct = max(UQtyAfterReduct),
			EpargneRemboursee = max(EpargneRemboursee),
			MntDepotAvantResil =max(MntDepotAvantResil),
			MntDepotApresResil =max (MntDepotApresResil)
		from (

			select  
				tr.ConventionNo, 
				tr.ConventionStateID,
				tr.unitid,
				nbResilunit,
				BreakingStartDate,
				DateDeVigueur,
				DateResilComplete = max(DateResilComplete),
				DepassBareme,
				Justifications,
				Sousc,
				UnitDir,
				UnitRep,
				
				DateResilPartielle = MinDateResilPartielle,
				RaisonResilPartielle = null, --max(RaisonResilPartielle),
				NbDepotAvantReduct = min(NbDepotAvantReduct),
				FraisCombles = min(FraisCombles),
				MontantTFR = min(MontantTFR),
				ModeDepot = min(ModeDepot), --min(case when ModeDepot = 'Forfait' then NULL else ModeDepot end), 
				MoisEcouleDeVigueurAResil=null,
				UQtyBeforeReduct = max(UQtyBeforeReduct),
				UQtyAfterReduct = null,
				EpargneRemboursee = min(EpargneRemboursee),
				MntDepotAvantResil =max(MntDepotAvantResil),
				MntDepotApresResil =null
			from 
				#tmpResult tr
				join (
					select ConventionNo,unitid,MinDateResilPartielle = min(DateResilPartielle),nbResilunit = count(*)
					from #tmpResult t1
					group by ConventionNo,unitid
					) MinD on tr.ConventionNo = MinD.ConventionNo and tr.unitid = MinD.unitid and tr.DateResilPartielle = MinD.MinDateResilPartielle -- datediff(d,tr.DateResilPartielle , MinD.MinDateResilPartielle) = 0
			group by tr.ConventionNo,tr.ConventionStateID,tr.unitid,nbResilunit,BreakingStartDate,DateDeVigueur,DepassBareme,Justifications,Sousc,UnitDir,UnitRep,MinDateResilPartielle
			
			UNION ALL
			
			select  
				tr.ConventionNo, 
				tr.ConventionStateID,
				tr.unitid,
				nbResilunit,
				BreakingStartDate,
				DateDeVigueur,
				DateResilComplete = max(DateResilComplete),
				DepassBareme,
				Justifications,
				Sousc,
				UnitDir,
				UnitRep,

				DateResilPartielle = MaxDateResilPartielle,
				RaisonResilPartielle = max(RaisonResilPartielle),
				NbDepotAvantReduct = min(NbDepotAvantReduct),
				FraisCombles = min(FraisCombles),
				MontantTFR = min(MontantTFR),
				ModeDepot = min(ModeDepot), --min(case when ModeDepot = 'Forfait' then NULL else ModeDepot end),
				MoisEcouleDeVigueurAResil=max(MoisEcouleDeVigueurAResil),
				UQtyBeforeReduct = null,
				UQtyAfterReduct = min(UQtyAfterReduct),
				EpargneRemboursee = min(EpargneRemboursee),
				MntDepotAvantResil = null,
				MntDepotApresResil = min(MntDepotApresResil)
			from 
				#tmpResult tr
				join (
					select ConventionNo,unitid,MaxDateResilPartielle = max(DateResilPartielle),nbResilunit = count(*)
					from #tmpResult t2
					group by ConventionNo,unitid
					) MaxD on tr.ConventionNo = MaxD.ConventionNo and tr.unitid = MaxD.unitid and tr.DateResilPartielle = MaxD.MaxDateResilPartielle -- datediff(d,tr.DateResilPartielle , MaxD.MaxDateResilPartielle) = 0
			group by tr.ConventionNo, tr.ConventionStateID,tr.unitid,nbResilunit,BreakingStartDate,DateDeVigueur,DepassBareme,Justifications,Sousc,UnitDir,UnitRep,MaxDateResilPartielle
		) V
		--where conventionno = 'C-20010122009'
		group by ConventionNo,ConventionStateID,unitid,nbResilunit,BreakingStartDate,DateDeVigueur,
				DateResilComplete,
				DepassBareme,
				Justifications,
				Sousc,
				UnitDir,
				UnitRep
				
		UNION ALL

		-- les groupes d'unité non touchés par des résiliation
		SELECT DISTINCT
			C4.ConventionNo,
			ConventionStateID = NULL,
			U4.unitID,
			nbResilunit = 0,
			BreakingStartDate,
			DateDeVigueur = U4.InforceDate,
			DateResilComplete = NULL,
			DateResilPartielle = NULL,
			DepassBareme = NULL,
			Justifications=NULL,
			Sousc = NULL,
			UnitDir = NULL,
			UnitRep = NULL,
			RaisonResilPartielle = NULL,
			NbDepotAvantReduct = mb.pmtQty, -- nb de dépôt de la modalité avant la réduction
			FraisCombles = 1, --0,
			MontantTFR = 0,
			ModeDepot = case 
						when Mb.PmtByYearID = 12 and Mb.PmtQty > 1 then 'Mensuel'
						when Mb.PmtByYearID = 1 and Mb.PmtQty > 1 then 'Annuel'
						when Mb.PmtByYearID = 1 and Mb.PmtQty = 1 then 'Forfait'
						end, -- NULL
			MoisEcouleDeVigueurAResil = NULL,
						
			UQtyBeforeReduct = u4.UnitQty,
			UQtyAfterReduct = u4.UnitQty,
			EpargneRemboursee = 0,
			MntDepotAvantResil = CAST(
							((u4.UnitQty * MB.PmtRate + (u4.UnitQty * MB.SubscriberInsuranceRate + (u4.UnitQty * MB.SubscriberInsuranceRate) * st.StateTaxPct) * U4.WantSubscriberInsurance ))
								+
							(  (ISNULL(BI.BenefInsurRate,0)  + ( ISNULL(BI.BenefInsurRate,0) * st.StateTaxPct)) * U4.WantSubscriberInsurance * (case when (u4.UnitQty ) > 0 then 1 else 0 end ))
							AS MONEY) ,
			MntDepotApresResil = CAST(
							((u4.UnitQty * MB.PmtRate + (u4.UnitQty * MB.SubscriberInsuranceRate + (u4.UnitQty * MB.SubscriberInsuranceRate) * st.StateTaxPct) * U4.WantSubscriberInsurance ))
								+
							(  (ISNULL(BI.BenefInsurRate,0)  + ( ISNULL(BI.BenefInsurRate,0) * st.StateTaxPct)) * U4.WantSubscriberInsurance * (case when (u4.UnitQty ) > 0 then 1 else 0 end ))
							AS MONEY)

		FROM dbo.Un_Unit u4
		JOIN dbo.Un_Convention c4 on u4.conventionid = c4.conventionid
		left join un_unitreduction ur4 on u4.unitid = ur4.unitid
		join #tmpResult T2 on c4.conventionno = T2.conventionno
		LEFT JOIN (
			SELECT 
				RB.RepID, 
				BossID = MAX(BossID)
			FROM Un_RepBossHist RB
			JOIN (
				SELECT 
					RB.RepID, 
					RepBossPct = MAX(RB.RepBossPct)
				FROM Un_RepBossHist RB
				WHERE RepRoleID = 'DIR'
					AND RB.StartDate <= @EndDate
					AND ISNULL(RB.EndDate,@EndDate) >= @EndDate
				GROUP BY 
					RB.RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate <= @EndDate
				AND ISNULL(RB.EndDate,@EndDate) >= @EndDate
			GROUP BY 
				RB.RepID
			) RD ON RD.RepID = U4.RepID
		LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = RD.BossID
		JOIN dbo.Mo_Human HR ON HR.HumanID = U4.RepID

		left JOIN Un_Modal MB ON MB.ModalID = U4.ModalID
		JOIN dbo.Un_Subscriber SS on SS.SubscriberID = C4.SubscriberID
		JOIN dbo.Mo_Human HS on HS.humanID = C4.SubscriberID
		join mo_state st on SS.stateid = st.stateid
		LEFT JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = SS.SubscriberID
		LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U4.BenefInsurID 
		where ur4.unitid is null				
				
	) Z
	--where ConventionNo = '2068712'
	group by
		ConventionNo
		--ConventionStateID
		--DepassBareme,
		--Justifications,
		--Sousc
	having sum(UQtyBeforeReduct) <> 0 -- pour ne pas afficher les annulation 
	and sum(UQtyBeforeReduct) - sum(UQtyAfterReduct) <> 0

	order by ConventionNo

	select 
		t.ConventionNo,
		DateDeVigueur,  
		DateResilComplete,
		DateResilPartielle,
		UQtyBeforeReduct,
		UQtyAfterReduct,
		EpargneRemboursee = isnull(EpargneRemboursee,0),
		MntDepotAvantResil,
		MntDepotApresResil,
		ModeDepot,
		NbDepotAvantReduct,
		FraisCombles,
		MontantTFR,
		MoisEcouleDeVigueurAResil, 
		RaisonResilPartielle, 
		Sousc,
		c.subscriberID,
		TelMaison = a.phone1,
		TelBureau = a.phone2,
		UnitDir,
		UnitRep,
		DepassBareme,
		Justifications
		,BreakingStartDate
		,DiffMoisBreakingVSResil = datediff(m,BreakingStartDate,DateResilPartielle)
	from 
		#TmpResil t
		JOIN dbo.Un_Convention c on c.conventionno = t.conventionno
		JOIN dbo.Mo_Human hs on c.subscriberID = hs.humanID
		JOIN dbo.Mo_Adr a on hs.adrID = a.adrID
	order by ConventionNo
			
	drop table #tmpResult
	DROP TABLE #tUnitReduction
	DROP TABLE #tUnitFeeReduction
	DROP TABLE #tUnitQtyReduction
	drop table #tUnitModalAfter
	drop table #tUnitModalbefore
	drop table #tNbDepotBeforeReduct

RETURN

end

/*
-- ####################### Le nb de convention par année ##########################

	select 
		P.plandesc,
		NbConvSansRIN = count(*)
	FROM dbo.Un_Convention c
	join un_plan p on c.planid = p.planid
	JOIN dbo.Mo_Human HB on HB.humanID = C.beneficiaryID -- select * FROM dbo.Mo_Human 

	join ( -- groupe d'unité SANS RIN à une date donnée
		select conventionid
		FROM dbo.Un_Unit 
		where IntReimbDate > '2009-12-31' or IntReimbDate is null
		group by conventionid
		) u on u.conventionid = c.conventionid
	join (  -- La plus récente d'état de convention par convention à une date donnée
			select 
				cs.conventionid,
				LaDate = max(cs.StartDate)
			from UN_ConventionConventionState cs
			where cs.StartDate <= '2009-12-31'
			group by cs.conventionid
		) csDate on c.conventionid = csDate.conventionid 
	join UN_ConventionConventionState cs on c.conventionid = cs.conventionid 
				and cs.StartDate = csDate.Ladate 
				and cs.ConventionStateID in ('REE','TRA')
	where p.planid in (8,10,12) -- select * from un_plan 
	group by P.plandesc
	
	--WHERE 	dbo.fn_Mo_Age(HB.birthDate,'2008-12-31') between 15 and 16

-- ####################### Le nb d'unité par année ##########################

	declare @Ladate datetime
	set @Ladate = '2009-12-31'

	select 
		Année = year(@Ladate),
		Régime = P.plandesc,
		NbConvSansRIN = count(distinct c.conventionid),
		NbUnite = sum(isnull(u1.UnitQty,0) + isnull(ur.QtyReduct,0))
	FROM dbo.Un_Convention c
	join un_plan p on c.planid = p.planid
	JOIN dbo.Mo_Human HB on HB.humanID = C.beneficiaryID -- select * FROM dbo.Mo_Human 

	join ( -- groupe d'unité SANS RIN à une date donnée
		select conventionid
		FROM dbo.Un_Unit 
		where IntReimbDate > @Ladate or IntReimbDate is null
		group by conventionid
		) u on u.conventionid = c.conventionid
	join (  -- La plus récente d'état de convention par convention à une date donnée
			select 
				cs.conventionid,
				LaDate = max(cs.StartDate)
			from UN_ConventionConventionState cs
			where cs.StartDate <= @Ladate
			group by cs.conventionid
		) csDate on c.conventionid = csDate.conventionid 
	join UN_ConventionConventionState cs on c.conventionid = cs.conventionid 
				and cs.StartDate = csDate.Ladate 
				and cs.ConventionStateID in ('REE','TRA')
	
	left JOIN dbo.Un_Unit u1 on c.conventionid = u1.conventionid and u1.inforcedate <= @Ladate
	left join (select unitid, QtyReduct = sum(unitqty)
				from un_unitreduction 
				where reductiondate > @Ladate
				group by unitid
		)ur on ur.unitid = u1.unitid
	where p.planid in (8,10,12) -- select * from un_plan 
	group by P.plandesc
	
*/