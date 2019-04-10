/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc.

Code du service		: psCONV_RapportPourLettreSurGroupeUnite
Nom du service		: Générer les info des groupe d'unité d'une convention à afficher dans une rapport afin de lancer des rapport de lettre à partir du UnitID
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportPourLettreSurGroupeUnite @ConventionNo = 'X-20150921055'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2015-11-12		Donald Huppé						Création du service	

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportPourLettreSurGroupeUnite] 
	@ConventionNo varchar(30)
AS
BEGIN

	select 
		c.ConventionNo,
		css.ConventionStateID,
		Souscripteur = hs.FirstName + ' ' + hs.LastName,
		Beneficiaire = hb.FirstName + ' ' + hb.LastName,
		u.UnitID,
		QteUnite = u.UnitQty,
		EtatGrUnite = us.UnitStateName,
		DateSignature = u.SignatureDate,
		DateDebutOpérationFinanciere = u.InForceDate,
		Date1erDepot = u.dtFirstDeposit,
		MontantDepot = ROUND(M.PmtRate * (U.UnitQty),2) + -- Cotisation et frais
				dbo.FN_CRQ_TaxRounding
					((	CASE U.WantSubscriberInsurance -- Assurance souscripteur
							WHEN 0 THEN 0
						ELSE ROUND(M.SubscriberInsuranceRate * (U.UnitQty ),2)
						END +
						ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
					(1+ISNULL(St.StateTaxPct,0)))

	FROM dbo.Un_Convention c
	JOIN dbo.Un_Subscriber s on c.SubscriberID = s.SubscriberID
	JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
	JOIN Un_Modal M ON U.ModalID = M.ModalID
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
					--and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
		) css on C.conventionid = css.conventionid
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
				--where startDate < DATEADD(d,1 ,'2014-02-08')
				group by unitid
				) uus on uus.unitid = us.unitid 
					and uus.startdate = us.startdate 
					--and us.UnitStateID in ('epg')
		)uus on uus.unitID = u.UnitID
	join Un_UnitState us on uus.UnitStateID = us.UnitStateID
	LEFT JOIN Mo_State St ON St.StateID = S.StateID
	LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID	
	WHERE c.ConventionNo = @ConventionNo

end	


