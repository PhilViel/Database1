/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas Inc.
Nom                 :	psREPR_ConstatationHonorairesAdhesion_A_Venir_2011 
Description         :	Procédure stockée du rapport de Constatation des Honoraires d'Adhesion à venir 2011 
						Probablement un rapport temporaire pour 2011 (voir Anne Mainguy).
Valeurs de retours  :	Dataset 
Note                :	2011-04-26	Donald Huppé	Création (glpi 5434)
						2011-10-21	Donald Huppé	GLPI 6246 - Ne plus exclure les RIO
						2011-11-29	Donald Huppé	glpi 6462 : annulation du glpi 6246
						2012-01-06	Donald Huppé	glpi 6700 : on exclut les RIO et TRI mais on inclut les frais transféré dans les individuels des RIO et TRI 
						2012-02-08	Donald Huppé	glpi 6880 : Nouveau calcul pour les frais à recevoir. Il faut prendre le solde des frais totaux dans la convention qui est 
																ouverte en date demandée et non l'ancien calcul qui n'incluait pas les TFR entre entre
																
exec psREPR_ConstatationHonorairesAdhesion_A_Venir_2011 '2011-12-31'

drop proc psREPR_CodeDeCommissionConstatation2011
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ConstatationHonorairesAdhesion_A_Venir_2011] (
	@EndDate DATETIME ) 
AS
BEGIN

	create table #TmpMonthList (Incr int, MonthNo int, TheDate datetime) -- drop table TmpMonthList
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
		NextFullPmtToPay,
		NextHalfPmtToPay = case when MontantDepot > 0 
								then floor(( totalFeeToPay - FeePaid - (NextFullPmtToPay *  MontantDepot  )) / ( MontantDepot / 2))
								else 0
								end
		,LastPmt =  case when MontantDepot > 0 
						then TotalFeeToPay - FeePaid - (NextFullPmtToPay * MontantDepot) - ((floor(( totalFeeToPay - FeePaid - (NextFullPmtToPay *  MontantDepot  )) / ( MontantDepot / 2))) *(MontantDepot/2)  )
						else 0
						end
	into #TmpFee -- drop table #TmpFee
	from (
		select 
			c.conventionno,
			u.unitid,
			U.dtfirstdeposit,
			DateLastPmt,
			modal = Case 
					when PmtByYearID = 12 then 'Mensuel'
					when PmtByYearID = 1 and PmtQty > 1 then 'Annuel'
					End,
			UnitQty = sum(u.unitqty + isnull(qtyreduct,0)),
			TotalFeeToPay = (sum(u.unitqty+isnull(qtyreduct,0))*200),
			FeePaid = sum(isnull(FeePaid,0)),
			
			--test
			--FeePaid = sum(isnull(FeePaid,0)) +sum(isnull(FeeTRAPaid,0)),
			
			FeeLeftToPay = (sum(u.unitqty + isnull(qtyreduct,0)) * 200 ) - sum(isnull(FeePaid,0)),
			
			--test
			--FeeLeftToPay = (sum(u.unitqty + isnull(qtyreduct,0)) * 200 ) - sum(isnull(FeePaid,0)) - sum(isnull(FeeTRAPaid,0)),

			MontantDepot = sum(u.unitqty + isnull(qtyreduct,0)) * PmtRate,

			NextFullFeeToPay =	case when sum(isnull(FeePaid,0)) <= ((sum(u.unitqty+isnull(qtyreduct,0))*200)) / 2
								then ((sum(u.unitqty + isnull(qtyreduct,0)) * 200 )  /2) - sum(isnull(FeePaid,0))
								else 0
								end,
			
			/*
			--test
			NextFullFeeToPay = case when sum(isnull(FeePaid,0))+sum(isnull(FeeTRAPaid,0)) <= ((sum(u.unitqty+isnull(qtyreduct,0))*200)) / 2
								then ((sum(u.unitqty + isnull(qtyreduct,0)) * 200 )  /2) - sum(isnull(FeePaid,0)) - sum(isnull(FeeTRAPaid,0))
								else 0
								end,
			*/

			NextFullPmtToPay = case when (sum(isnull(FeePaid,0)) <= ((sum(u.unitqty+isnull(qtyreduct,0))*200)) / 2) AND (sum(u.unitqty + isnull(qtyreduct,0)) * PmtRate) > 0 
									then CEILING(((((sum(u.unitqty + isnull(qtyreduct,0)) * 200 ) ) /2) - sum(isnull(FeePaid,0))) / (sum(u.unitqty + isnull(qtyreduct,0)) * PmtRate)) 
									else 0 end,
			/*
			--test
			NextFullPmtToPay = case when (sum(isnull(FeePaid,0))+sum(isnull(FeeTRAPaid,0)) <= ((sum(u.unitqty+isnull(qtyreduct,0))*200)) / 2) AND (sum(u.unitqty + isnull(qtyreduct,0)) * PmtRate) > 0 
									then CEILING(((((sum(u.unitqty + isnull(qtyreduct,0)) * 200 ) ) /2) - sum(isnull(FeePaid,0))-sum(isnull(FeeTRAPaid,0))) / (sum(u.unitqty + isnull(qtyreduct,0)) * PmtRate)) 
									else 0 end,
			*/

			NextHalfPmtToPay =  FLOOR( ( (sum(u.unitqty + isnull(qtyreduct,0)) * 200 )  -  sum(isnull(FeePaid,0)) - ((((sum(u.unitqty + isnull(qtyreduct,0)) * 200 ) - sum(FeePaid)) /2) - sum(isnull(FeePaid,0))) ) / ( (sum(u.unitqty + isnull(qtyreduct,0)) * PmtRate) / 2  ) )
			
			--test
			--NextHalfPmtToPay =  FLOOR( ( (sum(u.unitqty + isnull(qtyreduct,0)) * 200 )  -  sum(isnull(FeePaid,0)) - sum(isnull(FeeTRAPaid,0)) - ((((sum(u.unitqty + isnull(qtyreduct,0)) * 200 ) - sum(isnull(FeePaid,0)) - sum(isnull(FeeTRAPaid,0))) /2) - sum(isnull(FeePaid,0))) ) / ( (sum(u.unitqty + isnull(qtyreduct,0)) * PmtRate) / 2  ) )

		FROM dbo.Un_Convention c
		JOIN dbo.Un_Unit u on c.conventionid = u.conventionid --AND u.dtfirstdeposit >= '2011-01-01'

		JOIN (
		
			SELECT 
				c.ConventionNo,
				c.conventionid,
				u.UnitID,
				--FeeLeftToPay = sum((ur1.UniteNetteEnDate * 200) - FraisEncaisses)
				FeePaid = sum(FraisEncaisses)
				
			from 
				Un_Convention c
				JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID AND u.dtFirstDeposit >= '2011-01-01' and isnull(u.TerminatedDate,'3000-01-01') > @EndDate AND isnull(u.IntReimbDate,'3000-01-01') > @EndDate
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
							from un_conventionconventionstate
							where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @EndDate -- Si je veux l'état à une date précise 
							group by conventionid
							) ccs on ccs.conventionid = cs.conventionid 
								and ccs.startdate = cs.startdate 
								and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
					
				JOIN ( 
					select u1.unitid, UniteNetteEnDate = u1.unitqty + isnull(ur2.QteReduite,0)
					from  un_unit u1 
					LEFT JOIN (
						select unitid, QteReduite = sum(unitqty) 
						from un_unitreduction 
						where ReductionDate > @EndDate 
						group by unitid) ur2 on u1.unitid = ur2.unitid
					where 
						u1.dtFirstDeposit >= '2011-01-01' 
						and isnull(u1.TerminatedDate,'3000-01-01') > @EndDate
					) ur1 on u.unitid = ur1.unitid
					
				JOIN (	
						SELECT 
							U.UnitID, FraisEncaisses = sum(Ct.Fee)
						FROM 
							dbo.Un_Unit U
							JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
							JOIN Un_Oper O ON O.OperID = Ct.OperID
						where 
							operdate <= @EndDate
							and u.dtFirstDeposit >= '2011-01-01' 
							and isnull(u.TerminatedDate,'3000-01-01') > @EndDate
						GROUP BY 
							U.UnitID
					) FE ON u.UnitID = FE.UnitID
				where 1=1
					AND c.PlanID <> 4
				GROUP BY
				c.ConventionNo,
				c.conventionid,
				u.UnitID

			) CC ON CC.unitid = u.UnitID

		JOIN un_modal m on u.modalid = m.modalid --and PmtByYearID = 12 -- PmtQty > 12 -- exclu les paiements uniques -- select distinct PmtQty from un_modal where PmtByYearID = 12 and PmtQty > 12

		left join (
			SELECT 
				U.UnitID, DateLastPmt = MAX(Operdate)
			FROM 
				dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
			where operdate <= @EndDate and Ct.Fee > 0
			GROUP BY 
				U.UnitID
			) LP on u.unitid = LP.unitid

		left join (
			select unitid, qtyreduct = sum(unitqty)
			from un_unitreduction -- select * from un_unitreduction
			where reductiondate > @EndDate
			group by unitid
			) r on u.unitid = r.unitid
		where 	PmtByYearID = 12	or (PmtByYearID = 1 and PmtQty > 1) --ori
		
		group by c.conventionno,u.unitid,m.PmtQty,m.PmtRate,u.dtFirstDeposit,PmtByYearID,PmtQty, U.dtfirstDeposit,DateLastPmt
		
		having sum(u.unitqty + isnull(qtyreduct,0)) > 0
		) V

	--select 
	--	*
	--from #TmpFee	
	--where conventionno IN ('X-20111216014')

--select * into tmp_1	from #TmpFee
	
	--return

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
	join #TmpMonthList ML on (F.NextFullPmtToPay + F.NextHalfPmtToPay) = ML.MonthNo and ML.Incr > F.NextFullPmtToPay 
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
	join #TmpMonthList ML on (F.NextFullPmtToPay + F.NextHalfPmtToPay + 1) = ML.MonthNo and ML.Incr = (F.NextFullPmtToPay + F.NextHalfPmtToPay + 1)
	where modal = 'Mensuel'
	and TotalFeeToPay > MontantDepot

	-- Annuel
	insert into #TmpFinalFee
	select 
		'Annuel' ,
		conventionno,
		UnitID,
		UnitQty,
		FeePaid,
		TheDate = case 
					WHEN DateLastPmt IS not NULL THEN dateadd(d,-1,DATEADD(mm, DATEDIFF(mm,0,dateadd(yy,1,DateLastPmt))+1, 0))
					ELSE /*cas non gérable*/ dateadd(d,-1,DATEADD(mm, DATEDIFF(mm,0,dateadd(yy,1,dtfirstdeposit))+1, 0))
					END ,
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
		
	-- résultat final
	SELECT 	* from #TmpFinalFee -- where conventionno = 'X-20111213082'

	--select 
	--unitid, 
	--Pmt = sum(Pmt) 
	--INTO tmp_3
	--FROM #TmpFinalFee 
	--group by unitid

END


