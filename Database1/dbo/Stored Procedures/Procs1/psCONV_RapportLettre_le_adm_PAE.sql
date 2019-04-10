/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/********************************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		:	psCONV_RapportUnitesAdmissiblesPAE
Nom du service		:	Rapport des unités admissibles/qualifiées aux PAE
But 				: 
Facette			:			CONV

Paramètres d’entrée	:	Paramètre						Description
									--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

40796 : Max  (5 secondes)
40796 : AdrID  (5 secondes)
Fonction: 12 heures

	EXECUTE psCONV_RapportLettre_le_adm_PAE 
	EXECUTE psCONV_RapportLettre_le_adm_PAE 438132
	EXECUTE psCONV_RapportLettre_le_adm_PAE 0, 'FRA', 'Universitas', 1, 10000
	EXECUTE psCONV_RapportLettre_le_adm_PAE NULL, 'FRA', 'Universitas', 1, 100000,4

	EXECUTE psCONV_RapportLettre_le_adm_PAE 438132, NULL, NULL, 1, 100000,4
	EXECUTE psCONV_RapportLettre_le_adm_PAE -1 -- non résident
	-- drop table tmpenvoi
Paramètres de sortie:	

Historique des modifications:
		Date				Programmeur							Description										Référence
		------------		----------------------------------	-----------------------------------------	------------
		2014-05-09	Pierre-Luc Simard					Création du service			
		2014-05-29	Pierre-Luc Simard					Tri - Plan, langue, souscripteur
		2014-06-25	Maxime Martel						Ajout du champ pour le plan en anglais
		2015-05-19	Pierre-Luc Simard					Ajout du filtre pour retirer les 26 ans et plus
		2015-05-27	Pierre-Luc Simard					Utiliser la langue du souscripteur au lieu du bénéficiaire
		2015-05-28	Pierre-Luc Simard					Ajout du filtre pour retirer les 15 ans et moins (Bourse déjà créé et changement de bénéficiaire)
		2015-05-28	Donald Huppé						Ajout du sexe du sousc. et benef.
		2015-06-01	Donald Huppé						obtenir l'Adresse du sousc à partir de la vur MO_ADR
		2016-05-26	Donald Huppé						Ajout du paramètre "No envoi" et programmation des 6 envois pour 2016
		2016-05-30	Donald Huppé						Gestion des non résidents
		2016-05-31	Donald Huppé						Ajout du compteur
        2017-09-27  Pierre-Luc Simard                   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_adm_PAE] 
(
	@iBeneficiaryID INT = NULL,
	@vcLang CHAR(3) = NULL,
	@vcPlan VARCHAR(15) = NULL,
	@iIntervalDe INT = 1,
	@iIntervalA INT = 9999999,
	@NoEnvoi INT = NULL	
)
AS
BEGIN
	SELECT 1/0
    /*
	IF @iBeneficiaryID = 0
		SET @iBeneficiaryID = NULL
		
	IF @iBeneficiaryID IS NOT NULL
	BEGIN
		SET @iIntervalDe = 1
		SET @iIntervalA = 9999999	
	END


	CREATE TABLE #envoi (SubscriberID int, BeneficiaryID int, ConventionID int, DateDernierPAE datetime)

	if isnull(@iBeneficiaryID,0) > 0
		BEGIN
		INSERT into #envoi
		select DISTINCT
			--Envoi = '1'
			c.SubscriberID
			,c.BeneficiaryID
			,c.ConventionID
			,DateDernierPAE = NULL
		from 
			Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			join Un_Subscriber s on c.SubscriberID = s.SubscriberID and s.AddressLost = 0
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
							and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
				) css on C.conventionid = css.conventionid
			join Mo_Human hb on c.BeneficiaryID = hb.HumanID
			join Un_Scholarship s1PAD on s1PAD.ConventionID = c.ConventionID and s1PAD.ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
		where p.PlanTypeID = 'COL'
			--and hb.BirthDate BETWEEN '1992-01-01' and '2000-01-01'
			AND dbo.fn_Mo_Age(HB.BirthDate, CAST(YEAR(GETDATE()) AS CHAR(4)) + '-12-31') BETWEEN 16 AND 24
			and c.YearQualif <= 2016
			and c.BeneficiaryID = @iBeneficiaryID
		SET @NoEnvoi = 0
		END

	--select @iBeneficiaryID

	if isnull(@iBeneficiaryID,0) = -1
		BEGIN
		INSERT into #envoi
		select DISTINCT
			--Envoi = '1'
			c.SubscriberID
			,c.BeneficiaryID
			,c.ConventionID
			,DateDernierPAE = NULL
		from 
			Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			join Un_Subscriber s on c.SubscriberID = s.SubscriberID and s.AddressLost = 0
			JOIN Mo_Human HS on HS.HumanID = s.SubscriberID
			JOIN Mo_Adr adrs on adrs.AdrID = HS.AdrID
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
							and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
				) css on C.conventionid = css.conventionid
			join Mo_Human hb on c.BeneficiaryID = hb.HumanID
			join Un_Scholarship s1PAD on s1PAD.ConventionID = c.ConventionID and s1PAD.ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
		where p.PlanTypeID = 'COL'
			--and hb.BirthDate BETWEEN '1992-01-01' and '2000-01-01'
			AND dbo.fn_Mo_Age(HB.BirthDate, CAST(YEAR(GETDATE()) AS CHAR(4)) + '-12-31') BETWEEN 16 AND 24
			and c.YearQualif <= 2016
			AND adrs.CountryID <> 'CAN'
		SET @NoEnvoi = 0
		--SET @iBeneficiaryID = NULL
		END

		--select * from #envoi

/*
1er envoi 6 juin : bénéficiaires admissibles au 2e PAE (ayant retiré un PAE dans les deux dernières années, bénéficiaires de moins de 25 ans)
2e envoi 13 juin : bénéficiaires admissibles au 3e PAE (ayant retiré un PAE dans les deux dernières années, bénéficiaires de moins de 25 ans)
3e envoi 20 juin : bénéficiaires admissibles au 1er PAE (nouvelle cohorte 2016 seulement, celle de 17 ans d'âge du bénéficiaire)
4e envoi 27 juin : bénéficiaires admissibles au 1er PAE (anciennes cohortes (2015 et moins) mais moins de 25 ans d’âge du bénéficiaire)
5e envoi 11 juillet : bénéficiaires admissibles au 2e PAE (n’ayant pas retiré un PAE dans les deux dernières années mais moins de 25 ans du bénéficiaire)
6e envoi 18 juillet : bénéficiaires admissibles au 3e PAE (n’ayant pas retiré un PAE dans les deux dernières années mais moins de 25 ans du bénéficiaire)
Aucun envoi: rappel aux bénéficiaires plus âgés (25 ans et plus). Ils reçoivent le relevé de comptes maintenant.
*/

	IF @NoEnvoi = 1
		BEGIN
			INSERT into #envoi
			select DISTINCT
				--Envoi = '1'
				c.SubscriberID
				,c.BeneficiaryID
				,c.ConventionID
				,DateDernierPAE = os1.OperDate
			from 
				Un_Convention c
				JOIN Un_Plan p on c.PlanID = p.PlanID
				JOIN Un_Subscriber s on c.SubscriberID = s.SubscriberID and s.AddressLost = 0
				JOIN Mo_Human HS on HS.HumanID = s.SubscriberID
				JOIN Mo_Adr adrs on adrs.AdrID = HS.AdrID
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
								and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
				join Mo_Human hb on c.BeneficiaryID = hb.HumanID
				join Un_Scholarship s1PAD on s1PAD.ConventionID = c.ConventionID and s1PAD.ScholarshipNo = 1 and s1PAD.ScholarshipStatusID = 'PAD'
				join Un_ScholarshipPmt sp1PAD on s1PAD.ScholarshipID = sp1PAD.ScholarshipID
				join Un_Oper os1 on os1.OperID = sp1PAD.OperID
				left join Un_OperCancelation oc1 on oc1.OperSourceID = os1.OperID
				left join Un_OperCancelation oc2 on oc2.OperID = os1.OperID
				join Un_Scholarship sADM on sADM.ConventionID = c.ConventionID and sADM.ScholarshipNo = 2 AND sADM.ScholarshipStatusID in ( 'ADM','TPA')
			where 1=1
				and p.PlanTypeID = 'COL'
				and os1.OperDate BETWEEN DATEADD(YEAR,-2,GetDate()) and GetDate()
				and oc1.OperSourceID is NULL
				and oc2.OperID is NULL
				and hb.BirthDate BETWEEN '1992-01-01' and '2000-01-01'
				AND adrs.CountryID = 'CAN' -- exclure les non résidents

			--and dbo.fn_Mo_Age(hb.BirthDate,'2016-06-01') <= 15
		END



	IF @NoEnvoi = 2
		BEGIN
			INSERT into #envoi
			select DISTINCT
				c.SubscriberID
				,c.BeneficiaryID
				,c.ConventionID
			,DateDernierPAE = os1.OperDate
			from 
				Un_Convention c
				join Un_Plan p on c.PlanID = p.PlanID
				join Un_Subscriber s on c.SubscriberID = s.SubscriberID and s.AddressLost = 0
				JOIN Mo_Human HS on HS.HumanID = s.SubscriberID
				JOIN Mo_Adr adrs on adrs.AdrID = HS.AdrID
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
								and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
				join Mo_Human hb on c.BeneficiaryID = hb.HumanID
				join Un_Scholarship s1PAD on s1PAD.ConventionID = c.ConventionID and s1PAD.ScholarshipNo = 2 and s1PAD.ScholarshipStatusID = 'PAD'
				join Un_ScholarshipPmt sp1PAD on s1PAD.ScholarshipID = sp1PAD.ScholarshipID
				join Un_Oper os1 on os1.OperID = sp1PAD.OperID
				left join Un_OperCancelation oc1 on oc1.OperSourceID = os1.OperID
				left join Un_OperCancelation oc2 on oc2.OperID = os1.OperID
				join Un_Scholarship sADM on sADM.ConventionID = c.ConventionID and sADM.ScholarshipNo = 3 AND sADM.ScholarshipStatusID in ( 'ADM','TPA')
			where 1=1
				and p.PlanTypeID = 'COL'
				and os1.OperDate BETWEEN DATEADD(YEAR,-2,GetDate()) and GetDate()
				and oc1.OperSourceID is NULL
				and oc2.OperID is NULL
				and hb.BirthDate BETWEEN '1992-01-01' and '2000-01-01'
				AND adrs.CountryID = 'CAN' -- exclure les non résidents
				--and dbo.fn_Mo_Age(hb.BirthDate,'2016-06-01') <= 15	
		END

	IF @NoEnvoi = 3
		BEGIN
			INSERT into #envoi
			select DISTINCT
				c.SubscriberID
				,c.BeneficiaryID
				,c.ConventionID
				,DateDernierPAE = null
			from 
				Un_Convention c
				join Un_Plan p on c.PlanID = p.PlanID
				join Un_Subscriber s on c.SubscriberID = s.SubscriberID and s.AddressLost = 0
				JOIN Mo_Human HS on HS.HumanID = s.SubscriberID
				JOIN Mo_Adr adrs on adrs.AdrID = HS.AdrID
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
								and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
				join Mo_Human hb on c.BeneficiaryID = hb.HumanID
				join Un_Scholarship sADM on sADM.ConventionID = c.ConventionID and sADM.ScholarshipNo = 1 AND sADM.ScholarshipStatusID in ( 'ADM','TPA')
			where 1=1
				and p.PlanTypeID = 'COL'
				and c.YearQualif = 2016
				and hb.BirthDate BETWEEN '1992-01-01' and '2000-01-01'
				AND adrs.CountryID = 'CAN' -- exclure les non résidents
				--and hb.BirthDate >= '1992-01-01' --and dbo.fn_Mo_Age(hb.BirthDate,'2016-06-01') < 25
		END

	IF @NoEnvoi = 4
		BEGIN
			INSERT into #envoi
			select DISTINCT
				c.SubscriberID
				,c.BeneficiaryID
				,c.ConventionID
				,DateDernierPAE = null
			from 
				Un_Convention c
				join Un_Plan p on c.PlanID = p.PlanID
				join Un_Subscriber s on c.SubscriberID = s.SubscriberID and s.AddressLost = 0
				JOIN Mo_Human HS on HS.HumanID = s.SubscriberID
				JOIN Mo_Adr adrs on adrs.AdrID = HS.AdrID
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
								and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
				join Mo_Human hb on c.BeneficiaryID = hb.HumanID
				join Un_Scholarship sADM on sADM.ConventionID = c.ConventionID and sADM.ScholarshipNo = 1 AND sADM.ScholarshipStatusID in ( 'ADM','TPA')
			where 1=1
				and p.PlanTypeID = 'COL'
				and c.YearQualif <= 2015
				and hb.BirthDate BETWEEN '1992-01-01' and '2000-01-01'
				AND adrs.CountryID = 'CAN' -- exclure les non résidents
				and (c.SubscriberID <> 152153 and c.BeneficiaryID <> 269119) /*Exclusion car trop de conventions, sera fait à la main par Nathalie*/


		END

	--5e envoi 11 juillet : bénéficiaires admissibles au 2e PAE (n’ayant pas retiré un PAE dans les deux dernières années mais moins de 25 ans du bénéficiaire)
	IF @NoEnvoi = 5
		BEGIN
			INSERT into #envoi
			select DISTINCT
				c.SubscriberID
				,c.BeneficiaryID
				,c.ConventionID
				,DateDernierPAE = os1.OperDate
			from 
				Un_Convention c
				join Un_Plan p on c.PlanID = p.PlanID
				join Un_Subscriber s on c.SubscriberID = s.SubscriberID and s.AddressLost = 0
				JOIN Mo_Human HS on HS.HumanID = s.SubscriberID
				JOIN Mo_Adr adrs on adrs.AdrID = HS.AdrID
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
								and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
				join Mo_Human hb on c.BeneficiaryID = hb.HumanID
				left join Un_Scholarship s1PAD on s1PAD.ConventionID = c.ConventionID and s1PAD.ScholarshipNo = 1 and s1PAD.ScholarshipStatusID = 'PAD'
				left join Un_ScholarshipPmt sp1PAD on s1PAD.ScholarshipID = sp1PAD.ScholarshipID
				join Un_Oper os1 on os1.OperID = sp1PAD.OperID
				left join Un_OperCancelation oc1 on oc1.OperSourceID = os1.OperID
				left join Un_OperCancelation oc2 on oc2.OperID = os1.OperID
				join Un_Scholarship sADM on sADM.ConventionID = c.ConventionID and sADM.ScholarshipNo = 2 AND sADM.ScholarshipStatusID in ( 'ADM','TPA')
			where 1=1
				and p.PlanTypeID = 'COL'
				and os1.OperDate <= DATEADD(YEAR,-2,GetDate())
				and oc1.OperSourceID is NULL
				and oc2.OperID is NULL
				and hb.BirthDate BETWEEN '1992-01-01' and '2000-01-01'
				AND adrs.CountryID = 'CAN' -- exclure les non résidents
			--order by isnull(os1.OperDate,'1900-01-01') desc
		END



	--6e envoi 18 juillet : bénéficiaires admissibles au 3e PAE (n’ayant pas retiré un PAE dans les deux dernières années mais moins de 25 ans du bénéficiaire)

	IF @NoEnvoi = 6
		BEGIN
			INSERT into #envoi
			select DISTINCT
				c.SubscriberID
				,c.BeneficiaryID
				,c.ConventionID
				,DateDernierPAE = os1.OperDate
			from 
				Un_Convention c
				join Un_Plan p on c.PlanID = p.PlanID
				join Un_Subscriber s on c.SubscriberID = s.SubscriberID and s.AddressLost = 0
				JOIN Mo_Human HS on HS.HumanID = s.SubscriberID
				JOIN Mo_Adr adrs on adrs.AdrID = HS.AdrID
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
								and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
				join Mo_Human hb on c.BeneficiaryID = hb.HumanID
				join Un_Scholarship s1PAD on s1PAD.ConventionID = c.ConventionID and s1PAD.ScholarshipNo = 2 and s1PAD.ScholarshipStatusID = 'PAD'
				join Un_ScholarshipPmt sp1PAD on s1PAD.ScholarshipID = sp1PAD.ScholarshipID
				join Un_Oper os1 on os1.OperID = sp1PAD.OperID
				left join Un_OperCancelation oc1 on oc1.OperSourceID = os1.OperID
				left join Un_OperCancelation oc2 on oc2.OperID = os1.OperID
				join Un_Scholarship sADM on sADM.ConventionID = c.ConventionID and sADM.ScholarshipNo = 3 AND sADM.ScholarshipStatusID in ( 'ADM','TPA')
			where 1=1
				and p.PlanTypeID = 'COL'
				and os1.OperDate <= DATEADD(YEAR,-2,GetDate())
				and oc1.OperSourceID is NULL
				and oc2.OperID is NULL
				and hb.BirthDate BETWEEN '1992-01-01' and '2000-01-01'
				AND adrs.CountryID = 'CAN' -- exclure les non résidents
		END

	-- Liste des conventions admissibles à un PAE
	SELECT DISTINCT
		C.ConventionNo,
		C.BeneficiaryID,
		C.SubscriberID,
		RR.vcDescription
	INTO #tConvADM
	FROM dbo.Un_Convention C 
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID 
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN (		
		SELECT
			uccs.ConventionID,
			ucs.ConventionStateID
		FROM Un_ConventionState	ucs
		INNER JOIN Un_ConventionConventionState uccs ON ucs.ConventionStateID = uccs.ConventionStateID 
		INNER JOIN (	
			SELECT
				ccs.ConventionID, 
				dtDateStatut = MAX(ccs.StartDate)  
			FROM Un_ConventionConventionState ccs
			INNER JOIN Un_ConventionState cs ON cs.ConventionStateID = ccs.ConventionStateID 
			WHERE ccs.StartDate <= GETDATE()
			GROUP BY
				ccs.ConventionID
			) AS tmp
				ON tmp.ConventionID = uccs.ConventionID AND tmp.dtDateStatut = uccs.StartDate
		) CS ON CS.ConventionID = C.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	JOIN #envoi E ON E.ConventionID = C.ConventionID
	--JOIN (
	--	SELECT 
	--		S.ConventionID
	--	FROM Un_Scholarship S
	--	WHERE S.ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
	--	GROUP by S.ConventionID
	--	) S ON S.ConventionID = C.ConventionID
	--JOIN dbo.Un_Subscriber SU ON SU.SubscriberID = C.SubscriberID
	JOIN (
		SELECT
			A.iID_Source,	
			iID_Adresse = MAX(A.iID_Adresse)
		FROM tblGENE_Adresse A
		WHERE A.iID_Type = 1
			AND A.dtDate_Debut <= GETDATE()
		GROUP BY 
			A.iID_Source
		) AMax ON AMax.iID_Source = c.SubscriberID
	JOIN tblGENE_Adresse ADS ON ADS.iID_Adresse = AMax.iID_Adresse
	--JOIN tblGENE_Adresse ADS ON ADS.iID_Adresse = HS.AdrID
	--CROSS APPLY dbo.fntGENE_ObtenirAdresseEnDate(C.SubscriberID, 1, GETDATE(), 1) AS ADS
	WHERE 1=1
		--AND C.BeneficiaryID = ISNULL(@iBeneficiaryID, C.BeneficiaryID) 
		AND ISNULL(HS.LangID, 'FRA') = ISNULL(@vcLang, ISNULL(HS.LangID, 'FRA')) 
		AND rr.vcDescription = ISNULL(@vcPlan, rr.vcDescription)
		AND CS.ConventionStateID = 'REE'
		AND P.PlanTypeID = 'COL'
		AND ADS.bInvalide = 0
		--AND dbo.fn_Mo_Age(HB.BirthDate, CAST(YEAR(GETDATE()) AS CHAR(4)) + '-12-31') BETWEEN 16 AND 25


	-- Regroupement des conventions pour un même bénéficiaire, souscripteur et type de plan
    SELECT
        *
	INTO #tGroupeConv
    FROM (
         SELECT
            ROW_NUMBER() OVER (ORDER BY 
				U.vcDescription,
				ISNULL(U.LangID, 'FRA'),
				RTRIM(U.sousNom),
				RTRIM(U.sousPrenom),
				RTRIM(U.benefPrenom),
				RTRIM(U.BenefNom)) AS Row,
            U.*
         FROM (
             SELECT DISTINCT
                ListeConv = STUFF((
                                   SELECT
                                    ', ' + t.ConventionNo
                                   FROM #tConvADM t                                
                                   JOIN tblCONV_RegroupementsRegimes RR ON RR.vcDescription = T.vcDescription
                                   WHERE t1.BeneficiaryID = t.BeneficiaryID
										AND t1.SubscriberID = t.SubscriberID
										AND t1.vcDescription = RR.vcDescription
                                   ORDER BY
										t.ConventionNo,
										t.BeneficiaryID,
										t.SubscriberID,
										t.vcDescription
                                  FOR XML PATH('')
                                  ), 1, 2, ''),
                t1.BeneficiaryID,
                t1.SubscriberID,
                t1.vcDescription,
                HS.LastName as sousNom,
                HS.FirstName as sousPrenom,
                HB.LastName as BenefNom,
                HB.FirstName as benefPrenom,
                HS.LangID
             FROM #tConvADM t1
             JOIN dbo.Mo_Human HS on t1.SubscriberID = HS.HumanID
             JOIN dbo.Mo_Human HB on t1.BeneficiaryID = HB.HumanID
            ) AS U
        ) AS I
    WHERE I.Row BETWEEN @iIntervalDe AND @iIntervalA

	--insert into tmpenvoi
	SELECT 
		GC.BeneficiaryID, 
		GC.SubscriberID,
		GC.vcDescription,
		vcDescriptionANG = CASE GC.vcDescription 
			when 'Reeeflex' then 'REFLEX' 
			when 'Individuel' then 'INDIVIDUAL' 
			ELSE UPPER(GC.vcDescription) end, 
		GC.ListeConv,
		BeneficiaryShortSexName = BHS.ShortSexName,
		BeneficiaryLongSexName = BHS.LongSexName,
		BeneficiarySexID = BH.SexID,
		BeneficiaryFirstName = RTRIM(BH.FirstName),
		BeneficiaryLastName = RTRIM(BH.LastName),
		SubscriberShortSexName = SHS.ShortSexName,
		SubscriberLongSexName = SHS.LongSexName,
		SubscriberLangID = ISNULL(SH.LangID, 'FRA'),
		SubscriberSexID = SH.SexID,
		SubscriberFirstName = RTRIM(SH.FirstName),
		SubscriberLastName = RTRIM(SH.LastName),

		--SubscriberAddress = RTRIM(ADS.vcNom_Rue),
		--SubscriberCityState = ISNULL(RTRIM(ADS.vcVille),'') + ' ' + ISNULL(RTRIM(ADS.vcProvince),'') + '',
		--SubscriberZipCode = dbo.fn_Mo_FormatZIP(ISNULL(RTRIM(UPPER(ADS.vcCodePostal)),''), ADS.cID_Pays),

		SubscriberAddress = ads.Address,
		SubscriberCityState = ISNULL(RTRIM(ADS.City),'') + ' ' + ISNULL(RTRIM(ADS.StateName),'') + '',
		SubscriberZipCode = dbo.fn_Mo_FormatZIP(ISNULL(RTRIM(UPPER(ADS.ZipCode)),''), ADS.CountryID),
		SubscriberCountryID = ads.CountryID,
		SubscriberCountryName = sc.CountryName,
		BH.BirthDate,
		AgeBenef = dbo.fn_Mo_Age(BH.BirthDate, CAST(YEAR(GETDATE()) AS CHAR(4)) + '-12-31')
		,NextPAE
		,DateDernierPAE
		,LenListConv = len(GC.ListeConv)
		,NoEnvoi = @NoEnvoi
		,Compteur = DENSE_RANK() OVER (
					partition by 1
					ORDER BY 
						GC.vcDescription,
						ISNULL(SH.LangID, 'FRA'),
						RTRIM(SH.LastName),
						RTRIM(SH.FirstName),
						RTRIM(BH.FirstName),
						RTRIM(BH.LastName),
						GC.BeneficiaryID, 
						GC.SubscriberID				
					 asc
					) 
	--into tmpenvoi -- drop table tmpenvoi
	FROM #tGroupeConv GC
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = GC.BeneficiaryID
	JOIN (
		SELECT 
			c.BeneficiaryID, NextPAE = MIN(s.ScholarshipNo)
		FROM Un_Scholarship S
		JOIN Un_Convention c on s.ConventionID = c.ConventionID
		JOIN #envoi e on e.ConventionId = c.ConventionID
		WHERE S.ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
		GROUP by c.BeneficiaryID
		) S ON S.BeneficiaryID = B.BeneficiaryID
	JOIN dbo.Mo_Human BH ON BH.HumanID = B.BeneficiaryID
	JOIN dbo.Un_Subscriber SU ON SU.SubscriberID = GC.SubscriberID
	JOIN dbo.Mo_Human SH ON SH.HumanID = GC.SubscriberID
	JOIN Mo_Sex BHS ON BHS.SexID = BH.SexID AND BHS.LangID = SH.LangID
	JOIN Mo_Sex SHS ON SHS.SexID = SH.SexID AND SHS.LangID = SH.LangID
	
	left join (
		select e.BeneficiaryID, rr.vcDescription,DateDernierPAE = cast( min (e.DateDernierPAE) AS date)
		from #envoi e
		join Un_Convention c on c.ConventionID = e.ConventionID
		join Un_Plan p on c.PlanID = p.PlanID
		join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
		GROUP by e.BeneficiaryID, rr.vcDescription
		)ee on ee.BeneficiaryID = b.BeneficiaryID and gc.vcDescription = ee.vcDescription

	--JOIN (
	--	SELECT
	--		A.iID_Source,	
	--		iID_Adresse = MAX(A.iID_Adresse)
	--	FROM tblGENE_Adresse A
	--	WHERE A.iID_Type = 1
	--		AND A.dtDate_Debut <= GETDATE()
	--	GROUP BY 
	--		A.iID_Source
	--	) AMax ON AMax.iID_Source = GC.SubscriberID
	--JOIN tblGENE_Adresse ADS ON ADS.iID_Adresse = AMax.iID_Adresse

	JOIN dbo.Mo_Adr ads on sh.AdrID = ads.AdrID
	left join Mo_Country sc on sc.CountryID = ads.CountryID
	
	ORDER BY 
		GC.vcDescription,
		ISNULL(SH.LangID, 'FRA'),
		RTRIM(SH.LastName),
		RTRIM(SH.FirstName),
		RTRIM(BH.FirstName),
		RTRIM(BH.LastName),
		GC.BeneficiaryID, 
		GC.SubscriberID

	*/
END