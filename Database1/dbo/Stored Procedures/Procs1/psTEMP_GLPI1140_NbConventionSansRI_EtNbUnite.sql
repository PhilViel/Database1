/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: GLPI1140
Nom du service		: 
But 				: 
Facette				: 

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2012-07-03		Donald Huppé						Création du service
        2018-11-12      Pierre-Luc Simard                   Utilisation du type de plan

exec psTEMP_GLPI1140_NbConventionSansRI_EtNbUnite '2012-06-30'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_GLPI1140_NbConventionSansRI_EtNbUnite]
(
	@dtDateFin datetime
)
AS
BEGIN

	--declare @dtDateFin datetime
	--set @dtDateFin = '2012-05-31'

	select 
		enDatedu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
		Année = year(@dtDateFin),
		Régime = P.plandesc,
		NbConvSansRIN = count(distinct c.conventionid),
		NbUnite = sum(isnull(u1.UnitQty,0) + isnull(ur.QtyReduct,0))
	FROM dbo.Un_Convention c
	join un_plan p on c.planid = p.planid
	JOIN dbo.mo_human HB on HB.humanID = C.beneficiaryID -- select * FROM dbo.mo_human

	join ( -- groupe d'unité SANS RIN à une date donnée
		select conventionid
		FROM dbo.Un_Unit 
		where IntReimbDate > @dtDateFin or IntReimbDate is null
		group by conventionid
		) u on u.conventionid = c.conventionid
	join (  -- La plus récente d'état de convention par convention à une date donnée
			select 
				cs.conventionid,
				LaDate = max(cs.StartDate)
			from UN_ConventionConventionState cs
			where LEFT(CONVERT(VARCHAR, cs.StartDate, 120), 10) <= @dtDateFin
			group by cs.conventionid
		) csDate on c.conventionid = csDate.conventionid 
	join UN_ConventionConventionState cs on c.conventionid = cs.conventionid 
				and cs.StartDate = csDate.Ladate 
				and cs.ConventionStateID in ('REE','TRA')
	left JOIN dbo.Un_Unit u1 on c.conventionid = u1.conventionid and u1.inforcedate <= @dtDateFin
	left join (select unitid, QtyReduct = sum(unitqty)
				from un_unitreduction 
				where reductiondate > @dtDateFin
				group by unitid
		)ur on ur.unitid = u1.unitid
	--where p.planid in (8,10,12) -- select * from un_plan 
    WHERE p.PlanTypeID = 'COL'
	group by P.plandesc
	
END