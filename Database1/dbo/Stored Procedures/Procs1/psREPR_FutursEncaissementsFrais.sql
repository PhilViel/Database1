/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas Inc.
Nom                 :	psREPR_FutursEncaissementsFrais 
Description         :	Pour les projections de commissions (TT_UN_RepProjection)
Valeurs de retours  :	Dataset 
Note                :	2011-08-26	Donald Huppé	Création (glpi 5657)
						2013-03-11	Donald Huppé	Modification pour la gestion du paiement de frais à payer dans le mois où les 100$ de frais par unité est atteint.
													(IntermediaireFeeToPay)(MonthToPayIntermediairePmt)
						2013-04-02	Donald Huppé	Correction du calcul de "Mensuel Last Pmt"
						2014-10-07	Donald Huppé	glpi 10655 : Ajouter les dépot unique
						2014-10-21	Donald Huppé	glpi 10655 : DateLastPmt = isnull(DateLastPmt,u.dtFirstDeposit)
						2018-04-12	Guehel Bouanga	JIRA: MC-380 Calculer le nombre d'unites sur la base des frais encaissés dans le régime individuel
--'X-20120301005
exec psREPR_FutursEncaissementsFrais '2012-03-30'

tester avec U-20030919045
exec psREPR_FutursEncaissementsFrais '2003-09-30'

X-20120210100
exec psREPR_FutursEncaissementsFrais '2014-10-12'

exec psREPR_FutursEncaissementsFrais 
		@EndDate = '2014-10-12' 
		,@Conventionno = 'X-20140924030'--   'x-20130308001' 
		,@UnitID = null

drop proc psREPR_FutursEncaissementsFrais
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_FutursEncaissementsFrais] (
	@EndDate DATETIME,
	@Conventionno VARCHAR(30) = NULL,
	@UnitID INT = NULL )
AS
BEGIN

	create table #TmpMonthList (Incr int, MonthNo int, TheDate datetime) 
	declare @i integer
	declare @j integer
	declare @StartDate datetime
	declare @TheDate datetime

	set @StartDate = @EndDate
	set @i = 1
	while @i <= 48
		begin
		set @j = 1
		while @j <= @i
			begin
			set @TheDate =  dateadd(d,-1,DATEADD(mm, DATEDIFF(mm,0,@StartDate) +@j + 1, 0))
			insert into #TmpMonthList values (@j, @i, @TheDate)
			--print @TheDate
			set @j = @j + 1
			end
		set @i = @i + 1
		end

	print '1'
	--print GETDATE()

	--SELECT * FROM #TmpMonthList

	select 
		conventionno,
		unitid,
		dtfirstdeposit,
		DateLastPmt,
		modal,
		UnitQty,
		TotalFeeToPay,
		FeePaid,
		FeeLeftToPay,
		MontantDepot,
		NextFullFeeToPay,
							  
		-- Montant de frais à payer dans le mois où les 100$ de frais par unité est atteint.
		IntermediaireFeeToPay,

		--NextFullPmtToPay,
		
		NextFullPmtToPay = (floor(NextFullFeeToPay/MontantDepot)*MontantDepot)/MontantDepot,
		
		-- Quantité de mois (0 ou 1) où il faut payer le paiement inrtermédiaire suite aux NextFullPmtToPay
		MonthToPayIntermediairePmt = CASE WHEN IntermediaireFeeToPay > 0 AND IntermediaireFeeToPay <> MontantDepot then 1 ELSE 0 end,
		
		NextHalfPmtToPay = case when MontantDepot > 0 
								then floor(
												( 
												totalFeeToPay 
												- FeePaid 
												- (	 ((floor(NextFullFeeToPay/MontantDepot)*MontantDepot)/MontantDepot)  --NextFullPmtToPay 
													* MontantDepot 
												   )
												- IntermediaireFeeToPay
												) 
												/ 
												( MontantDepot / 2)
											)
								else 0
								end,
		LastPmt =  case when MontantDepot > 0 
						then	
								TotalFeeToPay 
							-	FeePaid 
							-	(	((floor(NextFullFeeToPay/MontantDepot)*MontantDepot)/MontantDepot) -- NextFullPmtToPay 
									*
									MontantDepot) 
							-	IntermediaireFeeToPay
							
							-	(
									(FLOOR	(
										
												( 
												totalFeeToPay 
												- FeePaid 
												-	(
														((floor(NextFullFeeToPay/MontantDepot)*MontantDepot)/MontantDepot)--NextFullPmtToPay 
													*  
														MontantDepot  
													)
												- IntermediaireFeeToPay
												) 
											/ 
												( MontantDepot / 2)
										
											)
										 
									*
									(MontantDepot/2)  
								
									)
								)
							
						else 0
						end
					
	into #TmpFee -- drop table #TmpFee
	from (
		select 
			c.conventionno,
			u.unitid,
			U.dtfirstdeposit,
			DateLastPmt = isnull(DateLastPmt,u.dtFirstDeposit),
			modal = Case 
					when PmtByYearID = 12 then 'Mensuel'
					when PmtByYearID = 1 and PmtQty > 1 then 'Annuel'
					End,
			UnitQty =  sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0)END),
			TotalFeeToPay = (sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty+isnull(qtyreduct,0) END)*200),
			FeePaid = sum(isnull(FeePaid,0)),
			
			FeeLeftToPay = (sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0)END)  * 200 ) - sum(isnull(FeePaid,0)),

			MontantDepot = round(sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * PmtRate ,2),  --(round(sum(u.unitqty + isnull(qtyreduct,0)) * PmtRate ,2))
			
			NextFullFeeToPay = case when sum(isnull(FeePaid,0)) <= ((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty+isnull(qtyreduct,0)END)*200)) / 2
								then ((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * 200 ) /2)	- sum(isnull(FeePaid,0)) --(((sum(u.unitqty + isnull(qtyreduct,0)) * 200 ) /2)	- sum(isnull(FeePaid,0)))
								else 0
								end,

			-- Pour voir d'où viennent les montants pour calculer  IntermediaireFeeToPay
			/*
			IntermediaireFeeToPay =	NextFullFeeToPay 
								-((FLOOR(NextFullFeeToPay/MontantDepot))*MontantDepot ) 
								+ (MontantDepot - (NextFullFeeToPay -((FLOOR(NextFullFeeToPay/MontantDepot))*MontantDepot )) ) /2,
			*/
			IntermediaireFeeToPay = case when sum(isnull(FeePaid,0)) <= ((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty+isnull(qtyreduct,0)END)*200)) / 2
									then
									(((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * 200 ) /2)	- sum(isnull(FeePaid,0))) 
									-((FLOOR((((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * 200 ) /2)	- sum(isnull(FeePaid,0)))/((round(sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * PmtRate ,2)))))*((round(sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * PmtRate ,2))) ) 
									+ (((round(sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * PmtRate ,2))) - ((((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0)END)  * 200 ) /2)	- sum(isnull(FeePaid,0))) -((FLOOR((((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE  u.unitqty + isnull(qtyreduct,0) END) * 200 ) /2)	- sum(isnull(FeePaid,0)))/((round(sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0)END) * PmtRate ,2)))))*((round(sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * PmtRate ,2))) )) ) /2
									else 0
									end,

			NextFullPmtToPay = case when (sum(isnull(FeePaid,0)) <= ((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty+isnull(qtyreduct,0) END)*200)) / 2) AND (sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * PmtRate) > 0 
									then CEILING(((((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * 200 ) ) /2) - sum(isnull(FeePaid,0))) / (sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * PmtRate)) 
									else 0 end,
			
			NextHalfPmtToPay =  FLOOR( ( (sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * 200 )  -  sum(isnull(FeePaid,0)) - ((((sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * 200 ) - sum(FeePaid)) /2) - sum(isnull(FeePaid,0))) ) / ( (sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) * PmtRate) / 2  ) )
			
		FROM dbo.Un_Convention c
		JOIN dbo.Un_Unit u on c.conventionid = u.conventionid

		JOIN (
			SELECT
				C.ConventionID,
				C.conventionNo,
				u1.unitid,
				FeePaid = SUM(Ct.Fee)
				
			from 
				Un_oper O 
				JOIN Un_Cotisation Ct on Ct.operID = O.operID
				JOIN dbo.Un_Unit U1 ON Ct.UnitID = U1.UnitID
				JOIN dbo.Un_Convention C on U1.ConventionID = C.ConventionID
			where 
				O.OperDate <= @EndDate
				AND O.OperTypeID <> 'RIN' -- Exclure les remboursement de RI
			group by
				C.ConventionID,
				C.conventionNo,
				u1.unitid
			) CC ON CC.unitid = u.UnitID

		JOIN un_modal m on u.modalid = m.modalid --and PmtByYearID = 12 -- PmtQty > 12 -- exclu les paiements uniques -- select distinct PmtQty from un_modal where PmtByYearID = 12 and PmtQty > 12

		left join (
			SELECT 
				U.UnitID, DateLastPmt = MAX(Operdate)
			FROM 
				dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				LEFT JOIN Mo_BankReturnLink br ON O.OperID = br.BankReturnSourceCodeID 
			where (operdate <= @EndDate and Ct.Fee > 0)
			AND br.BankReturnSourceCodeID IS NULL -- pas revenu NSF 
			GROUP BY 
				U.UnitID
			) LP on u.unitid = LP.unitid
		LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@EndDate, NULL) UI on UI.UnitID = U.UnitID
		left join (
			select unitid, qtyreduct = sum(unitqty)
			from un_unitreduction
			where reductiondate > @EndDate
			group by unitid
			) r on u.unitid = r.unitid
		where 	(PmtByYearID = 12	or (PmtByYearID = 1 and PmtQty > 1))
		AND (c.ConventionNo = @Conventionno OR @Conventionno IS NULL)
		AND (u.UnitID = @UnitID OR @UnitID is NULL)
		group by c.conventionno,u.unitid,m.PmtQty,m.PmtRate,u.dtFirstDeposit,PmtByYearID,PmtQty, U.dtfirstDeposit,DateLastPmt, C.PlanID, ISNULL(UI.UnitQty,0)
		having sum(CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u.unitqty + isnull(qtyreduct,0) END) > 0
		) V

	--select * from #TmpFee

	UPDATE #TmpFee SET NextHalfPmtToPay = 0 WHERE NextHalfPmtToPay < 0

	print '2'
	--print GETDATE()
	--select * from #TmpMonthList

	create table #TmpFinalFee ( -- drop table #TmpFinalFee
		modal varchar(10),
		conventionno varchar(20),
		UnitID int,
		UnitQty float,
		FeePaid float,
		PmtDate datetime,
		Pmt float
		)	

	-- Mensuel Full Pmt
	insert into #TmpFinalFee
	select 
		'Mensuel' ,
		conventionno,
		UnitID,
		UnitQty,
		FeePaid,
		TheDate,
		case when MontantDepot < TotalFeeToPay then MontantDepot else totalFeeToPay end
	from #TmpFee F
	join #TmpMonthList ML on F.NextFullPmtToPay = ML.MonthNo
	where modal = 'Mensuel'

	-- Mensuel Pmt intermédiaire
	insert into #TmpFinalFee
	select 
		'Mensuel' ,
		conventionno,
		UnitID,
		UnitQty,
		FeePaid,
		TheDate,
		IntermediaireFeeToPay
	from #TmpFee F
	join #TmpMonthList ML on F.NextFullPmtToPay + F.MonthToPayIntermediairePmt = ML.MonthNo AND F.NextFullPmtToPay + F.MonthToPayIntermediairePmt = ML.Incr
	where modal = 'Mensuel'
	and MonthToPayIntermediairePmt > 0 AND IntermediaireFeeToPay <> MontantDepot

	-- Mensuel Half Pmt
	insert into #TmpFinalFee
	select 
		'Mensuel' ,
		conventionno,
		UnitID,
		UnitQty,
		FeePaid,
		TheDate,
		MontantDepot/2
		--,*
	from #TmpFee F
	join #TmpMonthList ML on (F.NextFullPmtToPay + F.NextHalfPmtToPay + MonthToPayIntermediairePmt) = ML.MonthNo and ML.Incr > F.NextFullPmtToPay + MonthToPayIntermediairePmt
	where modal = 'Mensuel'

	-- Mensuel Last Pmt
	insert into #TmpFinalFee
	select 
		'Mensuel' ,
		conventionno,
		UnitID,
		UnitQty,
		FeePaid,
		TheDate,
		LastPmt
		--,*
	from #TmpFee F
	join #TmpMonthList ML on 
			(F.NextFullPmtToPay + F.NextHalfPmtToPay+ MonthToPayIntermediairePmt + 1) = ML.MonthNo 
			and (F.NextFullPmtToPay + F.NextHalfPmtToPay+ MonthToPayIntermediairePmt + 1) = ML.Incr
	where modal = 'Mensuel'
	-- 2014-06-05
	--and TotalFeeToPay > MontantDepot

	-- Annuel
	insert into #TmpFinalFee
	select 
		'Annuel' ,
		conventionno,
		UnitID,
		UnitQty,
		FeePaid,
		TheDate = dateadd(d,-1,DATEADD(mm, DATEDIFF(mm,0,dateadd(yy,1,DateLastPmt))+1, 0)) ,
		FeeLeftToPay
	from #TmpFee F
	where modal = 'Annuel'
	and FeeLeftToPay > 0

	/*
	-- Ni Annuel, ni mensuel
	insert into #TmpFinalFee
	select 
		'ND' ,
		conventionno,
		UnitID,
		UnitQty,
		FeePaid,
		TheDate = dateadd(mm,1,@Enddate) ,
		FeeLeftToPay
	from #TmpFee F
	where modal is null
	and FeeLeftToPay > 0
	*/
		
	print '3'
	--print GETDATE()	
	-- résultat final
	
	SELECT DISTINCT
		modal,
		conventionno,
		UnitID,
		UnitQty,
		FeePaid,
		PmtDate,
		Pmt
	
	FROM (
		SELECT 
			modal,
			conventionno,
			UnitID,
			UnitQty,
			FeePaid,
			PmtDate,
			Pmt -- = ROUND(Pmt,2)
		FROM #TmpFinalFee --where unitid = 559564

		UNION ALL

		-- ajouter les dépot unique
		SELECT
			Modal = 'Unique',
			C.conventionNo,
			u1.unitid,
			UnitQty = CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE u1.UnitQty END,
			FeePaid = SUM(Ct.Fee),
			-- mettre la date du paiement à la fin du premier mois
			PmtDate = (SELECT thedate FROM #TmpMonthList WHERE incr = 1 AND monthno = 1),
			Pmt = ( (CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U1.UnitQty + ISNULL(qtyreduct,0) END) * 200) - SUM(Ct.Fee) 
		FROM 
			Un_oper O 
			JOIN Un_Cotisation Ct on Ct.operID = O.operID
			JOIN dbo.Un_Unit U1 ON Ct.UnitID = U1.UnitID
			JOIN Un_Modal m ON U1.ModalID = m.ModalID
			JOIN dbo.Un_Convention C on U1.ConventionID = C.ConventionID
			LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@EndDate, NULL) UI on UI.UnitID = U1.UnitID
			left join (
				select unitid, qtyreduct = sum(unitqty)
				from un_unitreduction
				where reductiondate > @EndDate
				group by unitid
				) r on u1.unitid = r.unitid		
		where 
			O.OperDate <= @EndDate
			AND O.OperTypeID <> 'RIN' -- Exclure les remboursement de RI
			AND m.PmtQty = 1
			AND (C.ConventionNo = @Conventionno OR @Conventionno is NULL)
			AND (u1.unitid = @UnitID OR @UnitID IS NULL)
			
		group by
			C.ConventionID,
			C.conventionNo,
			u1.unitid,
			U1.UnitQty,
			ISNULL(UI.UnitQty,0),
			ISNULL(qtyreduct,0),
			C.PlanId
		)V
	--select SUM(Pmt) from #TmpFinalFee
	--SELECT DISTINCT UnitID into TmpU2 from #TmpFinalFee

-- 1002022
-- 1081905
END