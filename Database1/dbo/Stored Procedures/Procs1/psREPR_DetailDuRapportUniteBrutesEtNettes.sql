/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	psREPR_DetailDuRapportUniteBrutesEtNettes
Description         :	Pour le rapport DetailDuRapportUniteBrutesEtNettes
Valeurs de retours  :	Dataset 
Note                :	2016-10-25	Donald Huppé			Création
						2018-09-07	Maxime Martel			JIRA MP-699 Ajout de OpertypeID COU
select *
from mo_human h
join un_rep r on h.humanid = r.repid
where h.lastname = 'marchand'

exec psREPR_DetailDuRapportUniteBrutesEtNettes_test '2016-10-03', '2016-11-20', 149497, 'R' , 0
exec psREPR_DetailDuRapportUniteBrutesEtNettes '2016-01-01', '2016-10-23', 0, 'R' , 1

*********************************************************************************************************************/
CREATE procedure [dbo].[psREPR_DetailDuRapportUniteBrutesEtNettes] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID INTEGER,
	@BossOrRep varchar(1), -- B ou R
	@ConvTSeulement INTEGER = 0
	) 

as
BEGIN



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
		Reinscriptions24 FLOAT,
		DateUnite DATETIME) 


	CREATE TABLE #UniteConvT (
		UnitID INT PRIMARY KEY, 
		RepID INT, 
		BossID INT,
		dtFirstDeposit DATETIME )

	INSERT INTO #UniteConvT
	SELECT * FROM fntREPR_ObtenirUniteConvT(1)

	-- Les données des Rep
	INSERT #GrossANDNetUnits -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits_DateUnite --NULL, @StartDate, @EndDate, 0, 1
		@ReptreatmentID = NULL,
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1, -- On veut les résultats groupés par unitID.  Sinon, c'est groupé par RepID et BossID
		@QteMoisRecrue = 12,
		@incluConvT = 1

	if @ConvTSeulement = 1
	BEGIN
		DELETE FROM #GrossANDNetUnits
		WHERE UnitID NOT IN (SELECT UnitID FROM #UniteConvT)
	END

	--SELECT  * FROM #UniteConvT


	SELECT 
		V.RepID
		,v.UnitID
		,Cotis_Periode = SUM(V.Cotis_Periode)
	INTO #Cotis_Periode
	from (
		select 
			u.RepID
			,u.UnitID
			,Cotis_Periode = sum(ct.Cotisation + ct.Fee)
		--INTO #Cotis_Periode
		from 
			dbo.Un_Convention c
			join dbo.un_unit u on c.ConventionID = u.ConventionID
			join dbo.un_cotisation ct on ct.UnitID = u.UnitID
			join dbo.un_oper o on ct.OperID = o.OperID
			left join dbo.Un_Tio TIOt on TIOt.iTINOperID = o.operid
			left join dbo.Un_Tio TIOo on TIOo.iOUTOperID = o.operid
		where 1=1
			--and u.InForceDate BETWEEN @StartDate and @EndDate 

			and u.InForceDate BETWEEN @StartDate AND @EndDate

			-- Si on saisit une plage de date de vigueur, on la prend, sinon c'est la plage de date habituelle
			--AND (
			--		((@StartDateInforceCotisation IS NOT NULL AND @EndDateInforceCotisation IS NOT NULL)	AND u.InForceDate BETWEEN @StartDateInforceCotisation AND @EndDateInforceCotisation)
			--	OR
			--		((@StartDateInforceCotisation IS NULL OR @EndDateInforceCotisation IS NULL)				AND u.InForceDate BETWEEN @StartDate AND @EndDate)
			--	)
			------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
			AND o.OperDate BETWEEN @StartDate and @EndDate
			AND o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET','COU')
			AND tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
			AND tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			-----------------------------------------------------------------------------------------------------------
		group by 
			u.RepID
			,u.UnitID

		UNION ALL

		-- cont T
		select 
			T.RepID
			,u.UnitID
			,Cotis_Periode = sum(ct.Cotisation + ct.Fee)
		--into #Cotis
		from 
			Un_Convention c
			JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
			join #UniteConvT T on u.UnitID = T.UnitID
			join un_cotisation ct on ct.UnitID = u.UnitID
			join un_oper o on ct.OperID = o.OperID
			left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
			left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
		where 1=1
			-- Si on saisit une plage de date de vigueur, on la prend, sinon c'est la plage de date habituelle
			--AND (
			--		((@StartDateInforceCotisation IS NOT NULL AND @EndDateInforceCotisation IS NOT NULL)	AND u.InForceDate BETWEEN @StartDateInforceCotisation AND @EndDateInforceCotisation)
			--	OR
			--		((@StartDateInforceCotisation IS NULL OR @EndDateInforceCotisation IS NULL)				AND u.InForceDate BETWEEN @StartDate AND @EndDate)
			--	)
			------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
			and o.OperDate BETWEEN @StartDate and @EndDate
			and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET','COU')
			and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
			and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			-----------------------------------------------------------------------------------------------------------
		group by 
			T.RepID
			,u.UnitID

		)V
	GROUP BY V.RepID,v.UnitID

	select 
		RepCode,
		Representant,
		Directeur,
		Souscripteur,
		Beneficiaire,
		conventionno,
		UnitID,
		Brut,
		Retraits,
		Reinscriptions,
		Net,
		Date1erDepot,
		DateUnite,
		DateVigueur,
		QteuniteNow,
		Cotis_Periode
	from (

			select 
				--UnitID_Ori,
				--GNU.repid,
				--GNU.bossid,
				r.RepCode,
				Representant = HR.firstname + ' ' + HR.lastname,
				Directeur = HB.firstname + ' ' + HB.lastname,
				Souscripteur = hs.firstname + ' '+ hs.LastName,
				Beneficiaire = hben.firstname + ' ' + hben.lastname,
				c.conventionno,
				GNU.UnitID,
				Brut,
				Retraits,
				Reinscriptions,
				Net = (Brut - Retraits + Reinscriptions),  
				Date1erDepot = isnull(Convt.dtFirstDeposit,u.dtFirstDeposit),
				DateUnite,
				DateVigueur = u.InForceDate,
				QteuniteNow = u.UnitQty
				,Cotis_Periode = isnull(Cotis_Periode,0)
				--DateCodage = SD.StartDate



			from #GrossANDNetUnits GNU
			JOIN dbo.Un_Unit U on GNU.UnitID = U.UnitID
			JOIN un_rep R on r.RepID = gnu.RepID
			JOIN dbo.Mo_Human hr on GNU.repid = hr.humanid
			left JOIN dbo.Mo_Human hb on GNU.BossId = hb.humanid -- left join sur hb car le bossid peut être 0 -- cas de divorce (InforceDate est avant l'embauche du Rep)
			JOIN dbo.Un_Convention c on u.conventionID = c.conventionID
			JOIN dbo.Mo_Human hs on c.subscriberid = hs.humanid
			JOIN dbo.Mo_Human hben on c.beneficiaryid = hben.humanid
			LEFT JOIN #UniteConvT ConvT on ConvT.UnitID = GNU.UnitID
			LEFT JOIN #Cotis_Periode CP on cp.repid = gnu.RepID and CP.unitID = gnu.UnitID
			left join (
				select 
					unitid,
					startDate = min(startDate) 
				from Un_UnitUnitState
				group by unitid
				) sd on sd.unitid = U.unitid
			where	( 
						( @RepID = 0 AND @ConvTSeulement = 1)
					OR	( @BossOrRep = 'R' and GNU.repid  = @RepID) 
					OR	( @BossOrRep = 'B' and GNU.bossid = @RepID)
			  
					)
				and (Brut <> 0 or Retraits <> 0 or Reinscriptions <> 0)

			UNION ALL

			select 
				--UnitID_Ori,
				--GNU.repid,
				--GNU.bossid,
				r.RepCode,
				Representant = HR.firstname + ' ' + HR.lastname,
				Directeur = HB.firstname + ' ' + HB.lastname,
				Souscripteur = hs.firstname + ' '+ hs.LastName,
				Beneficiaire = hben.firstname + ' ' + hben.lastname,
				c.conventionno,
				GNU.UnitID,
				Brut = 0,
				Retraits = 0,
				Reinscriptions = 0,
				Net = 0,
				Date1erDepot = GNU.dtFirstDeposit,
				DateUnite = GNU.dtFirstDeposit,
				DateVigueur = u.InForceDate,
				QteuniteNow = u.UnitQty
				,Cotis_Periode = isnull(Cotis_Periode,0)
				--DateCodage = SD.StartDate



			from #UniteConvT GNU
			JOIN dbo.Un_Unit U on GNU.UnitID = U.UnitID
			JOIN #Cotis_Periode CP on cp.repid = gnu.RepID and CP.unitID = gnu.UnitID
			JOIN un_rep R on r.RepID = gnu.RepID
			JOIN dbo.Mo_Human hr on GNU.repid = hr.humanid
			left JOIN dbo.Mo_Human hb on GNU.BossId = hb.humanid -- left join sur hb car le bossid peut être 0 -- cas de divorce (InforceDate est avant l'embauche du Rep)
			JOIN dbo.Un_Convention c on u.conventionID = c.conventionID
			JOIN dbo.Mo_Human hs on c.subscriberid = hs.humanid
			JOIN dbo.Mo_Human hben on c.beneficiaryid = hben.humanid
			--LEFT JOIN #UniteConvT ConvT on ConvT.UnitID = GNU.UnitID
	 
			left join (
				select 
					unitid,
					startDate = min(startDate) 
				from Un_UnitUnitState
				group by unitid
				) sd on sd.unitid = U.unitid
			where	( 
						( @RepID = 0 AND @ConvTSeulement = 1)
					OR	( @BossOrRep = 'R' and GNU.repid  = @RepID) 
					OR	( @BossOrRep = 'B' and GNU.bossid = @RepID)
			  
					)
				and u.unitid not in (SELECT unitid from #GrossANDNetUnits)
		)v

	order by RepCode,conventionno


END