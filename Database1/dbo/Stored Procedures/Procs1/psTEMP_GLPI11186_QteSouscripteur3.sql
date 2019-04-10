/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_GLPI11186_QteSouscripteur3
Nom du service		: voir glpi 11386
But 				: pour le rapport RapStatistiquesMensuellesGLPI utilisé par J Gendron
Facette				: 

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
	
		2017-01-04		Donald Huppé		glpi 11386

exec psTEMP_GLPI11186_QteSouscripteur3 '2016-12-31'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_GLPI11186_QteSouscripteur3]
(
	@dtDateFin datetime
)
AS
BEGIN
	-- Question 1
	
--ID souscripteur	Nom du souscripteur	Prénom du souscripteur	# téléphone maison	Date RIN prévue de la plus ancienne convention	Date RIN prévue de la plus récente convention

--DECLARE @dtDateFin datetime = '2016-12-31'



select 
	Liste = '1 - Qte Sousc SANS RI, SANS Courriel'
	,QteSousc = count(DISTINCT v2.SubscriberID)
from (

	SELECT
			SubscriberID
			,nomsousc
			,PrenomSousc
			,Telmaison
			,RIEstimeLaPlusAncienne = LEFT(CONVERT(VARCHAR, RIEstimeLaPlusAncienne, 120), 10)-- cast(YEAR(RIEstimeLaPlusAncienne) as varchar(4)) + '-' + cast(month(RIEstimeLaPlusAncienne) as varchar(2)) 
			,RIEstimeLaPlusRecente = LEFT(CONVERT(VARCHAR, RIEstimeLaPlusRecente, 120), 10) --cast(YEAR(RIEstimeLaPlusRecente) as varchar(4)) + '-' + cast(month(RIEstimeLaPlusRecente) as varchar(2)) 
	from (

		SELECT 
			cREE.SubscriberID
			,nomsousc = hs.LastName
			,PrenomSousc = hs.FirstName
			,Telmaison = a.Phone1
			,RIEstimeLaPlusAncienne = min(dbo.FN_UN_EstimatedIntReimbDate(M.PmtByYearID,M.PmtQty,M.BenefAgeOnBegining,u.InForceDate,p.IntReimbAge,U.IntReimbDateAdjust))
			,RIEstimeLaPlusRecente = max(dbo.FN_UN_EstimatedIntReimbDate(M.PmtByYearID,M.PmtQty,M.BenefAgeOnBegining,u.InForceDate,p.IntReimbAge,U.IntReimbDateAdjust))
		FROM Un_Convention cREE 
		JOIN Mo_Human hs ON cREE.SubscriberID = hs.HumanID
		join (
			select
				sourceID, -- correspond au humanid
				adrID,
				adrtypeID,StartDate, EndDate = min(EndDate)
			from (	
				select
					aDebut.adrID,aDebut.sourceID,StartDate = aDebut.inforce, EndDate = aFin.inforce,aDebut.adrtypeID
				from 
					mo_adr aDebut
					join un_subscriber s on aDebut.sourceid = s.subscriberid -- pour avoir seulement des adresses de souscripteur
					left join mo_adr aFin on aDebut.sourceid = afin.sourceid and aFin.Inforce >= aDebut.inforce  and aFin.adrID > aDebut.adrID and aFin.adrtypeID = 'H'
				) VV
			--where sourceID = 428296
			group by 
				sourceID,adrID,
				adrtypeID,StartDate
			)ah ON ah.SourceID = hs.HumanID AND @dtDateFin BETWEEN ah.StartDate AND isnull(ah.EndDate,'3000-12-31')
		join Mo_Adr	a ON ah.AdrID = a.AdrID --AND a.EMail IS null -- n'a pas de courriel
		join Un_Unit u ON cREE.ConventionID = u.ConventionID AND isnull(u.IntReimbDate,'3000-12-31') > @dtDateFin -- n'a pas de RI
		join Un_Plan p ON cREE.PlanID = p.planid
		JOIN Un_Modal m ON u.ModalID = m.ModalID
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
					where startDate < DATEADD(d,1 ,@dtDateFin)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
			) css on cREE.conventionid = css.conventionid
		left JOIN tblOPER_OperationsRIO rio ON cREE.ConventionID = rio.iID_Convention_Destination AND rio.bRIO_Annulee = 0 AND rio.bRIO_QuiAnnule = 0	
		WHERE rio.iID_Convention_Destination IS null -- n'est pas une T
		AND isnull(a.EMail,'') = ''
		GROUP by 
			cREE.SubscriberID
			,hs.LastName
			,hs.FirstName
			,a.Phone1

		)v
	)v2	
	-----------------------------------------------------------
	
	--question 2
	
	--ID souscripteur	Nom du souscripteur	Prénom du souscripteur	# téléphone maison	# de conventions actives du souscripteur

	union ALL

select 
	Liste = '2 - Qte Sousc AVEC RI, AVEC Courriel'
	,QteSousc = count(DISTINCT v2.SubscriberID)
from (
	
	
	SELECT 
		s.SubscriberID,
		NomSousc = h.lastname,
		PrenomSousc = h.firstName,
		TelMaison = a.phone1,
		QteConvention = COUNT(DISTINCT u.conventionID),
		BeneficiaireRecuBourse = case when BoursePAD.SubscriberID is not null then 1 else 0 end,
		BenefStatutADM = case WHEN BourseADM.SubscriberID is not NULL and BoursePAD.SubscriberID is null then 1 ELSE 0 end
	FROM Un_Subscriber s
	JOIN Mo_Human h ON s.SubscriberID = h.HumanID
	join (
		select
			sourceID, -- correspond au humanid
			adrID,
			adrtypeID,StartDate, EndDate = min(EndDate)
		from (	
			select
				aDebut.adrID,aDebut.sourceID,StartDate = aDebut.inforce, EndDate = aFin.inforce,aDebut.adrtypeID
			from 
				mo_adr aDebut
				join un_subscriber s on aDebut.sourceid = s.subscriberid -- pour avoir seulement des adresses de souscripteur
				left join mo_adr aFin on aDebut.sourceid = afin.sourceid and aFin.Inforce >= aDebut.inforce  and aFin.adrID > aDebut.adrID and aFin.adrtypeID = 'H'
			) VV
		--where sourceID = 428296
		group by 
			sourceID,adrID,
			adrtypeID,StartDate
		)ah ON ah.SourceID = h.HumanID AND @dtDateFin BETWEEN ah.StartDate AND isnull(ah.EndDate,'3000-12-31')
	
	join Mo_Adr	a ON ah.AdrID = a.AdrID --AND a.EMail IS NOT null -- a un courriel
	join Un_Convention cREE on s.SubscriberID = cREE.SubscriberID
	join Un_Unit u ON cREE.ConventionID = u.ConventionID AND isnull(u.IntReimbDate,'3000-12-31') <= @dtDateFin-- a un RI
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
				where startDate < DATEADD(d,1 ,@dtDateFin)
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
		) css on cREE.conventionid = css.conventionid
	LEFT JOIN ( -- un bénéficiaire a recu une bourse
		SELECT DISTINCT c.SubscriberID
		FROM Un_Convention c
		join Un_Scholarship s ON c.ConventionID = s.ConventionID and s.ScholarshipNo = 1
		join Un_ScholarshipPmt sp ON s.ScholarshipID = sp.ScholarshipID
		join Un_Oper o ON sp.OperID = o.OperID
		LEFT JOIN Un_OperCancelation oc1 ON o.OperID = oc1.OperSourceID
		LEFT JOIN Un_OperCancelation oc2 ON o.OperID = oc2.OperID
		LEFT join Un_Oper o2 ON oc2.OperID = o2.OperID AND o2.OperDate > @dtDateFin
		left JOIN tblOPER_OperationsRIO rio ON c.ConventionID = rio.iID_Convention_Destination AND rio.bRIO_Annulee = 0 AND rio.bRIO_QuiAnnule = 0	
		WHERE 
			--s.ScholarshipStatusID = 'PAD'
			o.OperDate <= @dtDateFin --le pae est avant la date demandée
			and o.OperTypeID = 'PAE'
			and isnull(o2.OperDate,'3000-12-31') > @dtDateFin -- l'éventuelle annulation est après la date demandée
			and rio.iID_Convention_Destination IS null
		)BoursePAD ON BoursePAD.SubscriberID = s.SubscriberID
/*
	LEFT JOIN ( -- 
		SELECT DISTINCT c.SubscriberID
		FROM Un_Convention c
		join Un_Scholarship s ON c.ConventionID = s.ConventionID and s.ScholarshipNo = 1
		left JOIN tblOPER_OperationsRIO rio ON c.ConventionID = rio.iID_Convention_Destination AND rio.bRIO_Annulee = 0 AND rio.bRIO_QuiAnnule = 0	
		WHERE s.ScholarshipStatusID = 'ADM'
		and rio.iID_Convention_Destination IS null
		)BourseADM ON BourseADM.SubscriberID = s.SubscriberID
*/
	LEFT JOIN ( -- 
		SELECT DISTINCT c.SubscriberID
		FROM Un_Convention c
		join Un_Unit u on c.ConventionID = u.ConventionID
		join (
			select 
				us.unitid,
				uus.startdate,
				us.UnitStateID
			from 
				Un_UnitunitState us
				join (
					select 
					unitid,
					startdate = max(startDate)
					from un_unitunitstate
					where startDate < DATEADD(d,1 ,@dtDateFin)
					group by unitid
					) uus on uus.unitid = us.unitid 
						and uus.startdate = us.startdate 
						and us.UnitStateID in ('RBA')		
			)uss on uss.UnitID = u.UnitID
		join Un_Scholarship s ON c.ConventionID = s.ConventionID and s.ScholarshipNo = 1
		left JOIN tblOPER_OperationsRIO rio ON c.ConventionID = rio.iID_Convention_Destination AND rio.bRIO_Annulee = 0 AND rio.bRIO_QuiAnnule = 0	
		WHERE rio.iID_Convention_Destination IS null
		)BourseADM ON BourseADM.SubscriberID = s.SubscriberID


		
	left JOIN tblOPER_OperationsRIO rio ON cREE.ConventionID = rio.iID_Convention_Destination AND rio.bRIO_Annulee = 0 AND rio.bRIO_QuiAnnule = 0	
	LEFT JOIN ( --sousc REEE sans RI
			SELECT DISTINCT s.SubscriberID
			FROM Un_Subscriber s
			JOIN Mo_Human h ON s.SubscriberID = h.HumanID
			--join Mo_Adr	a ON h.AdrID = a.AdrID AND a.EMail IS NOT null -- a un courriel
			join Un_Convention cREE on s.SubscriberID = cREE.SubscriberID
			join Un_Unit u ON cREE.ConventionID = u.ConventionID AND isnull(u.IntReimbDate,'3000-12-31') > @dtDateFin -- n'a pas de RI
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
						where startDate < DATEADD(d,1 ,@dtDateFin)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
				) css on cREE.conventionid = css.conventionid
			left JOIN tblOPER_OperationsRIO rio2 ON cREE.ConventionID = rio2.iID_Convention_Destination AND rio2.bRIO_Annulee = 0 AND rio2.bRIO_QuiAnnule = 0	
			WHERE rio2.iID_Convention_Destination IS null -- n'est pas une T	
		)SNonRI ON SNonRI.SubscriberID = s.SubscriberID
	WHERE 
		rio.iID_Convention_Destination IS null -- n'est pas une T
		and SNonRI.SubscriberID IS NULL -- n'est pas un sousc qui a au moins une conv REEE sans RI	
		AND isnull(a.EMail,'') <> ''
		--and cREE.SubscriberID = 167301
	GROUP by
		s.SubscriberID,
		h.lastname,
		h.firstName,
		a.phone1,
		case when BoursePAD.SubscriberID is not null then 1 else 0 end,
		case WHEN BourseADM.SubscriberID is not NULL and BoursePAD.SubscriberID is null then 1 ELSE 0 end

	)v2		
	--		) v
	--where 
	--	v.BeneficiaireRecuBourse = 0 
	--	AND v.BenefStatutADM = 0  
	
	
END