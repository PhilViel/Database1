/********************************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psCONV_ReleveDeCompte
Description         :	
Valeurs de retours  :	Dataset de données

						TypeLigne : 
						10-SLD : Solde d’ouverture au début de la période 
						15-SLD : Cumulatif des frais de souscription payés au 1er janvier 2014
						20-DTL : Opération dans la période
						25-FRS : Pour la grille des frais d’opération et de fonctionnement 
						30-SLD : Solde de clôture à la fin de la période  
						

Note                :
	
					2015-02-18	Donald Huppé	Création 
					2016-10-12	Donald Huppé	jira ti-5058 : Gestion des contrat sans date de 1er dépot mais avec un RIN. (Environ 400 vieux contrats)
					2017-11-02	Donald Huppé	Gestion des convention I BEC
					2017-12-22	Donald Huppé	Modification du calcul de la cote part (QPPAE)
					2018-05-11	Donald Huppé	Version finale utilsée pour relevé de 2017-12-31
					2018-09-07	Maxime Martel	JIRA MP-699 Ajout de OpertypeID COU
exec psCONV_ReleveDeCompte 205876, null, NULL -- cas de PRA
exec psCONV_ReleveDeCompte 182442, null
exec psCONV_ReleveDeCompte 575993, null
exec psCONV_ReleveDeCompte NULL, 't-20111123116'  '0938274'  'u-20011218093' 'c-20010704004' 
exec psCONV_ReleveDeCompte null, 'x-20161229023' 'U-20070816019' 'r-20050304033' --'u-20031110023'--



*********************************************************************************************************************/


CREATE PROCEDURE [dbo].[psCONV_ReleveDeCompte] (
		@SubscriberID int = null
		,@conventionNO varchar(30) = NULL -- '2025720'
		,@LangueTEST varchar(3) = null

	)
AS
BEGIN

declare

	@dtDateFROM datetime = '2017-01-01',
	@dtDateTo datetime = '2017-12-31'
	-- Pour projection des I BEC qui ne sorte pas de la ps de projection présentement
	,@TauxAnnuelComposeMensuellement FLOAT = 0.040741543  --Taux d'intérêt annuel composé mensuellement



	,@LangIDOri varchar(3) 

	--IF YEAR(GETDATE()) <> YEAR(@dtDateTo) + 1
	--	BEGIN
	--	SELECT LEMESSAGE = '---- >  MAUVAISE VERSION DE PS  < --------------'
	--	RETURN
	--	END

	if @SubscriberID is not null and @LangueTEST is not NULL
	begin
	select @LangIDOri = langid from mo_human where HumanID = @SubscriberID
	update Mo_Human set LangID = @LangueTEST where HumanID = @SubscriberID and LangID <> @LangueTEST
	end

	SELECT DISTINCT u.UnitID, t.dtFirstDeposit ,c.SubscriberID
	INTO #ConvIBEC	
	FROM fntREPR_ObtenirUniteConvT (1) t
	JOIN Un_Unit u on u.UnitID = t.UnitID
	join Un_Convention c on c.ConventionID = u.ConventionID
	where c.ConventionNo like 'I%'

	

/*#############################################
			Projection subvention et rendement DÉBUT
##############################################*/

CREATE TABLE #Proj(
	[SubscriberID] [int] NOT NULL,
	[Sousc] [varchar](87) NULL,
	[BeneficiaryID] [int] NOT NULL,
	[Benef] [varchar](86) NULL,
	[ConventionNo] [varchar](15) NOT NULL,
	[PlanDesc] [varchar](75) NOT NULL,
	[QteUnite] [money] NULL,
	[EtatGrUnite] [varchar](75) NOT NULL,
	[ModeCotisation] [varchar](11) NULL,
	[MontantCotisation] [money] NULL,
	[CotisationFraisSoldeUnite] [money] NULL,
	[MontantSouscrit] [money] NULL,
	[PonderationAvecAutreConvention] [float] NULL,
	[ExcedentDe36k] [money] NULL,
	[RiVerse] [varchar](3) NOT NULL,
	[CAN_HorsQC] [varchar](3) NOT NULL,
	[International] [varchar](3) NOT NULL,
	[CotisationEncaisseDecembreReleve] [money] NULL,
	[CotisationEncaisseAnneeReleve] [money] NULL,
	[TotalSCEEEtRend] [real] NULL,
	[SCEEUnite] [money] NOT NULL,
	[SCEEPlusUnite] [money] NOT NULL,
	[BECUnite] [money] NOT NULL,
	[RendSCEEUnite] [real] NULL,
	[RevenuCotisationUnite] [real] NULL,
	[IQEEEtRevenuUnite] [real] NULL,
	[IQEEUnite] [real] NULL,
	[IQEEPlusUnite] [real] NULL,
	[RevenuIQEEUnite] [real] NULL,
	[BirthDate] [date] NULL,
	[DateDebutOperationFinanciere] [date] NULL,
	[DateDernierDepot] [date] NULL,
	[DateDebutProjection] [date] NULL,
	[DateFinProjection] [date] NULL,
	[DateFinCotisationSubventionnee] [date] NULL,
	[DateEncaissSCEEaRecevoir] [date] NULL,
	[DateEncaissIQEEaRecevoir] [date] NULL,
	[DateEncaissDerniereCotisSCEE] [date] NULL,
	[DateEncaissDerniereCotisIQEE] [date] NULL,
	[DiminutionProjectionPourPasDepasserPlafondAvie] [float] NULL,
	[SCEEaRecevoir] [numeric](22, 6) NULL,
	[SCEEperiodiqueAuContratSansDepasserPlafondAnnuel] [numeric](22, 6) NULL,
	[SCEEperiodiqueAuContratSansDepasserPlafondAvie] [float] NULL,
	[SCEEtotalPrevu] [float] NULL,
	[NbAnneeDeDateDebutProjection_A_FinProjection] [numeric](17, 6) NULL,
	[NbAnneeDeDateEncaissPrevuSCEEaRecevoir_A_FinProjection] [numeric](17, 6) NULL,
	[NbPeriodes_De_DateProchCot_A_DernCot] [float] NULL,
	[NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans] [float] NULL,
	[NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200] [float] NULL,
	[NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot] [float] NULL,
	[NbAnneeDeDateDernCot_A_FinProjection] [numeric](17, 6) NULL,
	[SoldeInitial_SCEE_BEC_RevenuProjete] [float] NULL,
	[SCEEaRecevoirProjete] [float] NULL,
	[SCEEPerodiqueProjete_De_DateProchCot_A_DernCot] [float] NULL,
	[SCEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie] [float] NULL,
	[SoldeSCEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot] [float] NULL,
	[SoldeSCEEProjete_De_DateEncaissDernCot_A_DateFinProj] [float] NULL,
	[SCEEProjete] [float] NULL,
	[SCEE_Plus_Bec_RecuEtProjete] [float] NULL, /* U */
	[Bec_Recu] [money] NOT NULL, /* U2 */
	[RevenuAccumuleSurSoldeRend] [float] NULL,
	[RevenuAccumuleRecuEtProjete] [float] NULL,
	[SCEEEtRevenuAccumule_Recu_EtProjete] [float] NULL, /* W */
	[IQEEDiminutionProjectionPourPasDepasserPlafondAvie] [float] NULL,
	[IQEEaRecevoir] [numeric](21, 5) NULL,
	[IQEEperiodiqueAuContratSansDepasserPlafondAnnuel] [numeric](22, 6) NULL,
	[IQEEperiodiqueAuContratSansDepasserPlafondAvie] [float] NULL,
	[IQEEtotalPrevu] [float] NULL,
	[IQEE_NbAnneeDeDateDebutProjection_A_FinProjection] [numeric](17, 6) NULL,
	[IQEE_NbAnneeDeDateEncaissPrevuIQEEaRecevoir_A_FinProjection] [numeric](17, 6) NULL,
	[IQEE_NbAnnee_De_DateProchCot_A_DernCot] [float] NULL,
	[IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans] [float] NULL,
	[IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600] [float] NULL,
	[IQEE_NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot] [float] NULL,
	[IQEE_NbAnneeDeDateDernCot_A_FinProjection] [numeric](17, 6) NULL,
	[IQEE_SoldeInitial_IQEE_RevenuProjete] [float] NULL,
	[IQEEaRecevoirProjete] [float] NULL,
	[IQEEPerodiqueProjete_De_DateProchCot_A_DernCot] [float] NULL,
	[IQEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie] [float] NULL,
	[SoldeIQEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot] [float] NULL,
	[SoldeIQEEProjete_De_DateEncaissDernCot_A_DateFinProj] [float] NULL,
	[IQEEProjete] [float] NULL,
	[IQEE_Plus_RecuEtProjete] [float] NULL, /* UU */
	[IQEERevenuAccumuleRecuEtProjete] [float] NULL, /* V */
	[IQEEEtRevenuAccumule_Recu_EtProjete] [float] NULL
) ON [PRIMARY]


-- SI LA TABLE DES PROJECTIONS EST LOADÉE ALORS ON PIGE DEDANS ....
IF EXISTS (SELECT NAME FROM sysobjects WHERE NAME = 'Projection')
	BEGIN
	IF EXISTS (SELECT TOP 1 * FROM Projection WHERE DateDebutProjection = DATEADD(DAY,1,@dtDateTo))
		BEGIN
		INSERT INTO #Proj SELECT * FROM Projection WHERE @SubscriberID = SubscriberID OR @conventionNO = conventionNO
		END
	END

-- .... SINON, ON LES CALCULE
IF NOT EXISTS (SELECT 1 FROM #Proj)
	BEGIN
	insert into #Proj
	exec psCONV_ProjectionSubventionsEtLeurRendement @SubscriberID, NULL, @conventionNO
	END


	create table #ProjParConvention (
		ConventionID INT
		,DateFinProjection DATE
		,SCEEProjete FLOAT 
		,Bec_Recu FLOAT
		,IQEEProjete FLOAT
		,RendementProjete FLOAT
		)

	-- Faire un aggégat par convention pour les valeurs projetées qui sont utilisées dans la relevé de compte.
	INSERT INTO #ProjParConvention
	SELECT 
		c.ConventionID
		,DateFinProjection = max(DateFinProjection)
		,SCEEProjete = sum(SCEE_Plus_Bec_RecuEtProjete) /* U */ 
		,Bec_Recu = sum(Bec_Recu) /* U2 */
		,IQEEProjete = sum(IQEE_Plus_RecuEtProjete) /* UU */ 
		,RendementProjete = CASE	-- 2017-02-17 : si le rendement projeté est négatif alors on inscrit 0
									WHEN sum(RevenuAccumuleRecuEtProjete) /* V */ + sum(IQEERevenuAccumuleRecuEtProjete ) /* V V */ > 0 
											THEN sum(RevenuAccumuleRecuEtProjete) /* V */ + sum(IQEERevenuAccumuleRecuEtProjete ) /* V V */
									ELSE 0
							END

	FROM #Proj p
	JOIN Un_Convention c on c.ConventionNo = p.ConventionNo
	GROUP BY c.ConventionID



	-- Patch pour les I BEC
	INSERT INTO #ProjParConvention
	SELECT 
		c.ConventionID,
		DateFinProjection = DATEADD(YEAR,17,hb.BirthDate),
		SCEEProjete = 0,
		Bec_Recu  = SoldeBEC,
		IQEEProjete = 0,
		RendementProjete =	 (SoldeBEC + isnull(SoldeRendBEC,0)) * POWER( (1+@TauxAnnuelComposeMensuellement) , ( DATEDIFF(DAY,@dtDateTo,DATEADD(YEAR,17,hb.BirthDate)) / 365.0   ))
							- SoldeBEC

	FROM #ConvIBEC i
	JOIN Un_Unit u on u.UnitID = i.UnitID
	JOIN Un_Convention c on c.ConventionID = u.ConventionID
	JOIN (
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
					and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
		) css on C.conventionid = css.conventionid
	JOIN Mo_Human hb on hb.HumanID = c.BeneficiaryID
	JOIN (
		SELECT ConventionID, SoldeBEC = SUM(fCLB)
		from Un_CESP ce
		join un_oper oc on oc.OperID = ce.OperID
		where oc.OperDate <= @dtDateTo
		group by ConventionID
		)bec on bec.ConventionID = c.ConventionID
	LEFT JOIN (
		SELECT co.ConventionID, SoldeRendBEC = SUM(co.ConventionOperAmount)
		from Un_ConventionOper co
		join Un_Oper o on o.OperID = co.OperID
		where 1=1
			and o.OperDate <= @dtDateTo
			and ConventionOperTypeID = 'IBC'
		GROUP by co.ConventionID
		)r on r.ConventionID = c.ConventionID
	where 1=1
		AND c.ConventionID NOT IN (SELECT ConventionID FROM #ProjParConvention)
		AND c.ConventionNo = ISNULL (@conventionNO,c.ConventionNo)
		AND c.SubscriberID = ISNULL (@SubscriberID,c.SubscriberID)


--RETURN

/*#############################################
			Projection subvention et rendement FIN
##############################################*/



	-- échantillon de conventions
	
	SELECT Distinct c.ConventionID,AnneeQualification = NULL
	INTO #ConventionRC
	FROM Un_Convention c
	--left join TblCONV_RelevecompteExclusions e on c.ConventionNo = e.conventionno
	WHERE 
		(
			(@SubscriberID is NOT null AND c.SubscriberID = @SubscriberID)
			or (@conventionNO IS not null AND c.ConventionNo = @conventionNO)
		)

		and c.SubscriberID not in (
						-- Exclusion complete pour le souscipteur au complet
						select SubscriberID from TblCONV_RelevecompteExclusions 
						where 
							TypeExclusion like 'Q9%' 
						)

		and c.ConventionNo not in (
						-- Exclusion pour seulement la convention
						select ConventionNo from TblCONV_RelevecompteExclusions 
						)

	--and e.conventionno is null -- exclure les exclusion
	
	--Déterminer l'année de qualification en date de fin car cette date est calculé lors du 1er PAE
	UPDATE RC set AnneeQualification = brs.AnneeQualification -- l'année de qualification en date de fin
	from #ConventionRC RC
	JOIN(
		SELECT 
			s.ConventionID
			,AnneeQualification = cast( case when month(max(o.OperDate)) <= 6 then year(max(o.OperDate)) -1 else year(max(o.OperDate)) end as varchar(4))
		FROM Un_Scholarship S
		JOIN #ConventionRC rc ON S.ConventionID = rc.ConventionID
		JOIN Un_ScholarshipPmt SP ON S.ScholarshipID = SP.ScholarshipID
		JOIN UN_OPER O ON sp.OperID = o.OperID
		LEFT JOIN Un_OperCancelation oc1 ON oc1.OperSourceID = o.OperID
		LEFT JOIN Un_OperCancelation oc2 ON oc2.OperID = o.OperID
		WHERE O.OperDate <= @dtDateTo
			AND oc1.OperSourceID IS NULL AND oc2.OperID IS NULL
			AND s.ScholarshipNo = 1 -- on vérifie la bourse 1 car en théorie, dans le collectif on commence toujours par la 1
		group by s.ConventionID
		)brs ON RC.ConventionID = brs.ConventionID

--select * from #ConventionRC



	--select * from #ConventionRC


	-- Info sur la convention
	SELECT
		c.ConventionID
		,c.ConventionNo
		,c.SubscriberID
		,BeneficiaryID = BeneficiaryIDEnDateDu
		,SubPrenom = hs.FirstName
		,SubNom = hs.LastName
		,LangID = hs.LangID
		,SubLongSexName = SubSex.LongSexName
		,SubShortSexName = SubSex.ShortSexName
		,SubAdresse = SubAdr.Address
		,SubVille = SubAdr.City
		,SubEtat = SubAdr.StateName
		,SubCodePostal = dbo.fn_Mo_FormatZIP( SubAdr.ZipCode,subadr.CountryID)
		,SubCountryID = SubAdr.CountryID
		,SubCountryName = cn.CountryName --2016-03-03
		,BenPrenom = hb.FirstName
		,BenNom = hb.LastName
		,BenSex = hb.SexID
		--,BenDeathDate = hb.DeathDate
		-- Représentant, s'il est inactif alors on inscrit le nom du directeur
		,Prenom_Representant = isnull(REP.Prenom_Representant,DIR.Prenom_Directeur)
		,Nom_Representant = isnull(REP.Nom_Representant,DIR.Nom_Directeur)
		,RepTelephone = isnull(REP.RepTelephone,DIR.DirTelephone)
		,RepCourriel = isnull(REP.RepCourriel,DIR.DirCourriel)
		
		,LePlan = UPPER(CASE 
						WHEN hs.LangID = 'ENU' AND p.PlanDesc = 'Reeeflex' THEN 'Reflex'
						WHEN hs.LangID = 'ENU' AND p.PlanDesc = 'Individuel' THEN 'Individual' 
						ELSE p.PlanDesc END
						)
		,p.PlanTypeID
		,GrRegimeCode = RR.vcCode_Regroupement
		,Cohorte =	CASE 
						WHEN rc.AnneeQualification IS NULL AND c.PlanID <> 4 THEN CAST(c.YearQualif as varchar(4)) 
						ELSE 
							CASE 
								WHEN hs.LangID = 'ENU' THEN 'n/a' 
								ELSE 's/o' 
							END
					END -- Afficher seulement si aucun pae n'a été versé
		,c.YearQualif --2016-02-16
		,CotisationAEcheance = CAST(
									SUM(	
											CASE
											WHEN  P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
											ELSE (ROUND( (U.UnitQty +ISNULL(qtyreduct,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
											END
										) 
								AS MONEY
									)

		,CotisationPaiementFutur = CAST( -- utilisé dans le tableau des paiements futurs
									SUM(	
											CASE
											WHEN  P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
													-- Dans un collectif, si le RI a eu lieu, on inscrit le solde des cotisation
											when  P.PlanTypeID <> 'IND' AND isnull(u.IntReimbDate,'9999-12-31') <= @dtDateTo THEN ISNULL(V1.Cotisation,0) + ISNULL(V1.Frais,0)
													-- Si le RI n'a pas eu lie alors c'est le montant soucrit
											ELSE (ROUND( (U.UnitQty +ISNULL(qtyreduct,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
											END
										) 
								AS MONEY
									)

		,DateRIEstimé = MIN(dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust))
		,DateRIN = MIN(u.IntReimbDate)
		,ApresEcheance =	case 
							when MIN(dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust)) <= @dtDateTo --DateRIEstimé estimé est passé
								then 1 
							else 0 
							end
		,RIO = case when rio.iID_Convention_Destination is not null and p.PlanTypeID = 'IND' then 1 else 0 end
		,RendTIN = isnull(RendTIN,0)
		,DateFinCotisation = MAX(	CASE 
									WHEN ISNULL(U.LastDepositForDoc,0) <= 0 THEN dbo.fn_Un_LastDepositDate(U.InForceDate,C.FirstPmtDate,M.PmtQty,M.PmtByYearID)
									ELSE U.LastDepositForDoc
									END)
		,DateAdhesion = MIN(u.SignatureDate)
		,UnitStateID = USS.UnitStateID
		,UnitStateName = USS.UnitStateName
		,AssuranceObligatoire = isnull(SUM(AssuranceObligatoire),0) -- sert à savoir si on affiche la note concernant les commissions sur la vente d'assurance vie et invalidité que GUI recoit de SSQ.
		,AnnéeQualification = 
								case when p.PlanTypeID <> 'IND' then isnull(cast(rc.AnneeQualification as varchar(4)),(case when hs.LangID = 'ENU' then 'n/a' else 's/o' end)) 
								else case when hs.LangID = 'ENU' then 'n/a' else 's/o' end 
								end
		,FraisDisponibleTotalSousc = ISNULL(FD.FraisDisponibleTotalSousc,0)
		,PlanIND = CASE WHEN p.PlanTypeID = 'IND' THEN 1 ELSE 0 END
		,PlanCOL = CASE WHEN p.PlanTypeID = 'COL' THEN 1 ELSE 0 END
		,ConventionStateIDFin = cssFin.ConventionStateID
		,QPCohorteComptePAE = ISNULL(QPCohorteComptePAE,0)
		,QPQteUniteActive = ISNULL(QPQteUniteActive,0)
		,QPRevenuAccumuleUnite = ISNULL(QPRevenuAccumuleUnite,0)
		,QPPAE = isnull(QPPAE,0)
		,Ristourne = isnull(Ristourne,0)
		,QteUnitesConverties = isnull(QteUnitesConverties,0) --2016-02-19
		,SequenceAffichBenEtConv = DENSE_RANK() OVER (
							partition by c.SubscriberID -- #2 : basé sur le SubscriberID
							ORDER BY hb.BirthDate, benef.BeneficiaryIDEnDateDu, MIN(u.SignatureDate) , c.ConventionNo -- #1 : On numérote selon l'age et la signature
														)
	INTO #ConventionRCinfo
	FROM 
		Un_Convention C
		JOIN #ConventionRC rc ON c.ConventionID = rc.ConventionID
		JOIN Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		JOIN Mo_Human hs ON c.SubscriberID = hs.HumanID
		JOIN Mo_Sex SubSex on hs.SexID = SubSex.SexID and hs.LangID = SubSex.LangID
		JOIN Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN (
			select umh.UnitID, ModalID = max(umh.ModalID )
			from Un_UnitModalHistory umh
			join Un_Unit u on umh.UnitID = u.UnitID
			join Un_Convention c on u.ConventionID = c.ConventionID 
			JOIN #ConventionRC rc ON c.ConventionID = rc.ConventionID
			where umh.StartDate = (
								select max(StartDate)
								from Un_UnitModalHistory umh2
								where umh.UnitID = umh2.UnitID
								--and umh2.StartDate <= @dtDateTo
								AND CAST(umh2.StartDate AS DATE) <=  CAST(@dtDateTo AS DATE)
								)
			GROUP BY umh.UnitID
			)mh on mh.UnitID = u.UnitID
		JOIN Un_Modal M ON M.ModalID = mh.ModalID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime


		-- ajouté le 2015-12-02 : pour la demande de ne pas sortir les convention qui sont fermée en date de fin. donc on sort celles qui sont REE ou TRA en date de fin
		JOIN (
			SELECT 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			FROM 
				un_conventionconventionstate cs
				JOIN (
					SELECT 
					conventionid,
					startdate = max(startDate)
					FROM un_conventionconventionstate
					WHERE startDate < DATEADD(d,1 ,@dtDateTo)
					GROUP BY conventionid
					) ccs ON ccs.conventionid = cs.conventionid 
						AND ccs.startdate = cs.startdate 
						AND cs.ConventionStateID in ('REE','TRA')
		) cssFin ON C.conventionid = cssFin.conventionid


		LEFT JOIN Mo_Adr SubAdr on hs.AdrID = SubAdr.AdrID
		LEFT JOIN Mo_Country cn on SubAdr.CountryID = cn.CountryID --2016-03-03
		LEFT JOIN (
			SELECT 
				R.RepID,
				R.RepCode,
				Prenom_Representant = HR.FirstName,
				Nom_Representant = HR.LastName,
				RepTelephone = dbo.fn_Mo_FormatPhoneNo(MAX(ISNULL(tt.vcTelephone,'')),'CAN'), -- On prend le max juste pour s'assurer qu'on sort juste un tel travail actif, ce qui est théoriquement le cas
				RepCourriel = MAX(ISNULL(c.vcCourriel,''))-- On prend le max juste pour s'assurer qu'on sort juste un courriel proffessionel actif, ce qui est théoriquement le cas
			FROM Un_Rep R
			JOIN Mo_Human HR ON R.RepID = HR.HumanID
			LEFT JOIN tblGENE_Telephone tt on HR.HumanID = tt.iID_Source and GETDATE() BETWEEN tt.dtDate_Debut and isnull(tt.dtDate_Fin,'9999-12-31') and tt.iID_Type = 4
			LEFT JOIN tblGENE_Courriel c on c.iID_Source = hr.HumanID and GETDATE() BETWEEN c.dtDate_Debut and ISNULL(c.dtDate_Fin,'9999-12-31') and c.iID_Type = 2
			WHERE 
				isnull(R.BusinessEnd,'9999-12-31') > GETDATE()
				and isnull(r.BusinessStart,'9999-12-31') <= GETDATE() -- Le rep est actif
			group BY
				R.RepID,
				R.RepCode,
				HR.FirstName,
				HR.LastName	
			)REP on S.RepID = REP.RepID	
		
		LEFT JOIN ( --- Directeur du représentant
			SELECT
				RB.RepID,
				BossID = MAX(BossID)
			FROM 
				Un_RepBossHist RB
				JOIN (
					SELECT
						RepID,
						RepBossPct = MAX(RepBossPct)
					FROM 
						Un_RepBossHist RB
					WHERE 
						RepRoleID = 'DIR'
						AND StartDate IS NOT NULL
						AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
						AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
					GROUP BY
							RepID
					) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
				WHERE RB.RepRoleID = 'DIR'
					AND RB.StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
					AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
				GROUP BY
					RB.RepID
			)BR on BR.RepID = S.RepID
		LEFT JOIN (
			SELECT 
				R.RepID,
				R.RepCode,
				Prenom_Directeur = HR.FirstName,
				Nom_Directeur = HR.LastName,
				DirTelephone = dbo.fn_Mo_FormatPhoneNo(MAX(ISNULL(tt.vcTelephone,'')),'CAN'), -- On prend le max juste pour s'assurer qu'on sort juste un tel travail actif, ce qui est théoriquement le cas
				DirCourriel = MAX(ISNULL(c.vcCourriel,''))-- On prend le max juste pour s'assurer qu'on sort juste un courriel proffessionel actif, ce qui est théoriquement le cas
			FROM Un_Rep R
			JOIN Mo_Human HR ON R.RepID = HR.HumanID
			LEFT JOIN tblGENE_Telephone tt on HR.HumanID = tt.iID_Source and GETDATE() BETWEEN tt.dtDate_Debut and isnull(tt.dtDate_Fin,'9999-12-31') and tt.iID_Type = 4
			LEFT JOIN tblGENE_Courriel c on c.iID_Source = hr.HumanID and GETDATE() BETWEEN c.dtDate_Debut and ISNULL(c.dtDate_Fin,'9999-12-31') and c.iID_Type = 2
			group BY
				R.RepID,
				R.RepCode,
				HR.FirstName,
				HR.LastName	
			)DIR on DIR.RepID = BR.BossID

		LEFT JOIN (SELECT qtyreduct = SUM(unitqty), unitid FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) r ON u.UnitID = r.UnitID

		LEFT JOIN (
			SELECT 
				U.UnitID
				,Frais = SUM(Ct.Fee)
				,Cotisation = SUM(Ct.Cotisation)
				,AssuranceObligatoire = sum(case when m.ModalDate <= '2008-12-08' and o.OperDate BETWEEN @dtDateFROM and @dtDateTo then ct.SubscInsur + ct.BenefInsur else 0 end)
			FROM 
				Un_Unit U
				JOIN (
					select umh.UnitID, ModalID = max(umh.ModalID )
					from Un_UnitModalHistory umh
					join Un_Unit u on umh.UnitID = u.UnitID
					join Un_Convention c on u.ConventionID = c.ConventionID
					JOIN #ConventionRC rc ON c.ConventionID = rc.ConventionID
					WHERE umh.StartDate = (
										select max(StartDate)
										from Un_UnitModalHistory umh2
										where umh.UnitID = umh2.UnitID
										--and umh2.StartDate <= @dtDateTo
										AND CAST(umh2.StartDate AS DATE) <=  CAST(@dtDateTo AS DATE)
										)
					GROUP BY umh.UnitID
					)mh on mh.UnitID = u.UnitID
				JOIN Un_Modal M ON M.ModalID = mh.ModalID
				JOIN Un_Convention c1 ON u.ConventionID = c1.ConventionID
				JOIN #ConventionRC rc ON c1.ConventionID = rc.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE o.OperDate <= @dtDateTo
			GROUP BY 
				U.UnitID
				) V1 ON V1.UnitID = U.UnitID

		LEFT JOIN
			(
			SELECT rc.ConventionID, BeneficiaryIDEnDateDu = CB.iID_Nouveau_Beneficiaire
			FROM tblCONV_ChangementsBeneficiaire CB
			JOIN #ConventionRC rc ON CB.iID_Convention = rc.ConventionID
			WHERE CB.dtDate_Changement_Beneficiaire = (SELECT MAX(CB2.dtDate_Changement_Beneficiaire)
													 FROM tblCONV_ChangementsBeneficiaire CB2
													 WHERE CB2.iID_Convention = CB.iID_Convention
														AND CB2.dtDate_Changement_Beneficiaire <= @dtDateTo)
			)benef on benef.ConventionID = c.ConventionID
		LEFT JOIN Mo_Human hb ON benef.BeneficiaryIDEnDateDu = hb.HumanID

		LEFT JOIN (
			SELECT
				C.SubscriberID,
				FraisDisponibleTotalSousc = SUM(CO.ConventionOperAmount)
			FROM Un_ConventionOper CO
			JOIN un_oper o on co.OperID = o.OperID
			JOIN Un_Convention C ON CO.ConventionID = C.ConventionID
			JOIN (
				SELECT DISTINCT C1.SubscriberID
				FROM Un_Convention C1
				JOIN #ConventionRC RC ON RC.ConventionID = C1.ConventionID 
				)SUB ON SUB.SubscriberID = C.SubscriberID
			WHERE 
				CO.ConventionOperTypeID = 'FDI'
				AND O.OperDate <= @dtDateTo
			GROUP BY C.SubscriberID
			)FD ON FD.SubscriberID = C.SubscriberID

		LEFT JOIN (
			select DISTINCT iID_Convention_Destination
			from tblOPER_OperationsRIO
			where bRIO_Annulee = 0
			and bRIO_QuiAnnule = 0
			and OperTypeID = 'RIO'
			)rio on c.ConventionID = rio.iID_Convention_Destination

		LEFT JOIN (
			select c.ConventionID, RendTIN = 1 -- la valeur 1 indique qu'il y au moins un montant inscrit dans le compte ITR
			from Un_Convention c
			JOIN #ConventionRC rc ON c.ConventionID = rc.ConventionID
			join Un_ConventionOper co on c.ConventionID = co.ConventionID
			join un_oper o on co.OperID = o.OperID
			where 
				o.OperDate <= @dtDateTo 
				and co.ConventionOperTypeID in ( 'ITR','IST','IQI','III' )
			GROUP by c.ConventionID
			) RendTIN on RendTIN.ConventionID = c.ConventionID

		LEFT join (

			select 
				c.ConventionID
				--,u.UnitID
				--,u.UnitQty
				,QPCohorteComptePAE
				,QPQteUniteActive
				,QPRevenuAccumuleUnite
				,QPPAE =
						 sum( --2016-02-15
								case 

								--Si UNIVERSITAS: montant unitaire de PAE selon table + Prime de ristourne applicable) x nombre d'unités du groupe d'unités
								--Si REEEFLEX: (montant unitaire de PAE selon table + Prime de ristourne applicable) x nombre d'unités du groupe d'unités x Facteur de conversion applicable

								when qp.iID_Regroupement_Regime = 1 then --UNIVERSITAS
									--	round(--2016-02-24
												(
													--ROUND(	
															qp.MntUnitairePAEProjete  
															+ 
															CAST(dbo.fnCONV_ObtenirRistourneAssurance(M.ModalID, U.WantSubscriberInsurance, u.SignatureDate, u.InForceDate) AS MONEY) 
													--	,2)
												)
												* 
												(
													(u.UnitQty + ISNULL(R2.qtyreduct,0)	) * (1 - ISNULL(RatioDemande,0))
												)
									--		,2)


								when qp.iID_Regroupement_Regime = 2 then --REEEFLEX
									(
									--	round(--2016-02-24
											qp.MntUnitairePAEProjete  *
											--round(	--2016-02-19
													(	
													CAST(dbo.fnCONV_ObtenirFacteurConversion(C.PlanID, M.ModalDate, u.SignatureDate, u.InForceDate) AS DECIMAL(10,3))
													*	(
														(u.UnitQty + ISNULL(R2.qtyreduct,0)	) * (1 - ISNULL(RatioDemande,0))
														)
													)
											--	,3)
									--		,2)
									)
									+	
									--		round(
													CAST(dbo.fnCONV_ObtenirRistourneAssurance(M.ModalID, U.WantSubscriberInsurance, u.SignatureDate, u.InForceDate) AS MONEY)  
													*	
														(
														(u.UnitQty + ISNULL(R2.qtyreduct,0)	) * (1 - ISNULL(RatioDemande,0))
														)
										--		,2)
								end
							)

				,Ristourne =
							 sum( --2016-02-15
									(
										CAST(dbo.fnCONV_ObtenirRistourneAssurance(M.ModalID, U.WantSubscriberInsurance, u.SignatureDate, u.InForceDate) AS MONEY) 
									)
										* 
									(
										(u.UnitQty + ISNULL(R2.qtyreduct,0)	) * (1 - ISNULL(RatioDemande,0))
									)
								)
				,QteUnitesConverties = sum( --2016-02-19
											round(	
													(	
														CAST(dbo.fnCONV_ObtenirFacteurConversion(C.PlanID, M.ModalDate, u.SignatureDate, u.InForceDate) AS DECIMAL(10,3))
														* 
													(
														(u.UnitQty + ISNULL(R2.qtyreduct,0)	) -- * (1 - ISNULL(RatioDemande,0)) -- on veut le vrai nb d'untité et non le solde pour calcul de PAE
													)

													)
												,3)
											)


			from Un_Convention c
			join #ConventionRC RC ON RC.ConventionID = C.ConventionID 
			JOIN ( -- comme dans psCONV_RapportUnitesAdmissiblesPAE
				SELECT 
					PV.PlanID,
					Cohorte = MAX(PV.ScholarshipYear) 
				--INTO #tPlanCohorte
				FROM Un_PlanValues PV -- select * from Un_PlanValues
				JOIN Un_Plan P ON P.PlanID = PV.PlanID
				WHERE P.PlanTypeID = 'COL'
				and PV.ScholarshipYear <= year(@dtDateTo)
				GROUP BY PV.PlanID
				) PC ON PC.PlanID = C.PlanID
			join Un_Plan p on c.PlanID = p.PlanID
			join Un_Unit u on c.ConventionID = u.ConventionID
			JOIN (
				select umh.UnitID, ModalID = max(umh.ModalID )
				from Un_UnitModalHistory umh
				join Un_Unit u on umh.UnitID = u.UnitID
				join Un_Convention c on u.ConventionID = c.ConventionID --and c.SubscriberID = 575993 
				JOIN #ConventionRC rc ON c.ConventionID = rc.ConventionID
				where umh.StartDate = (
									select max(StartDate)
									from Un_UnitModalHistory umh2
									where umh.UnitID = umh2.UnitID
									--and umh2.StartDate <= @dtDateTo --@dtDateTo
									AND CAST(umh2.StartDate AS DATE) <=  CAST(@dtDateTo AS DATE)
									)
				GROUP BY umh.UnitID
				)mh on mh.UnitID = u.UnitID
			JOIN Un_Modal M ON M.ModalID = mh.ModalID

			LEFT JOIN (SELECT qtyreduct = SUM(unitqty), unitid FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) R2 ON R2.UnitID = U.UnitID
			LEFT JOIN (
				SELECT 
					S.ConventionID, 
					mQuantite_UniteDemande =	CASE WHEN TU.TotalUniteConv <= SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
														THEN TU.TotalUniteConv -- SI ON A DONNE PLUS D'UNTIÉ EN PAE QUE LE NB TOTAL DANS LA CONV ALORS C'EST PAS LOGIQUE MAIS ON RETOURNE TotalUniteConv
												ELSE SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
												END
					-- ratio d'unité demandé en PAE en date du
					,RatioDemande =		CASE WHEN TU.TotalUniteConv > 0 THEN
										(
												CASE WHEN TU.TotalUniteConv <= SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
														THEN TU.TotalUniteConv -- SI ON A DONNE PLUS D'UNTIÉ EN PAE QUE LE NB TOTAL DANS LA CONV ALORS C'EST PAS LOGIQUE MAIS ON RETOURNE TotalUniteConv
												ELSE SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
												END
										) / TU.TotalUniteConv * 1.0
										ELSE 0 END
				FROM 
					Un_Scholarship S
					JOIN (
						SELECT U2.ConventionID, TotalUniteConv = sum(UnitQty)
						from Un_Unit u2
						JOIN #ConventionRC R2 ON R2.ConventionID = U2.ConventionID
						group by U2.ConventionID
						)TU	 on TU.ConventionID = S.ConventionID
					JOIN #ConventionRC RC ON RC.ConventionID = S.ConventionID
					JOIN (
						SELECT S1.ScholarshipID, MAXOperDate = MAX(O1.OperDate)
						FROM Un_Scholarship S1
						JOIN #ConventionRC RC ON RC.ConventionID = S1.ConventionID
						JOIN Un_ScholarshipPmt SP1 ON SP1.ScholarshipID = S1.ScholarshipID
						JOIN UN_OPER O1 ON O1.OperID = SP1.OperID
						LEFT JOIN Un_OperCancelation OC11 ON OC11.OperSourceID = O1.OperID
						LEFT JOIN Un_OperCancelation OC21 ON OC21.OperID = O1.OperID
						WHERE
							OC11.OperSourceID IS NULL
							AND OC21.OperID IS NULL
						GROUP BY S1.ScholarshipID
						)MO ON MO.ScholarshipID = S.ScholarshipID
					--JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = S.ScholarshipID
					--JOIN UN_OPER O ON O.OperID = SP.OperID
					--LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
					--LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
				WHERE 1=1
					AND MAXOperDate <= @dtDateTo -- comme la valeur de quotee part est en date du jour, alors on prend tous les PAE en date du jour, et non en date de fin
					AND S.ScholarshipStatusID IN ('24Y','25Y','DEA','PAD','REN')

					--AND O.OperDate <= @dtDateTo -- comme la valeur de quotee part est en date du jour, alors on prend tous les PAE en date du jour, et non en date de fin
					--AND OC1.OperSourceID IS NULL
					--AND OC2.OperID IS NULL
				GROUP BY S.ConventionID,TU.TotalUniteConv
				)QUD ON QUD.ConventionID = C.ConventionID

			LEFT join ( --2016-02-11
				select iID_Regroupement_Regime, LastYearQualif = max(YearQualif), FirstYearQualif = min(YearQualif)
				from tblCONV_ReleveDeCompteQuotePartPAE
				where AnneeReleveCompte = year(@dtDateTo)
				GROUP by iID_Regroupement_Regime
				)mQP on mqp.iID_Regroupement_Regime = p.iID_Regroupement_Regime

			LEFT join tblCONV_ReleveDeCompteQuotePartPAE QP on 
					qp.iID_Regroupement_Regime = p.iID_Regroupement_Regime 
					and qp.AnneeReleveCompte = year(@dtDateTo)

					and (c.YearQualif = qp.YearQualif 
							or (c.YearQualif > mqp.LastYearQualif and qp.YearQualif = mqp.LastYearQualif ) -- si année de qualif est > que le max prévu, on prend le max
							or (c.YearQualif < mqp.FirstYearQualif and qp.YearQualif = mqp.FirstYearQualif )
						) 

			GROUP BY
				c.ConventionID
				--,u.UnitID
				--,u.UnitQty
				,QPCohorteComptePAE
				,QPQteUniteActive
				,QPRevenuAccumuleUnite

		) QP on QP.ConventionID = c.ConventionID

		 
		LEFT JOIN (
			SELECT 
				ConventionID
				--,UnitID
				,UnitStateID = MAX(CASE WHEN UnitStateID = 'CPT' THEN 'EPG' ELSE UnitStateID END) -- une convention en CPT est affichée EPG.
				--,etape
				--,RangEtat	
			FROM (
				SELECT 
					c.ConventionID
					,u.UnitID
					,uss.UnitStateID
					,uss.etape
					-- Le 1er rangEtat est celui qu'on veut afficher parmis tout les état des groupe d'unité de la convention
					,RangEtat = DENSE_RANK() OVER (
											PARTITION BY c.ConventionNo -- #2 : basé sur le ConventionID
											ORDER BY etape -- #1 : On numérote les no d'etape
												)
				from Un_Convention c
				JOIN #ConventionRC rc ON c.ConventionID = rc.ConventionID
				JOIN Un_Unit u ON c.ConventionID = u.ConventionID
				JOIN (
					SELECT 
						us.unitid,
						uus.startdate,
						-- dans une convention, plusieurs gr d'unité peuvent avoir différent état de résiliation (RCP RFE RPG RV0).  Il faut en choisir un seul. alors je choisi RPG
						UnitStateID = CASE WHEN ust.OwnerUnitStateID = 'RES' THEN 'RPG' ELSE us.UnitStateID END, 
						etape = CASE 
							-- dans une convention, on ne peut pas avoir un groupe d'unité EPG ou CPT avec un autre groupe autre que EPG ou CPT. Et les autre que ceux là (non fermé) seront tous pareil, ex : RBA, R1B, 
							WHEN us.UnitStateID = 'EPG' THEN 1 -- on veut afficher celui là
							WHEN us.UnitStateID = 'CPT' THEN 2 -- sinon celui là
							WHEN ust.OwnerUnitStateID NOT IN ('FRM','RES') THEN 3 -- n'importe quel état non fermé (il seront tous pareil normalement)
							ELSE 4	-- l'état fermé
							END
					FROM 
						Un_UnitunitState us
						-- on recherche seulement les état associé à une convention ouverte (ainsi, on exclut les groupes d'unité fermé dans une convention ouverte)
						JOIN Un_UnitState ust on ust.UnitStateID = us.UnitStateID --and ust.OwnerUnitStateID not in ( 'FRM','RES')
						JOIN (
							SELECT 
								unitid,
								startdate = MAX(startDate)
							FROM un_unitunitstate
							WHERE startDate < DATEADD(d,1 ,@dtDateTo)
							GROUP BY unitid
							) uus on uus.unitid = us.unitid and uus.startdate = us.startdate 
					) uss on u.UnitID = uss.UnitID
				)t
			WHERE RangEtat = 1 -- Le 1er rangEtat est celui qu'on veut afficher parmis tout les état des groupe d'unité de la convention
			GROUP by ConventionID
			)etat ON etat.ConventionID = c.ConventionID
		JOIN Un_UnitState USS ON etat.UnitStateID = USS.UnitStateID
		
		LEFT JOIN #ConvIBEC BEC on BEC.UnitID = U.UnitID

	-- retiré le 2015-12-02 : pour la demande de ne pas sortir les convention qui sont fermée en date de fin
	--WHERE css.conventionid IS NULL -- la convention n'est pas en état fermée au début de la période

	WHERE ISNULL(ISNULL(BEC.dtFirstDeposit,u.dtFirstDeposit),'9999-12-31') <= @dtDateTo -- Filtre pour ne pas sortir de convention 1er dépôt en date de fin
		 OR ISNULL(u.IntReimbDate,'9999-12-31') <= @dtDateTo -- Les vieille convention qui n'ont pas de date de 1er dpot mais elles ont un RIN
	
	GROUP BY 
		c.ConventionID
		,c.ConventionNo
		,c.PlanID
		,p.PlanTypeID
		,RR.vcCode_Regroupement
		,c.SubscriberID
		,BeneficiaryIDEnDateDu
		,hs.FirstName
		,hs.LastName
		,SubSex.LongSexName
		,SubSex.ShortSexName
		,SubAdr.Address
		,SubAdr.City
		,SubAdr.StateName
		,SubAdr.ZipCode
		,SubAdr.CountryID
		,cn.CountryName
		,hb.FirstName
		,hb.LastName
		,hb.SexID
		--,hb.DeathDate
		,REP.Prenom_Representant
		,REP.Nom_Representant
		,REP.RepTelephone
		,REP.RepCourriel

		,DIR.Prenom_Directeur
		,DIR.Nom_Directeur
		,DIR.DirTelephone
		,DIR.DirCourriel


		,ISNULL(BeneficiaryIDEnDateDu, c.BeneficiaryID)
		,rc.ConventionID
		,c.YearQualif
		,hs.LangID
		,p.PlanDesc	
		,rio.iID_Convention_Destination
		,isnull(RendTIN,0)
		,USS.UnitStateID
		,USS.UnitStateName
		,rc.AnneeQualification
		,ISNULL(FD.FraisDisponibleTotalSousc,0)
		,cssFin.ConventionStateID
		,QPCohorteComptePAE
		,QPQteUniteActive
		,QPRevenuAccumuleUnite
		,QPPAE
		,Ristourne
		,QteUnitesConverties --2016-02-19
		,hb.BirthDate
		,p.OrderOfPlanInReport


	create index #indconv ON #ConventionRCinfo (ConventionID)


	--select * from #ConventionRCinfo --63,72

/************************************************
		État des PAE Payé et ou calculé --2016-02-11

		Ici, on recherche les valeur de PAE dans les scolarship ET les valeurs calculées (fnCONV_ObtenirValeurUnitaireCohorte)
		Plus loin, selon que les valeur sont calculé ou non en date du relevé, on détermine les valeur de PAE futur.

		Sert uniquement à afficher les montant futur de PAE. Et non les montant déjà payé.


*************************************************/

/*
-- 2018-01-01 : N'est plus utile depuis le projet d'enlevement des critères d'admission au bourse
	select 
		c.ConventionID
		,DernierPAEPaye = isnull(DernierPAEPaye,0)
		,PAE2Calcul = isnull(PAE2Calcul ,0)
		,PAE3Calcul = isnull(PAE3Calcul ,0)
		,PAE1Montant = 
						CASE --2016-02-11
							WHEN isnull(DernierPAEPaye,0) <> 0 THEN isnull(PAE1Montant ,0) -- Si on PAE a déjà été payé alors on met la valeur calculée
							ELSE isnull(RCI.QPPAE,0) - isnull(RCI.Ristourne,0)  -- on enlève la ristourne car QPPAE la contient. Et ici on veut l'équivalent du scolaship   
						END
		,PAE2Montant = case --2016-02-22
						when isnull(PAE2Calcul ,0) = 0 and isnull(PAE1Calcul ,0) = 0	then isnull(PAE1Montant ,0) -- donnera surement 0 mais ce cas ne soertira pas de toute façon
						when isnull(PAE2Calcul ,0) = 0 and isnull(PAE1Calcul ,0) = 1	then isnull(PAE1CalculValeur ,0) 
						when isnull(PAE2Calcul ,0) = 1									then isnull(PAE2CalculValeur ,0) 
						end
		,PAE3Montant = case --2016-02-22
						when isnull(PAE3Calcul ,0) = 0 and isnull(PAE2Calcul ,0) = 0 and isnull(PAE1Calcul ,0) = 0	then isnull(PAE1Montant ,0) -- donnera surement 0 mais ce cas ne soertira pas de toute façon
						when isnull(PAE3Calcul ,0) = 0 and isnull(PAE2Calcul ,0) = 0 and isnull(PAE1Calcul ,0) = 1	then isnull(PAE1CalculValeur,0) -- ne devrait pas etre utilisé dans le rapprot
						when isnull(PAE3Calcul ,0) = 0 and isnull(PAE2Calcul ,0) = 1								then isnull(PAE2CalculValeur ,0)
						when isnull(PAE3Calcul ,0) = 1																then isnull(PAE3CalculValeur ,0) 
						end
		,PAE2CalculValeur = isnull(PAE2CalculValeur ,0) --2016-02-12
		,PAE3CalculValeur = isnull(PAE3CalculValeur ,0)
		,CalculValideJusquau = cast( cast(year(@dtDateTo) + 1 as varchar(4)) + '-06-30' as DATE)
	into #EtatPAEs
	from Un_Convention c
	JOIN #ConventionRC rc ON c.ConventionID = rc.ConventionID
	join #ConventionRCinfo RCI on c.ConventionID = RCI.ConventionID
	left join (
		select 
			brs.ConventionID
			,DernierPAEPaye = max(brs.ScholarshipNo)
			,PAE1Etat =MAX( case when brs.ScholarshipNo = 1 then 'PAD' else null end)-- Si la bourse 1 sort, elle est donc payée
			,PAE2Etat =MAX( case when brs.ScholarshipNo = 2 then 'PAD' else null end)-- Si la bourse 2 sort, elle est donc payée
			,PAE3Etat =MAX( case when brs.ScholarshipNo = 3 then 'PAD' else null end)-- Si la bourse 3 sort, elle est donc payée
		from (
			SELECT 
				s.ConventionID
				,s.ScholarshipNo
			FROM Un_Scholarship S
			JOIN Un_Convention c ON S.ConventionID = c.ConventionID
			JOIN #ConventionRCinfo rc ON c.ConventionID = rc.ConventionID
			JOIN Un_ScholarshipPmt SP ON S.ScholarshipID = SP.ScholarshipID
			JOIN UN_OPER O ON sp.OperID = o.OperID
			LEFT JOIN Un_OperCancelation oc1 ON oc1.OperSourceID = o.OperID
			LEFT JOIN Un_OperCancelation oc2 ON oc2.OperID = o.OperID
			WHERE 
				O.OperDate <= @dtDateTo
				AND oc1.OperSourceID IS NULL AND oc2.OperID IS NULL
			group by s.ConventionID, s.ScholarshipNo
			)brs
		GROUP BY
			brs.ConventionID
		)PAE on c.ConventionID = pae.ConventionID

	LEFT join (
		select 
			ConventionID
			,PAE1Calcul = max(sc2.PAE1Calcul)--2016-02-22
			,PAE2Calcul = max(sc2.PAE2Calcul)
			,PAE3Calcul = max(sc2.PAE3Calcul)
			,PAE1Montant = max(PAE1Montant)
			,PAE2Montant = max(PAE2Montant)
			,PAE3Montant = max(PAE3Montant)
			,PAE1CalculValeur = max(PAE1CalculValeur)--2016-02-12
			,PAE2CalculValeur = max(PAE2CalculValeur)--2016-02-12
			,PAE3CalculValeur = max(PAE3CalculValeur)
		from (

			select 
				sc.ConventionID
				,PAE1Calcul = case when sc.ScholarshipNo = 1 then cast(sc.EstCalcule as int) ELSE NULL end --2016-02-22
				,PAE2Calcul = case when sc.ScholarshipNo = 2 then cast(sc.EstCalcule as int) ELSE NULL end
				,PAE3Calcul = case when sc.ScholarshipNo = 3 then cast(sc.EstCalcule as int) ELSE NULL end
				,PAE1Montant = case when sc.ScholarshipNo = 1 then ScholarshipAmount ELSE 0 end
				,PAE2Montant = case when sc.ScholarshipNo = 2 then ScholarshipAmount ELSE 0 end
				,PAE3Montant = case when sc.ScholarshipNo = 3 then ScholarshipAmount ELSE 0 end
				,PAE1CalculValeur = case when sc.ScholarshipNo = 1 and cast(sc.EstCalcule as int) = 1 then sc.Calcul ELSE NULL end--2016-02-12
				,PAE2CalculValeur = case when sc.ScholarshipNo = 2 and cast(sc.EstCalcule as int) = 1 then sc.Calcul ELSE NULL end--2016-02-12
				,PAE3CalculValeur = case when sc.ScholarshipNo = 3 and cast(sc.EstCalcule as int) = 1 then sc.Calcul ELSE NULL end
			from (
					SELECT 
						C.ConventionID,
						S.ScholarshipNo,
						s.ScholarshipAmount,
						EstCalcule = dbo.fnCONV_ObtenirValeurUnitaireCohorteExiste (C.PlanID, ISNULL(C.iAnnee_QualifPremierPAE, 0), S.ScholarshipNo),
						Calcul = round(--2016-02-23
										dbo.fnCONV_ObtenirValeurUnitaireCohorte (C.PlanID, ISNULL(C.iAnnee_QualifPremierPAE, 0), S.ScholarshipNo) * rc.QteUnitesConverties --2016-02-19  --qu.UnitQty --2016-02-12
									,2)
					FROM Un_Scholarship S
					JOIN Un_Convention C ON C.ConventionID = S.ConventionID
					JOIN #ConventionRCinfo rc ON c.ConventionID = rc.ConventionID

					WHERE S.ScholarshipStatusID IN ('ADM','RES','TPA','WAI','PAD') /*on doit inclure état PAD car le PAE peut avoir été payé après la période. on veut donc la valeur*/
					and c.PlanID <> 4
				)sc
			)sc2
		group by ConventionID
	)Calcul on c.ConventionID = Calcul.ConventionID
*/
	--select * from #ConventionRCinfo
	--return		

	-- Opération annulée le même jour
	SELECT DISTINCT	o.OperID, OperIDCancel = oCancel.OperID, o.OperDate,OperTypeIDCancel= o.OperTypeID
	INTO #oCancel
	FROM	 
		un_oper o
		JOIN Un_OperCancelation oc1 ON oc1.OperSourceID = o.OperID
		JOIN un_oper oCancel ON  oCancel.OperID = oc1.OperID
	WHERE 
		LEFT(CONVERT(VARCHAR, o.OperDate, 120), 10) = LEFT(CONVERT(VARCHAR, oCancel.OperDate, 120), 10)
		AND o.OperDate BETWEEN @dtDateFROM AND @dtDateTo

	-- Opération de Correction (opération d'annulation faite une autre journée que l'opération annulée
	SELECT DISTINCT	OperIDCorrect = oc.OperID, oCorrect.OperDate,OperTypeIDCorrect = oCorrect.OperTypeID
	INTO #oCorrection
	FROM	 
		un_oper o
		JOIN Un_OperCancelation oc ON oc.OperSourceID = o.OperID
		JOIN un_oper oCorrect ON oCorrect.OperID = oc.OperID
	WHERE 
		LEFT(CONVERT(VARCHAR, o.OperDate, 120), 10) <> LEFT(CONVERT(VARCHAR, oCorrect.OperDate, 120), 10)
		AND o.OperDate BETWEEN @dtDateFROM AND @dtDateTo

	-- Date de souscription d'un groupe D'unité.  Est considéré comme étant le 1er vrai dépôt dans le groupe D'unité

	SELECT DISTINCT
		u.ConventionID,
		u.UnitID,
		--DateSousc = U.dtFirstDeposit
		--2016-10-12
		DateSousc = CASE 
					WHEN U.dtFirstDeposit IS NOT NULL THEN u.dtFirstDeposit -- Les cas standards
					WHEN U.dtFirstDeposit IS NULL AND u.IntReimbDate is not null THEN u.InForceDate -- Les vieille convention qui n'ont pas de date de 1er dpot mais elles ont un RIN
					ELSE null
					END
	INTO #DateSousc
	FROM Un_Convention c
	JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
	JOIN Un_Unit u ON u.ConventionID = c.ConventionID


	/*
	SELECT 
		u.ConventionID,
		u.UnitID,
		DateSousc = min(o.OperDate)
	INTO #DateSousc
	FROM Un_Convention c
	JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
	JOIN Un_Unit u ON u.ConventionID = c.ConventionID
	JOIN Un_Cotisation ct ON u.UnitID = ct.UnitID
	JOIN un_oper o ON ct.OperID = o.OperID
	LEFT JOIN Un_OperCancelation oc1 ON o.OperID = oc1.OperSourceID
	LEFT JOIN Un_OperCancelation oc2 ON o.OperID = oc2.OperID
	WHERE 
		o.OperTypeID in ( 'CHQ','PRD','CPA','RDI','TIN','RIO')
		AND oc1.OperSourceID IS NULL
		AND oc2.OperID IS NULL
	GROUP BY 
		u.ConventionID,
		u.UnitID
	*/


	-- Table des opérations qui génère une réduction d'unité
	CREATE TABLE #TableRES ( -- tiré de SL_UN_TransactionHistoryForCS (#SpecialOperView)
		OperID INTEGER PRIMARY KEY,
		OperTypeID CHAR(3),
		UnitQtyRES FLOAT
	)

	INSERT INTO #TableRES (
			OperID,
			OperTypeID,
			UnitQtyRES)

		SELECT
			O2.OperID,--O.OperID,
			'RES',
			ur.UnitQty
		FROM Un_Unit U
		JOIN #ConventionRCinfo c1 ON U.ConventionID = c1.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID AND URC2.CotisationID <> Ct.CotisationID
		JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
		JOIN Un_UnitReduction ur ON urc.UnitReductionID = ur.UnitReductionID
		WHERE 	O.OperTypeID = 'TFR'
			AND	O2.OperTypeID = 'RES'
			AND o.OperDate BETWEEN @dtDateFROM AND @dtDateTo
		-----
		UNION
		-----
		SELECT
			O2.OperID,--O.OperID,
			'OUT',
			ur.UnitQty
		FROM Un_Unit U
		JOIN #ConventionRCinfo c1 ON U.ConventionID = c1.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID AND URC2.CotisationID <> Ct.CotisationID
		JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
		JOIN Un_UnitReduction ur ON urc.UnitReductionID = ur.UnitReductionID
		LEFT JOIN Un_TIO T ON T.iOUTOperID = O2.OperID
		WHERE 	O.OperTypeID = 'TFR'
			AND	O2.OperTypeID = 'OUT'
			AND o.OperDate BETWEEN @dtDateFROM AND @dtDateTo
			AND T.iTIOID IS NULL		-- N'est pas lié à un transfert interne
		-----
		UNION
		-----
		SELECT
			O2.OperID,--O.OperID,
			'TIO',
			ur.UnitQty
		FROM Un_Unit U
		JOIN #ConventionRCinfo c1 ON U.ConventionID = c1.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Unit U2 ON U2.UnitID = U.UnitID
		JOIN Un_Convention C ON C.ConventionID = U2.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID AND URC2.CotisationID <> Ct.CotisationID
		JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
		JOIN Un_TIO T ON O2.OperID = T.iOUTOperID
		JOIN Un_UnitReduction ur ON urc.UnitReductionID = ur.UnitReductionID
		WHERE 	O.OperTypeID = 'TFR'
			AND	O2.OperTypeID = 'OUT'
			AND o.OperDate BETWEEN @dtDateFROM AND @dtDateTo






	-------------------- Data SET détaillé et solde au début et à la fin
	SELECT
		ci.ConventionNo,
		TypeLigne,
		T1.ConventionID,
		T1.Correction,
		--OperTypeID1 = NULL, --T1.OperTypeID1, -- je l'enlève pour regrouper la Label
		--OperTypeID = NULL, --T1.OperTypeID
		LAB.GroupeOper,
		--lab.Label_FRA,
		DescriptionOperation = case 
									WHEN TypeLigne = '20-DTL' then 
											case 
											when ci.LangID = 'ENU' then lab.Label_ANG 
											else lab.Label_FRA 
											end
									ELSE TypeLigne
									END,
		DetailDuReleveAnnuel = case when T1.TypeLigne in ('10-SLD','15-SLD','20-DTL') then 1 else 0 end, -- indique si cette ligne fait partie de la section détail du relevé annuel
		QteUnite = CASE WHEN ci.PlanTypeID = 'IND' THEN NULL ELSE SUM(QteUnite) END, -- RDC-61 : si IND, alors on affiche 0 unité
		Operdate = LEFT(CONVERT(VARCHAR, T1.Operdate, 120), 10),
		lab.OrdreParDate,
		OperIDAgregat = min(OperID), -- Sert seulement à mettre en ordre, dans une même journée les opération du même type
		Epargne = SUM(Epargne),
		Frais = SUM(Frais),
		AssuranceSousc = SUM(AssuranceSousc),
		AutreFrais = SUM(AutreFrais),
		SCEE = SUM(SCEE),
		BEC = SUM(BEC),
		IQEE = SUM(IQEE),
		Revenu = SUM(Revenu),
		ComptePAE = SUM(ComptePAE),
		Total = SUM(
					Epargne  + AssuranceSousc + AutreFrais + SCEE + BEC + IQEE + Revenu + ComptePAE
					+ case when TypeLigne = '20-DTL' then Frais else 0 end  -- on inclut les frais dans le relevé annuel
					)
		,ci.SequenceAffichBenEtConv
		,ci.LePlan
		,ci.PlanTypeID
		,ci.GrRegimeCode
		,ci.Cohorte
		,ci.CotisationAEcheance
		,ci.CotisationPaiementFutur
		,ci.DateRIEstimé
		,ci.DateRIN
		,ci.ApresEcheance
		,ci.RIO
		,ci.RendTIN
		,ci.DateFinCotisation
		,ci.DateAdhesion
		,ci.UnitStateID
		,CI.UnitStateName
		,ci.AssuranceObligatoire
		,ci.AnnéeQualification

		,ci.SubscriberID
		,ci.SubPrenom
		,ci.SubNom
		,ci.LangID
		,ci.SubLongSexName
		,ci.SubShortSexName
		,ci.SubAdresse
		,ci.SubVille
		,ci.SubEtat
		,ci.SubCodePostal
		,ci.SubCountryID
		,ci.SubCountryName --2016-03-03

		,ci.BeneficiaryID
		,ci.BenPrenom
		,ci.BenNom
		,ci.BenSex
		,ci.Prenom_Representant
		,ci.Nom_Representant
		,ci.RepTelephone
		,ci.RepCourriel
		,ci.FraisDisponibleTotalSousc
		,ci.PlanIND
		,ci.PlanCOL
		,ci.ConventionStateIDFin
		,DateOuverture = @dtDateFROM
		,DateCloture = @dtDateTo
		--,Row = DENSE_RANK() OVER(PARTITION BY ci.ConventionNo 
		--	ORDER BY
		--			ci.BeneficiaryID,
		--			ci.SubscriberID

		--			--T1.TypeLigne,
		--			--T1.OperDate,
		--			--lab.OrdreParDate
		--)
		,ci.QPCohorteComptePAE
		,ci.QPQteUniteActive
		,ci.QPRevenuAccumuleUnite

		,QPPAE =	
				round( --2016-02-15
						case 
						when ci.PlanTypeID = 'COL' then  -- Si collectif alors c'Est la cotePart

							ci.QPPAE

							/*
							case 
							--when ci.UnitStateID = 'RBA' and DernierPAEPaye = 0					then (PAE.PAE1Montant + ci.Ristourne) * 3 --2016-02-12
							when ci.YearQualif <= year(@dtDateTo) and DernierPAEPaye = 0			then (PAE.PAE1Montant + ci.Ristourne) * 3 --2016-02-12
							when DernierPAEPaye = 1 and PAE.PAE2Calcul = 0							then (PAE.PAE1Montant + ci.Ristourne) * 2
							when DernierPAEPaye = 1 and PAE.PAE2Calcul = 1 and PAE.PAE3Calcul = 0	then (PAE.PAE2CalculValeur/*PAE2Montant*/ + ci.Ristourne) * 2 --2016-02-12
							when DernierPAEPaye = 1 and PAE.PAE2Calcul = 1 and PAE.PAE3Calcul = 1	then PAE.PAE2CalculValeur/*PAE2Montant*/ + ci.Ristourne + PAE.PAE3CalculValeur/*PAE3Montant*/ + ci.Ristourne --2016-02-12

							when DernierPAEPaye = 2 and PAE.PAE2Calcul = 0							then PAE.PAE1Montant + ci.Ristourne
							when DernierPAEPaye = 2 and PAE.PAE2Calcul = 1 and PAE.PAE3Calcul = 0	then PAE.PAE2CalculValeur/*PAE2Montant*/ + ci.Ristourne --2016-02-12
							when DernierPAEPaye = 2 and PAE.PAE3Calcul = 1							then PAE.PAE3CalculValeur/*PAE3Montant*/ + ci.Ristourne --2016-02-12

							else ci.QPPAE * 3 /*pour 3 pae*/ -- contient deja la ristourne 2016-02-12
							end
							*/
		
						else NULL-- sinon (IND), c'est le total des revenus
						end 
					,2)

		,DateFinProjection = ISNULL(PPC.DateFinProjection,'9999-12-31')
		,SCEEProjete = round (isnull(PPC.SCEEProjete,0) ,2 )
		,BECRecu = ROUND(ISNULL(PPC.Bec_Recu,0) ,2)
		,IQEEProjete = round (isnull(PPC.IQEEProjete,0) ,2 )
		,RendementProjete = round (isnull(PPC.RendementProjete,0) ,2)
		,ci.YearQualif -- valeur du Yearqualif dans un_convention, sert à déterminer si la convention est admissible au PAE ou non. admissible = yearqualif <= à année du relevé. Sinon, Non admissible.  --2016-02-12
		,ci.QteUnitesConverties
		/*
		,DernierPAEPaye
		,PAE.PAE2Calcul
		,PAE.PAE3Calcul
		,PAE1Montant = round(PAE.PAE1Montant + ci.Ristourne,2) --2016-02-15
		,PAE2Montant = round(PAE.PAE2Montant + ci.Ristourne,2) --2016-02-15
		,PAE3Montant = round(PAE.PAE3Montant + ci.Ristourne,2) --2016-02-15
		,PAE.CalculValideJusquau
		*/


	--INTO tmpReleveCompte -- drop table tmpReleveCompte
	FROM (

		SELECT 
			TypeLigne = '20-DTL',
			c.ConventionID,
			QteUnite = u.UnitQty + ISNULL(ur.QteRES,0), 
			OperID = 0,
			Correction = '',
			OperTypeID1 = 'Sousc',
			OperTypeID = 'Sousc',
			OperDate = min(o.OperDate),
			Epargne = 0,
			Frais = 0,
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0

		FROM Un_Convention c
		JOIN Un_Plan P on c.PlanID = P.PlanID
		JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
		JOIN Un_Unit u ON u.ConventionID = c.ConventionID
		JOIN Un_Cotisation ct ON u.UnitID = ct.UnitID
		JOIN un_oper o ON ct.OperID = o.OperID
		LEFT JOIN Un_OperCancelation oc1 ON o.OperID = oc1.OperSourceID
		LEFT JOIN Un_OperCancelation oc2 ON o.OperID = oc2.OperID
		LEFT JOIN (SELECT UnitID, QteRES = SUM(UnitQty) FROM Un_UnitReduction GROUP BY unitid) ur ON u.UnitID = ur.UnitID
		WHERE 
			o.OperTypeID in ( 'CHQ','PRD','CPA','RDI','TIN','RIO','TFR','COU')
			AND oc1.OperSourceID IS NULL
			AND oc2.OperID IS NULL
		GROUP BY 
			c.ConventionID,
			u.UnitID,
			u.UnitQty + ISNULL(ur.QteRES,0)
		HAVING min(o.OperDate) BETWEEN @dtDateFROM AND @dtDateTo

		UNION ALL

		SELECT
			TypeLigne = '20-DTL',
			U.ConventionID,
			QteUnite = ISNULL(R.UnitQtyRES,0) * -1,
			o.OperID,
			Correction = CASE WHEN  cor.OperIDCorrect is not null THEN 'Correction - ' ELSE  '' END,
			OperTypeID1 = CASE 
						WHEN  ISNULL(tio.iOUTOperID,0) = o.OperID THEN 'TIO_OUT'
						WHEN  ISNULL(tio.iTINOperID,0) = o.OperID THEN 'TIO_TIN'
						--WHEN  ISNULL(tio.iTFROperID,0) = o.OperID THEN 'TIO_TFR'
						WHEN  ISNULL(tio.iTFROperID,0) = o.OperID AND isnull(ctOUT.UnitID,0) = u.UnitID THEN 'TIO_TFR_OUT'
						WHEN  ISNULL(tio.iTFROperID,0) = o.OperID AND isnull(ctOUT.UnitID,0) <> u.UnitID THEN 'TIO_TFR_TIN'

						WHEN  ISNULL(rio.iID_Convention_Source,0) = c.ConventionID THEN rio.OperTypeID + '_NEG'
						WHEN  ISNULL(rio.iID_Convention_Destination,0) = c.ConventionID THEN rio.OperTypeID + '_POS'
						WHEN  o.OperTypeID = 'TFR' AND ct.Fee < 0 THEN 'TFR_NEG'
						WHEN  o.OperTypeID = 'TFR' AND ct.Fee > 0 THEN 'TFR_POS'
						ELSE  o.OperTypeID
						end,
			o.OperTypeID,
			o.OperDate,
			Epargne = Ct.Cotisation,
			Frais = Ct.Fee, --CASE WHEN p.PlanTypeID = 'IND' THEN 0 ELSE Ct.Fee END, -- On ne veut pas afficher les frais des plans IND
			AssuranceSousc = ct.SubscInsur + ct.TaxOnInsur,
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			JOIN Un_Plan P on c.PlanID = P.PlanID
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
			JOIN un_oper o ON ct.OperID = o.OperID
			LEFT JOIN Un_TIO tio ON o.OperID = tio.iOUTOperID OR o.OperID = tio.iTINOperID OR o.OperID = tio.iTFROperID
			LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
			LEFT JOIN #oCorrection Cor ON Cor.OperIDCorrect = o.OperID
			LEFT JOIN tblOPER_OperationsRIO rio ON o.OperID = rio.iID_Oper_RIO
			LEFT JOIN #TableRES R ON R.OperID = o.OperID

			-- aller chercher le unitid de la cotisation out.  sert a déterminer le TFR du TIO : est il OUT ?. sinon il est TIN
			LEFT JOIN UN_OPER oOUT ON oOUT.OperID = tio.iOUTOperID
			LEFT JOIN Un_Cotisation ctOUT on oOUT.OperID = ctOUT.OperID

		WHERE 1=1
			--AND c.ConventionNo = @conventionNO
			AND o.OperDate BETWEEN @dtDateFROM AND @dtDateTo
			AND o.OperTypeID not in ('CMD','FCB','RCB')
			AND oC.OperID IS NULL

		UNION ALL

		SELECT 
			TypeLigne = '20-DTL',
			ce.conventionid,
			QteUnite = 0,
			o.OperID,
			Correction = CASE WHEN  cor.OperIDCorrect is not null THEN 'Correction - ' ELSE  '' END,
			OperTypeID1 = CASE 
						WHEN  ISNULL(tio.iOUTOperID,0) = o.OperID THEN 'TIO_OUT'
						WHEN  ISNULL(tio.iTINOperID,0) = o.OperID THEN 'TIO_TIN'
						WHEN  ISNULL(tio.iTFROperID,0) = o.OperID THEN 'TIO_TFR' -- n'arrive pas ici pour le PCEE
						WHEN  ISNULL(rio.iID_Convention_Source,0) = ce.ConventionID THEN rio.OperTypeID + '_NEG'
						WHEN  ISNULL(rio.iID_Convention_Destination,0) = ce.ConventionID THEN rio.OperTypeID + '_POS'
						ELSE  o.OperTypeID
						end,
			o.OperTypeID,
			o.OperDate,
			Epargne = 0,
			Fraisouscription = 0,
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = fcesg + ce.fACESG,
			BEC = fCLB,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM un_oper o
		join un_cesp ce ON ce.operid = o.operid
		JOIN #ConventionRCinfo c1 ON ce.ConventionID = c1.ConventionID
		LEFT JOIN Un_TIO tio ON o.OperID = tio.iOUTOperID OR o.OperID = tio.iTINOperID OR o.OperID = tio.iTFROperID
		LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
		LEFT JOIN #oCorrection Cor ON Cor.OperIDCorrect = o.OperID
		LEFT JOIN tblOPER_OperationsRIO rio ON o.OperID = rio.iID_Oper_RIO
/*
		FROM un_cesp ce
		JOIN un_convention c ON ce.conventionid = c.conventionid
		JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
		JOIN Un_Plan P ON c.PlanID = P.PlanID
		JOIN un_oper o ON ce.operid = o.operid
		LEFT JOIN Un_TIO tio ON o.OperID = tio.iOUTOperID OR o.OperID = tio.iTINOperID OR o.OperID = tio.iTFROperID
		LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
		LEFT JOIN #oCorrection Cor ON Cor.OperIDCorrect = o.OperID
		LEFT JOIN tblOPER_OperationsRIO rio ON o.OperID = rio.iID_Oper_RIO
*/
		WHERE 1=1
			AND o.operdate BETWEEN @dtDateFROM AND @dtDateTo
			AND oC.OperID IS NULL
			AND (ce.fcesg <> 0 OR ce.fACESG <> 0 OR ce.fCLB <> 0)

		UNION ALL

		SELECT DISTINCT
			TypeLigne = '20-DTL',
			co.ConventionID,
			QteUnite = 0,
			o.OperID,
			Correction = CASE WHEN  cor.OperIDCorrect is not null THEN 'Correction - ' ELSE  '' END,
			OperTypeID1 = CASE 
						WHEN  ISNULL(tio.iOUTOperID,0) = o.OperID THEN 'TIO_OUT'
						WHEN  ISNULL(tio.iTINOperID,0) = o.OperID THEN 'TIO_TIN'
						WHEN  ISNULL(tio.iTFROperID,0) = o.OperID THEN 'TIO_TFR'
						WHEN  ISNULL(rio.iID_Convention_Source,0) = co.ConventionID THEN rio.OperTypeID + '_NEG'
						WHEN  ISNULL(rio.iID_Convention_Destination,0) = co.ConventionID THEN rio.OperTypeID + '_POS'
						ELSE  o.OperTypeID
						end,
			o.OperTypeID,
			o.OperDate,
			Epargne = 0,
			Fraisouscription = 0,
			AssuranceSousc = 0,
			/*
			AutreFrais = SUM(CASE WHEN  co.ConventionOperTypeID in ('INC') THEN co.ConventionOperAmount ELSE  0 END), 
			SCEE = 0,
			BEC = 0,
			IQEE = SUM(CASE WHEN  co.ConventionOperTypeID in ('CBQ','MMQ') THEN co.ConventionOperAmount ELSE  0 END),
			Revenu = SUM(CASE WHEN  co.ConventionOperTypeID in ('IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI') THEN co.ConventionOperAmount ELSE  0 END),
			ComptePAE = SUM(CASE WHEN  co.ConventionOperTypeID in ('BRS','AVC','RTN') THEN co.ConventionOperAmount ELSE  0 END)
			*/
			AutreFrais = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'INC', 1) > 0 /*co.ConventionOperTypeID in ('INC')*/ THEN co.ConventionOperAmount ELSE  0 END), 
			SCEE = 0,
			BEC = 0,
			IQEE = SUM(CASE WHEN  CharIndex(CO.ConventionOperTypeID, 'CBQ,MMQ', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END),
			Revenu = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'IBC,ICQ,III,IIQ,IMQ,INS,IS+,IST,INM,ITR,MIM,IQI', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END),
			ComptePAE = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'BRS,AVC,RTN', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END)
		FROM 
			un_oper o
			JOIN Un_ConventionOper co ON co.operID = o.OperID
			JOIN #ConventionRCinfo c1 ON co.ConventionID = c1.ConventionID
			LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
			LEFT JOIN Un_TIO tio ON o.OperID = tio.iOUTOperID OR o.OperID = tio.iTINOperID OR o.OperID = tio.iTFROperID
			LEFT JOIN #oCorrection Cor ON Cor.OperIDCorrect = o.OperID
			LEFT JOIN tblOPER_OperationsRIO rio ON o.OperID = rio.iID_Oper_RIO
			/*
			Un_Convention c
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_ConventionOper co ON co.ConventionID = c.ConventionID
			JOIN un_oper o ON co.OperID = o.OperID

			LEFT JOIN Un_TIO tio ON o.OperID = tio.iOUTOperID OR o.OperID = tio.iTINOperID OR o.OperID = tio.iTFROperID
			LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
			LEFT JOIN #oCorrection Cor ON Cor.OperIDCorrect = o.OperID
			LEFT JOIN tblOPER_OperationsRIO rio ON o.OperID = rio.iID_Oper_RIO
			*/
		WHERE 1=1
			--AND c.ConventionNo = @conventionNO
			AND o.operdate BETWEEN @dtDateFROM AND @dtDateTo
			AND oC.OperID IS NULL
			AND o.OperTypeID NOT IN ('PRA','RIF','RIP') -- EXCLURE PRA ET LES RETENUS.  SERA FAIT DANS SECTION suivante
		GROUP BY
			co.ConventionID,
			cor.OperIDCorrect,
			o.OperID,
			o.OperTypeID,
			o.OperDate
			,tio.iOUTOperID
			,tio.iTINOperID
			,tio.iTFROperID
			,rio.iID_Convention_Source
			,rio.iID_Convention_Destination
			,rio.OperTypeID


		UNION ALL

		-- section pour les PRA et leur retenues d'impôt
		SELECT DISTINCT
			TypeLigne = '20-DTL',
			co.ConventionID,
			QteUnite = 0,
			o.OperID,
			Correction = CASE WHEN  cor.OperIDCorrect is not null THEN 'Correction - ' ELSE  '' END,
			OperTypeID1 = o.OperTypeID,
			o.OperTypeID,
			o.OperDate,
			Epargne = 0,
			Fraisouscription = 0,
			AssuranceSousc = 0,
			AutreFrais = 0, 
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'IBC,ICQ,III,IIQ,IMQ,INS,IS+,IST,INM,ITR,MIM,IQI,RTN', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END),
			ComptePAE = 0
		FROM 
			un_oper o
			JOIN Un_ConventionOper co ON co.operID = o.OperID
			JOIN #ConventionRCinfo c1 ON co.ConventionID = c1.ConventionID
			LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
			LEFT JOIN #oCorrection Cor ON Cor.OperIDCorrect = o.OperID
		WHERE 1=1
			AND o.operdate BETWEEN @dtDateFROM AND @dtDateTo
			AND oC.OperID IS NULL
			AND o.OperTypeID IN ('PRA','RIF','RIP') 
		GROUP BY
			co.ConventionID,
			cor.OperIDCorrect,
			o.OperID,
			o.OperTypeID,
			o.OperDate


		/*
		-- ceci est à définir
		UNION ALL

		SELECT
			TypeLigne = '20-DTL',
			C.ConventionID,
			QteUnite = uu.UnitQty * -1,
			o.OperID,
			Correction = CASE WHEN  cor.OperIDCorrect is not null THEN 'Correction - ' ELSE  '' END,
			OperTypeID1 = 'FERMER_CONTRAT',
			o.OperTypeID,
			o.OperDate,
			Epargne = 0,
			Frais = 0,
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			JOIN (
				SELECT u.ConventionID, UnitQty = SUM(u.UnitQty + ISNULL(ur.QteRESAfter,0))
				FROM Un_Unit u
				JOIN #ConventionRCinfo c1 ON u.ConventionID = c1.ConventionID 
				LEFT JOIN (SELECT UnitID, QteRESAfter = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) ur ON u.UnitID = ur.UnitID
				GROUP BY u.ConventionID
				)uu ON c.ConventionID = uu.ConventionID
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Scholarship s ON c.ConventionID = s.ConventionID
			JOIN Un_ScholarshipPmt sp ON s.ScholarshipID = sp.ScholarshipID
			JOIN un_oper o ON sp.OperID = o.OperID
			LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
			LEFT JOIN #oCorrection Cor ON Cor.OperIDCorrect = o.OperID

		WHERE 1=1
			AND o.OperDate BETWEEN @dtDateFROM AND @dtDateTo
			AND o.OperTypeID = 'PAE'
			AND s.ScholarshipNo = 3
			AND oC.OperID IS NULL
			AND p.PlanTypeID <> 'IND'
		*/

		------------------------------ SOLDE début --------------------------------
		UNION ALL


		---------------RDC-80 : On créé une ligne de solde de départ à 0 pour les conventions ouvertes dans la période
		SELECT
			TypeLigne = '10-SLD',
			U.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Frais = 0,
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			JOIN #DateSousc ds ON ds.unitID = u.UnitID
		WHERE 
			ds.DateSousc BETWEEN @dtDateFrom and @dtDateTo
		GROUP BY U.ConventionID

		UNION ALL
		---------------RDC-80 : On créé une ligne de solde de départ de FRAIS à 0 pour les conventions ouvertes dans la période
		SELECT
			TypeLigne = '15-SLD',
			U.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Frais = 0,
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			JOIN #DateSousc ds ON ds.unitID = u.UnitID
		WHERE 
			ds.DateSousc BETWEEN @dtDateFrom and @dtDateTo
		GROUP BY U.ConventionID

		UNION ALL

		SELECT
			TypeLigne = '10-SLD',
			U.ConventionID,
			QteUnite = SUM(u.UnitQty + ISNULL(ur.UnitQtyRES,0)),
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Frais = 0,
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			JOIN #DateSousc ds ON ds.unitID = u.UnitID
			LEFT JOIN (SELECT UnitID, UnitQtyRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate >=@dtDateFROM GROUP BY UnitID) ur ON ur.UnitID = u.UnitID
		WHERE 
			ds.DateSousc < @dtDateFrom
		GROUP BY U.ConventionID
		

		UNION ALL

		SELECT
			TypeLigne = '10-SLD',
			U.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = SUM(Ct.Cotisation),
			Frais = 0, --Le solde au début ne contient pas cet info --SUM(Ct.Fee),
			AssuranceSousc = 0, --Le solde au début ne contient pas cet info -- SUM(ct.SubscInsur),
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
			JOIN un_oper o ON ct.OperID = o.OperID

		WHERE 1=1
			--AND c.ConventionNo = @conventionNO
			AND o.OperDate < @dtDateFrom
			AND o.OperTypeID not in ('CMD','FCB','RCB')

		GROUP BY 
			U.ConventionID


		UNION ALL

		SELECT
			TypeLigne = '15-SLD',
			U.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Frais = SUM(Ct.Fee), -- SUM(CASE WHEN p.PlanTypeID = 'IND' THEN 0 ELSE Ct.Fee END),
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			JOIN Un_Plan P on c.PlanID = P.PlanID
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
			JOIN un_oper o ON ct.OperID = o.OperID

		WHERE 1=1
			--AND c.ConventionNo = @conventionNO
			AND o.OperDate < @dtDateFrom
			AND o.OperTypeID not in ('CMD','FCB','RCB')

		GROUP BY 
			U.ConventionID

		UNION ALL

		SELECT 
			TypeLigne = '10-SLD',
			ce.conventionid,
			QteUnite = 0,
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Fraisouscription = 0,
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = SUM(fcesg + ce.fACESG),
			BEC = SUM(fCLB),
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM un_cesp ce
		JOIN un_convention c ON ce.conventionid = c.conventionid
		JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
		JOIN Un_Plan P ON c.PlanID = P.PlanID
		JOIN un_oper o ON ce.operid = o.operid
		WHERE 1=1
			--AND c.ConventionNo = @conventionNO
			AND o.operdate < @dtDateFROM 
		GROUP BY 
			ce.conventionid

		UNION ALL

		SELECT --DISTINCT
			TypeLigne = '10-SLD',
			c.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Fraisouscription = 0,
			AssuranceSousc = 0,
			AutreFrais = 0, /*Le solde du au début et à la fin n'inclut cet info */  -- SUM(CASE WHEN  co.ConventionOperTypeID in ('INC') THEN co.ConventionOperAmount ELSE  0 END), 
			SCEE = 0,
			BEC = 0,
			IQEE = SUM(CASE WHEN  co.ConventionOperTypeID in ('CBQ','MMQ') THEN co.ConventionOperAmount ELSE  0 END),
			Revenu = SUM(CASE WHEN  co.ConventionOperTypeID in ('IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI') THEN co.ConventionOperAmount ELSE  0 END),
			ComptePAE = 0 /*Le solde du au début et à la fin n'inclut pas le compte PAE*/  -- SUM(CASE WHEN  co.ConventionOperTypeID in ('BRS','AVC','RTN') THEN co.ConventionOperAmount ELSE  0 END)
		FROM 
			Un_Convention c
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_ConventionOper co ON co.ConventionID = c.ConventionID
			JOIN un_oper o ON co.OperID = o.OperID
		WHERE 1=1
			--AND c.ConventionNo = @conventionNO
			AND o.operdate < @dtDateFROM 
		GROUP BY
			c.ConventionID


			--------------------------------------- solde à la fin ---------------------------
		UNION ALL

		SELECT
			TypeLigne = '30-SLD',
			U.ConventionID,
			-- Qté unité à la fin : si la conv est fermée, ON met zéro.
						-- si elle a été résiliée, donc c'est 0 de toute façon
						-- si c'est à cause que toute les bourse sont payé, alors ON force 0
			QteUnite = SUM(CASE WHEN ConventionStateIDFin <> 'FRM' THEN u.UnitQty + ISNULL(ur.UnitQtyRES,0) ELSE  0 END ),
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Frais = 0,
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			--JOIN (
			--	SELECT 
			--		Cs.conventionid ,
			--		ccs.startdate,
			--		cs.ConventionStateID
			--	FROM 
			--		un_conventionconventionstate cs
			--		JOIN (
			--			SELECT 
			--			conventionid,
			--			startdate = max(startDate)
			--			FROM un_conventionconventionstate
			--			WHERE startDate < DATEADD(d,1 ,@dtDateTo)
			--			GROUP BY conventionid
			--			) ccs ON ccs.conventionid = cs.conventionid 
			--				AND ccs.startdate = cs.startdate 
			--				--AND cs.ConventionStateID in ('REE','TRA')
			--	) css ON C.conventionid = css.conventionid
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			JOIN #DateSousc ds ON ds.unitID = u.UnitID
			LEFT JOIN (SELECT UnitID, UnitQtyRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) ur ON ur.UnitID = u.UnitID
		WHERE ds.DateSousc <= @dtDateTo
		GROUP BY U.ConventionID

		UNION ALL

		SELECT
			TypeLigne = '30-SLD',
			U.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = SUM(Ct.Cotisation),
			Frais = SUM(Ct.Fee), --SUM(CASE WHEN p.PlanTypeID = 'IND' THEN 0 ELSE Ct.Fee END),
			AssuranceSousc = 0,  /*Le solde du au début et à la fin n'inclut cet info */ --SUM(ct.SubscInsur),
			AutreFrais = 0,
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			JOIN Un_Plan P on c.PlanID = P.PlanID
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
			JOIN un_oper o ON ct.OperID = o.OperID
			LEFT JOIN Un_TIO tio ON o.OperID = tio.iOUTOperID OR o.OperID = tio.iTINOperID OR o.OperID = tio.iTFROperID
			LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
			LEFT JOIN #oCorrection Cor ON Cor.OperIDCorrect = o.OperID
			LEFT JOIN tblOPER_OperationsRIO rio ON o.OperID = rio.iID_Oper_RIO
		WHERE 1=1
			--AND c.ConventionNo = @conventionNO
			AND o.OperDate <= @dtDateTo
			AND o.OperTypeID not in ('CMD','FCB','RCB')
			AND oC.OperID IS NULL
		GROUP BY
			U.ConventionID

		UNION ALL

		SELECT 
			TypeLigne = '30-SLD',
			ce.conventionid,
			QteUnite = 0,
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Fraisouscription = 0,
			AssuranceSousc = 0,
			AutreFrais = 0,
			SCEE = SUM(fcesg + ce.fACESG),
			BEC = SUM(fCLB),
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		from un_oper o
		join un_cesp ce ON ce.operid = o.operid
		JOIN #ConventionRCinfo c1 ON ce.ConventionID = c1.ConventionID
		LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
			/*
		FROM un_cesp ce
		JOIN un_convention c ON ce.conventionid = c.conventionid
		JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
		JOIN Un_Plan P ON c.PlanID = P.PlanID
		JOIN un_oper o ON ce.operid = o.operid
		LEFT JOIN Un_TIO tio ON o.OperID = tio.iOUTOperID OR o.OperID = tio.iTINOperID OR o.OperID = tio.iTFROperID
		LEFT JOIN #oCancel oC ON o.OperID = oC.OperID OR o.OperID = oC.OperIDCancel
		LEFT JOIN #oCorrection Cor ON Cor.OperIDCorrect = o.OperID
		LEFT JOIN tblOPER_OperationsRIO rio ON o.OperID = rio.iID_Oper_RIO
		*/
		WHERE 1=1
			AND o.operdate <= @dtDateTo
			AND oC.OperID IS NULL
		GROUP BY
			ce.conventionid

		UNION ALL

		SELECT DISTINCT
			TypeLigne = '30-SLD',
			co.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = NULL,
			OperTypeID1 = NULL,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Fraisouscription = 0,
			AssuranceSousc = 0,
			AutreFrais = 0, /*Le solde du au début et à la fin n'inclut cet info */  -- SUM(CASE WHEN  co.ConventionOperTypeID in ('INC') THEN co.ConventionOperAmount ELSE  0 END), 
			SCEE = 0,
			BEC = 0,
			IQEE = SUM(CASE WHEN  CharIndex(CO.ConventionOperTypeID, 'CBQ,MMQ', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END),
			Revenu = SUM(CASE WHEN CharIndex(CO.ConventionOperTypeID, 'IBC,ICQ,III,IIQ,IMQ,INS,IS+,IST,INM,ITR,MIM,IQI', 1) > 0 THEN co.ConventionOperAmount ELSE  0 END),
			ComptePAE = 0 /*Le solde du au début et à la fin n'inclut pas le compte PAE*/ 
		FROM 
			un_oper o
			JOIN Un_ConventionOper co ON co.OperID = o.OperID
			JOIN #ConventionRCinfo c1 ON co.ConventionID = c1.ConventionID
		WHERE 1=1
			AND o.operdate <= @dtDateTo
		GROUP BY
			co.ConventionID

		UNION ALL

		SELECT
			TypeLigne = '25-FRS',
			U.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = '',
			OperTypeID1 = CASE WHEN o.OperTypeID = 'FRS' then o.OperTypeID else '' end,
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = sum(ct.Cotisation),
			Frais = sum(Ct.Fee), --
			AssuranceSousc = 0,
			AutreFrais = 0, --
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			JOIN Un_Plan P on c.PlanID = P.PlanID
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
			JOIN un_oper o ON ct.OperID = o.OperID
		WHERE 
			o.OperDate BETWEEN @dtDateFROM AND @dtDateTo
			AND o.OperTypeID NOT IN ('CMD','FCB','RCB')
			AND o.OperTypeID NOT IN ('TIO','TFR','RIO','RIM','TRI','RIN') --IOuellet 2015-11-24 : Exclure les frais issus des transactions RIO-TRI-RIM-RIN-TIO ainsi que le TFR, qu'il soit seul ou rattaché à une autre transaction financière
			AND NOT (o.OperTypeID = 'TRA' and c.ConventionNo like 'T%') -- IOuellet 2015-11-24 : exclure les transactions TRA dans un plan individuel débutant par la lettre «T». Les autres TRA doivent être affichés.
		GROUP BY
			U.ConventionID,
			CASE WHEN o.OperTypeID = 'FRS' then o.OperTypeID else '' end

		UNION ALL

		SELECT 
			TypeLigne = '25-FRS',
			c.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = '',
			OperTypeID1 = '',
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Frais = 0,
			AssuranceSousc = 0,
			AutreFrais = SUM(co.ConventionOperAmount), 
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			Un_Convention c
			JOIN #ConventionRCinfo c1 ON c.ConventionID = c1.ConventionID
			JOIN Un_ConventionOper co ON co.ConventionID = c.ConventionID
			JOIN un_oper o ON co.OperID = o.OperID
		WHERE 
			o.operdate BETWEEN @dtDateFROM AND @dtDateTo
			and co.ConventionOperTypeID = 'INC'

		GROUP BY
			c.ConventionID

		UNION ALL

		-- Un Moins, un solde à 0 par convention
		SELECT 
			TypeLigne = '25-FRS',
			c1.ConventionID,
			QteUnite = 0,
			OperID = NULL,
			Correction = '',
			OperTypeID1 = '',
			OperTypeID = NULL,
			OperDate = NULL,
			Epargne = 0,
			Frais = 0,
			AssuranceSousc = 0,
			AutreFrais = 0, 
			SCEE = 0,
			BEC = 0,
			IQEE = 0,
			Revenu = 0,
			ComptePAE = 0
		FROM 
			#ConventionRCinfo c1
		GROUP BY
			c1.ConventionID


		) T1
	JOIN #ConventionRCinfo ci ON ci.ConventionID = T1.ConventionID
	--LEFT JOIN #EtatPAEs pae on pae.ConventionID = ci.ConventionID
	LEFT JOIN #ProjParConvention PPC on ci.ConventionID = PPC.ConventionID
	LEFT JOIN tblCONV_ReleveDeCompteOpertypeLabel lab ON t1.OperTypeID1 = lab.OperTypeID1 -- SELECT * FROM tblCONV_ReleveDeCompteOpertypeLabel



	GROUP BY
		T1.TypeLigne,
		T1.ConventionID,
		T1.Correction,
		--T1.OperTypeID1,
		--T1.OperTypeID,
		--lab.Label_FRA,
		LAB.GroupeOper,
		case 
				WHEN TypeLigne = '20-DTL' then 
						case 
						when ci.LangID = 'ENU' then lab.Label_ANG 
						else lab.Label_FRA 
						end
				ELSE TypeLigne
				END,
		--QteUnite,
		T1.OperDate,
		lab.OrdreParDate,

		ci.ConventionNo
		,ci.SequenceAffichBenEtConv
		,ci.LePlan
		,ci.PlanTypeID
		,ci.GrRegimeCode
		,ci.Cohorte
		,ci.CotisationAEcheance
		,ci.CotisationPaiementFutur
		,ci.DateRIEstimé
		,ci.DateRIN
		,ci.ApresEcheance
		,ci.RIO
		,ci.RendTIN
		,ci.DateFinCotisation
		,ci.DateAdhesion
		,ci.UnitStateID
		,CI.UnitStateName
		,ci.AssuranceObligatoire
		,ci.SubscriberID
		,ci.BeneficiaryID
		,ci.AnnéeQualification

		,ci.SubPrenom
		,ci.SubNom
		,ci.LangID
		,ci.SubLongSexName
		,ci.SubShortSexName
		,ci.SubAdresse
		,ci.SubVille
		,ci.SubEtat
		,ci.SubCodePostal
		,ci.SubCountryID
		,ci.SubCountryName --2016-03-03
		,ci.BenPrenom
		,ci.BenNom
		,ci.BenSex

		,ci.Prenom_Representant
		,ci.Nom_Representant
		,ci.RepTelephone
		,ci.RepCourriel
		,ci.FraisDisponibleTotalSousc
		,ci.PlanIND
		,ci.PlanCOL
		,ci.ConventionStateIDFin
		,ci.QPCohorteComptePAE
		,ci.QPQteUniteActive
		,ci.QPRevenuAccumuleUnite
		,ci.QPPAE


		,ISNULL(PPC.DateFinProjection,'9999-12-31')
		,isnull(PPC.SCEEProjete,0)
		,ISNULL(PPC.Bec_Recu,0)
		,isnull(PPC.IQEEProjete,0)
		,isnull(PPC.RendementProjete,0)
		,ci.YearQualif --2016-02-12
		,ci.QteUnitesConverties
		/*
		,DernierPAEPaye
		,PAE.PAE2Calcul
		,PAE.PAE3Calcul
		,PAE.PAE1Montant
		,PAE.PAE2Montant
		,PAE.PAE3Montant
		,PAE.PAE2CalculValeur --2016-02-12
		,PAE.PAE3CalculValeur --2016-02-12
		,PAE.CalculValideJusquau
		,ci.Ristourne
		*/
		

		
	HAVING
		
		T1.TypeLigne in ( '30-SLD','10-SLD','15-SLD','25-FRS') -- Le solde à la fin peut être à 0 partout
		OR ( -- sinon, au moins un montant différent de 0 par ligne
			SUM(ISNULL(QteUnite,0)) <> 0 OR
			SUM(Epargne) <> 0 OR
			--(SUM(Frais) <> 0 and ci.PlanTypeID <> 'IND' ) OR -- un depot de frais dans un IND ne sera pas affiché dans le détail (20-DTL)
			SUM(Frais) <> 0 OR
			SUM(AssuranceSousc) <> 0 OR
			SUM(SCEE) <> 0 OR
			SUM(BEC) <> 0 OR
			SUM(IQEE) <> 0 OR
			SUM(Revenu) <> 0 OR
			SUM(ComptePAE) <> 0
			)
		
	ORDER BY
		ci.BeneficiaryID,
		ci.ConventionNo,
		--T1.ConventionID,
		T1.TypeLigne,
		T1.OperDate,
		lab.OrdreParDate
		--,T1.OperTypeID


	drop table #oCancel
	drop TABLE #oCorrection
	drop table #ConventionRC
	drop table #ConventionRCinfo

	--if @SubscriberID is not null
	--begin
	--update Mo_Human set LangID = @LangIDOri where HumanID = @SubscriberID and @LangueTEST is not NULL
	--end


/*
			10-SLD : Solde d’ouverture au début de la période 
			15-SLD : Cumulatif des frais de souscription payés au 1er janvier 2014
			20-DTL : Opération dans la période
			25-FRS : Pour la grille des frais d’opération et de fonctionnement 
			30-SLD : Solde de clôture à la fin de la période  
*/

end