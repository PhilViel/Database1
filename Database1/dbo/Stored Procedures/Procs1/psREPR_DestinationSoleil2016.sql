/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	psREPR_DestinationSoleil2016
Description         :	Rapport Destination Soleil 2016
Valeurs de retours  :	Dataset 
Note                :	2015-02-12	Donald Huppé	Création (glpi 13524)
						2015-03-19	Donald Huppé	Ajout des Rep sans vente, pour avoir la liste de tous les rep des agence
													,sera utilisé dans destination Soleil Agence pour avoir le nb de rep par agence
						2015-04-09	Donald Huppé	GLPI 14086 : exclure (AH Amyot Gélinas et KD Leprohon) partout et Ghislain Thibeault n'est pas une recrue
						2015-06-05	Donald Huppé	glpi 14752 : correction QualifRecrue
*********************************************************************************************************************/

--  exec psREPR_DestinationSoleil2016 '2015-01-01', '2015-05-31' , '2014-01-01',  '2014-05-31', 22

CREATE procedure [dbo].[psREPR_DestinationSoleil2016] 
	(
	@DateDu DATETIME, -- Date de début
	@DateAu DATETIME, -- Date de fin
	@DateDuPrec DATETIME, -- Date de début
	@DateAuPrec DATETIME, -- Date de fin
	@NbSemaine int
	) 

as
BEGIN
	/*
		set @DateDu  = '2015-01-01'
		set @DateAu  = '2015-02-01'
		set @DateDuPrec  = '2014-01-01'
		set @DateAuPrec  = '2014-02-02'
		set @NbSemaine  = 5
	*/

	declare @DateDebutAnneePrec datetime = cast(year(@DateDuPrec) as varchar) + '-01-01'
	declare @DateFinAnneePrec datetime = cast(year(@DateDuPrec) as varchar) + '-09-28'

	--select @DateFinAnneePrec
	 
 	SELECT
		RB.RepID,
		BossID = MAX(BossID)
	into #BossRepActuel
	FROM Un_RepBossHist RB
	JOIN (
		SELECT
			RepID,
			RepBossPct = MAX(RepBossPct)
		FROM Un_RepBossHist RB
		WHERE RepRoleID = 'DIR'
			AND StartDate IS NOT NULL
			AND (StartDate <= @DateAu)
			AND (EndDate IS NULL OR EndDate >= @DateAu)
		GROUP BY
			RepID
		) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
	WHERE RB.RepRoleID = 'DIR'
		AND RB.StartDate IS NOT NULL
		AND (RB.StartDate <= @DateAu)
		AND (RB.EndDate IS NULL OR RB.EndDate >= @DateAu)
	GROUP BY
		RB.RepID	
 	
	-- changer le directeur actuel du rep pour les rep du NB :glpi 14752
	update BR set BR.BossID = LA.BossID
	from #BossRepActuel BR
	join tblREPR_LienAgenceRepresentantConcours LA ON BR.RepID = LA.RepID
	where LA.BossID = 671417

	create table #GrossANDNetUnitsPrec (
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
	INSERT #GrossANDNetUnitsPrec -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateDuPrec, @DateAuPrec, 0, 1

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
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateDu, @DateAu, 0, 1

	create table #GrossANDNetUnitsAnneePrecFull (
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
	INSERT #GrossANDNetUnitsAnneePrecFull -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateDebutAnneePrec, @DateFinAnneePrec, 0, 1

	select 

		RepCode,
		Representant
		,Agence = ltrim(rtrim(replace(Agence,'Agence','')))
		,BusinessStart
		,QteUniteNettesAnneePrec
		,QteUniteNettesPrec
		,QteUniteNettes
		,QteUniteNettesRecrue = case when v.RepCode <> 70098 then QteUniteNettesRecrue else 0 end -- Ghislain Thibeault n'est pas recrue
		,ConsPct
		,QualifNonRecrue
		,QualifRecrue
		,Croissance
		,Cotis_Periode = case when Cotis_Periode <0 then 0 else Cotis_Periode end

	from (

		select 
			R.RepCode,
			Representant = hr.FirstName + ' ' + hr.LastName
			,Agence = hb.FirstName + ' ' + hb.LastName
			,r.BusinessStart

			,QteUniteNettesAnneePrec = SUM(QteUniteNettesAnneePrec)
			,QteUniteNettesPrec = SUM(QteUniteNettesPrec)

			,QteUniteNettes = SUM(QteUniteNettes)
			,QteUniteNettesRecrue = sum(QteUniteNettesRecrue)
			,ConsPct = round(MAX(ConsPct),2)
			,QualifNonRecrue = isnull(
									case 
									WHEN SUM(QteUniteNettes)>= 600 and round(SUM(ConsPct),2) >= 85 then 1
									when SUM(QteUniteNettes) >= @NbSemaine * 15.385  and round(SUM(ConsPct),2) >= 85 then 2
									end
								,999)
			,QualifRecrue = isnull(	
								case 
								WHEN SUM(QteUniteNettesRecrue /*QteUniteNettes*/)>= 300  and round(SUM(ConsPct),2) >= 95  then 1
								end
								,999)
			,Croissance =  SUM(QteUniteNettes) - SUM(QteUniteNettesPrec)
			,Cotis_Periode = sum(Cotis_Periode)
		from 
			(

			SELECT 
				gnuF.RepID
				,QteUniteNettesAnneePrec = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = 0
			FROM #GrossANDNetUnitsAnneePrecFull gnuF
			GROUP by 
				gnuF.RepID

			UNION ALL

			SELECT 
				gnuP.RepID
				,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,QteUniteNettes = 0
				,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = 0
			FROM #GrossANDNetUnitsPrec gnuP
			GROUP by 
				gnuP.RepID

			UNION ALL

			SELECT 
				gnu.RepID
				,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,QteUniteNettesRecrue = 0
				,ConsPct =	CASE
								WHEN SUM(Brut24) <= 0 THEN 0
								ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
							END
				,Cotis_Periode = 0
			FROM #GrossANDNetUnits gnu
			GROUP by 
				gnu.RepID

			UNION ALL

			SELECT 
				gnu.RepID
				,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				,QteUniteNettesRecrue = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,ConsPct = 0
				,Cotis_Periode = 0
			FROM #GrossANDNetUnits gnu
			where gnu.Recrue = 1
			and gnu.RepID <> 711180 -- exclure Marie-Ève Saulnier 
			GROUP by 
				gnu.RepID

			UNION ALL

			select 
				u.RepID
				,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = sum(ct.Cotisation + ct.Fee)
			from 
				Un_Convention c
				JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
				join un_cotisation ct on ct.UnitID = u.UnitID
				join un_oper o on ct.OperID = o.OperID
				left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
				left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
			where 
				u.SignatureDate BETWEEN @DateDu and @DateAu
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
				and o.OperDate BETWEEN @DateDu and @DateAu
				and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET')
				and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
				and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				-----------------------------------------------------------------------------------------------------------
			group by 
				u.RepID

			UNION ALL

			SELECT DISTINCT -- tous les Rep
				R.RepID
				,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				,QteUniteNettesRecrue = 0
				,ConsPct =	0
				,Cotis_Periode = 0
			FROM UN_REP R
			WHERE 
				ISNULL(R.BusinessStart,'9999-12-31') <= @DateAu
				and ISNULL(R.BusinessEnd,'9999-12-31') > @DateAu
				--and RepCode <> 6141 -- siege social

			) V
		JOIN UN_REP R ON V.RepID = R.RepID
		join #BossRepActuel br on r.RepID = br.RepID
		JOIN dbo.Mo_Human hb on br.BossID = hb.HumanID
		JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
		WHERE 
			ISNULL(R.BusinessStart,'9999-12-31') <= @DateAu
			and ISNULL(R.BusinessEnd,'9999-12-31') > @DateAu
			and RepCode <> 6141 -- siege social
			and (hr.FirstName + ' ' + hr.LastName) <> (hb.FirstName + ' ' + hb.LastName) --vente de directeur

		GROUP BY
			R.RepCode
			,hr.FirstName + ' ' + hr.LastName
			,hb.FirstName + ' ' + hb.LastName
			,r.BusinessStart

		) v
	where v.RepCode not in (70090,6141,70104,70105) -- APG Neuros + siege social + AH Amyot Gélinas + KD Leprohon
	order by v.QualifNonRecrue,QteUniteNettes desc

	drop TABLE #GrossANDNetUnits
	drop TABLE #GrossANDNetUnitsPrec

end
	--select * from un_rep where RepID = 629154


