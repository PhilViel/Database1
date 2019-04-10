/********************************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service		: psCONV_RapportConvEcheanceRIN
Nom du service		: Rapport des conventions arrivant à échéance RIN dans la plage de date donnée
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

EXECUTE psCONV_RapportConvEcheanceRIN '2016-09-15','2016-09-15', '99'
EXECUTE psCONV_RapportConvEcheanceRIN '2017-05-01','2017-09-15', '0'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2016-04-22		Donald Huppé						Création du service	
		2016-08-08		Donald Huppé						Ajustement ÉcartTotal		
		2016-08-09		Donald Huppé						changer titre paramètre 1 : Cotisations versées dans l’année – impact IQEE 
		2016-08-17		Donald Huppé						Ajout de ProvinceBenef
		2016-08-22		Donald Huppé						Ajout du critère 7
		2017-03-08		Donald Huppé						Ajout du courriel
		2017-04-18		Donald Huppé						Changer les noms de paramètre de date
		2017-05-25		Donald Huppé						Modification du critère de concours, et ajout du champ SourceDeVente (jira prod-1512)
		2017-05-26		Donald Huppé						Ajout de CotisationPeriodique et TypeModalitePeriodique et mettre le nom du régime bilingue et en majuscule
		2017-05-29		Donald Huppé						Utiliser la date de Dernier dépôt (relevés et contrat), si non NULL
		2017-08-16		Donald Huppé						Pour le filtre 1, AddressLost doit être 0
		2018-09-07		Maxime Martel						JIRA MP-699 Ajout de OpertypeID COU
        2018-09-26      Pierre-Luc Simard                   Ajout de l'audit dans la table tblGENE_AuditHumain
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportConvEcheanceRIN] 
(
	@StartDate DATETIME 	-- Date de début de la période --@StartDate AND @EndDate
	,@EndDate DATETIME 	-- Date de fin de la période
	,@cReportFilter VARCHAR(20) = '0,1,2,3,4,5,6'
)
AS
BEGIN

--if @cReportFilter = '1,2,3,4,5,6'

DECLARE @EnDateDu datetime = getdate()
--declare @cReportFilter varchar(20) = '0,1,2,3,4,5,6'-- '1,6'

declare @TexteFiltre varchar(500) = ''

set @TexteFiltre = @TexteFiltre 
		+ case when CharIndex('1',@cReportFilter, 1) > 0 then ' - Cotisations versées dans l’année – impact IQEE' else '' end
		+ case when CharIndex('2',@cReportFilter, 1) > 0 then ' - Gagnants de concours' else '' end
		+ case when CharIndex('3',@cReportFilter, 1) > 0 then ' - Adresse invalide' else '' end
		+ case when CharIndex('4',@cReportFilter, 1) > 0 then ' - Non-résident' else '' end
		+ case when CharIndex('5',@cReportFilter, 1) > 0 then ' - Assurance bénéficiaire' else '' end
		+ case when CharIndex('6',@cReportFilter, 1) > 0 then ' - Écart négatif' else '' end
		+ case when CharIndex('99',@cReportFilter, 1) > 0 then ' - Tout sauf les filtres proposés' else '' end

if  CharIndex('0',@cReportFilter, 1) > 0
	set @TexteFiltre = 'AUCUN FILTRE'

--1 -conventions sur lesquelles il y a eu des cotisations la même année que l'échéance RIN
--2 -conventions gagnants de concours à l'échéance RIN
--3 -conventions dont le souscripteur a une adresse invalide à l'échéance RIN
--4 -conventions dont le souscripteur est non-résident à l'échéance RIN
--5 -conventions avec assurance bénéficiaire à l'échéance RIN
--6 -conventions en écart négatif à l'échéance RIN
--99 -Tout sauf les filtres proposés


		-- Liste des conventions touchées
	select 
		c.ConventionID,
		PaysIDSousc = cn.CountryID,
		PaysSousc = cn.CountryName,
		PaysBenef = cnb.CountryName,
		ProvinceBenef = adb.StateName,
		DateRIOriginale =cast( min(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL)) as date),
		DateRIEstime = cast(min(dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,U.InForceDate,IntReimbAge,U.IntReimbDateAdjust)) as date),
		GagnantConcours = max(cast(isnull(ss.bIsContestWinner,0) as int)),
		S.AddressLost,
		SourceDeVente = SS.SaleSourceDesc
		--,Assurance = max(cast(u.WantSubscriberInsurance as int) )
	INTO #Conv -- drop table #Conv
	from Un_Convention c
	JOIN Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	join Mo_Human hs on c.SubscriberID = hs.HumanID
	join Mo_Human hb on c.BeneficiaryID = hb.HumanID
	join Mo_Adr ad on hs.AdrID = ad.AdrID
	join Mo_Adr adb on hb.AdrID = adb.AdrID
	left join Mo_Country cn on ad.CountryID = cn.CountryID
	left join Mo_Country cnb on adb.CountryID = cnb.CountryID
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
	join Un_Unit U ON c.ConventionID = U.ConventionID
	JOIN Un_Modal m ON u.ModalID = m.ModalID
	JOIN Un_Plan p ON c.PlanID = p.PlanID
	JOIN (
		SELECT ConventionID, MIN_UnitID= MIN(UnitID)
		FROM Un_Unit
		GROUP BY ConventionID
		)MU	 ON MU.ConventionID = C.ConventionID
	JOIN Un_Unit U1 ON U1.UnitID = MU.MIN_UnitID

	-- Source de vente du 1er groupe d'unité de la convention
	LEFT JOIN (
		SELECT 
			SaleSourceID,
			SaleSourceDesc,
			bIsContestWinner =  CASE
								WHEN SaleSourceID IN (
										-- Liste reconnue de gagnant de concours proposée par Nathalie Poulin le 2017-05-24 (jira prod-1512)
										-- (elle dit qu'on ne peut pas se fier au flag bIsContestWinner = 1)
										50	, --	UNI-CGT-Concours, Gagnant d'un tirage
										92	, --	SUP-CEN-Centraide
										221	, --	SUP-ECE-Éducaide Centraide Estrie
										222	, --	SUP-ECS-Éducaide Centraide Côte-Sud
										235	, --	SUP-EPP-Éducaide Programme Persevera
										246	  --	UNI-GCB-Gagnant, Capital remis au Bénéficiaire
									) THEN 1
								ELSE 0 
								END
		FROM Un_SaleSource
			) SS ON U1.SaleSourceID = SS.SaleSourceID
	WHERE 
		P.PlanTypeID = 'COL'
		--AND ISNULL(S.AddressLost,0) = 0 -- Ajouté le 2017-08-03 -- retiré le 2017-08-16
	GROUP BY 
		c.ConventionID ,cn.CountryName,cnb.CountryName,adb.StateName,S.AddressLost,cn.CountryID,SS.SaleSourceDesc
	HAVING 
		MIN(	dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,U.InForceDate,IntReimbAge,U.IntReimbDateAdjust)) BETWEEN @StartDate AND @EndDate

	--select * from #Conv --where conventionid = 158170 --'2109961'


	select 
		DISTINCT
		DateRIOriginale
		,DateRIEstime
		,c.ConventionNo
		,PlanDesc = UPPER( CASE WHEN RR.vcCode_Regroupement = 'REF' AND HS.LangID = 'ENU' THEN 'REFLEX' ELSE p.PlanDesc END) 
		,es.QteUnite
		,c.SubscriberID
		,NomSousc = hs.LastName
		,PrenomSousc = hs.FirstName
		,SexSousc = hs.SexID
		,Langsousc = hs.LangID
		,AppelLongSouc = SXS.LongSexName
		,AppelCourtSouc = SXS.ShortSexName
		,adrs.Address
		,adrs.City
		,adrs.StateName
		,CodePostal = dbo.fn_Mo_FormatZIP( adrs.ZipCode,adrs.CountryID)
		,PaysSousc
		,CourrielSousc =	CASE
							WHEN DBO.fnGENE_ValidateEmail(ISNULL(CRm.vcCourriel,'')) = 1 THEN CRm.vcCourriel
							WHEN DBO.fnGENE_ValidateEmail(ISNULL(CRt.vcCourriel,'')) = 1 THEN CRt.vcCourriel
							WHEN DBO.fnGENE_ValidateEmail(ISNULL(CRa.vcCourriel,'')) = 1 THEN CRa.vcCourriel
							ELSE ''
							END

		,c.BeneficiaryID
		,NomBenef = hb.LastName
		,PrenomBenef = hb.FirstName
		,SexBenef = hb.SexID
		,ProvinceBenef
		,PaysBenef


		,SoldeEpargneEtFrais = isnull(ep.Épargne,0) + isnull(ep.frais,0)
		,MontantSouscrit
		,EcartTotal = ( isnull(ep.Épargne,0) + isnull(ep.frais,0)  ) - MontantSouscrit
		--,EcartEpargne = isnull(ep.Épargne,0) - ( ISNULL(EstimatedCotisationAndFee,0) - ISNULL(EstimatedFee,0) )
		--,EcartFrais =  isnull(ep.frais,0) - ISNULL(EstimatedFee,0)

		,DateDernierDepot

		,GagnantConcours
		,SourceDeVente
		,AssuranceBenef = isnull(AssuranceBenef,0)
		,CotisationAnneeRIN = isnull(CotisationAnneeRIN,0)
		,CotisationPeriodique =ISNULL(CotisationPeriodique,0)
		,TypeModalitePeriodique = ISNULL(TypeModalitePeriodique,'')
		,AgeAnneeEnCours = year(DateRIEstime) - year(hb.BirthDate)
		,filtre = @TexteFiltre
		,ListeCritereRepondu = ' ' 
				+ 
					CASE
					WHEN 
						isnull(CotisationAnneeRIN,0) > 0	
						and year(DateRIEstime) - year(hb.BirthDate) < 18
						and ProvinceBenef = 'QC'
						AND ISNULL(SoldeIQEE,0) > 0
						AND C.bSouscripteur_Desire_IQEE <> 0
						AND AddressLost = 0 -- ajouté le 2017-08-16
						THEN ',1'
					ELSE ''
					END
				+	CASE WHEN GagnantConcours > 0 THEN ',2'	ELSE ''	END
				+	CASE WHEN AddressLost <> 0 THEN ',3'	ELSE ''	END
				+	CASE WHEN PaysIDSousc <> 'CAN' THEN ',4'	ELSE ''	END
				+	CASE WHEN isnull(AssuranceBenef,0) > 0 THEN ',5'	ELSE ''	END
				+	CASE WHEN (	( isnull(ep.Épargne,0) + isnull(ep.frais,0)  ) - MontantSouscrit	) < 0 THEN ',6'	ELSE ''	END
	INTO #RESULTS
	from Un_Convention c
	JOIN Un_Plan p on c.PlanID = p.PlanID
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	JOIN #Conv cc on c.ConventionID = cc.ConventionID
	join Mo_Human HS on C.SubscriberID = HS.HumanID
	JOIN Mo_Sex SXS ON SXS.SexID = HS.SexID AND SXS.LangID = HS.LangID
	JOIN Mo_Human HB ON C.BeneficiaryID = HB.HumanID
	JOIN Mo_Adr adrs on hs.AdrID = adrs.AdrID
	left join Mo_Country cn on adrs.CountryID = cn.CountryID

	LEFT JOIN tblGENE_Courriel CRm on CRm.iID_Source = C.SubscriberID AND GETDATE() BETWEEN CRm.dtDate_Debut and ISNULL(CRm.dtDate_Fin,'9999-12-31') and CRm.iID_Type = 1 and CRm.bInvalide = 0
	LEFT JOIN tblGENE_Courriel CRt on CRt.iID_Source = C.SubscriberID AND GETDATE() BETWEEN CRt.dtDate_Debut and ISNULL(CRt.dtDate_Fin,'9999-12-31') and CRt.iID_Type = 2 and CRt.bInvalide = 0
	LEFT JOIN tblGENE_Courriel CRa on CRa.iID_Source = C.SubscriberID AND GETDATE() BETWEEN CRa.dtDate_Debut and ISNULL(CRa.dtDate_Fin,'9999-12-31') and CRa.iID_Type = 4 and CRa.bInvalide = 0



	LEFT JOIN (
		SELECT 
			CO.ConventionID
			,SoldeIQEE = SUM(CO.ConventionOperAmount)
		FROM Un_Oper O
		JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
		JOIN #Conv CC ON CO.ConventionID = CC.ConventionID
		JOIN Un_Convention C ON C.ConventionID = CC.ConventionID
		WHERE CO.ConventionOperTypeID IN ('CBQ','MMQ')
			--AND C.bSouscripteur_Desire_IQEE
		GROUP BY CO.ConventionID
		)IQEE ON IQEE.ConventionID = C.ConventionID


	LEFT JOIN (
		SELECT 
			U.ConventionID
			,CotisationAnneeRIN = SUM( case when YEAR(O.OPERDATE) = YEAR(CC.DateRIEstime) then CT.COTISATION + CT.FEE else 0 end )
			,AssuranceBenef = sum(ct.BenefInsur)
		FROM Un_Unit U
		JOIN #Conv cc on U.ConventionID = cc.ConventionID
		JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
		JOIN Un_Oper O ON CT.OperID = O.OperID
		LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
		LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
		WHERE 1=1
		--AND YEAR(O.OPERDATE) = YEAR(CC.DateRIEstime)
		AND O.OPERTYPEID IN ('CPA','CHQ','PRD','RDI','NSF','COU')
		--AND OC1.OperSourceID IS NULL
		--AND OC2.OperID IS NULL		
		group by U.ConventionID
		HAVING SUM(CT.COTISATION + CT.FEE) > 0
		)COTIS ON C.ConventionID = COTIS.ConventionID

	LEFT JOIN (
		SELECT 
			c.ConventionID
			,DateDernierDepot = cast(
									max(
										ISNULL(
											-- La date de Dernier dépôt (relevés et contrat), si non NULL
											u.LastDepositForDoc
											-- Sinon la date caclulée
											,dbo.fn_Un_LastDepositDate(u.InForceDate,c.FirstPmtDate,m.PmtQty,m.PmtByYearID)
											)
										) 
								as date)
			,QteUnite = sum(u.UnitQty)
		FROM Un_Convention c
		JOIN #Conv cc1 on c.ConventionID = cc1.ConventionID
		join Un_Unit u ON c.ConventionID = u.ConventionID
		join Un_Modal m ON u.ModalID = m.ModalID
		join Un_Plan p ON c.PlanID = p.PlanID
		GROUP by c.ConventionID
	)es on c.ConventionID = es.ConventionID

	LEFT JOIN (
			SELECT
				U.ConventionID,
				Épargne = SUM(Ct.Cotisation),
				Frais = SUM(Ct.Fee)
			FROM Un_Unit U 
			JOIN #Conv cc1 on U.ConventionID = cc1.ConventionID
			JOIN Un_Cotisation Ct (readuncommitted) ON Ct.UnitID = U.UnitID
			join un_oper o on ct.operid = o.operid
			where isnull(u.TerminatedDate,'9999-12-31') >= @EnDateDu
			group by U.ConventionID
		)ep on c.conventionid = ep.conventionid

	LEFT JOIN (
		SELECT
			C.ConventionID, 
			MontantSouscrit = SUM(			CONVERT(money,CASE
												WHEN ISNULL(SS.bIsContestWinner,0) = 1 THEN 0
												WHEN ISNULL(Co.ConnectID,0) = 0 THEN 
													(ROUND( (U.UnitQty ) * M.PmtRate,2) * M.PmtQty) /*+ U.SubscribeAmountAjustment*/
												ELSE ISNULL(V1.CotisationFee,0) /*+ U.SubscribeAmountAjustment*/
											END))
		FROM 
			dbo.Un_Convention C
			JOIN #Conv cc on c.ConventionID = cc.ConventionID
			JOIN un_unit U ON U.ConventionID = C.ConventionID
			--LEFT join (select qtyreduct = sum(unitqty), unitid from un_unitreduction group by unitid) r on u.unitid = r.unitid
			JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
			JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
			LEFT JOIN dbo.Mo_Connect Co ON Co.ConnectID = U.PmtEndConnectID
			LEFT JOIN dbo.Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
			LEFT JOIN (
				SELECT 
					U.UnitID,Cotisation = SUM(Ct.Cotisation),CotisationFee = SUM(Ct.Cotisation + Ct.Fee)
				FROM 
					dbo.Un_Unit U
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
				GROUP BY 
					U.UnitID
					) V1 ON V1.UnitID = U.UnitID
		GROUP BY C.ConventionID

		) MS ON C.ConventionID = MS.ConventionID


	LEFT JOIN (
		SELECT
			C.ConventionID
			,CotisationPeriodique =cast( 
					SUM(ROUND(M.PmtRate * U.UnitQty,2))
						/*
						+ -- Cotisation et frais
					dbo.FN_CRQ_TaxRounding
						((	CASE U.WantSubscriberInsurance -- Assurance souscripteur
								WHEN 0 THEN 0
							ELSE ROUND(M.SubscriberInsuranceRate * (U.UnitQty + isnull(qtyreduct,0)),2)
							END +
							ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
						(1+ISNULL(St.StateTaxPct,0))) -- Taxes*/
						as MONEY)
			,TypeModalitePeriodique = MAX(
						CASE
						WHEN m.PmtByYearID = 12 then 'Mensuel'
						WHEN m.PmtQty > 1 and m.PmtByYearID = 1 then 'Annuel'
						END
						)
		FROM 
			dbo.Un_Convention C
			JOIN #Conv cc on c.ConventionID = cc.ConventionID
			JOIN un_unit U ON U.ConventionID = C.ConventionID
			JOIN (
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
							and us.UnitStateID in ('EPG')
				)uus on uus.unitID = u.UnitID			
			JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
			where m.PmtQty > 1
		GROUP BY C.ConventionID

		) Modalite ON Modalite.ConventionID = c.ConventionID

/*
where CharIndex('0',@cReportFilter, 1) > 0

or (

		(	(CharIndex('1',@cReportFilter, 1) > 0	and isnull(CotisationAnneeRIN,0) > 0	
													and year(DateRIEstime) - year(hb.BirthDate) < 18
													and ProvinceBenef = 'QC'
													AND ISNULL(SoldeIQEE,0) > 0
													AND C.bSouscripteur_Desire_IQEE <> 0
																						)	OR CharIndex('1',@cReportFilter, 1) = 0	)

	and (	(CharIndex('2',@cReportFilter, 1) > 0 and GagnantConcours > 0				)	OR CharIndex('2',@cReportFilter, 1) = 0	)
	and (	(CharIndex('3',@cReportFilter, 1) > 0 and AddressLost <> 0					)	OR CharIndex('3',@cReportFilter, 1) = 0	)
	and (	(CharIndex('4',@cReportFilter, 1) > 0 and PaysIDSousc <> 'CAN'				)	OR CharIndex('4',@cReportFilter, 1) = 0	)
	and (	(CharIndex('5',@cReportFilter, 1) > 0 and isnull(AssuranceBenef,0) > 0		)	OR CharIndex('5',@cReportFilter, 1) = 0	)
	and (	(CharIndex('6',@cReportFilter, 1) > 0 and (	( isnull(ep.Épargne,0) + isnull(ep.frais,0)  ) - MontantSouscrit	) < 0

																						)	 OR CharIndex('6',@cReportFilter, 1) = 0	)
	)

*/



	SELECT *
    INTO #tpsCONV_RapportConvEcheanceRIN
	FROM #RESULTS
	WHERE CharIndex('0',@cReportFilter, 1) > 0

	OR (

			(	(CharIndex('1',@cReportFilter, 1) > 0 AND ListeCritereRepondu LIKE '%1%'	)	OR CharIndex('1',@cReportFilter, 1) = 0	)
		AND (	(CharIndex('2',@cReportFilter, 1) > 0 AND ListeCritereRepondu LIKE '%2%'	)	OR CharIndex('2',@cReportFilter, 1) = 0	)
		AND (	(CharIndex('3',@cReportFilter, 1) > 0 AND ListeCritereRepondu LIKE '%3%'	)	OR CharIndex('3',@cReportFilter, 1) = 0	)
		AND (	(CharIndex('4',@cReportFilter, 1) > 0 AND ListeCritereRepondu LIKE '%4%'	)	OR CharIndex('4',@cReportFilter, 1) = 0	)
		AND (	(CharIndex('5',@cReportFilter, 1) > 0 AND ListeCritereRepondu LIKE '%5%'	)	OR CharIndex('5',@cReportFilter, 1) = 0	)
		AND (	(CharIndex('6',@cReportFilter, 1) > 0 AND ListeCritereRepondu LIKE '%6%'	)	OR CharIndex('6',@cReportFilter, 1) = 0	)
		AND (	(CharIndex('99',@cReportFilter, 1) > 0 AND LTRIM(RTRIM(ListeCritereRepondu)) = ''	)	OR CharIndex('99',@cReportFilter, 1) = 0	)
	)	

    SELECT * FROM #tpsCONV_RapportConvEcheanceRIN

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tpsCONV_RapportConvEcheanceRIN', 
            @vcNom_ChampIdentifiant = 'SubscriberID', 
            @vcUtilisateur = @vcAudit_Utilisateur, 
            @vcContexte = @vcAudit_Contexte, 
            @bAcces_Courriel = 1, 
            @bAcces_Telephone = 0, 
            @bAcces_Adresse = 1
    --------------
    -- AUDIT - FIN
    --------------
    END 


END