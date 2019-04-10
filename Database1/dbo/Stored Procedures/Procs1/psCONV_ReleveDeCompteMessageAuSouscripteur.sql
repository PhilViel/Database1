/********************************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psCONV_ReleveDeCompteMessageAuSouscripteur
Description         :	retourne les messages à afficher dans le relevé de compte
Valeurs de retours  :	Dataset de données



Note                : ### il faut dabord populer les tables suivantes :

					1 - tblCONV_ReleveDeCompte_RecensementPCEEerreurM
					2 - tblCONV_ReleveDeCompte_RecensementPCEEerreur4
					exec psCONV_ReleveDeCompte_Populer_tblCONV_ReleveDeCompte_RecensementPCEEerreurM_4 'M'
					exec psCONV_ReleveDeCompte_Populer_tblCONV_ReleveDeCompte_RecensementPCEEerreurM_4 '4'


					3 - tblCONV_ReleveDeCompte_RecensementPCEEerreurL
					exec psCONV_ReleveDeCompte_Populer_tblCONV_ReleveDeCompte_RecensementPCEEerreurL
	
					2015-02-18	Donald Huppé	Création 
					2016-12-14	Donald Huppé	Ajout de la note (id = -100)
					2016-12-19	Donald Huppé	modification de notes
					2017-02-13	Donald Huppé	ajout message gagnant de concours
					2018-02-08  Steeve Picard   Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
					2018-06-06  Steeve Picard   Modificiation de la gestion des retours d'erreur par RQ
					2018-05-11	Donald Huppé	Version finale utilsée pour relevé de 2017-12-31
					2018-09-07	Maxime Martel	JIRA MP-699 Ajout de OpertypeID COU

exec psCONV_ReleveDeCompteMessageAuSouscripteur 1, null -- POUR TOUS -- drop table ALLMessage -- drop table ##Portail
create clustered index clsindAlleMessage on ALLMessage (SubscriberID)

exec psCONV_ReleveDeCompteMessageAuSouscripteur null, 'X-20171027009'
exec psCONV_ReleveDeCompteMessageAuSouscripteur 575993, null
create clustered index clsindAlleMessage on ALLMessage (SubscriberID)

*********************************************************************************************************************/


CREATE PROCEDURE [dbo].[psCONV_ReleveDeCompteMessageAuSouscripteur] (
		@SubscriberID int = null
		,@conventionNO varchar(30) = NULL -- '2025720'
		/* 
		exec psCONV_ReleveDeCompteMessageAuSouscripteur @SubscriberID = 575993  , @conventionNO = NULL 575993 738885 151197 --738885
		create clustered index clsindAlleMessage on ALLMessage (SubscriberID)
		*/
	)
AS
BEGIN

DECLARE @dtDateTo Datetime = '2017-12-31'
DECLARE @SQL VARCHAR(2000)
DECLARE @ServeurPortail varchar(255)



set @ServeurPortail = dbo.fnGENE_ObtenirParametre('GENE_BD_USER_PORTAIL', NULL, NULL, NULL, NULL, NULL, NULL) 

create table #Sub (SubscriberID int)

if @SubscriberID is not null and @SubscriberID <> 1
	begin
	insert into #Sub values (@SubscriberID)
	end

if @conventionNO is not null
	begin
	insert into #Sub select SubscriberID from Un_Convention where ConventionNo= @conventionNO
	SELECT @SubscriberID = SubscriberID from Un_Convention where ConventionNo= @conventionNO
	end


if @SubscriberID = 1
	begin
	insert into #Sub 
	select DISTINCT c.SubscriberID 
	from Un_Convention c
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
				where startDate < DATEADD(d,1 ,@dtDateTo)
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID <> 'FRM'
		) css on C.conventionid = css.conventionid
	--left join TblCONV_RelevecompteExclusions e on c.SubscriberID = e.SubscriberID -- select * from TblCONV_RelevecompteExclusions
	--where e.SubscriberID is null -- exclure les exclusion		
	end

	 --La vérification du Portail est désactivée
	if @SubscriberID = 1
		BEGIN
		SET @sql = 
			'select
				DISTINCT su.SubscriberID
			into ##Portail
			from '
				 + @ServeurPortail+ '.dbo.profiles P
				join ' + @ServeurPortail+ '.dbo.Users U				on P.userId = U.userID
				join ' + @ServeurPortail+ '.dbo.[Memberships] m		on m.UserId = p.UserId
				JOIN dbo.Un_Subscriber su on cast(su.SubscriberID as varchar) = U.UserName
				join #Sub s on s.SubscriberID = su.SubscriberID
			where 
				LEFT(CONVERT(VARCHAR, m.LastLoginDate, 120), 10) <> ''1900-01-01'' 
				and isnull(cast(m.comment as VARCHAR),'''') = ''''
			'
		END


	 --La vérification du Portail est désactivée
	if ISNULL(@SubscriberID,0) <> 1
		BEGIN
		SET @sql = 
			'select
				DISTINCT su.SubscriberID
			into ##Portail
			from '
				 + @ServeurPortail+ '.dbo.profiles P
				join ' + @ServeurPortail+ '.dbo.Users U				on P.userId = U.userID
				join ' + @ServeurPortail+ '.dbo.[Memberships] m		on m.UserId = p.UserId
				JOIN dbo.Un_Subscriber su on cast(su.SubscriberID as varchar) = U.UserName
				
			where 
				LEFT(CONVERT(VARCHAR, m.LastLoginDate, 120), 10) <> ''1900-01-01'' 
				and isnull(cast(m.comment as VARCHAR),'''') = ''''
				and su.SubscriberID = ' + cast(@SubscriberID as VARCHAR(50))
			
		END

	--print @sql
	exec (@sql)
	


	--select * from ##Portail
	--RETURN

/*
	select
			SubscriberID = 1
	into ##Portail
*/
	select u.ConventionID,Epg = sum(ct.Cotisation + ct.Fee)
	into #ConvNonRI
	from Un_Unit u
	join Un_Convention c on u.ConventionID = c.ConventionID
	join #Sub s on c.SubscriberID = s.SubscriberID
	join Un_Cotisation ct on u.UnitID = ct.UnitID
	join Un_Oper o on ct.OperID = o.OperID
	where u.IntReimbDate is null
	GROUP by u.ConventionID
	HAVING sum(ct.Cotisation + ct.Fee) > 0


	select DISTINCT
		c.SubscriberID, c.ConventionID
	INTO #ConvCotis_36Mois
	from 
		dbo.Un_Convention c
		join #Sub s on c.SubscriberID = s.SubscriberID
		join dbo.un_unit u on c.ConventionID = u.ConventionID
		join dbo.un_cotisation ct on ct.UnitID = u.UnitID
		join dbo.un_oper o on ct.OperID = o.OperID
		left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
		left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
		left join dbo.Un_Tio TIOt on TIOt.iTINOperID = o.operid
		left join dbo.Un_Tio TIOo on TIOo.iOUTOperID = o.operid
	where 
		o.OperDate BETWEEN dateadd(MONTH,-36,getdate()) and getdate()
		and o.OperTypeID in ( 'CHQ','PRD','CPA','RDI','TIN','COU')
		and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
		and oc1.OperSourceID is NULL
		and oc2.OperID is null



select 
	DISTINCT
	SubscriberID
	,IDMessage
	,Info
	,LeMessage
	,h.LangID
	,Beneficiaire
--into ALLMessage -- drop table ALLMessage
from (



	select DISTINCT
		S.SubscriberID
		,IDMessage = 70
		,Info = 'BUG BUG BUG'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'<b>----------- > La vérification du Portail est désactivée <-----------------</b>'
			ELSE
				'<b>----------- > La vérification du Portail est désactivée <-----------------</b>'
			end
		,Beneficiaire = NULL
	from 
		#Sub s 
		join Mo_Human HS on HS.HumanID = s.SubscriberID
	where object_id('tempdb..##Portail') is NULL

	UNION ALL

	select DISTINCT
		S.SubscriberID
		,IDMessage = 80
		,Info = 'Message général'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'The terms used herein are defined in the "Glossary" section of your statement of account.'
			ELSE
				'Les termes utilisés dans le présent document sont définis à la section « Lexique » de votre relevé de compte.'
			end
		,Beneficiaire = NULL
	from 
		#Sub s 
		join Mo_Human HS on HS.HumanID = s.SubscriberID

	UNION ALL

	select DISTINCT
		S.SubscriberID
		,IDMessage = 85
		,Info = 'Fin de régime'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'We remind you that your plan will expire on ' + dbo.fn_Mo_DateToLongDateStr(FR.DateFinRegime,hs.langID)  + ' (cut-off date). You have until this date to apply for Educational Assistance Payments (EAPs) or an Accumulated Income Payment (AIP).'
			ELSE
				'Nous vous rappelons que votre plan atteindra sa date butoir le ' + dbo.fn_Mo_DateToLongDateStr(FR.DateFinRegime,hs.langID)  + '. Vous avez jusqu’à cette date pour effectuer une demande de paiement d’aide aux études (PAE) ou une demande de paiement de revenu accumulé (PRA).'
			end
		,Beneficiaire = NULL
	from 
		#Sub s 
		JOIN tblCONV_ReleveDeCompteConventionFinRegime FR on FR.SubscriberID = s.SubscriberID 
		JOIN Mo_Human HS on HS.HumanID = s.SubscriberID
	WHERE FR.AnneeReleveCompte= year(@dtDateTo)

	UNION ALL

	select DISTINCT
		S.SubscriberID
		,IDMessage = 85
		,Info = 'Fin de régime'
		,LeMessage = '<b>--- >BUG BUG BUG tblCONV_ReleveDeCompteConventionFinRegime est vide pour relevé de compte ' + cast( year(@dtDateTo) as VARCHAR(5)) + ' < ----</b>'
		,Beneficiaire = NULL
	from 
		#Sub s 
	where not exists (select 1 from tblCONV_ReleveDeCompteConventionFinRegime where AnneeReleveCompte= year(@dtDateTo))



	UNION ALL

	select 
		c.SubscriberID
		,IDMessage = 90
		,Info = 'Gagnant de concours'
		,LeMessage = case 
						when hs.LangID = 'ENU' 
						then '<b>Important Notice!</b> Considering that the RESP ' + c.ConventionNo + ' for ' + hb.FirstName + ' ' + hb.LastName + ' (the “RESP Prize”) was opened as part of a contest, you may have waived all entitlement to the contributions and sales charges invested by Universitas Management Inc. If such is the case, the contributions and sales charges presented herein and paid toward the RESP Prize will not be returned or refunded to you, and remain the exclusive property of Universitas Management Inc. The educational assistance payments (EAPs) indicated in this document may also differ from those to which ' + hb.FirstName + ' ' + hb.LastName + ' may be entitled under the RESP Prize. This document does not change the contract you signed as part of the contest.'
						else '<b>Avis important !</b> Considérant que le REEE ' + c.ConventionNo + ' de ' + hb.FirstName + ' ' + hb.LastName + ' (la « Convention de concours ») a été ouvert dans le cadre d’un concours, il est possible que vous ayez renoncé à tout droit sur les cotisations et les frais de souscription investis par Gestion Universitas inc. Le cas échéant, les cotisations et les frais de souscription indiqués dans le présent document et versés à la Convention de concours ne vous seront pas retournés ou remboursés et demeurent la propriété exclusive de Gestion Universitas inc. Les paiements d’aide aux études (PAE) indiqués pourraient également différer de ceux auquel ' + hb.FirstName + ' ' + hb.LastName + ' pourrait avoir droit dans le cadre de la Convention de concours. Le présent document ne modifie pas le contrat que vous avez signé dans le cadre du concours.'
						end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	from 
		Un_Convention c
		join un_unit u on c.ConventionID = u.ConventionID
		join #Sub s on c.SubscriberID = s.SubscriberID
		join ( -- 2016-03-08
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
					where startDate < DATEADD(d,1 ,@dtDateTo)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID <> 'FRM'
			) css on C.conventionid = css.conventionid
		join Mo_Human hs on c.SubscriberID = hs.HumanID
		join Mo_Human hb on c.BeneficiaryID = hb.HumanID
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
	where 
		u.SaleSourceID = 50 -- UNI-CGT-Concours, Gagnant d'un tirage
		and e.conventionno is null



	UNION ALL


	select 
		c.SubscriberID
		,IDMessage = 100
		,Info = 'Convention transitoire - NAS manquant'
		,LeMessage = case 
						when hs.LangID = 'ENU' 
						then '<b>Important Notice!</b> You must provide your social insurance number (SIN) and the SIN of ' + hb.FirstName + ' ' + hb.LastName + ' before your education savings plan (ESP) can be registered with the government. The <i>Income Tax Act</i> (Canada) does not allow us to register your plan as an RESP without these numbers. Accordingly, you must provide your beneficiary’s SIN before ' + dbo.fn_Mo_DateToLongDateStr(dateadd(year,2/*1*/, dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)),hs.langID)  + '. Otherwise, we will have no choice but to cancel your ESP.'
						else '<b>Avis important !</b> L’obtention du numéro d’assurance sociale (NAS) du bénéficiaire et du souscripteur d’un régime d’épargne-études (REE) constitue une condition préalable à son enregistrement en vertu de la <i>Loi de l’impôt sur le revenu</i> (Canada). Par conséquent, vous devez nous transmettre le NAS de ' + hb.FirstName + ' ' + hb.LastName + ' avant le ' + dbo.fn_Mo_DateToLongDateStr(dateadd(year,2/*1*/, dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)),hs.langID)  + '.  Dans le cas contraire, nous nous verrons dans l’obligation de mettre fin à votre REE.'
						end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	from 
		Un_Convention c
		join #Sub s on c.SubscriberID = s.SubscriberID
		join ( -- 2016-03-08
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
					where startDate < DATEADD(d,1 ,@dtDateTo)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID = 'TRA'
			) css on C.conventionid = css.conventionid
		join Mo_Human hs on c.SubscriberID = hs.HumanID
		join Mo_Human hb on c.BeneficiaryID = hb.HumanID
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
	where 
		(isnull(hb.SocialNumber,'') = '' )
		AND
			(c.SCEEFormulaire93Recu = 1 
			AND (c.SCEEAnnexeBTuteurRecue = 1 or c.SCEEAnnexeBTuteurRequise = 0 )
			)
		AND dateadd(year,2, dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)) > dateadd(month,2,@dtDateTo) -- pour ceux dont le délai est après le 1 mars de l'année suivant. sinon il est trop tard
		AND e.conventionno is null
	/*

	Afficher lorsque le formulaire 0093 manquant
	ou 
	l'annexe B tuteur requise sont indiqués non reçus en date courante
	*/

	UNION ALL

	select 
		c.SubscriberID
		,IDMessage = 200
		,Info = 'Formulaire SCEE manquant'
		,LeMessage = case 
						when hs.LangID = 'ENU' 
						then '<b>Important Notice!</b> We still need to receive your <b>government grant application form</b>. Without this document, we cannot apply for the grants to which ' + hb.FirstName + ' ' + hb.LastName + ' is entitled. Please contact us as soon as possible at 1 877 710-7377 (RESP).'
						else '<b>Avis important !</b> Nous souhaitons vous rappeler qu’il manque à votre dossier le formulaire <i>Subvention canadienne pour l''épargne-études (SCEE) de base et supplémentaire et Bon d''études canadien (BEC)</i> pour le régime enregistré d’épargne-études (REEE) de ' + hb.FirstName + ' ' + hb.LastName + ' afin de réclamer les subventions auxquelles votre bénéficiaire a droit. Veuillez communiquer avec nous dans les plus brefs délais au 1 877 410-7333.'
					END
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	from 
		Un_Convention c
		join #Sub s on c.SubscriberID = s.SubscriberID
		join Un_Unit u on c.ConventionID = u.ConventionID --2016-03-08
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
					where startDate < DATEADD(d,1 ,@dtDateTo)
					group by unitid
					) uus on uus.unitid = us.unitid 
						and uus.startdate = us.startdate 
						and us.UnitStateID in ('epg','CPT','TRA')
			)uus on uus.unitID = u.UnitID
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
					where startDate < DATEADD(d,1 ,@dtDateTo)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID <> 'FRM'
			) css on C.conventionid = css.conventionid
		---------------------------------------------------------------------------------------
		join Mo_Human hs on c.SubscriberID = hs.HumanID
		join Mo_Human hb on c.BeneficiaryID = hb.HumanID
		left join (
			select r.iID_Convention_Destination
			from tblOPER_OperationsRIO r
			where r.bRIO_Annulee = 0
			AND r.bRIO_QuiAnnule = 0
			) rio on rio.iID_Convention_Destination = c.ConventionID
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
	where 
		(
				(c.SCEEAnnexeBTuteurRequise = 1 AND c.SCEEAnnexeBTuteurRecue = 0)
			OR	 c.SCEEFormulaire93Recu = 0
		)
		AND (isnull(hb.SocialNumber,'') <> '' )
		AND rio.iID_Convention_Destination is NULL -- on exclut les convention RIO selon F Ménard 2016-03-08
		AND e.conventionno is null

	/*
	(
	Afficher lorsque le NAS d'un bénéficiaire est manquant 
	et le formulaire 0093 
	)
	ou 
	l'annexe B tuteur requise sont indiqués non reçus en date courante
	*/
	UNION ALL

	select 
		c.SubscriberID
		,IDMessage = 300
		,Info = 'Formulaire SCEE et NAS manquant'
		,LeMessage = case 
						when hs.LangID = 'ENU' 
						then '<b>Important Notice!</b> You must provide your social insurance number (SIN) and the SIN of ' + hb.FirstName + ' ' + hb.LastName + ' before your education savings plan (ESP) can be registered with the government. The <i>Income Tax Act</i> (Canada) does not allow us to register your plan as an RESP without these numbers. Accordingly, you must provide your beneficiary’s SIN before ' + dbo.fn_Mo_DateToLongDateStr(dateadd(year,2, dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)),hs.langID)  + '. Otherwise, we will have no choice but to cancel your ESP.<br>Furthermore, we wish to remind you that we still need to receive your <b>government grant application form</b>. Without this document, we cannot apply for the grants to which ' + hb.FirstName + ' ' + hb.LastName + ' is entitled. Please contact us as soon as possible at 1 877 710-7377 (RESP).'
						else '<b>Avis important !</b> L’obtention du numéro d’assurance sociale (NAS) du bénéficiaire et du souscripteur d’un régime d''épargne-études (REE) constitue une condition préalable à son enregistrement en vertu de la <i>Loi de l’impôt sur le revenu</i> (Canada). Par conséquent, vous devez nous transmettre le NAS de ' + hb.FirstName + ' ' + hb.LastName + ' avant le ' + dbo.fn_Mo_DateToLongDateStr(dateadd(year,2, dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)),hs.langID)  + '.  Dans le cas contraire, nous nous verrons dans l''obligation de mettre fin à votre REE.<br>De plus, nous souhaitons vous rappeler qu’il manque à votre dossier le formulaire <i>Subvention canadienne pour l''épargne-études (SCEE) de base et supplémentaire et Bon d''études canadien (BEC)</i> pour le régime enregistré d’épargne-études (REEE) de ' + hb.FirstName + ' ' + hb.LastName + ' afin que nous puissions réclamer les subventions auxquelles votre bénéficiaire a droit. Veuillez communiquer avec nous dès que possible au 1 877 410-7333.'
						end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
		--, LaDate = '1 an après signature voir comme dans lettre Sans NAS'
	from 
		Un_Convention c
		join #Sub s on c.SubscriberID = s.SubscriberID
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
					where startDate < DATEADD(d,1 ,@dtDateTo)
					group by unitid
					) uus on uus.unitid = us.unitid 
						and uus.startdate = us.startdate 
						and us.UnitStateID in ('epg','CPT','TRA')
			)uus on uus.unitID = u.UnitID
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
					where startDate < DATEADD(d,1 ,@dtDateTo)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID <> 'FRM'
			) css on C.conventionid = css.conventionid
		join Mo_Human hs on c.SubscriberID = hs.HumanID
		join Mo_Human hb on c.BeneficiaryID = hb.HumanID
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
	where 
		(
			(c.SCEEAnnexeBTuteurRequise = 1 and c.SCEEAnnexeBTuteurRecue = 0)
			or c.SCEEFormulaire93Recu = 0
		)
		AND (isnull(hb.SocialNumber,'') = '' )
		AND dateadd(year,2, dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)) > dateadd(month,2,@dtDateTo) -- pour ceux dont le délai est après le 1 mars de l'année suivant. sinon il est trop tard
		AND e.conventionno is null

	UNION ALL


	select 
		SubscriberID
		,IDMessage
		,Info
		,LeMessage =
			case 
			when hs.LangID = 'ENU'  then
					case 
					when IDMessage = 400 then '<b>Important Notice!</b> The Canada Education Savings Program (CESP) has reported an irregularity in the grant application for ' + hb.FirstName + ' ' + hb.LastName + '. Please contact us as soon as possible at 1 877 710-7377 (RESP).'
					when IDMessage = 500 then '<b>Important Notice!</b> Revenu Québec has reported an irregularity in the information in the grant application for ' + hb.FirstName + ' ' + hb.LastName + '. Please contact us as soon as possible at 1 877 710-7377 (RESP).'
					when IDMessage = 600 then '<b>Important Notice!</b> The Canada Education Savings Program (CESP) and Revenu Québec have reported an irregularity in the grant application for ' + hb.FirstName + ' ' + hb.LastName + '. Please contact us as soon as possible at 1 877 710-7377 (RESP).'
					end
			ELSE
					case 
					when IDMessage = 400 then '<b>Avis important !</b> Le Programme canadien pour l’épargne-études nous signale une irrégularité dans le dossier de ' + hb.FirstName + ' ' + hb.LastName + '. Veuillez communiquer avec nous dans les plus brefs délais au 1 877 410-7333.'
					when IDMessage = 500 then '<b>Avis important !</b> Revenu Québec nous signale une irrégularité dans le dossier de ' + hb.FirstName + ' ' + hb.LastName + '. Veuillez communiquer avec nous dans les plus brefs délais au 1 877 410-7333.'
					when IDMessage = 600 then '<b>Avis important !</b> Le Programme canadien pour l’épargne-études ainsi que Revenu Québec nous signalent une irrégularité dans le dossier de ' + hb.FirstName + ' ' + hb.LastName + '. Veuillez communiquer avec nous dans les plus brefs délais au 1 877 410-7333.'
					end
			end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	from (

		select DISTINCT
			c.SubscriberID
			,IDMessage = case 
					when ms4.BeneficiaryID = ms5.BeneficiaryID then 600
					when ms4.BeneficiaryID is not null and ms5.BeneficiaryID is null then 400
					when ms4.BeneficiaryID is null and ms5.BeneficiaryID is not null then 500
					end
			,Info = case 
					when ms4.BeneficiaryID = ms5.BeneficiaryID then 'Enregistrement du bénéficiaire au PCEE et à RQ'
					when ms4.BeneficiaryID is not null and ms5.BeneficiaryID is null then 'Enregistrement du bénéficiaire au PCEE'
					when ms4.BeneficiaryID is null and ms5.BeneficiaryID is not null then 'Enregistrement du bénéficiaire à RQ'
					end 
			,BeneficiaryID  = case 
					when ms4.BeneficiaryID = ms5.BeneficiaryID then ms4.BeneficiaryID
					when ms4.BeneficiaryID is not null and ms5.BeneficiaryID is null then ms4.BeneficiaryID
					when ms4.BeneficiaryID is null and ms5.BeneficiaryID is not null then ms5.BeneficiaryID
					end

			--, ms4.*,ms5.*
		from Un_Convention c
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
						and cs.ConventionStateID <> 'FRM'
			) css on C.conventionid = css.conventionid
		join #Sub s on c.SubscriberID = s.SubscriberID
		left join (
			select DISTINCT
				c.SubscriberID
				,IDMessage = 400
				,b.BeneficiaryID
			FROM 
				Un_CESP800ToTreat C8T 
				JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8T.iCESP800ID
				JOIN Un_CESP800Error C8E ON C8E.siCESP800ErrorID = C8.siCESP800ErrorID
				JOIN Un_CESP200 C2 ON C2.iCESP800ID = C8T.iCESP800ID
				JOIN dbo.Un_Convention C ON C.ConventionID = C2.ConventionID
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
								and cs.ConventionStateID <> 'FRM' -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
				LEFT JOIN Un_CESP200 C2B ON C2B.HumanID = C2.HumanID AND C2B.ConventionID = C2.ConventionID AND C2B.iCESP200ID > C2.iCESP200ID -- 2010-04-14 : JFG : Ajout du lien sur le ConventionID
				JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
				JOIN dbo.Mo_Human HS ON HS.HumanID = S.SubscriberID
				LEFT JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
				where c2.tiType = 3 -- Bénéficiaire seulement	
			)ms4 on ms4.SubscriberID = c.SubscriberID and c.BeneficiaryID = ms4.BeneficiaryID	

        left join (
            SELECT DISTINCT
                SubscriberID = D.iID_Souscripteur
                ,IDMessage = 500
                ,BeneficiaryID = d.iID_Beneficiaire_31Decembre
            FROM (
                    SELECT D.iID_Demande_IQEE, D.tiCode_Version, D.cStatut_Reponse, D.iID_Souscripteur, d.iID_Beneficiaire_31Decembre,
                           row_num = ROW_NUMBER() OVER (PARTITION BY iID_Convention, siAnnee_Fiscale ORDER BY iID_Demande_IQEE DESC)
                      FROM dbo.tblIQEE_Demandes D 
                           JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE 
                                                   AND (bFichier_Test = 0  AND bInd_Simulation = 0) --2018-01-23
                     WHERE D.siAnnee_Fiscale BETWEEN (year(@dtDateTo) - 2) and year(@dtDateTo) -- 3 dernière année fiscale se terminant à celle du relevé
                 ) D
                 JOIN tblIQEE_Erreurs E ON E.iID_Enregistrement =  D.iID_Demande_IQEE 
                 JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                 --join Mo_Human hb on hb.HumanID = d.iID_Beneficiaire_31Decembre
                 --JOIN tblIQEE_TypesErreurRQ RQ ON RQ.siCode_Erreur = E.siCode_Erreur
            WHERE D.row_num = 1
              AND D.tiCode_Version IN (0, 2) 
              AND D.cStatut_Reponse <> 'R' 
              AND TE.cCode_Type_Enregistrement = '02'
              AND E.siCode_Erreur IN (5000, 5003, 5006, 5007, 5010, 5016, 5019, 5022)
            ) ms5 on ms5.SubscriberID = c.SubscriberID and c.BeneficiaryID = ms5.BeneficiaryID 
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
		where (ms4.BeneficiaryID is not null or ms5.BeneficiaryID is not null)
		and e.conventionno is null
		--and c.SubscriberID = 180419
		)f	
	join Mo_Human HS on HS.HumanID = f.SubscriberID  
	join mo_human HB on HB.humanID = f.BeneficiaryID
	--order by SubscriberID



	UNION ALL

	select 
		e4.SubscriberID
		,IDMessage = 700
		,Info = 'Informations bénéficiaire, erreur 4'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
			'<b>Important Notice!</b> The Canada Education Savings Program (CESP) has reported that our information on file for ' + hb.FirstName + ' ' + hb.LastName + ' is inconsistent with their data. Please contact us as soon as possible at 1 877 710-7377 (RESP).'
			ELSE
			'<b>Avis important !</b> Le Programme canadien pour l''épargne-études nous signale que certaines informations concernant ' + hb.FirstName + ' ' + hb.LastName + ' ne concordent pas avec leurs données. Veuillez communiquer avec nous dans les plus brefs délais au 1 877 410-7333.'
			end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	from tblCONV_ReleveDeCompte_RecensementPCEEerreur4 e4 -- select * from tblCONV_ReleveDeCompte_RecensementPCEEerreur4
	join #Sub s on e4.SubscriberID = s.SubscriberID
	join Mo_Human hs on hs.HumanID = e4.SubscriberID
	join Mo_Human hb on hb.HumanID = e4.BeneficiaryID
	left join tblCONV_ReleveDeCompte_RecensementPCEEerreurL eL on e4.SubscriberID = eL.SubscriberID AND e4.BeneficiaryID = eL.BeneficiaryID
	left join tblCONV_ReleveDeCompte_RecensementPCEEerreurM eM on e4.SubscriberID = eM.SubscriberID AND e4.BeneficiaryID = eM.BeneficiaryID
	where 
		eL.SubscriberID is null and eL.BeneficiaryID is null
		and eM.SubscriberID is null and eM.BeneficiaryID is null


	UNION ALL

	select 
		eLM.SubscriberID
		,IDMessage = 800
		,Info = 'Principal responsable, erreur L et M'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'<b>Important Notice!</b> The Canada Education Savings Program (CESP) has reported that our information on file for ' + hb.FirstName + ' ' + hb.LastName + ' and that of the primary caregiver is inconsistent with their data. Please contact us as soon as possible at 1 877 710-7377 (RESP).'
			ELSE
				'<b>Avis important !</b> Le Programme canadien pour l''épargne-études nous signale que l''information concernant le principal responsable de ' + hb.FirstName + ' ' + hb.LastName + ' ne concorde pas avec leurs données. Veuillez communiquer avec nous dans les plus brefs délais au 1 877 410-7333.'
			end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	from 
		(
		select SubscriberID, BeneficiaryID
		from  tblCONV_ReleveDeCompte_RecensementPCEEerreurL
		UNION 
		select SubscriberID, BeneficiaryID 
		from  tblCONV_ReleveDeCompte_RecensementPCEEerreurM
		)eLM
	join #Sub s on eLM.SubscriberID = s.SubscriberID
	join Mo_Human hs on hs.HumanID = eLM.SubscriberID
	join Mo_Human hb on hb.HumanID = eLM.BeneficiaryID
	left join tblCONV_ReleveDeCompte_RecensementPCEEerreur4 e4 on e4.SubscriberID = eLM.SubscriberID and e4.BeneficiaryID = eLM.BeneficiaryID 
	where e4.SubscriberID is null and e4.BeneficiaryID is null

	UNION ALL

	select 
		e4.SubscriberID
		,IDMessage = 900
		,Info = 'Informations bénéficiaire, erreur 4 et Principal responsable, erreur L et M'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
			'<b>Important Notice!</b> The Canada Education Savings Program (CESP) has reported that our information on file for ' + hb.FirstName + ' ' + hb.LastName + ' and that of the primary caregiver is inconsistent with their data. Please contact us as soon as possible at 1 877 710-7377 (RESP).'
			ELSE
			'<b>Avis important !</b> Le Programme canadien pour l''épargne-études nous signale que certaines informations concernant ' + hb.FirstName + ' ' + hb.LastName + ' et son principal responsable ne concordent pas avec leurs données. Veuillez communiquer avec nous dans les plus brefs délais au 1 877 410-7333.'
			end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	from 
		tblCONV_ReleveDeCompte_RecensementPCEEerreur4 e4
		join #Sub s on e4.SubscriberID = s.SubscriberID
		join Mo_Human hs on hs.HumanID = e4.SubscriberID
		join Mo_Human hb on hb.HumanID = e4.BeneficiaryID
		left join tblCONV_ReleveDeCompte_RecensementPCEEerreurL eL on e4.SubscriberID = eL.SubscriberID AND e4.BeneficiaryID = eL.BeneficiaryID
		left join tblCONV_ReleveDeCompte_RecensementPCEEerreurM eM on e4.SubscriberID = eM.SubscriberID AND e4.BeneficiaryID = eM.BeneficiaryID
	where 
		(eL.SubscriberID is not null and eL.BeneficiaryID is not null)
		OR 
		(eM.SubscriberID is not null and eM.BeneficiaryID is not null)



	UNION ALL

	-- Afficher ce message si les tables d'erreur de PCEE ne sont pas populées
	select DISTINCT
		s.SubscriberID
		,IDMessage = 800
		,Info = 'Temp'
		,LeMessage = '-------- >>>>> Message erreur PCEE 4, L ou M désactivé car les tables de recensement des erreurs sont vides <<<<<< -------'
		,Beneficiaire = ''
	from #Sub s
	where not exists (select 1 from tblCONV_ReleveDeCompte_RecensementPCEEerreurM)
			or not exists (select 1 from tblCONV_ReleveDeCompte_RecensementPCEEerreur4)
			or not exists (select 1 from tblCONV_ReleveDeCompte_RecensementPCEEerreurL)

	UNION ALL

	select 
		c.SubscriberID
		,IDMessage = 1000 /* <<<---- Cet IDMessage = 1000 est hard codé dans le relevé de compte.  NE PAS MODIFIER*/
		,Info = 'Les informations du principal responsable n''ont jamais été fournies'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then

			'<b>Important Notice!</b>' + 
			'  Please note that we do not have the primary caregiver’s information on file for your beneficiary(ies), which could affect government grant entitlements.'
			+ '<br><br><b>Who is the Primary Caregiver?</b>' 
			+ '<br>The primary caregiver is the individual who receives the Canada Child Benefit (sometimes called family allowance or baby bonus). Therefore, the subscriber is not always the primary caregiver.'
			+ '<br><br>If you are the primary caregiver, please complete the form <a href="https://www.universitas.ca/images/documents/CESG_CLB_application.pdf">Application CESG - 0093</a>'
			+ '; a separate form must be completed per beneficiary. Your must then return the form/s by mail or fax. If you are not the primary caregiver, we ask that this person complete the form  <a href="https://www.universitas.ca/images/documents/CESG_CLB_application_annex_B.pdf">Application CESG – Annex B</a>'
			+ '. Again, a separate form must be completed per beneficiary and returned to us by mail or fax.'
			+ '<br><br>Both forms are available on our website (universitas.ca). Once we receive these documents, we will forward the necessary information to the government to remedy the situation.'
			+ '<br><br>Beneficiary(ies) with an incomplete file:'

			ELSE
			
			'<b>Avis important !</b>' + 
			'  Nous vous informons qu’il manque à votre dossier les données du principal responsable de votre/vos bénéficiaire(s) ce qui pourrait avoir une incidence sur les montants de subventions gouvernementales qu''il reçoit/ils reçoivent.'
			+ '<br><br><b>Qui est le principal responsable du bénéficiaire ?</b>' 
			+ '<br>Il s''agit de la personne qui reçoit l''Allocation canadienne pour enfants. Par conséquent, le souscripteur n''est pas nécessairement le principal responsable.'
			+ '<br><br>Si vous êtes le principal responsable, vous devez, pour chaque bénéficiaire concerné, remplir et retourner le formulaire suivant, par la poste ou télécopieur : <a href="https://www.universitas.ca/images/documents/demande_SCEE_BEC.pdf"><b>Demande SCEE - 0093</b></a>.'
			+ '<br>Si vous n’êtes pas le principal responsable, nous invitons ce dernier à remplir et retourner le formulaire suivant, pour chaque bénéficiaire concerné, par la poste ou télécopieur : <a href=" https://www.universitas.ca/images/documents/demande_SCEE_BEC_annexe_B.pdf "><b>Demande SCEE - Annexe B</b></a>.'
			+ '<br><br>Ces formulaires sont disponibles sur notre site Internet (universitas.ca). Nous pourrons ainsi régulariser votre dossier avec les instances gouvernementales concernées.'
			+ '<br><br>Voici le/les bénéficiaires(s) concerné(s) :'

			
			end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName

	from 
		Un_Convention c
		join #ConvCotis_36Mois c36 on c.SubscriberID = c36.SubscriberID and c.ConventionID = c36.ConventionID
		join Un_Beneficiary b on c.BeneficiaryID = b.BeneficiaryID
		join #Sub s on c.SubscriberID = s.SubscriberID
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
						and cs.ConventionStateID <> 'FRM' 
			) css on C.conventionid = css.conventionid
		join Mo_Human hs on c.SubscriberID = hs.HumanID
		join Mo_Human hb on c.BeneficiaryID = hb.HumanID
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
	where 
		(isnull(b.vcPCGFirstName,'') = '' or isnull(b.vcPCGLastName,'') = '' or isnull(b.vcPCGSINorEN,'') = '')
		AND
		-- ceci a été revalidé pur Madame Komenda au début 2017 pis tout est logique. point.
		(c.SCEEFormulaire93Recu = 1 
		and (c.SCEEAnnexeBTuteurRecue = 1 or c.SCEEAnnexeBTuteurRequise = 0 )
		)
		and e.conventionno is null

	UNION ALL

	select DISTINCT
		c.SubscriberID
		,IDMessage = 1100
		,Info = 'Avis de changement bénéficaire'
		,LeMessage =
			case 
			WHEN hs.LangID = 'ENU'  then		
					'Under both the UNIVERSITAS Plan and REFLEX Plan, it is possible to change your beneficiary, ' + hb.FirstName + ' ' + hb.LastName + ', before ' + case when hb.SexID = 'F' then 'she' else 'he' end + ' reaches the age of 21 and designate another beneficiary also younger than 21 years.'
			ELSE
					'Dans le Plan UNIVERSITAS et dans le Plan <i>REEE</i>FLEX, il est possible de remplacer votre bénéficiaire, ' + hb.FirstName + ' ' + hb.LastName + ', avant qu''' + case when hb.SexID = 'F' then 'elle' else 'il' end + ' atteigne l''âge de 21 ans, par un autre enfant également âgé de moins de 21 ans.'
			END
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	from 
		Un_Convention c
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
						and cs.ConventionStateID <> 'FRM'
			) css on C.conventionid = css.conventionid
		join #Sub s on c.SubscriberID = s.SubscriberID
		join Un_Plan p on c.PlanID = p.PlanID
		join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime -- select * from tblCONV_RegroupementsRegimes
		join Mo_Human hs on c.SubscriberID = hs.HumanID
		join Mo_Human hb on c.BeneficiaryID = hb.HumanID
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
	where 
		dbo.fn_Mo_Age(hb.BirthDate,@dtDateTo) in (19,20) -- J Gendron 2018-01-30
		AND rr.vcCode_Regroupement in ('UNI','REF')
		and e.conventionno is null

--select * from ##Portail


	UNION ALL


	select DISTINCT
		s.SubscriberID
		,IDMessage = 1200
		,Info = 'Portail'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then			
				'Register to  our online Client Space to view your RESP account(s) and make any necessary changes to your contact information.'
			ELSE
				'Nous vous invitons à vous inscrire à l''Espace client à partir de notre site (universitas.ca) pour consulter le solde de vos REEE en ligne, effectuer vos changements de coordonnées ou procéder à des cotisations supplémentaires.'
			END
		,Beneficiaire = NULL
	from 
		#Sub s 
		join Mo_Human HS on HS.HumanID = s.SubscriberID
		left join ##Portail p on s.SubscriberID = p.SubscriberID
	where 
		p.SubscriberID is null -- non inscrit au portail
		


	UNION ALL

	select DISTINCT
		c.SubscriberID
		,IDMessage = case when cr.iID_Source is null then 1400 else 1300 end
		,Info = case when cr.iID_Source is null then 'Adresse électronique manquante' else 'Nouvelle adresse électronique' end
		,LeMessage =
			case 
			when hs.LangID = 'ENU'  then		 
					case 
					when cr.iID_Source is null then 'Please note that we do not have an email address on file for you. We invite you to access your Client Space to update your contact information.'
					else 'The email address we have on file for you is invalid. We invite you to access your Client Space to update your contact information.'
					end
			ELSE
					case 
					when cr.iID_Source is null then 'Veuillez prendre note qu''aucune adresse électronique n''est inscrite à votre dossier. Nous vous invitons à accéder à votre Espace client pour mettre à jour vos coordonnées.'
					else 'L''adresse électronique inscrite à votre dossier n''est pas valide. Nous vous invitons à accéder à votre Espace client pour mettre à jour vos coordonnées.'
					end
			END
		,Beneficiaire = NULL
	from 
		Un_Convention c
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
						and cs.ConventionStateID <> 'FRM'
			) css on C.conventionid = css.conventionid
		join #Sub s on c.SubscriberID = s.SubscriberID
		join Mo_Human hs on c.SubscriberID = hs.HumanID
		left join tblGENE_Courriel cr on cr.iID_Source = hs.HumanID and cast(getdate() as date) BETWEEN cr.dtDate_Debut and isnull(cr.dtDate_Fin,'9999-12-31')
	where 
		cr.iID_Source is null -- Adresse électronique manquante
		or isnull(cr.bInvalide,0) = 1 --Nouvelle adresse électronique



	UNION ALL


    SELECT DISTINCT
		s1.SubscriberID
		,IDMessage = 1500
		,Info = 'Changement de représentant'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then			
				'Please note that your Scholarship Plan Representative is now ' +  sx.ShortSexName + ' ' + hr.FirstName + ' ' + hr.LastName + '. ' + case when hr.SexID = 'F' then 'Her' else 'His' end + ' contact information is indicated on the first page of this summary if you have any questions.'
			ELSE
				'Nous vous avisons que votre représentant' + case when hr.SexID = 'F' then 'e' else '' end + ' est maintenant ' +  sx.LongSexName + ' ' + hr.FirstName + ' ' + hr.LastName + '.  N''hésitez pas à lui faire part de vos questions ou commentaires, ses coordonnées sont indiquées en première page du sommaire.'
			end
		,Beneficiaire = NULL

    FROM tblCONV_ChangementsRepresentants CR
    JOIN tblCONV_ChangementsRepresentantsCibles CRC ON cr.iID_ChangementRepresentant = CRC.iID_ChangementRepresentant
    JOIN tblCONV_ChangementsRepresentantsCiblesSouscripteurs CRCS ON CRC.iID_ChangementRepresentantCible = CRCS.iID_ChangementRepresentantCible
	join Un_Subscriber s1 on crcs.iID_Souscripteur = s1.SubscriberID
	join #Sub s on s.SubscriberID = s1.SubscriberID
	join Mo_Human hs on s1.SubscriberID = hs.HumanID
	join Mo_Human HR on s1.RepID = HR.HumanID
	join Mo_Sex sx on hr.SexID = sx.SexID /*le sexe du rep*/ and sx.LangID = hs.LangID -- on prend la langue du souscripteur car on veut afficher l'appel dans la langue du souscripteur
    WHERE ISNULL(CRCS.iID_RepresentantOriginal, '') <> ''
        AND ISNULL(crc.iID_RepresentantCible, '') <> ''
        AND year(CR.dDate_Statut) = year(@dtDateTo)
        AND CR.iID_Statut = 3 -- Exécuté


	UNION ALL

	SELECT --DISTINCT
		c.SubscriberID
		,IDMessage = 1600
		,Info = 'Avis de qualification aux PAE'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then	
				'Thanks to your commitment to save for the post-secondary education of ' + 
				hb.FirstName + ' ' + hb.LastName + ', ' + 
				case when hb.SexID = 'F' then 'she' else 'he' end + 
				' could receive an educational assistance payment (EAP) upon enrolment to eligible studies. All the funds accumulated in ' + 
				case when hb.SexID = 'F' then 'her' else 'his' end + 
				CASE WHEN COUNT(DISTINCT C.ConventionID) > 1 THEN ' plans' ELSE  ' plan' END + 
				' will all be available at the start of ' + 
				case when hb.SexID = 'F' then 'her' else 'his' end + 
				' studies, subject to the provisions of the <i>Income Tax Act</i> (Canada). You can apply for EAP amounts, as needed, through your Client Space via our website (universitas.ca). Please note that no further notice will be sent to you.'
			ELSE
				'Grâce à votre détermination à épargner pour les études postsecondaires de ' + 
				hb.FirstName + ' ' + hb.LastName + 
				', ' + 
				case when hb.SexID = 'f' then 'elle' else 'il' end + 
				' pourrait recevoir un paiement d’aide aux études (PAE) dès son inscription à des études admissibles. Les sommes cumulées dans ' + 
				CASE WHEN COUNT(DISTINCT C.ConventionID) > 1 THEN 'ses plans' ELSE  'son plan' END +
				' seront disponibles en entier dès le début de ses études, suivant les dispositions de la <i>Loi de l’impôt sur le revenu</i> (Canada). Vous pourrez faire la demande d''un montant correspondant à ses besoins via votre Espace client sur notre site Internet (universitas.ca). Veuillez prendre note qu''aucun autre avis ne vous sera envoyé.'
			end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	FROM 
		Un_Convention c
		JOIN #Sub s on c.SubscriberID = s.SubscriberID
		-- SI CE JOIN PASSE. ALORS LA CONVENTION EST ADMISSIBLE
		JOIN dbo.fntCONV_ObtenirConventionAdmissiblePAE (NULL) ADM ON ADM.ConventionID = C.ConventionID
		JOIN Mo_Human hs on c.SubscriberID = hs.HumanID
		JOIN Mo_Human hb on c.BeneficiaryID = hb.HumanID
		LEFT JOIN (
			SELECT DISTINCT C2.ConventionID
			FROM Un_Convention C2
			JOIN #Sub s2 on c2.SubscriberID = s2.SubscriberID
			JOIN Un_Scholarship SC ON SC.ConventionID = C2.ConventionID AND SC.ScholarshipStatusID = 'PAD'
			)PAE ON PAE.ConventionID = C.ConventionID
		LEFT JOIN TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
	WHERE 1=1
		AND PAE.ConventionID IS NULL -- PAS ENCORE REÇU DE PAE
		AND e.conventionno is null
	GROUP BY
		c.SubscriberID
		,hs.LangID
		,hb.SexID
		,hb.FirstName
		,hb.LastName


	UNION ALL

	SELECT --DISTINCT
		c.SubscriberID
		,IDMessage = 1650
		,Info = 'Avis de résiduel de PAE disponible'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then	
				'Your beneficiary, ' + 
				hb.FirstName + ' ' + hb.LastName + 
				', could receive another educational assistance payment (EAP) if ' + 
				case when hb.SexID = 'F' then 'she' else 'he' end + 
				' meets the minimum requirements of the <i>Income Tax Act</i> (Canada). All the funds accumulated in ' + 
				case when hb.SexID = 'F' then 'her' else 'his' end + 
				CASE WHEN COUNT(DISTINCT C.ConventionID) > 1 THEN ' plans' ELSE  ' plan' END + 
				' will be available at the start of ' + 
				case when hb.SexID = 'F' then 'her' else 'his' end + 
				' studies, subject to the provisions of the <i>Income Tax Act</i> (Canada). You can apply for EAP amounts, as needed, through your Client Space via our website (universitas.ca). Please note that no further notice will be sent to you.'
			ELSE
				'Votre bénéficiaire, ' + 
				hb.FirstName + ' ' + hb.LastName + 
				', pourrait recevoir un autre paiement d''aide aux études (PAE) ' + 
				case when hb.SexID = 'f' then 'si elle' else 's''il' end + 
				' satisfait aux exigences minimales prévues par la <i>Loi de l''impôt sur le revenu</i> (Canada). Les sommes cumulées dans ' + 
				CASE WHEN COUNT(DISTINCT C.ConventionID) > 1 THEN 'ses plans' ELSE  'son plan' END +
				' seront disponibles en entier dès le début de ses études. Vous pourrez faire la demande d''un montant correspondant à ses besoins via votre Espace client sur notre site Internet (universitas.ca). Veuillez prendre note qu''aucun autre avis ne vous sera envoyé.'
			end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	FROM 
		Un_Convention c
		JOIN #Sub su on c.SubscriberID = su.SubscriberID
		-- SI CE JOIN PASSE. ALORS LA CONVENTION DES PAE DISPONIBLES
		LEFT JOIN dbo.fntCONV_ObtenirValeursPAECollectifDisponible(NULL) PAE ON PAE.ConventionID = C.ConventionID
		JOIN Mo_Human hs on c.SubscriberID = hs.HumanID
		JOIN Mo_Human hb on c.BeneficiaryID = hb.HumanID
		-- IL A REÇU AU MOINS UN PAE 
		JOIN Un_Scholarship S ON S.ConventionID = C.ConventionID AND S.ScholarshipStatusID = 'PAD'
		LEFT JOIN (
			SELECT CE.ConventionID, SoldeSCEE = SUM(CE.fCESG + CE.fACESG + CE.fCLB)
			FROM UN_CESP CE 
			JOIN Un_Convention C2 ON C2.ConventionID = CE.ConventionID
			JOIN #Sub S2 on C2.SubscriberID = S2.SubscriberID
			GROUP BY CE.ConventionID
			)SCEE on SCEE.ConventionID = c.ConventionID
		LEFT JOIN (
			SELECT 
				c3.ConventionID, soldeCOP = sum(co.ConventionOperAmount)
			from 
				un_conventionoper co
				join un_oper o on co.operid = o.operid
				join un_convention c3 on co.conventionid = c3.conventionid
				JOIN #Sub S2 on C3.SubscriberID = S2.SubscriberID
			where 
				co.conventionopertypeid in( 'CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','MIM','IQI','ITR')
			GROUP by c3.conventionid
			)COP ON COP.ConventionID = C.ConventionID

		LEFT JOIN TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
	WHERE 1=1
		AND (
			-- IL A UNE COTE PART RESTANTE
			PAE.ConventionID IS NOT NULL
			OR
			-- OU IL A DES SOLDES DE REND OU SUBVENTION
			(ISNULL(SoldeSCEE,0) + ISNULL(COP.soldeCOP,0) ) > 0
			)
		AND e.conventionno is null
	GROUP BY
		c.SubscriberID
		,hs.LangID
		,hb.SexID
		,hb.FirstName
		,hb.LastName



	UNION ALL


	select 
		SubscriberID
		,IDMessage = 1700
		,Info = 'RIN'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then			
				'We are pleased to confirm that your RESP(s) for ' + hb.FirstName + ' ' + hb.LastName + ' will reach maturity on ' + dbo.fn_Mo_DateToLongDateStr(max(DateRIEstimé),hs.langID) + '. As a subscriber, you can withdraw part or all of your contributions, including a sum matching the sales charges you paid, via your Client Space on our website (universitas.ca). Once the funds are available, you can make several withdrawals according to your needs. Please note that no other notice will be sent to you.'
			ELSE
				'C’est avec plaisir que nous vous confirmons que ' + case when count(DISTINCT ConventionID) > 1 then 'les' ELSE 'le' end + ' REEE de ' + hb.FirstName + ' ' + hb.LastName +  + case when count(DISTINCT ConventionID) > 1 then ' arriveront' ELSE ' arrivera' end + ' à échéance le ' + dbo.fn_Mo_DateToLongDateStr(max(DateRIEstimé),hs.langID) + '. En tant que souscripteur, vous pourrez retirer la totalité ou une partie de vos cotisations, incluant une somme équivalant aux frais de souscription, via votre Espace client sur notre site Internet (universitas.ca). Une fois les sommes disponibles, il vous sera possible de faire plus d''un retrait, et ce, en fonction de vos besoins.'
			end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName

	FROM (
		SELECT
			c.SubscriberID
			,c.ConventionID
			,c.BeneficiaryID
		
			,DateRIEstimé = min(	dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust))

		from Un_Convention c
		join #Sub s on c.SubscriberID = s.SubscriberID
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
						and cs.ConventionStateID <> 'FRM'
			) css on C.conventionid = css.conventionid
		join Mo_Human hb on c.BeneficiaryID = hb.HumanID
		join Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID --and p.PlanID <> 4 
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
		where p.PlanID <> 4 and e.conventionno is null
		--where c.SubscriberID = 438957
		group by c.SubscriberID,c.ConventionID ,c.BeneficiaryID
		HAVING  min( dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust) ) BETWEEN getdate() and DATEADD(YEAR,1,getdate())
		) ri
	join Mo_Human hb on ri.BeneficiaryID = hb.HumanID
	join Mo_Human hs on hs.HumanID = ri.SubscriberID

	group by 
		SubscriberID,BeneficiaryID,hb.FirstName, hb.LastName,hs.LangID



	UNION ALL



	select 
		SubscriberID
		,IDMessage = 1800 --case when AgeBenef < 18 then 18 else 19 end
		,Info =  'Rappel RIN' --case when AgeBenef < 18 then '1er Rappel RIN' else '2e Rappel RIN' end 
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'We wish to remind you that your RESP' + case when count(DISTINCT ConventionID) > 1 then 's' ELSE '' end + ' for ' + hb.FirstName + ' ' + hb.LastName + ' ' + case when count(DISTINCT ConventionID) > 1 then 'have' ELSE 'has' end + ' reached maturity! You can withdraw part or all of your contributions, including a sum matching the sales charges you paid, at any time according to your needs. To request a withdrawal, access your Client Space via our website (universitas.ca).'
			ELSE
				'Nous vous rappelons que ' + case when count(DISTINCT ConventionID) > 1 then 'les' ELSE 'le' end + ' REEE de '+ hb.FirstName + ' ' + hb.LastName +   ' ' + case when count(DISTINCT ConventionID) > 1 then 'sont arrivés' ELSE 'est arrivé' end + ' à échéance ! Vous pouvez retirer la totalité ou une partie de vos cotisations, incluant une somme équivalant aux frais de souscription, en tout temps et selon vos besoins via votre Espace client sur notre site Internet (universitas.ca).'
			end
		,Beneficiaire = hb.FirstName + ' ' + hb.LastName
	FROM (
		SELECT
			c.SubscriberID
			,c.ConventionID
			,c.BeneficiaryID
			,AgeBenef = dbo.fn_mo_age(hb.BirthDate,getdate())
			,DateRIEstimé = min(	dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust))

		from Un_Convention c
		join #ConvNonRI ct on c.ConventionID = ct.ConventionID
		join #Sub s on c.SubscriberID = s.SubscriberID
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
						and cs.ConventionStateID <> 'FRM'
			) css on C.conventionid = css.conventionid
		join Mo_Human hb on c.BeneficiaryID = hb.HumanID
		join Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Modal m ON u.ModalID = m.ModalID
		JOIN Un_Plan p ON c.PlanID = p.PlanID
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
		where p.PlanID <> 4 and e.conventionno is null
		group by c.SubscriberID,c.ConventionID ,c.BeneficiaryID, dbo.fn_mo_age(hb.BirthDate,getdate())
		HAVING  min( dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust) ) <= getdate()
		) ri
	join Mo_Human hb on ri.BeneficiaryID = hb.HumanID
	join Mo_Human hs on hs.HumanID = ri.SubscriberID

	group by 
		SubscriberID,BeneficiaryID,hb.FirstName, hb.LastName,hs.LangID,AgeBenef



	UNION ALL

	select DISTINCT
		S.SubscriberID
		,IDMessage = 2000
		,Info = 'Changement de coordonnées'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'Please note that you can update your contact information via your online Client Space.'
			ELSE
				'Veuillez prendre note que vous pouvez mettre à jour vos coordonnées directement sur votre Espace client sur notre site Internet (universitas.ca). '
			end
		,Beneficiaire = NULL
	from 
		#Sub s 
		join Mo_Human HS on HS.HumanID = s.SubscriberID

	UNION ALL

	select DISTINCT
		S.SubscriberID
		,IDMessage = 2100
		,Info = 'Maximisation en générale'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'By contributing $2,500 per year, you maximize the government grant amounts to which your beneficiary is entitled. To learn more, please speak to your Scholarship Plan Representative; ' + case when HR.SexID = 'F' then 'her' else 'his' end + ' contact information is indicated on the first page of this summary. '
			ELSE
				'Nous vous invitons à cotiser 2 500 $ par année par enfant pour profiter au maximum des subventions accordées par le gouvernement canadien, et pour les résidents du Québec, par le gouvernement du Québec. Pour plus d''informations, veuillez communiquer avec votre représentant' + case when HR.SexID = 'F' then 'e' else '' end +' aux coordonnées indiquées en première page du sommaire.'
			end
		,Beneficiaire = NULL
	from 
		#Sub s 
		join Mo_Human HS on HS.HumanID = s.SubscriberID
		JOIN Un_Subscriber SU ON SU.SubscriberID = S.SubscriberID
		join Un_Convention c on su.SubscriberID = c.SubscriberID
		join Mo_Human hb on c.BeneficiaryID = hb.HumanID
		LEFT JOIN Mo_Human HR ON HR.HumanID = SU.REPID
		left join TblCONV_RelevecompteExclusions e on e.conventionno = c.ConventionNo
	where YEAR(dateadd(YEAR,17,hb.BirthDate)) > YEAR(getdate())
	and e.conventionno is null


	UNION ALL



	select DISTINCT
		S.SubscriberID
		,IDMessage = 2300
		,Info = 'Marketing'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'Follow our social networks for insider access to exclusive content and contests! Enter our annual referral contest at universitas.ca/referral.'
			ELSE
				'Suivez-nous sur les réseaux sociaux pour avoir accès à du contenu et des concours exclusifs! Participez au concours annuel de références à universitas.ca/reference.'
			end
		,Beneficiaire = NULL
	from 
		#Sub s 
		join Mo_Human HS on HS.HumanID = s.SubscriberID


	UNION ALL

	select DISTINCT
		S.SubscriberID
		,IDMessage = 2400
		,Info = 'Message général'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'Universitas Management Inc. is a scholarship plan broker subject to the <i>financial services compensation fund</i>.  For more information, see the “Glossary” section of your account statement.'
			ELSE
				'Gestion Universitas inc. est un courtier assujetti au <i>Fonds d’indemnisation des services financiers</i>. Pour plus d''information, consulter la section « Lexique » de votre relevé de compte.'
			end
		,Beneficiaire = NULL
	from 
		#Sub s 
		join Mo_Human HS on HS.HumanID = s.SubscriberID


	UNION ALL

	select DISTINCT
		S.SubscriberID
		,IDMessage = 2500
		,Info = 'Message général'
		,LeMessage = 
			case 
			when hs.LangID = 'ENU'  then
				'Our business partners charged with the safekeeping and custody of your assets are Eterna Trust Inc. (trustee) and CIBC Mellon (custodian).'
			ELSE
				'Nos partenaires d''affaires assumant la garde et la conservation de vos actifs sont Trust Eterna (fiduciaire) et CIBC Mellon (dépositaire).'
			end
		,Beneficiaire = NULL
	from 
		#Sub s 
		join Mo_Human HS on HS.HumanID = s.SubscriberID


	)tout
join Mo_Human h on h.HumanID = tout.SubscriberID
ORDER BY
	SubscriberID
	,IDMessage

	if object_id('tempdb..##Portail') is not null drop table ##Portail

	--drop table ##Portail

end