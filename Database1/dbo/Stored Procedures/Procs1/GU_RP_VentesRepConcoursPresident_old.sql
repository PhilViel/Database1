/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_VentesRepConcoursPresident (GU_RP_VentesExcelRepConcoursUnitBenef)
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants pour le rapport SSRS "Club du Président"
Valeurs de retours  :	Dataset 
Note                :	2009-03-04	Donald Huppé	Créaton (à partir de GU_RP_VentesExcelRepConcoursUnitBenef)
						2009-09-01	Donald Huppé	hardcoder certaines dates de début d'agence (GLPI 2220)
						2009-09-21	donald Huppé	remplacé cet SP par la nouvelle SP avec les nouveaux calculs de rétention
*********************************************************************************************************************/

-- exec GU_RP_VentesRepConcoursPresident '2008-10-01', '2009-07-01' , '2007-10-01',  '2008-07-01'

CREATE procedure [dbo].[GU_RP_VentesRepConcoursPresident_old] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@StartDatePrec DATETIME, -- Date de début
	@EndDatePrec DATETIME -- Date de fin
	) 

as
BEGIN

declare	@tFinal TABLE(
		Groupe varchar(10),
		RepID int,
		RepCode varchar(30),
		Rep varchar(255),
		BusinessStart DATETIME,
		Agence varchar(255),
		AgenceStart DATETIME,
		Point float,
		ConsPct float,
		PointPrec float
		)

declare	@tConsAg TABLE(
		Agence varchar(255),
		ConsPct float
		)

	insert into @tFinal

	select -- Les Rep
		Groupe = 'REP',
		repID, 
		RepCode, 
		Rep, 
		BusinessStart, 
		Agence, 
		AgenceStart = '1900-01-01',
		Point, 
		ConsPct = round(ConsPct,1),
		PointPrec = 0
	from 
		FN_VentesRep (@StartDate, @EndDate , 0,  'REP')

	UNION

/*
Date de début d'agence : 

Michel Maheu 149521: 1 avril 2000

Daniel Turpin 149602: 1 avril 2000

Maryse Logelin 298925: 1 décembre 2003

Martin Mercier 149593 : 1 avril 1996

Dolorès Dessureault 415878 : 13 mai 2007

*/

	select -- Les Directeurs
		Groupe,
		repID, 
		RepCode, 
		Rep, 
		BusinessStart, 
		Agence, 
		AgenceStart = case 
					when repID = 149521 then '2000-04-01'
					when repID = 149602 then '2000-04-01'
					when repID = 298925 then '2003-12-01'
					when repID = 149593 then '1996-04-01'
					when repID = 415878 then '2007-05-13'
					else AgenceStart
					end,
		Point = sum(Point), 
		ConsPct = sum(ConsPct),
		PointPrec = sum(PointPrec)

	from (
		select 
			Groupe = 'DIR',
			VR.repID, 
			VR.RepCode, 
			VR.Rep, 
			VR.BusinessStart, 
			Agence = Rep, 
			AgenceStart = Ag.DebutAgence,
			VR.Point, 
			VR.ConsPct,
			PointPrec = 0
		from 
			FN_VentesRep (@StartDate, @EndDate , 0,  'DIR') VR
			join (
				select 
					rh.repid,
					DebutAgence = MIN(startdate)
				from un_repbosshist rh
				where isnull(EndDate,'3000-01-01') > getdate()
				group by rh.repid
				)Ag on VR.repID = Ag.RepID

		UNION

		select 
			Groupe = 'DIR',
			VR.repID, 
			VR.RepCode, 
			VR.Rep, 
			VR.BusinessStart, 
			Agence = VR.Rep, -- Agence n'est pas utilisé ici alors on le met = au Rep(nom de l'agence) afin de regrouper le tout
			AgenceStart = Ag.DebutAgence,
			Point = 0, 
			ConsPct = 0,
			PointPrec = VR.Point
		from 
			FN_VentesRep (@StartDatePrec, @EndDatePrec , 0,  'DIR') VR
			join (
				select 
					rh.repid,
					DebutAgence = MIN(startdate)
				from un_repbosshist rh
				where isnull(EndDate,'3000-01-01') > getdate()
				group by rh.repid
				)Ag on VR.repID = Ag.RepID
		where VR.repID <> 496768 -- exclure l'ancien directeur Vahan Matossian
		) V
	group by 
		Groupe,
		repID, 
		RepCode, 
		Rep, 
		BusinessStart, 
		Agence,
		case 
			when repID = 149521 then '2000-04-01'
			when repID = 149602 then '2000-04-01'
			when repID = 298925 then '2003-12-01'
			when repID = 149593 then '1996-04-01'
			when repID = 415878 then '2007-05-13'
			else AgenceStart
			end

	declare @RepID integer
	declare @businessStart datetime
	declare @EndDateREC datetime

	-- Pour le tableau "Recrue de l'année"
	DECLARE MyCursor CURSOR FOR

		select --top 2 -- pour tester
			repid , businessStart
		from 
			un_rep 
		where 
			businessStart between dateADD(month,-12,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) 
			and isnull(businessEnd,'3000-01-01') > @EndDate 
			and repid in (select repid FROM dbo.Un_Unit where dtfirstDeposit between dateADD(month,-24,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) )
		order by businessStart

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @RepID, @businessStart

	WHILE @@FETCH_STATUS = 0
	BEGIN

		if dateADD(month,12,@businessStart) >= @EndDate
		begin
			set @EndDateREC = @EndDate		
		end
		else
		begin
			set @EndDateREC = dateADD(month,12,@businessStart)		
		end

		insert into @tFinal
		select 
			Groupe = 'REC',
			repID, 
			RepCode, 
			Rep, 
			BusinessStart, 
			Agence, 
			AgenceStart = '1900-01-01',
			Point, 
			ConsPct,
			PointPrec = 0
		from 
			FN_VentesRep (@businessStart, @EndDateREC, @RepID,  'REP')

		FETCH NEXT FROM MyCursor INTO @RepID, @businessStart
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor

	-- Pour le tableau "Mortier bâtisseur" (tableau d'agence)
	-- On prend les ventes de la recrue à partir du début du concours jusqu'à la fin de sa période recrue (BusinessStart + 12 mois)

	-- Mettre les taux de conservation des agence dans une table temporaire afin de les associer dans le tableau suivant
	-- ps : Le REP est égal à l'agence car groupe = 'DIR'
	insert into @tConsAg select Rep, ConsPct from @tFinal where groupe = 'DIR'

	DECLARE MyCursor CURSOR FOR

		select --top 2 -- pour tester
			repid , businessStart
		from 
			un_rep 
		where 
			businessStart between dateADD(month,-12,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) 
			and isnull(businessEnd,'3000-01-01') > @EndDate 
			and repid in (select repid FROM dbo.Un_Unit where dtfirstDeposit between dateADD(month,-24,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) )
		order by businessStart

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @RepID, @businessStart

	WHILE @@FETCH_STATUS = 0
	BEGIN

		if dateADD(month,12,@businessStart) >= @EndDate
		begin
			set @EndDateREC = @EndDate		
		end
		else
		begin
			set @EndDateREC = dateADD(month,12,@businessStart)		
		end

		insert into @tFinal
		select 
			Groupe = 'AG_REC',
			repID, 
			RepCode, 
			Rep, 
			BusinessStart, 
			v.Agence, 
			AgenceStart = '1900-01-01',
			Point, 
			ConsPct = CA.ConsPct,
			PointPrec = 0
		from 
			FN_VentesRep (@StartDate, @EndDateREC, @RepID,  'REP') v
			left join @tConsAg CA on CA.Agence = v.Agence

		FETCH NEXT FROM MyCursor INTO @RepID, @businessStart
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor

select * from @tFinal order by Groupe, RepID

END


