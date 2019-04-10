/****************************************************************************************************
Copyrights (c) 2015 Gestion Universitas Inc.
Nom                 :	psOPER_RapportConventionQuiReculeEtat 
Description         :	
						Nous devons obtenir la liste de toutes les conventions 
						qui sont présentement en statut "proposition" ou en statut "transitoire" 
						mais que dans leur historique d'état de la convention, cette convention a déjà été REEE.

Valeurs de retours  :	Dataset 
Note                :	2015-02-10	Donald Huppé	Création (glpi 13268)

exec psOPER_RapportConventionQuiReculeEtat

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportConventionQuiReculeEtat] 
AS
BEGIN

	select 
		c.ConventionNo,--v.*, css.*
		NomSousc = hs.LastName,
		PrenomSousc = hs.FirstName,
		c.SubscriberID,
		NomBenef = hb.LastName,
		PrenomBenef = hb.FirstName,
		c.BeneficiaryID,
		ÉtatActuelConv = css.ConventionStateID,
		ÉtatActuelDateDébut = css.startdate,
		DateDébutÉtatREEE = v.StartDate,
		DateFinÉtatREEE = v.EndDate
	from (

		select -- tous les états de convention par plage de date
			W.ConventionID,
			W.ConventionConventionStateID,
			cs.ConventionStateID,
			W.StartDate,
			EndDate = isnull(min(W.EndDate),'9999-12-31')
		from (
			select csDebut.ConventionConventionStateID, csDebut.ConventionID, csDebut.StartDate, EndDate = csFin.StartDate
			from un_conventionconventionstate csDebut
			left join un_conventionconventionstate csFin on 
					csFin.ConventionID = csDebut.ConventionID and 
					csFin.StartDate >= csDebut.StartDate and 
					csFin.ConventionConventionStateID > csDebut.ConventionConventionStateID
			) W
			join un_conventionconventionstate cs on w.ConventionConventionStateID = cs.ConventionConventionStateID
		GROUP BY
			W.ConventionID,
			W.ConventionConventionStateID,
			cs.ConventionStateID,
			W.StartDate
		) v
	join ( -- La convention est en état PRP ou TRA présentement
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
				--where startDate < DATEADD(d,1 ,'2013-12-31')
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID in ('PRP','TRA') 
		) css on v.conventionid = css.conventionid
	JOIN dbo.Un_Convention c on v.ConventionID = c.ConventionID
	JOIN dbo.Mo_Human hs on c.SubscriberID = hs.HumanID
	JOIN dbo.Mo_Human hb on c.BeneficiaryID = hb.HumanID
	where 
		-- La convention a déjà été REE avant l'état présent
		v.ConventionStateID = 'REE' and v.StartDate < css.startdate 

/*
	-- Même chose sans les plage de date
	select DISTINCT c.ConventionNo,c.ConventionID, css.ConventionStateID, css.startdate, cs.StartDate
	FROM dbo.Un_Convention c
	JOIN dbo.Mo_Human hs on c.SubscriberID = hs.HumanID
	JOIN dbo.Mo_Human hb on c.BeneficiaryID = hb.HumanID
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
				--where startDate < DATEADD(d,1 ,'2013-12-31')
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID in ('PRP','TRA') -- je veux les convention qui ont cet état
		) css on C.conventionid = css.conventionid
	join Un_ConventionConventionState cs on cs.ConventionID = c.ConventionID and cs.ConventionStateID = 'REE'

*/

END


