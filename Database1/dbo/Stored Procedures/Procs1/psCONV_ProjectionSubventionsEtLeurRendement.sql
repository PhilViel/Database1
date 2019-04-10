--
/********************************************************************************************************************
Copyrights (c) 2006 Gestion psCONV_ProjectionSubventionsEtLeurRendement inc
Nom                 :	psCONV_ProjectionSubventionsEtLeurRendement
Description         :	projection des subventions et rendements des conventions d'un bénéficiaire à une date donnée.
						Pour le relevé de compte
Valeurs de retours  :	Dataset de données

Note                :	
					2015-08-26	Donald Huppé	Création 
					2018-05-11	Donald Huppé	Version finale utilsée pour relevé de 2017-12-31

exec psCONV_ProjectionSubventionsEtLeurRendement NULL, 528782      , NULL
exec psCONV_ProjectionSubventionsEtLeurRendement 1, NULL, NULL
exec psCONV_ProjectionSubventionsEtLeurRendement 2, NULL, NULL
exec psCONV_ProjectionSubventionsEtLeurRendement 575993, NULL, NULL
exec psCONV_ProjectionSubventionsEtLeurRendement NULL, NULL,'X-20151113011' 'X-20140121090'
exec psCONV_ProjectionSubventionsEtLeurRendement 575993, NULL, 'R-20091203092'
exec psCONV_ProjectionSubventionsEtLeurRendement NULL, NULL, 'R-20080130043'
exec psCONV_ProjectionSubventionsEtLeurRendement NULL, NULL,'T-20130915130'  --'r-20060405001'

SELECT 
	c.ConventionID
	,DateFinProjection = max(DateFinProjection)
	,SCEEProjete = sum(SCEE_Plus_Bec_RecuEtProjete) -- U 
	,Bec_Recu = sum(Bec_Recu) -- U2
	,IQEEProjete = sum(IQEE_Plus_RecuEtProjete) -- UU 
	,RendementProjete = sum(RevenuAccumuleRecuEtProjete)  + sum(IQEERevenuAccumuleRecuEtProjete ) -- V  + V V 

FROM #Proj p
JOIN Un_Convention c on c.ConventionNo = p.ConventionNo
GROUP BY c.ConventionID

*/
--CREATE TABLE #Proj(
	--[SubscriberID] [int] NOT NULL,	[Sousc] [varchar](87) NULL,	[BeneficiaryID] [int] NOT NULL,	[Benef] [varchar](86) NULL,	[ConventionNo] [varchar](15) NOT NULL,	[PlanDesc] [varchar](75) NOT NULL,	[QteUnite] [money] NULL,	[EtatGrUnite] [varchar](75) NOT NULL,	[ModeCotisation] [varchar](11) NULL,	[MontantCotisation] [money] NULL,	[CotisationFraisSoldeUnite] [money] NULL,	[MontantSouscrit] [money] NULL,	[PonderationAvecAutreConvention] [float] NULL,	[ExcedentDe36k] [money] NULL,
	--[RiVerse] [varchar](3) NOT NULL,	[CAN_HorsQC] [varchar](3) NOT NULL,	[International] [varchar](3) NOT NULL,	[CotisationEncaisseDecembreReleve] [money] NULL,	[CotisationEncaisseAnneeReleve] [money] NULL,	[TotalSCEEEtRend] [real] NULL,	[SCEEUnite] [money] NOT NULL,	[SCEEPlusUnite] [money] NOT NULL,	[BECUnite] [money] NOT NULL,	[RendSCEEUnite] [real] NULL,	[RevenuCotisationUnite] [real] NULL,
	--[IQEEEtRevenuUnite] [real] NULL,	[IQEEUnite] [real] NULL,	[IQEEPlusUnite] [real] NULL,	[RevenuIQEEUnite] [real] NULL,	[BirthDate] [date] NULL,	[DateDebutOperationFinanciere] [date] NULL,	[DateDernierDepot] [date] NULL,	[DateDebutProjection] [date] NULL,	[DateFinProjection] [date] NULL,	[DateFinCotisationSubventionnee] [date] NULL,	[DateEncaissSCEEaRecevoir] [date] NULL,	[DateEncaissIQEEaRecevoir] [date] NULL,
	--[DateEncaissDerniereCotisSCEE] [date] NULL,	[DateEncaissDerniereCotisIQEE] [date] NULL,	[DiminutionProjectionPourPasDepasserPlafondAvie] [float] NULL,	[SCEEaRecevoir] [numeric](22, 6) NULL,	[SCEEperiodiqueAuContratSansDepasserPlafondAnnuel] [numeric](22, 6) NULL,	[SCEEperiodiqueAuContratSansDepasserPlafondAvie] [float] NULL,	[SCEEtotalPrevu] [float] NULL,	[NbAnneeDeDateDebutProjection_A_FinProjection] [numeric](17, 6) NULL,	[NbAnneeDeDateEncaissPrevuSCEEaRecevoir_A_FinProjection] [numeric](17, 6) NULL,	[NbPeriodes_De_DateProchCot_A_DernCot] [float] NULL,	[NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans] [float] NULL,	[NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200] [float] NULL,	[NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot] [float] NULL,
	--[NbAnneeDeDateDernCot_A_FinProjection] [numeric](17, 6) NULL,	[SoldeInitial_SCEE_BEC_RevenuProjete] [float] NULL,	[SCEEaRecevoirProjete] [float] NULL,	[SCEEPerodiqueProjete_De_DateProchCot_A_DernCot] [float] NULL,	[SCEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie] [float] NULL,	[SoldeSCEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot] [float] NULL,	[SoldeSCEEProjete_De_DateEncaissDernCot_A_DateFinProj] [float] NULL,	[SCEEProjete] [float] NULL,	[SCEE_Plus_Bec_RecuEtProjete] [float] NULL, /* U */	[Bec_Recu] [money] NOT NULL, /* U2 */	[RevenuAccumuleSurSoldeRend] [float] NULL,	[RevenuAccumuleRecuEtProjete] [float] NULL,	[SCEEEtRevenuAccumule_Recu_EtProjete] [float] NULL, /* W */	[IQEEDiminutionProjectionPourPasDepasserPlafondAvie] [float] NULL,	[IQEEaRecevoir] [numeric](21, 5) NULL,
	--[IQEEperiodiqueAuContratSansDepasserPlafondAnnuel] [numeric](22, 6) NULL,	[IQEEperiodiqueAuContratSansDepasserPlafondAvie] [float] NULL,	[IQEEtotalPrevu] [float] NULL,	[IQEE_NbAnneeDeDateDebutProjection_A_FinProjection] [numeric](17, 6) NULL,	[IQEE_NbAnneeDeDateEncaissPrevuIQEEaRecevoir_A_FinProjection] [numeric](17, 6) NULL,	[IQEE_NbAnnee_De_DateProchCot_A_DernCot] [float] NULL,	[IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans] [float] NULL,	[IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600] [float] NULL,	[IQEE_NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot] [float] NULL,	[IQEE_NbAnneeDeDateDernCot_A_FinProjection] [numeric](17, 6) NULL,	[IQEE_SoldeInitial_IQEE_RevenuProjete] [float] NULL,	[IQEEaRecevoirProjete] [float] NULL,	[IQEEPerodiqueProjete_De_DateProchCot_A_DernCot] [float] NULL,	[IQEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie] [float] NULL,
	--[SoldeIQEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot] [float] NULL,	[SoldeIQEEProjete_De_DateEncaissDernCot_A_DateFinProj] [float] NULL,	[IQEEProjete] [float] NULL,	[IQEE_Plus_RecuEtProjete] [float] NULL, /* UU */	[IQEERevenuAccumuleRecuEtProjete] [float] NULL, /* V */	[IQEEEtRevenuAccumule_Recu_EtProjete] [float] NULL) ON [PRIMARY]
--insert into #Proj

CREATE PROCEDURE [dbo].[psCONV_ProjectionSubventionsEtLeurRendement] (
		@SubscriberID int = null
		,@BeneficiaryID int = null
		,@conventionNO varchar(30) = NULL -- '2025720'

	)
AS
BEGIN

--set @ConventionNo = 'R-20091203092'

/*
jtessier Jonathan Tessier added a comment - 2018-01-16 10:30 
Donald Huppe Pour les relevés 2017 : 
Taux d'intérêt 4,0%
 Taux d'intérêt annuel composé mensuellement 0,040741543
 Taux d'intérêt mensuel composé 0,00327374

*/

DECLARE @dtDateTo DATETIME = '2017-12-31'
DECLARE @dtDateDebutProjection DATETIME = '2018-01-01'
DECLARE @TauxMensuelCompose FLOAT = 0.00327374 -- Taux d'intérêt mensuel composé 
DECLARE @TauxAnnuelComposeMensuellement FLOAT = 0.040741543  --Taux d'intérêt annuel composé mensuellement

create table #conv (conventionid int)



--if @SubscriberID is not NULL OR @BeneficiaryID is NOT NULL or @ConventionNo is not null
--	BEGIN
--	insert into #conv
--	select DISTINCT c.ConventionID
--	from Un_Convention c
--	where c.SubscriberID in (
--		select DISTINCT SubscriberID
--		from Un_Convention c1
--		where  
--			(c1.SubscriberID = @SubscriberID or @SubscriberID is null) 
--			AND (c1.BeneficiaryID = @BeneficiaryID or @BeneficiaryID is null)  
--			AND (c1.ConventionNo = @ConventionNo or @ConventionNo is null)	
--		)
--	END


if @SubscriberID is not NULL OR @BeneficiaryID is NOT NULL or @ConventionNo is not null
	BEGIN
	insert into #conv
	select DISTINCT c.ConventionID
	from Un_Convention c
	where c.SubscriberID in (
		select DISTINCT SubscriberID
		from Un_Convention c1
		where  

			-- demande par souscripteur : on va chercher toutes les convention des benef de ce souscripteur: pour le calcul de excedent36k
			(c1.BeneficiaryID in (select BeneficiaryID from Un_Convention where SubscriberID = @SubscriberID )
			
				or @SubscriberID is null
			) 

			-- demande par benef
			AND (c1.BeneficiaryID = @BeneficiaryID 
				or @BeneficiaryID is null
			)  
			
			-- demande par convention : on va chercher toutes les convention du benef de cette convention : pour le calcul de excedent36k
			AND (
				c1.BeneficiaryID in (select BeneficiaryID from Un_Convention where ConventionNo = @ConventionNo )
				or @ConventionNo is null
			)	
		)
	END

--select * from #conv

print '00000000 1'

if @SubscriberID = 1
begin
-- Lsite de conventions demandées par jf Pak
INSERT into #conv (ConventionID) select DISTINCT ConventionID from Un_Convention where ConventionNo in (
'U-20090811004','1572000','C-20010718052','R-20090317020','X-20141205017','I-20140110004','C-19991025019','R-20061220033','T-20130501741','U-20060106022','X-20130204020','C-20010109044','I-20121102011','2032122','I-20141112002','R-20090625063','U-20100923012','R-20070918072','X-20120221088','R-20081104042','T-20120915872','T-201211011912','U-20130925005','X-20130308038','2065072',
'C-20000518032','I-20120223005','2163737','C-19990914092','F-20011214007','R-20020516002','T-201405011155','U-20011210048','X-20110519080','929703','','2156939','C-19990913077','E-19991006001','R-20020326008','R-20020603005','U-20140926004','X-20100126038','R-20080410053','','2167027',
'C-19990909025','I-20121204001','R-20050315017','R-20090902022','T-20110501722','T-201405011700','U-20011003046','U-20100721005','X-20100302038','','X-20140224037','X-20140319033','U-20050921003','X-20141210027','U-20040520017','X-20140401020','R-20070501002','U-20081128028','U-20050921004','C-20000605041','R-20021009020','2028773','X-20140228024',
'','','X-20120823048','R-20081001090','U-20140926004','X-20141215098','1586414','C-19991022034','R-20050110002','R-20070920077','X-20121219004','R-20081023015','R-20090908008','U-20100629006','U-20110418005','X-20100824058','U-20031215001','I-20130125001','R-20051130041',
'T-20131101089','X-20100831044','R-20080820037','U-20061220048','X-20111116087','2018808','R-20070926085','R-20080820037','U-20061220048','X-20110104003','2018808','C-20010711038','R-20080424014','R-20080820037','C-20011003005','U-20030707018','R-20040428020','U-20010911002','R-20080424014','X-20110527029','U-20071025068'
)


UNION

select DISTINCT ConventionID from Un_Convention where BeneficiaryID in (

237506	,243555	,258593	,259183	,259570	,259766	,262625	,263509	,263795	,266792	,268558	,275413	,276078	,277219	,277300	,278142	,278512	,279253	,279791	,283165	,284308	,284342	,284800	,288688	,289579	,295055	,295211	,295313	,296521	,
296777	,297594	,300536	,300734	,301875	,378687	,381557	,382574	,388735	,397756	,400135	,402418	,416486	,417847	,419183	,432153	,434581	,447242	,447244	,452354	,454625	,481328	,482564	,490274	,490986	,502313	,502313	,506060	,520701	,522126	,
522291	,526900	,532412	,536847	,538952	,540189	,543047	,551943	,552214	,555802	,561768	,564336	,565428	,588661	,590372	,593316	,593775	,595323	,601618	,603863	,614352	,614883	,629083	,631366	,652371	,663543	,666281	,669044	,684627	,691161	,692192	,696098	,697812	,697877	,698807	,699439	,703547	,717856	,718209	
)

end

if @SubscriberID = 2
begin
	INSERT into #conv (ConventionID)  
	select DISTINCT ConventionID 
	from Un_Convention c
	join Excedent36k k on c.BeneficiaryID = k.BeneficiaryID
end

create INDEX #Indconv on #conv(ConventionID)

--select * from #conv
--RETURN

print '00000000 2'

	select
		c.BeneficiaryID
		,c.ConventionID
		,u.UnitID

		,MontantSouscritUnite = --2016-02-11
				cast(
					case 
					when P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
					else m.PmtQty * round(  
											(
											m.PmtRate 
												*	(
													-- Dans le cas de convention TRI il y a un TerminatedDate,mais il reste 1 unité mais le montant souscrit devrait être 0 car il N'y a plus de cotisation dans le contrat
													case when isnull(u.TerminatedDate,'9999-12-31') > @dtDateTo then u.UnitQty + ISNULL(ur.UnitQtyRES,0)
													else 0
													end
													)
											) 
										,2) + U.SubscribeAmountAjustment
					end
				as money)

		,MontantSouscrit =
			CASE 
			WHEN rio_rim_COL.iID_Convention_Source is null and rio_rim_IND.iID_Convention_Destination is NULL then -- Pour les convention COL et IND avec RIO, on inscrit le montant souscrit à 0
										cast(
										case 
										when P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
										else m.PmtQty * round(  
																(
																m.PmtRate 
																	*	(
																		-- Dans le cas de convention TRI il y a un TerminatedDate,mais il reste 1 unité mais le montant souscrit devrait être 0 car il N'y a plus de cotisation dans le contrat
																		case when isnull(u.TerminatedDate,'9999-12-31') > @dtDateTo then u.UnitQty + ISNULL(ur.UnitQtyRES,0)
																		else 0
																		end
																		)
																) 
															,2) + U.SubscribeAmountAjustment
										end
									as money)
			ELSE 0
			END

		,MontantSouscritEPG =
			CASE when UnitStateID in ('EPG','TRA') /*2016-02-24*/ then

				CASE 
				WHEN rio_rim_COL.iID_Convention_Source is null and rio_rim_IND.iID_Convention_Destination is NULL then -- Pour les convention COL et IND avec RIO, on inscrit le montant souscrit à 0
											cast(
											case 
											when P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
											else m.PmtQty * round(  
																	(
																	m.PmtRate 
																		*	(
																			-- Dans le cas de convention TRI il y a un TerminatedDate,mais il reste 1 unité mais le montant souscrit devrait être 0 car il N'y a plus de cotisation dans le contrat
																			case when isnull(u.TerminatedDate,'9999-12-31') > @dtDateTo then u.UnitQty + ISNULL(ur.UnitQtyRES,0)
																			else 0
																			end
																			)
																	) 
																,2) + U.SubscribeAmountAjustment
											end
										as money)
				ELSE 0
				END

			ELSE 0
			END


		,MontantSouscritANNUEL_EPG =
			CASE when UnitStateID in ('EPG','TRA') /*2016-02-24*/ and m.PmtByYearID = 1 and m.PmtQty > 1 then

				CASE 
				WHEN rio_rim_COL.iID_Convention_Source is null and rio_rim_IND.iID_Convention_Destination is NULL then -- Pour les convention COL et IND avec RIO, on inscrit le montant souscrit à 0
											cast(
											case 
											when P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
											else m.PmtQty * round(  
																	(
																	m.PmtRate 
																		*	(
																			-- Dans le cas de convention TRI il y a un TerminatedDate,mais il reste 1 unité mais le montant souscrit devrait être 0 car il N'y a plus de cotisation dans le contrat
																			case when isnull(u.TerminatedDate,'9999-12-31') > @dtDateTo then u.UnitQty + ISNULL(ur.UnitQtyRES,0)
																			else 0
																			end
																			)
																	)
																,2) + U.SubscribeAmountAjustment 
											end
										as money)
				ELSE 0
				END

			ELSE 0
			END

		,MontantSouscritMENSUEL_EPG =
			CASE when UnitStateID in ('EPG','TRA') /*2016-02-24*/ and m.PmtByYearID = 12 then

				CASE 
				WHEN rio_rim_COL.iID_Convention_Source is null and rio_rim_IND.iID_Convention_Destination is NULL then -- Pour les convention COL et IND avec RIO, on inscrit le montant souscrit à 0
											cast(
											case 
											when P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
											else m.PmtQty * round(  
																	(
																	m.PmtRate 
																		*	(
																			-- Dans le cas de convention TRI il y a un TerminatedDate,mais il reste 1 unité mais le montant souscrit devrait être 0 car il N'y a plus de cotisation dans le contrat
																			case when isnull(u.TerminatedDate,'9999-12-31') > @dtDateTo then u.UnitQty + ISNULL(ur.UnitQtyRES,0)
																			else 0
																			end
																			)
																	)
																,2)  + U.SubscribeAmountAjustment
											end
										as money)
				ELSE 0
				END

			ELSE 0
			END

	into #MntSouscrit

	from Un_Unit u
	JOIN (
		select umh.UnitID, ModalID = max(umh.ModalID )
		from Un_UnitModalHistory umh
		join Un_Unit u on umh.UnitID = u.UnitID
		join Un_Convention c on u.ConventionID = c.ConventionID --and c.SubscriberID = 575993 
		--join #conv cv on c.ConventionID = cv.ConventionID
		where umh.StartDate = (
							select max(StartDate)
							from Un_UnitModalHistory umh2
							where umh.UnitID = umh2.UnitID
							and umh2.StartDate <= @dtDateTo --@dtDateTo
							)
		GROUP BY umh.UnitID
		)mh on mh.UnitID = u.UnitID
	JOIN Un_Modal M ON M.ModalID = mh.ModalID

	join (
		select 
			us.unitid,
			uus.startdate,
			us.UnitStateID,
			EtatGrUnite = st.UnitStateName
		from 
			Un_UnitunitState us
			join Un_UnitState st on st.UnitStateID = us.UnitStateID
			join (
				select 
				unitid,
				startdate = max(startDate)
				from un_unitunitstate
				where startDate < DATEADD(d,1 ,@dtDateTo)
				group by unitid
				) uus on uus.unitid = us.unitid 
					and uus.startdate = us.startdate 
					--and us.UnitStateID in ('epg')
		)uus on uus.UnitID = u.UnitID

	join Un_Convention c on u.ConventionID = c.ConventionID
	join Un_Plan p on c.PlanID = p.PlanID
	LEFT JOIN (
		SELECT 
			U2.UnitID,Cotisation = SUM(Ct.Cotisation)
		FROM 
			dbo.Un_Unit U2
			join Un_Convention c2 on u2.ConventionID = c2.ConventionID
			--join #conv cv on c2.ConventionID = cv.ConventionID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U2.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
		where o.OperDate <= @dtDateTo
		and o.OperTypeID <> 'RIN' -- 2016-02-24 ponderation
		GROUP BY 
			U2.UnitID
			) V1 ON V1.UnitID = U.UnitID
	join (
			select distinct BeneficiaryID
			from Un_Convention c1
			join #conv cv on c1.ConventionID = cv.ConventionID
		)b on b.BeneficiaryID = c.BeneficiaryID
	LEFT JOIN (SELECT UnitID, UnitQtyRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) ur ON ur.UnitID = u.UnitID

	LEFT JOIN (
		select DISTINCT r.iID_Convention_Source
		from tblOPER_OperationsRIO r
		join Un_Oper o on o.OperID = r.iID_Oper_RIO
		where r.bRIO_Annulee = 0
		and r.bRIO_QuiAnnule = 0
		and r.OperTypeID in ('RIO','RIM')
		and o.OperDate <= @dtDateTo
		)rio_rim_COL on rio_rim_COL.iID_Convention_Source = c.ConventionID

	LEFT JOIN (
		select DISTINCT r.iID_Convention_Destination
		from tblOPER_OperationsRIO r
		join Un_Oper o on o.OperID = r.iID_Oper_RIO
		where r.bRIO_Annulee = 0
		and r.bRIO_QuiAnnule = 0
		and r.OperTypeID in ('RIO','RIM')
		and o.OperDate <= @dtDateTo
		)rio_rim_IND on rio_rim_IND.iID_Convention_Destination = c.ConventionID

	WHERE u.dtFirstDeposit <= @dtDateTo -- les convention ouverte avant la date de fin


-----------------DÉBUT------------------------
--SELECT * from #MntSouscrit
--RETURN
print '00000000 3'

	select DISTINCT
		T1.*

		/*
		,PonderationAvecAutreConvention = 
			case 
			when MontantSouscritTotalBenef > 0
			then cast(MontantSouscrit as float)  /  cast(MontantSouscritTotalBenef as float) 
			else 0
			end
		*/

		,PonderationAvecAutreConvention = --2016-02-24 ponderation
			CASE
			WHEN MontantSouscritEPG > 0 and (MontantSouscritEPG = MontantSouscritEPGTotalBenef)
				then 1
			WHEN MontantSouscritEPGTotalBenef - CotisationFraisSoldeBenef_EPG <> 0
				THEN (MontantSouscritEPG - CotisationFraisSoldeUniteEPG) / (MontantSouscritEPGTotalBenef - CotisationFraisSoldeBenef_EPG)

			else 0
			end

		,SCEEaRecevoir = /* B */
			--round(
				CASE
				when T1.International = 'oui' then 0
				else
					case 
					when ModeCotisation = 'Mensuel' then
							case when CotisationEncaisseDecembreReleve * 0.2 > 500.0/12	then 500.0/12 else CotisationEncaisseDecembreReleve * 0.2 END
					else --when ModeCotisation = 'Annuel' then
							case when CotisationEncaisseDecembreReleve * 0.2 > 500		then 500	else CotisationEncaisseDecembreReleve * 0.2 END
					--else 0
					end
				end
			--,2)
		,IQEEaRecevoir = /* BB */
			--round(
				case 
				when T1.CAN_HorsQC = 'oui' or T1.International = 'oui' then 0
				else
					case when CotisationEncaisseAnneeReleve * 0.1 > 250.0		then 250.0	else CotisationEncaisseAnneeReleve * 0.1 END
				END
			--,2)	
															

	/*	
		,RevenuAccumuleSurSoldeRend /* U3 */ =
			case when T1.RevenuCotisationConv > 0 THEN 
				T1.RevenuCotisationConv *  
				(
					POWER	( 1 + @TauxAnnuelComposeMensuellement , 
								(
								CASE 
								WHEN  datediff(DAY,DateDebutProjection,DateFinProjection) > 0
									THEN datediff(DAY,DateDebutProjection,DateFinProjection) / 365.0
								ELSE 0
								END
								)  
					
					
							) 
					
				)
			else 0
			end
		*/
	INTO #Tempo1
	from (

		SELECT
			c.SubscriberID
			,u.unitid
			,Sousc = hs.LastName + ', ' + hs.FirstName
			,c.BeneficiaryID
			,Benef = hb.FirstName + ' ' + hb.LastName
		
			,c.ConventionNo
			,p.PlanDesc
			,QteUnite = u.UnitQty + ISNULL(ur.UnitQtyRES,0)
			,EtatGrUnite
		

							
			,ModeCotisation = CASE	
								WHEN m.PmtQty = 1 then 'Forfaitaire'
								WHEN m.PmtQty > 1 AND m.PmtByYearID = 12 then 'Mensuel'
								WHEN m.PmtQty > 1 AND m.PmtByYearID = 1 then 'Annuel'
								END
			,MontantCotisation = 
			round(
				case 
				when c.PlanID <> 4 then cast(m.PmtRate * (u.UnitQty + ISNULL(ur.UnitQtyRES,0)) as MONEY) 
				else 0 
				end
			,2)

			,MontantCotisationMensuelEPG = 
			round(
				case 
				when c.PlanID <> 4 and m.PmtByYearID = 12 and UnitStateID in ('EPG','TRA') /*2016-02-24*/ then cast(m.PmtRate * (u.UnitQty + ISNULL(ur.UnitQtyRES,0)) as MONEY) 
				else 0 
				end
			,2)

			,MontantCotisationAnnuelEPG = 
			round(
				case 
				when c.PlanID <> 4 and m.PmtQty > 1 AND m.PmtByYearID = 1 and UnitStateID in ('EPG','TRA') /*2016-02-24*/ then cast(m.PmtRate * (u.UnitQty + ISNULL(ur.UnitQtyRES,0)) as MONEY) 
				else 0 
				end
			,2)

			,CotisationFraisSoldeUnite /*= 
				case  -- S'il n'y a pas de solde (RI a eu lieu) alors on met le montant souscrit dans ce champs, pour éviter une division par 0
				when CotisationFraisSoldeUnite > 0 or c.PlanID = 4 then CotisationFraisSoldeUnite 
				else cast(m.PmtQty * m.PmtRate * (u.UnitQty + ISNULL(ur.UnitQtyRES,0)) as money) 
				end*/


			,MontantSouscrit = isnull(msu.MontantSouscrit,0)

			,RiVerse = case when isnull(u.IntReimbDate,'9999-12-31') <= @dtDateTo then 'oui'  else 'non' end
			,CAN_HorsQC = case when isnull(adrBen.vcProvince,'') <> 'QC' and isnull(adrben.vcPays,'') = 'Canada' then 'Oui' else 'non' end
			,International = case when isnull(adrben.vcPays,'') <> 'Canada' then 'Oui' else 'non' end
			,CotisationEncaisseDecembreReleve = isnull(CotisationEncaisseDecembreReleve,0)
			,CotisationEncaisseAnneeReleve = isnull(CotisationEncaisseAnneeReleve,0)

			,SCEECot = isnull(SCEECot,0)
			,SCEEPlusCot =  isnull(SCEEPlusCot,0)
			,BECCot = isnull(BECCot,0)
												
			,RevenuSCEEConv = isnull(RevenuSCEEConv,0)
			,RevenuCotisationConv = isnull(RevenuCotisationConv,0)
			,IQEEConv = isnull(IQEEConv,0)
			,IQEEPlusConv = isnull(IQEEPlusConv,0)
			,RevenuIQEEConv = isnull(RevenuIQEEConv,0)


			,SCEEUnite =  isnull(SCEECot,0)
			,SCEEPlusUnite =  isnull(SCEEPlusCot,0)
			,BECUnite = isnull(BECCot,0)

			,SCEEConv
			,SCEEPlusConv
			,BECConv

			,BirthDate = cast(hb.BirthDate as date)
			,DateDebutOperationFinanciere = cast(u.InForceDate as date)
			,DateDernierDepot
			,DateDebutProjection = cast(@dtDateDebutProjection as DATE)

			,DateFinProjection = cast(	
									CASE 
									WHEN C.PlanID <> 4 THEN 
											case	
											when CAST(cast(c.YearQualif as VARCHAR)+ '-07-01' AS DATE) >	dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust)
													THEN CAST(cast(c.YearQualif as VARCHAR)+ '-07-01' AS DATE)
											else dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust)
											end
									ELSE  dateadd(YEAR,17,hb.BirthDate) -- CAST ( CAST(YEAR(hb.BirthDate)+ 17 AS VARCHAR) + '-12-31' AS DATE)
									END
									as DATE)
			,FIN = '---------- ' --Fin du dataset de départ dans Excel
			,DateFinCotisationSubventionnee =  cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE) -----
			,DateEncaissSCEEaRecevoir = cast( dateadd(DAY,-1, DATEADD(MONTH,2, @dtDateDebutProjection)) as DATE)
			,DateEncaissIQEEaRecevoir =  cast( cast( YEAR(@dtDateDebutProjection) as VARCHAR) + '-05-15' as DATE)

			,DateEncaissDerniereCotisSCEE = 
									case -- Si la [date encaiss dern cotis SCEE] est avant le dernier alors c'est la [date encaiss dern cotis SCEE] + 1 mois
									when cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE) < DateDernierDepot 
											then cast(
														cast( year(		cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE)						)/*year*/		as VARCHAR) + '-' +
														cast( month(	DATEADD(MONTH,1,cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE))	)/*month*/		as VARCHAR) + '-' +

														case 
														-- Si en février et jour plus grand que 28 alors on force 28
														when month(	DATEADD(MONTH,1,cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE))	) = 2 and day(DateDernierDepot) > 28 then '28'
														else 
															cast( day(		DateDernierDepot)																						as VARCHAR)
														end

												as DATE)
										-- sinon, c'est DateDernierDepot + 2 mois
									else DATEADD(MONTH,2,DateDernierDepot) --cast(DATEADD(MONTH,2,DateDernierDepot)as DATE)
									end														

			,DateEncaissDerniereCotisIQEE =
				case 
				when DateDernierDepot < (cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE)) THEN
							cast(	
								cast(
									year(
										DateDernierDepot
										) + 1
									as VARCHAR
									) + '-05-15'
									as DATE
								)
				else
							cast(	
								cast(
									year(
										(cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE))
										) /*+ 1*/
									as VARCHAR
									) + '-05-15'
									as DATE
								)

				end
			,MontantSouscritConv = isnull(MontantSouscritConv,0)
			,CotisationFraisSoldeCONV = 
				case -- S'il n'y a pas de solde (RI a eu lieu) alors on met le montant souscrit dans ce champs, pour éviter une division par 0
				when CotisationFraisSoldeCONV > 0 then CotisationFraisSoldeCONV 
				else msc.MontantSouscritUniteConv --MontantSouscritConv  --2016-02-11
				end
			,MontantSouscritTotalBenef = isnull(MontantSouscritTotalBenef,0)
			,adrBen.vcProvince
			,adrBen.vcPays


			,MontantSouscritEPG = isnull(MontantSouscritEPG,0)
			,MontantSouscritEPGConv = isnull(MontantSouscritEPGConv,0)
			,MontantSouscritEPGTotalBenef = isnull(MontantSouscritEPGTotalBenef,0)

			,MontantSouscritMENSUEL_EPGBenef = isnull(MontantSouscritMENSUEL_EPGBenef,0)
			,MontantSouscritANNUEL_EPGBenef = isnull(MontantSouscritANNUEL_EPGBenef,0)
			,CotisationFraisSoldeANNUELBenef_EPG = ISNULL(CotisationFraisSoldeANNUELBenef_EPG,0)
			,CotisationFraisSoldeMENSUELBenef_EPG = ISNULL(CotisationFraisSoldeMENSUELBenef_EPG,0)


			,CotisationFraisSoldeBenef_EPG = isnull(CotisationFraisSoldeBenef_EPG,0)
			,CotisationFraisSoldeCONV_EPG = ISNULL(CotisationFraisSoldeCONV_EPG,0)
			,CotisationFraisSoldeUniteEPG = isnull(CotisationFraisSoldeUniteEPG,0)
			,QteGrUnitetotalConv --2016-02-18

		FROM 
			Un_Convention c
			join #conv cv on c.ConventionID = cv.ConventionID
			JOIN Un_Plan p ON c.PlanID = p.PlanID
			join Mo_Human HB on c.BeneficiaryID = hb.HumanID
			join Mo_Human HS on c.SubscriberID = HS.HumanID
			JOIN Un_Unit U ON c.ConventionID = U.ConventionID
			join (
				select 
					us.unitid,
					uus.startdate,
					us.UnitStateID,
					EtatGrUnite = st.UnitStateName
				from 
					Un_UnitunitState us
					join Un_Unit u on us.UnitID = u.UnitID
					join #conv cv on u.ConventionID = cv.ConventionID
					join Un_UnitState st on st.UnitStateID = us.UnitStateID
					join (
						select 
						unitid,
						startdate = max(startDate)
						from un_unitunitstate
						where startDate < DATEADD(d,1 ,@dtDateTo)
						group by unitid
						) uus on uus.unitid = us.unitid 
							and uus.startdate = us.startdate 
							--and us.UnitStateID in ('epg')
				)uus on uus.UnitID = u.UnitID
			JOIN ( -- modalité active en date du
					select umh.UnitID, ModalID = max(umh.ModalID)
					from Un_UnitModalHistory umh
					join Un_Unit u on umh.UnitID = u.UnitID
					join Un_Convention c on u.ConventionID = c.ConventionID --and c.SubscriberID = @SubscriberID 
					join #conv cv on c.ConventionID = cv.ConventionID
					where umh.StartDate = (
										select max(StartDate)
										from Un_UnitModalHistory umh2
										where umh.UnitID = umh2.UnitID
										and umh2.StartDate <= @dtDateTo
										)
					GROUP BY umh.UnitID

				)mh on mh.UnitID = u.UnitID
			JOIN Un_Modal m on m.ModalID = mh.ModalID
			LEFT JOIN (SELECT UnitID, UnitQtyRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) ur ON ur.UnitID = u.UnitID

			left join (
				select DISTINCT 
					unitid
					,MontantSouscrit 
					,MontantSouscritEPG
					from #MntSouscrit
				)msu on u.UnitID = msu.unitid

			left join (
				select 
					ConventionID
					,MontantSouscritUniteConv = sum(MontantSouscritUnite) --2016-02-11
					,MontantSouscritConv = sum(MontantSouscrit) 
					,MontantSouscritEPGConv = sum(MontantSouscritEPG)
					,MontantSouscritMENSUEL_EPG = SUM(MontantSouscritMENSUEL_EPG)
					,MontantSouscritANNUEL_EPG = SUM(MontantSouscritANNUEL_EPG)
					from #MntSouscrit 
					GROUP BY ConventionID
				)msc on u.ConventionID = msc.ConventionID

			left join (
				select 
					BeneficiaryID
					,MontantSouscritTotalBenef = sum(MontantSouscrit) 
					,MontantSouscritEPGTotalBenef = sum(MontantSouscritEPG)
					,MontantSouscritMENSUEL_EPGBenef = SUM(MontantSouscritMENSUEL_EPG)
					,MontantSouscritANNUEL_EPGBenef = SUM(MontantSouscritANNUEL_EPG)
					from #MntSouscrit 
					GROUP BY BeneficiaryID
				)mst on mst.BeneficiaryID = c.BeneficiaryID

			JOIN ( -- 2016-02-18
				select 
					c.ConventionID
					,QteGrUnitetotalConv = count(distinct u.UnitID)
				from Un_Unit u
				join Un_Convention c on u.ConventionID = c.ConventionID
				join #conv cv on c.ConventionID = cv.ConventionID
				LEFT JOIN (SELECT UnitID, UnitQtyRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) ur ON ur.UnitID = u.UnitID
				where u.UnitQty + isnull(ur.UnitQtyRES,0) > 0
				GROUP by c.ConventionID
				)qg on qg.ConventionID = u.ConventionID

			JOIN (
				select DISTINCT
					u.UnitID
					,DateDernierDepot =
						cast(
							CASE 
							WHEN ISNULL(U.LastDepositForDoc,0) <= 0 THEN dbo.fn_Un_LastDepositDate(U.InForceDate,C.FirstPmtDate,M.PmtQty,M.PmtByYearID)
							ELSE U.LastDepositForDoc
							END
							as date)
				from Un_Unit u
				JOIN ( -- modalité active en date du
						select umh.UnitID, ModalID = max(umh.ModalID)
						from Un_UnitModalHistory umh
						join Un_Unit u on umh.UnitID = u.UnitID
						join Un_Convention c on u.ConventionID = c.ConventionID --and c.SubscriberID = @SubscriberID 
						join #conv cv on c.ConventionID = cv.ConventionID
						where umh.StartDate = (
											select max(StartDate)
											from Un_UnitModalHistory umh2
											where umh.UnitID = umh2.UnitID
											and umh2.StartDate <= @dtDateTo
											)
						GROUP BY umh.UnitID

					)mh on mh.UnitID = u.UnitID
				JOIN Un_Modal m on m.ModalID = mh.ModalID
				join Un_Convention c on u.ConventionID = c.ConventionID
				join #conv cv on c.ConventionID = cv.ConventionID
				LEFT JOIN (SELECT UnitID, UnitQtyRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) ur ON ur.UnitID = u.UnitID
				)dd on dd.UnitID = u.UnitID

			LEFT JOIN (
				SELECT 
					u.ConventionID, 
					CotisationFraisSoldeCONV = sum(ct.Cotisation + ct.Fee),
					CotisationFraisSoldeCONV_EPG = sum( case when UnitStateID in ('EPG','TRA') /*2016-02-24*/ then ct.Cotisation + ct.Fee else 0 end)
				FROM Un_Cotisation ct
				join Un_Unit u on ct.UnitID = u.UnitID
				join (
					select 
						us.unitid,
						uus.startdate,
						us.UnitStateID,
						EtatGrUnite = st.UnitStateName
					from 
						Un_UnitunitState us
						join Un_Unit u on us.UnitID = u.UnitID
						join #conv cv on u.ConventionID = cv.ConventionID
						join Un_UnitState st on st.UnitStateID = us.UnitStateID
						join (
							select 
							unitid,
							startdate = max(startDate)
							from un_unitunitstate
							where startDate < DATEADD(d,1 ,@dtDateTo)
							group by unitid
							) uus on uus.unitid = us.unitid 
								and uus.startdate = us.startdate 
					)uus on uus.UnitID = u.UnitID
				join Un_Convention c on u.ConventionID = c.ConventionID
				join #conv cv on c.ConventionID = cv.ConventionID
				join Un_Oper o on ct.OperID = o.OperID  
				left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
				left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
				-- voir pour la gestion des cancellation APRÈS la date de fin (@dtDateTo)
				where 
					o.OperDate <= @dtDateTo
					and oc1.OperSourceID is NULL
					and oc2.OperID is NULL
				GROUP BY u.ConventionID
				)sc on u.ConventionID = sc.ConventionID

			LEFT JOIN (
				SELECT 
					c.BeneficiaryID, 
					CotisationFraisSoldeBenef_EPG = sum( --2016-02-23	
															case --2016-02-24
															when 
																UnitStateID in ('EPG','TRA') 
																and rio_rim_COL1.iID_Convention_Source is null 
																and rio_rim_IND1.iID_Convention_Destination is NULL 
																and (p.PlanTypeID <> 'IND'
																	or (
																		p.PlanTypeID = 'IND' and o.OperTypeID <> 'RIN' --2016-02-24 ponderation
																		)

																	)
																	then ct.Cotisation + case when p.PlanTypeID <> 'IND' then ct.Fee ELSE 0 end --2016-02-24 ponderation
															else 0 
															end
														)

					,CotisationFraisSoldeANNUELBenef_EPG = sum( --2016-02-23 

															case --2016-02-24
															when UnitStateID in ('EPG','TRA') AND M.PmtByYearID = 1 and M.PmtQty > 1 and rio_rim_COL1.iID_Convention_Source is null and rio_rim_IND1.iID_Convention_Destination is NULL 
																then ct.Cotisation + case when p.PlanTypeID <> 'IND' then ct.Fee ELSE 0 end --2016-02-24 ponderation
															else 0 
															end
															
															)
					,CotisationFraisSoldeMENSUELBenef_EPG = sum(  --2016-02-23 
															case --2016-02-24
															when UnitStateID in ('EPG','TRA') AND M.PmtByYearID = 12 and rio_rim_COL1.iID_Convention_Source is null and rio_rim_IND1.iID_Convention_Destination is NULL
																then ct.Cotisation + case when p.PlanTypeID <> 'IND' then ct.Fee ELSE 0 end --2016-02-24 ponderation
															else 0 
															end
															)

				FROM Un_Cotisation ct
				join Un_Unit u on ct.UnitID = u.UnitID
				JOIN ( -- modalité active en date du
						select umh.UnitID, ModalID = max(umh.ModalID)
						from Un_UnitModalHistory umh
						join Un_Unit u on umh.UnitID = u.UnitID
						join Un_Convention c on u.ConventionID = c.ConventionID --and c.SubscriberID = @SubscriberID 
						join #conv cv on c.ConventionID = cv.ConventionID
						where umh.StartDate = (
											select max(StartDate)
											from Un_UnitModalHistory umh2
											where umh.UnitID = umh2.UnitID
											and umh2.StartDate <= @dtDateTo
											)
						GROUP BY umh.UnitID

					)mh on mh.UnitID = u.UnitID
				JOIN Un_Modal m on m.ModalID = mh.ModalID
				join (
					select 
						us.unitid,
						uus.startdate,
						us.UnitStateID,
						EtatGrUnite = st.UnitStateName
					from 
						Un_UnitunitState us
						join Un_Unit u on us.UnitID = u.UnitID
						join #conv cv on u.ConventionID = cv.ConventionID
						join Un_UnitState st on st.UnitStateID = us.UnitStateID
						join (
							select 
							unitid,
							startdate = max(startDate)
							from un_unitunitstate
							where startDate < DATEADD(d,1 ,@dtDateTo)
							group by unitid
							) uus on uus.unitid = us.unitid 
								and uus.startdate = us.startdate 
					)uus on uus.UnitID = u.UnitID
				join Un_Convention c on u.ConventionID = c.ConventionID
				join Un_Plan p on c.PlanID = p.PlanID--2016-02-24 ponderation
				join (
					select c1.BeneficiaryID
					from Un_Convention c1
					join #conv cv on c1.ConventionID = cv.ConventionID
					group by c1.BeneficiaryID
					)b on b.BeneficiaryID = c.BeneficiaryID
				join Un_Oper o on ct.OperID = o.OperID  
				left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
				left join Un_OperCancelation oc2 on o.OperID = oc2.OperID

				LEFT JOIN (--2016-02-23
					select DISTINCT r.iID_Convention_Source
					from tblOPER_OperationsRIO r
					where r.bRIO_Annulee = 0
					and r.bRIO_QuiAnnule = 0
					and r.OperTypeID in ('RIO','RIM')
					)rio_rim_COL1 on rio_rim_COL1.iID_Convention_Source = c.ConventionID


				LEFT JOIN (--2016-02-23
					select DISTINCT r.iID_Convention_Destination
					from tblOPER_OperationsRIO r
					where r.bRIO_Annulee = 0
					and r.bRIO_QuiAnnule = 0
					and r.OperTypeID in ('RIO','RIM')
					)rio_rim_IND1 on rio_rim_IND1.iID_Convention_Destination = c.ConventionID

				-- voir pour la gestion des cancellation APRÈS la date de fin (@dtDateTo)
				where 
					o.OperDate <= @dtDateTo
					and oc1.OperSourceID is NULL
					and oc2.OperID is NULL
				GROUP BY c.BeneficiaryID
				)sb on c.BeneficiaryID = sb.BeneficiaryID

			LEFT JOIN (
				select DISTINCT r.iID_Convention_Source
				from tblOPER_OperationsRIO r
				where r.bRIO_Annulee = 0
				and r.bRIO_QuiAnnule = 0
				and r.OperTypeID in ('RIO','RIM')
				)rio_rim_COL on rio_rim_COL.iID_Convention_Source = c.ConventionID


			LEFT JOIN (
				select DISTINCT r.iID_Convention_Destination
				from tblOPER_OperationsRIO r
				where r.bRIO_Annulee = 0
				and r.bRIO_QuiAnnule = 0
				and r.OperTypeID in ('RIO','RIM')
				)rio_rim_IND on rio_rim_IND.iID_Convention_Destination = c.ConventionID

			LEFT JOIN (
				SELECT 
					u.UnitID, 
					CotisationFraisSoldeUnite = sum(ct.Cotisation + ct.Fee),
					CotisationFraisSoldeUniteEPG = sum( case when UnitStateID in ('EPG','TRA') /*2016-02-24*/ and rio_rim_COL.iID_Convention_Source is null and rio_rim_IND.iID_Convention_Destination is null then ct.Cotisation + case when p.PlanTypeID <> 'IND' then ct.Fee else 0 end else 0 end), --2016-02-23 --2016-02-24 ponderation
					CotisationEncaisseDecembreReleve = 
						
								sum(
									case 
									when 
										not(o.OperTypeID = 'TIN' and Ttin.iTINOperID is not null) -- exclure les TIN externe
										and not(o.OperTypeID = 'OUT' and Tout.iOUTOperID is not null)  -- exclute les OUT externe
										and o.OperTypeID <> 'TFR' --exclure les TFR
										and o.OperDate BETWEEN dateadd(DAY,1, dateadd(MONTH,-1, @dtDateTo)) and @dtDateTo 
										and o.OperDate < cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE) -- JF Pak 2015-11-19 : Il faudrait afficher les données seulement si les cotisations ont été encaissées avant le 1 janvier des 18 ans du bénéficiaire.
											then ct.Cotisation + case when p.PlanTypeID <> 'IND' then ct.Fee else 0 end --2016-02-24 ponderation
									else 0 
									end
									)
						
					,CotisationEncaisseAnneeReleve = 
						
								sum(
									case 
									when 
										not(o.OperTypeID = 'TIN' and Ttin.iTINOperID is null)  -- exclure les TIN externe
										and not(o.OperTypeID = 'OUT' and Tout.iOUTOperID is null)   -- exclute les OUT externe
										and o.OperTypeID <> 'TFR' --exclure les TFR
										and o.OperDate BETWEEN dateadd(DAY,1, dateadd(YEAR,-1, @dtDateTo)) and @dtDateTo 
										and o.OperDate < cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE) -- JF Pak 2015-11-19 : Il faudrait afficher les données seulement si les cotisations ont été encaissées avant le 1 janvier des 18 ans du bénéficiaire.
											then ct.Cotisation + case when p.PlanTypeID <> 'IND' then ct.Fee else 0 end --2016-02-24 ponderation
									else 0 
									end
									)
						

				FROM Un_Cotisation ct
				join Un_Unit u on ct.UnitID = u.UnitID
				join (
					select 
						us.unitid,
						uus.startdate,
						us.UnitStateID,
						EtatGrUnite = st.UnitStateName
					from 
						Un_UnitunitState us
						join Un_Unit u on us.UnitID = u.UnitID
						join #conv cv on u.ConventionID = cv.ConventionID
						join Un_UnitState st on st.UnitStateID = us.UnitStateID
						join (
							select 
							unitid,
							startdate = max(startDate)
							from un_unitunitstate
							where startDate < DATEADD(d,1 ,@dtDateTo)
							group by unitid
							) uus on uus.unitid = us.unitid 
								and uus.startdate = us.startdate 
					)uus on uus.UnitID = u.UnitID

				JOIN ( -- modalité active en date du
						select umh.UnitID, ModalID = max(umh.ModalID)
						from Un_UnitModalHistory umh
						join Un_Unit u on umh.UnitID = u.UnitID
						join Un_Convention c on u.ConventionID = c.ConventionID --and c.SubscriberID = @SubscriberID 
						join #conv cv on c.ConventionID = cv.ConventionID
						where umh.StartDate = (
											select max(StartDate)
											from Un_UnitModalHistory umh2
											where umh.UnitID = umh2.UnitID
											and umh2.StartDate <= @dtDateTo
											)
						GROUP BY umh.UnitID

					)mh on mh.UnitID = u.UnitID
				JOIN Un_Modal m on m.ModalID = mh.ModalID
				join Un_Convention c on u.ConventionID = c.ConventionID
				join un_plan p on c.PlanID = p.PlanID --2016-02-24 ponderation
				join Mo_Human hb on c.BeneficiaryID = hb.HumanID
				join #conv cv on c.ConventionID = cv.ConventionID
				join Un_Oper o on ct.OperID = o.OperID  
				left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
				left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
				left join Un_TIO Ttin on o.OperID = Ttin.iOUTOperID
				left join un_tio Tout on o.OperID = Tout.iTINOperID
				LEFT JOIN (--2016-02-23
					select DISTINCT r.iID_Convention_Source
					from tblOPER_OperationsRIO r
					where r.bRIO_Annulee = 0
					and r.bRIO_QuiAnnule = 0
					and r.OperTypeID in ('RIO','RIM')
					)rio_rim_COL on rio_rim_COL.iID_Convention_Source = c.ConventionID


				LEFT JOIN (--2016-02-23
					select DISTINCT r.iID_Convention_Destination
					from tblOPER_OperationsRIO r
					where r.bRIO_Annulee = 0
					and r.bRIO_QuiAnnule = 0
					and r.OperTypeID in ('RIO','RIM')
					)rio_rim_IND on rio_rim_IND.iID_Convention_Destination = c.ConventionID
				-- voir pour la gestion des cancellation APRÈS la date de fin (@dtDateTo)
				where 
					o.OperDate <= @dtDateTo /*ici*/
					--and o.OperDate < cast( cast( YEAR(hb.BirthDate) + 18 as VARCHAR) + '-01-01' as DATE) -- JF Pak 2015-11-19 : Il faudrait afficher les données seulement si les cotisations ont été encaissées avant le 1 janvier des 18 ans du bénéficiaire.
					and (
						(c.PlanID <> 4 and o.OperTypeID not in ('RIN','RIO') ) -- exclure les remboursement dans le collectif
						OR
						(c.PlanID = 4 and o.OperTypeID not in ('RIN') ) -- exclure les remboursement dans l'individuel (on n'exclut pas le RIO car c'est un entréé d'argent)
						)
					and oc1.OperSourceID is NULL
					and oc2.OperID is NULL
				GROUP BY u.UnitID
													

				)su on u.UnitID = su.UnitID


			LEFT JOIN (
				select 
					u.UnitID,
					-- Calcul du solde de scee selon le ratio d'unité sur le total de la convention
					SCEECot = (u.UnitQty + ISNULL(UnitQtyRES,0)) / QteUniteConv * SCEEConv,
					SCEEPlusCot = (u.UnitQty + ISNULL(UnitQtyRES,0)) / QteUniteConv * SCEEPlusConv,
					BECCot = (u.UnitQty + ISNULL(UnitQtyRES,0)) / QteUniteConv * BECConv
					,SCEEConv
					,SCEEPlusConv
					,BECConv

				--into tblsct
				from Un_Unit u
				LEFT JOIN (SELECT UnitID, UnitQtyRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) ur ON ur.UnitID = u.UnitID
				join Un_Convention c on u.ConventionID = c.ConventionID
				join #conv cv on c.ConventionID = cv.ConventionID
				join (
					SELECT c.ConventionID,QteUniteConv = sum(u.UnitQty+ ISNULL(UnitQtyRES,0))
					FROM Un_Unit u
					LEFT JOIN (SELECT UnitID, UnitQtyRES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtDateTo GROUP BY UnitID) ur ON ur.UnitID = u.UnitID
					JOIN Un_Convention c on u.ConventionID = c.ConventionID
					JOIN #conv cv on c.ConventionID = cv.ConventionID
					WHERE u.dtFirstDeposit <= @dtDateTo /*2016-05-02*/
					GROUP by c.ConventionID
					)cu on c.ConventionID = cu.ConventionID
				join (
					SELECT 
						c.ConventionID,
						SCEEConv = SUM(CE.fCESG),
						SCEEPlusConv = SUM(CE.fACESG),
						BECConv = SUM(CE.fCLB)
					FROM Un_Convention c 
					join #conv cv on c.ConventionID = cv.ConventionID
					JOIN Un_CESP CE ON (CE.ConventionID = c.ConventionID)
					JOIN Un_Oper OP ON OP.OperID = CE.OperID 
					where OP.OperDate <= @dtDateTo
					GROUP by c.ConventionID
					)ce on ce.ConventionID = c.ConventionID
				where QteUniteConv > 0
				)sct on u.UnitID = sct.UnitID

			LEFT JOIN (
				SELECT 
					c.ConventionID,
					RevenuSCEEConv = SUM(CASE WHEN  co.ConventionOperTypeID in ('IBC','INS','IS+','IST') THEN co.ConventionOperAmount ELSE  0 END),
					RevenuCotisationConv = SUM(CASE WHEN  co.ConventionOperTypeID in ('ITR','INM') THEN co.ConventionOperAmount ELSE  0 END),
					IQEEConv = SUM(CASE WHEN  co.ConventionOperTypeID in ('CBQ') THEN co.ConventionOperAmount ELSE  0 END),
					IQEEPlusConv = SUM(CASE WHEN  co.ConventionOperTypeID in ('MMQ') THEN co.ConventionOperAmount ELSE  0 END),
					RevenuIQEEConv = SUM(CASE WHEN  co.ConventionOperTypeID in ('ICQ','III','IIQ','IMQ','MIM','IQI') THEN co.ConventionOperAmount ELSE  0 END)
				FROM 
					Un_Convention c
					join #conv cv on c.ConventionID = cv.ConventionID
					JOIN Un_ConventionOper co ON co.ConventionID = c.ConventionID
					JOIN un_oper o ON co.OperID = o.OperID
				WHERE 1=1
					--and ( ( c.SubscriberID = @SubscriberID or @SubscriberID is null) AND (c.BeneficiaryID = @BeneficiaryID or @BeneficiaryID is null)  )
					AND o.operdate <= @dtDateTo 
				GROUP BY
					c.ConventionID
				) RendEtIQEE on RendEtIQEE.ConventionID = c.ConventionID

			left join (
				select 
					iID_Adresse
					,iID_Source
					,cType_Source
					,iID_Type
					,dtDate_Debut
					,dtDate_Fin
					,iID_Province
					,vcProvince
					,cID_Pays
					,vcPays
				from tblGENE_AdresseHistorique a1
				join Un_Convention c on c.BeneficiaryID = a1.iID_Source
				join #conv cv on c.ConventionID = cv.ConventionID
				--where iID_Source = 575993
				--order by iID_Adresse desc 

				union all 

				select 
					iID_Adresse
					,iID_Source
					,cType_Source
					,iID_Type
					,dtDate_Debut
					,dtDate_Fin = '9999-12-31'
					,iID_Province
					,vcProvince
					,cID_Pays
					,vcPays
				from tblGENE_Adresse a2
				join Un_Convention c on c.BeneficiaryID = a2.iID_Source
				join #conv cv on c.ConventionID = cv.ConventionID
				--where iID_Source = 575993
				--order by iID_Adresse desc 

				) adrBen on adrben.iID_Source = c.BeneficiaryID and @dtDateTo BETWEEN adrben.dtDate_Debut and adrben.dtDate_Fin


		where 1=1
		--and isnull(u.TerminatedDate,'9999-12-31') > @dtDateTo --msc.MontantSouscritConv <> 0
		and u.dtFirstDeposit <= @dtDateTo
	)T1	



-----------------FIN-----------------------------------------------
/*
SCEEUnite	SCEEPlusUnite
586,20	232,50

exec psCONV_ProjectionSubventionsEtLeurRendement 1, null   , NULL

*/
/*
select *
from #Tempo1
RETURN
*/
print '00000000 4'

select 
       BeneficiaryID
       ,ExcedentDe36k = -- 2016-02-23
       (

             (
                    CASE 
                           WHEN sum(MontantCotisationAnnuelEPG) = 0 THEN 0
                           ELSE
                                  (MontantSouscritANNUEL_EPGBenef - CotisationFraisSoldeANNUELBenef_EPG) 
                                  / sum(MontantCotisationAnnuelEPG)
                                  * sum(MontantCotisationAnnuelEPG) *0.20


                    END
             )

             +
             
             (
                    CASE 
                           WHEN sum(MontantCotisationMensuelEPG) = 0 THEN 0
                           ELSE
                                  (MontantSouscritMENSUEL_EPGBenef - CotisationFraisSoldeMENSUELBenef_EPG) 
                                  / sum(MontantCotisationMensuelEPG)
                                  * sum(MontantCotisationMensuelEPG) * 0.20


                    END
             )

             + sum(isnull(SCEEUnite,0)) + sum(isnull(SCEEPlusUnite,0)) + /*2016-03-22*/ sum(isnull(SCEEaRecevoir ,0))/**/  - 7200
       )
       / 0.20


into #tExcedent36k
from #Tempo1
group by BeneficiaryID,MontantSouscritTotalBenef
		,MontantSouscritMENSUEL_EPGBenef
		,MontantSouscritANNUEL_EPGBenef
		,CotisationFraisSoldeANNUELBenef_EPG
		,CotisationFraisSoldeMENSUELBenef_EPG

delete from #tExcedent36k where ExcedentDe36k <= 0
--select * from #tExcedent36k
--RETURN
--exec psCONV_ProjectionSubventionsEtLeurRendement 1, NULL, NULL

print '00000000 5'

select 
	T1.*
	,ExcedentDe36k = isnull(ExcedentDe36k,0)
	,DiminutionProjectionPourPasDepasserPlafondAvie = /* A1 */ 
	round( PonderationAvecAutreConvention * isnull(ExcedentDe36k,0)
	/*
		case when MontantSouscritTotalBenef - 36000.0 > 0  AND MontantSouscritTotalBenef > 0 then
			(	PonderationAvecAutreConvention * ExcedentDe36k	) 

		else 0
		end
	*/
	,2)

	,IQEEDiminutionProjectionPourPasDepasserPlafondAvie /* AA */ = PonderationAvecAutreConvention * isnull(ExcedentDe36k,0)
	/*
		case when MontantSouscritTotalBenef - 36000.0 > 0  AND MontantSouscritTotalBenef > 0 then
			(	PonderationAvecAutreConvention * ExcedentDe36k	) 
		else 0
		end
		*/
into #tempo2
from #Tempo1 T1
left join #tExcedent36k t36k on t36k.BeneficiaryID = T1.BeneficiaryID

--select * from #tempo2

print '00000000 6'

select DISTINCT
	T2.*
	,TotalSCEEEtRend = cast(isnull(SCEECot,0) +  isnull(SCEEPlusCot,0) + isnull(BECCot,0) as real) 
				+	( 
					cast(RevenuSCEEConv as real)  
							*	case 
								when (QteGrUnitetotalConv = 1 or CotisationFraisSoldeCONV = 0) AND QteUnite > 0 then 1 --2016-02-18 
								when QteUnite <= 0 then 0--2016-03-23
								else (cast(CotisationFraisSoldeUnite as real)  / cast(CotisationFraisSoldeCONV as real)) 
								end
					)

	,RendSCEEUnite = cast(RevenuSCEEConv as real)  
							*	case 
								when (QteGrUnitetotalConv = 1 or CotisationFraisSoldeCONV = 0) AND QteUnite > 0 then 1  --2016-02-18 -- Si la convention a un seul groupe d'unité actif, on ne fait pas le ratio. ça cause certain problème dans les individuel.
								when QteUnite <= 0 then 0--2016-03-23
								else (cast(CotisationFraisSoldeUnite as real)  / cast(CotisationFraisSoldeCONV as real)) 
								end
	,RevenuCotisationUnite = cast(RevenuCotisationConv as real)  
							*	case 
								when (QteGrUnitetotalConv = 1 or CotisationFraisSoldeCONV = 0) AND QteUnite > 0 then 1  --2016-02-18
								when QteUnite <= 0 then 0--2016-03-23
								else (cast(CotisationFraisSoldeUnite as real)  / cast(CotisationFraisSoldeCONV as real)) 
								end
	,IQEEEtRevenuUnite = cast((isnull(IQEEConv,0) + isnull(IQEEPlusConv,0) + isnull(RevenuIQEEConv,0)) as real) 
							*	case 
								when (QteGrUnitetotalConv = 1 or CotisationFraisSoldeCONV = 0) AND QteUnite > 0 then 1  --2016-02-18
								when QteUnite <= 0 then 0--2016-03-23
								else (cast(CotisationFraisSoldeUnite as real)  / cast(CotisationFraisSoldeCONV as real)) 
								end
	,IQEEUnite = cast(isnull(IQEEConv,0)as real) 
							*	case 
								when (QteGrUnitetotalConv = 1 or CotisationFraisSoldeCONV = 0) AND QteUnite > 0 then 1  --2016-02-18
								when QteUnite <= 0 then 0--2016-03-23
								else (cast(CotisationFraisSoldeUnite as real)  / cast(CotisationFraisSoldeCONV as real)) 
								end
	,IQEEPlusUnite = cast(isnull(IQEEPlusConv,0)as real) 
							*	case 
								when (QteGrUnitetotalConv = 1 or CotisationFraisSoldeCONV = 0) AND QteUnite > 0 then 1  --2016-02-18
								when QteUnite <= 0 then 0--2016-03-23
								else (cast(CotisationFraisSoldeUnite as real)  / cast(CotisationFraisSoldeCONV as real)) 
								end
	,RevenuIQEEUnite = cast(isnull(RevenuIQEEConv,0)as real) 
							*	case 
								when (QteGrUnitetotalConv = 1 or CotisationFraisSoldeCONV = 0) AND QteUnite > 0 then 1  --2016-02-18
								when QteUnite <= 0 then 0--2016-03-23
								else (cast(CotisationFraisSoldeUnite as real)  / cast(CotisationFraisSoldeCONV as real)) 
								end

	,SCEEperiodiqueAuContratSansDepasserPlafondAnnuel = /* C */
		round(
			CASE 
			WHEN T2.International = 'oui' then 0 
			ELSE
				case 
				when ModeCotisation = 'Mensuel' then
						case when MontantCotisation * 0.2 > 500.0/12		then 500.0/12	else MontantCotisation * 0.2 END
				when ModeCotisation = 'Annuel' then
						case when MontantCotisation * 0.2 > 500				then 500		else MontantCotisation * 0.2 END
				else 0
				end
			END
		,2)

/*
	,NbPeriodes_De_DateProchCot_A_DernCot = /* H */
			case
			when CotisationFraisSoldeUnite < MontantSouscrit then
					CASE
					when RiVerse = 'non' then 
						CASE 
						when /*MontantSouscrit = 0 and CotisationFraisSoldeUnite = 0 and*/ MontantCotisation = 0 then 0
						else (MontantSouscrit - CotisationFraisSoldeUnite - DiminutionProjectionPourPasDepasserPlafondAvie) / MontantCotisation
						end
					else 0
					end
			else 0
			end
*/

	,NbPeriodes_De_DateProchCot_A_DernCot = /* H */
			case
			when CotisationFraisSoldeUnite > MontantSouscrit or RiVerse = 'oui' or MontantCotisation = 0 then 0

			else
				CASE 
				when		(
							(MontantSouscrit - CotisationFraisSoldeUnite - DiminutionProjectionPourPasDepasserPlafondAvie) / MontantCotisation
							) > 0 
					then	(MontantSouscrit - CotisationFraisSoldeUnite - DiminutionProjectionPourPasDepasserPlafondAvie) / MontantCotisation
				else 0
				end


			end


	,IQEE_NbAnnee_De_DateProchCot_A_DernCot /* HH */ =
		cast(
			case 
			when CotisationFraisSoldeUnite > MontantSouscrit or RiVerse = 'oui' or MontantCotisation = 0 then 0

			else
				case 
					when	(
							(MontantSouscrit - CotisationFraisSoldeUnite - IQEEDiminutionProjectionPourPasDepasserPlafondAvie) / (MontantCotisation * (case when ModeCotisation = 'Mensuel' then 12.0 else 1.0 end) )
							) > 0  
						then 
							(MontantSouscrit - CotisationFraisSoldeUnite - IQEEDiminutionProjectionPourPasDepasserPlafondAvie) / (MontantCotisation * (case when ModeCotisation = 'Mensuel' then 12.0 else 1.0 end) )
					ELSE 0
				END

			
			end
		as FLOAT)


	,NbAnneeDeDateDebutProjection_A_FinProjection /* F */ = 
		--ROUND(
			case
			when datediff(DAY, @dtDateDebutProjection, DateFinProjection) / 365.0 < 0 then 0 
			ELSE datediff(DAY, @dtDateDebutProjection, DateFinProjection) / 365.0 
			END
		--,2)

	,IQEE_NbAnneeDeDateDebutProjection_A_FinProjection /* FF */ = 
		--ROUND(
			case
			when datediff(DAY, @dtDateDebutProjection, DateFinProjection) / 365.0 < 0 then 0 
			ELSE datediff(DAY, @dtDateDebutProjection, DateFinProjection) / 365.0 
			END
		--,2)

	,NbAnneeDeDateEncaissPrevuSCEEaRecevoir_A_FinProjection /* G */ = 
		--ROUND(
			case
			when datediff(DAY, DateEncaissSCEEaRecevoir, DateFinProjection) / 365.0 < 0 then 0
			ELSE datediff(DAY, DateEncaissSCEEaRecevoir, DateFinProjection) / 365.0 
			END
		--,2)


	,IQEE_NbAnneeDeDateEncaissPrevuIQEEaRecevoir_A_FinProjection /* GG */ = 
		--ROUND(
			case
			when datediff(DAY, DateEncaissIQEEaRecevoir, DateFinProjection) / 365.0 < 0 then 0
			ELSE datediff(DAY, DateEncaissIQEEaRecevoir, DateFinProjection) / 365.0 
			END
		--,2)

	,NbAnneeDeDateDernCot_A_FinProjection /* L */  = 
											
			case 
			when datediff(DAY, DateEncaissDerniereCotisSCEE, DateFinProjection) / 365.0 < 0 then 0
			else datediff(DAY, DateEncaissDerniereCotisSCEE ,DateFinProjection) / 365.0
			end

	,IQEE_NbAnneeDeDateDernCot_A_FinProjection /* LL */  = 
		--round(
			case 
			when datediff(DAY, DateEncaissDerniereCotisIQEE, DateFinProjection ) / 365.0 < 0 then 0
			else datediff(DAY, DateEncaissDerniereCotisIQEE, DateFinProjection ) / 365.0
			end
		--,2)
									

	,IQEEperiodiqueAuContratSansDepasserPlafondAnnuel = /* CC */
		round(
			CASE 
			WHEN T2.CAN_HorsQC = 'oui' or T2.International = 'oui' then 0
			ELSE
				case 
				when ModeCotisation = 'Mensuel' then
						case when MontantCotisation * 0.1 > 250/12.0	then 250.0/12	else MontantCotisation * 0.1 END
				when ModeCotisation = 'Annuel' then
						case when MontantCotisation * 0.1 > 250			then 250.0		else MontantCotisation * 0.1 END
				else 0
				end
			END
		,2)

INTO #DATASET

from #tempo2 T2


--select * from #dataset
--return

print '00000000 7'
	
select 

	V12.SubscriberID
	,V12.Sousc
	,V12.BeneficiaryID
	,V12.Benef
	,V12.ConventionNo
	,V12.PlanDesc
	,QteUnite = isnull(V12.QteUnite,0)
	,V12.EtatGrUnite
	,ModeCotisation = isnull(V12.ModeCotisation,'')
	,MontantCotisation = isnull(V12.MontantCotisation,0)
	,CotisationFraisSoldeUnite = isnull(V12.CotisationFraisSoldeUnite,0 )
	,MontantSouscrit = isnull(V12.MontantSouscrit,0)
	,PonderationAvecAutreConvention = isnull(v12.PonderationAvecAutreConvention,0)
	,ExcedentDe36k = isnull(v12.ExcedentDe36k,0)
	,V12.RiVerse

	,V12.CAN_HorsQC
	,V12.International

	,CotisationEncaisseDecembreReleve = ISNULL(V12.CotisationEncaisseDecembreReleve,0)
	,CotisationEncaisseAnneeReleve = ISNULL(V12.CotisationEncaisseAnneeReleve,0)
	,TotalSCEEEtRend = ISNULL(V12.TotalSCEEEtRend,0)
	,SCEEUnite = ISNULL(V12.SCEEUnite,0)
	,SCEEPlusUnite = ISNULL(V12.SCEEPlusUnite,0)
	,BECUnite = ISNULL(V12.BECUnite,0)
	,RendSCEEUnite = ISNULL(V12.RendSCEEUnite,0)
	,RevenuCotisationUnite = ISNULL(V12.RevenuCotisationUnite,0)
	,IQEEEtRevenuUnite = ISNULL(V12.IQEEEtRevenuUnite,0)
	,IQEEUnite = ISNULL(V12.IQEEUnite,0)
	,IQEEPlusUnite = ISNULL(V12.IQEEPlusUnite,0)
	,RevenuIQEEUnite = ISNULL(V12.RevenuIQEEUnite,0)

	,V12.BirthDate
	,V12.DateDebutOperationFinanciere
	,V12.DateDernierDepot
	,V12.DateDebutProjection

	,V12.DateFinProjection 	
	--,v12.FIN ----------------------- FIN

	,V12.DateFinCotisationSubventionnee
	,V12.DateEncaissSCEEaRecevoir
	,V12.DateEncaissIQEEaRecevoir
	,V12.DateEncaissDerniereCotisSCEE
	,V12.DateEncaissDerniereCotisIQEE

	--------------------------------SCEE
	,DiminutionProjectionPourPasDepasserPlafondAvie = ISNULL(v12.DiminutionProjectionPourPasDepasserPlafondAvie,0)  /* A1 */
	,SCEEaRecevoir = ISNULL(v12.SCEEaRecevoir,0)  /* B */ 
	,SCEEperiodiqueAuContratSansDepasserPlafondAnnuel = ISNULL(v12.SCEEperiodiqueAuContratSansDepasserPlafondAnnuel,0)  /* C */
	,SCEEperiodiqueAuContratSansDepasserPlafondAvie = ISNULL(v12.SCEEperiodiqueAuContratSansDepasserPlafondAvie,0)  /* D */
	,SCEEtotalPrevu = ISNULL(v12.SCEEtotalPrevu,0)  /* E */
	,NbAnneeDeDateDebutProjection_A_FinProjection = ISNULL(v12.NbAnneeDeDateDebutProjection_A_FinProjection,0)  /* F */
	,NbAnneeDeDateEncaissPrevuSCEEaRecevoir_A_FinProjection = ISNULL(v12.NbAnneeDeDateEncaissPrevuSCEEaRecevoir_A_FinProjection,0)  /* G */
	,NbPeriodes_De_DateProchCot_A_DernCot = ISNULL(v12.NbPeriodes_De_DateProchCot_A_DernCot,0)  /* H */
	,NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans = ISNULL(v12.NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans,0)  /* I */
	,NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200 = ISNULL(v12.NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200,0)  /* J */
	,NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot = ISNULL(v12.NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot,0)  /* K */
	,NbAnneeDeDateDernCot_A_FinProjection = ISNULL(v12.NbAnneeDeDateDernCot_A_FinProjection,0)  /* L */
	,SoldeInitial_SCEE_BEC_RevenuProjete = ISNULL(v12.SoldeInitial_SCEE_BEC_RevenuProjete,0)  /* M */ 
	,SCEEaRecevoirProjete = ISNULL(v12.SCEEaRecevoirProjete,0)  /* O */
	,SCEEPerodiqueProjete_De_DateProchCot_A_DernCot = ISNULL(v12.SCEEPerodiqueProjete_De_DateProchCot_A_DernCot,0)  /* P */
	,SCEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie = ISNULL(v12.SCEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie,0)  /* Q */
	,SoldeSCEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot = ISNULL(v12.SoldeSCEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot,0)  /* R */
	,SoldeSCEEProjete_De_DateEncaissDernCot_A_DateFinProj = ISNULL(v12.SoldeSCEEProjete_De_DateEncaissDernCot_A_DateFinProj,0)  /* S */
	,SCEEProjete = ISNULL(v12.SCEEProjete,0)  /* T */
	,SCEE_Plus_Bec_RecuEtProjete = ISNULL(v12.SCEE_Plus_Bec_RecuEtProjete,0)  /* U */
	,Bec_Recu = ISNULL(v12.Bec_Recu,0)  /* U2 */
	,RevenuAccumuleSurSoldeRend = ISNULL(v12.RevenuAccumuleSurSoldeRend,0)  /* U3 */
	,RevenuAccumuleRecuEtProjete = ISNULL(v12.RevenuAccumuleRecuEtProjete,0)  /* V */
	,SCEEEtRevenuAccumule_Recu_EtProjete = ISNULL(v12.SCEEEtRevenuAccumule_Recu_EtProjete,0)  /* W */

	,IQEEDiminutionProjectionPourPasDepasserPlafondAvie = ISNULL(v12.IQEEDiminutionProjectionPourPasDepasserPlafondAvie,0)  /* AA */
	,IQEEaRecevoir = ISNULL(v12.IQEEaRecevoir,0)  /* BB */
	,IQEEperiodiqueAuContratSansDepasserPlafondAnnuel = ISNULL(v12.IQEEperiodiqueAuContratSansDepasserPlafondAnnuel,0)  /* CC */

	,IQEEperiodiqueAuContratSansDepasserPlafondAvie = ISNULL(v12.IQEEperiodiqueAuContratSansDepasserPlafondAvie,0)  /* DD */
	
	
	
	,IQEEtotalPrevu = ISNULL(v12.IQEEtotalPrevu,0)  /* EE */
	,IQEE_NbAnneeDeDateDebutProjection_A_FinProjection = ISNULL(v12.IQEE_NbAnneeDeDateDebutProjection_A_FinProjection,0)  /* FF */
	,IQEE_NbAnneeDeDateEncaissPrevuIQEEaRecevoir_A_FinProjection = ISNULL(v12.IQEE_NbAnneeDeDateEncaissPrevuIQEEaRecevoir_A_FinProjection,0)  /* GG */
	,IQEE_NbAnnee_De_DateProchCot_A_DernCot = ISNULL(v12.IQEE_NbAnnee_De_DateProchCot_A_DernCot,0)  /* HH */
	,IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans = ISNULL(v12.IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans,0)  /* II */
	,IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600 = ISNULL(v12.IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600,0)  /* JJ */
	,IQEE_NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot = ISNULL(v12.IQEE_NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot,0)  /* KK */
	,IQEE_NbAnneeDeDateDernCot_A_FinProjection = ISNULL(v12.IQEE_NbAnneeDeDateDernCot_A_FinProjection,0)  /* LL */
	,IQEE_SoldeInitial_IQEE_RevenuProjete = ISNULL(v12.IQEE_SoldeInitial_IQEE_RevenuProjete,0)  /* MM */
	,IQEEaRecevoirProjete = ISNULL(v12.IQEEaRecevoirProjete,0)  /* OO */
	,IQEEPerodiqueProjete_De_DateProchCot_A_DernCot = ISNULL(v12.IQEEPerodiqueProjete_De_DateProchCot_A_DernCot,0)  /* PP */
	,IQEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie = ISNULL(v12.IQEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie,0)  /* QQ */
	,SoldeIQEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot = ISNULL(v12.SoldeIQEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot,0)  /* RR */
	,SoldeIQEEProjete_De_DateEncaissDernCot_A_DateFinProj = ISNULL(v12.SoldeIQEEProjete_De_DateEncaissDernCot_A_DateFinProj,0)  /* SS */
	,IQEEProjete = ISNULL(v12.IQEEProjete,0)  /* TT */ 
	,IQEE_Plus_RecuEtProjete = ISNULL(v12.IQEE_Plus_RecuEtProjete,0)  /* UU */
	,IQEERevenuAccumuleRecuEtProjete = ISNULL(v12.IQEERevenuAccumuleRecuEtProjete,0)  /* VV */
	,IQEEEtRevenuAccumule_Recu_EtProjete = ISNULL(v12.IQEEEtRevenuAccumule_Recu_EtProjete,0)  /* WW */
	

from (



	SELECT 
		V11.*
		,RevenuAccumuleRecuEtProjete /* V */ = SCEEEtRevenuAccumule_Recu_EtProjete - SCEE_Plus_Bec_RecuEtProjete - Bec_Recu
		,IQEERevenuAccumuleRecuEtProjete /* VV */ = IQEEEtRevenuAccumule_Recu_EtProjete - IQEE_Plus_RecuEtProjete 

	FROM (


		SELECT	
			V10.*
			,SCEEEtRevenuAccumule_Recu_EtProjete /* W */ = SoldeInitial_SCEE_BEC_RevenuProjete + SoldeSCEEProjete_De_DateEncaissDernCot_A_DateFinProj + SCEEaRecevoirProjete + RevenuAccumuleSurSoldeRend
			,IQEEEtRevenuAccumule_Recu_EtProjete /* WW */ = IQEE_SoldeInitial_IQEE_RevenuProjete + V10.SoldeIQEEProjete_De_DateEncaissDernCot_A_DateFinProj + V10.IQEEaRecevoirProjete

		from (
			select 
				V9.*
				,SoldeSCEEProjete_De_DateEncaissDernCot_A_DateFinProj =	/* S */
					case
					when SCEEtotalPrevu <= 7200 then 
							SCEEPerodiqueProjete_De_DateProchCot_A_DernCot *
							(
								POWER ( 1 + @TauxAnnuelComposeMensuellement , NbAnneeDeDateDernCot_A_FinProjection  ) 
							)
					else
							SoldeSCEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot *  
							(
								POWER ( 1 + @TauxAnnuelComposeMensuellement , NbAnneeDeDateDernCot_A_FinProjection  ) 
							)
					end

				,SoldeIQEEProjete_De_DateEncaissDernCot_A_DateFinProj /* SS */ =
					case
					when IQEEtotalPrevu <= 3600 then 
							IQEEPerodiqueProjete_De_DateProchCot_A_DernCot *
							(
								POWER ( 1 + @TauxAnnuelComposeMensuellement , IQEE_NbAnneeDeDateDernCot_A_FinProjection  ) 
							)
					else
							SoldeIQEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot *  
							(
								POWER ( 1 + @TauxAnnuelComposeMensuellement , IQEE_NbAnneeDeDateDernCot_A_FinProjection  ) 
							)
					end

				,SCEE_Plus_Bec_RecuEtProjete /* U */ =	case --2016-02-24
														when (V9.SCEEUnite + V9.SCEEPlusUnite + V9.SCEEaRecevoir + v9.SCEEProjete) > 7200 then 7200 /*2016-03-22*/
														else  V9.SCEEUnite + V9.SCEEPlusUnite + V9.SCEEaRecevoir + v9.SCEEProjete 
														end
				,Bec_Recu /* U2 */ = V9.BECUnite
				,IQEE_Plus_RecuEtProjete /* UU */  =	case --2016-02-24
														when (V9.IQEEUnite + V9.IQEEPlusUnite + V9.IQEEaRecevoir + V9.IQEEProjete) > 3600 then 3600 /*2016-03-22*/ 
														ELSE  V9.IQEEUnite + V9.IQEEPlusUnite + V9.IQEEaRecevoir + V9.IQEEProjete 
														end

		
				,RevenuAccumuleSurSoldeRend /* U3 */ =
					--case when RevenuCotisationUnite > 0 THEN -- retiré le 2017-02-15
						RevenuCotisationUnite *  
						(
							POWER	( 1 + @TauxAnnuelComposeMensuellement , 
										(
										CASE 
										WHEN  datediff(DAY,DateDebutProjection,DateFinProjection) > 0
											THEN datediff(DAY,DateDebutProjection,DateFinProjection) / 365.0
										ELSE 0
										END
										)  
					
					
									) 
					
						)
					--else 0
					--end
	


			from (

				select 
					v8.*

					,SoldeSCEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot /* R */ = 
						case 
						when ModeCotisation = 'Mensuel' then 
								SCEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie *  
								(
									POWER ( 1 + @TauxAnnuelComposeMensuellement , NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot / 12.0 ) 
									---1
								)
						when ModeCotisation = 'Annuel' then  
								SCEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie *  
								(
									POWER ( 1 + @TauxAnnuelComposeMensuellement , NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot		) 
									---1
								)
						else 0
						end

					,SoldeIQEEProjete_De_DateAtteintePlafondAvie_A_DateEncaissDernCot /* RR */ =
						IQEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie *  
						(
							POWER ( 1 + @TauxAnnuelComposeMensuellement , IQEE_NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot ) 
							---1
						)


				from (
	

					select 

						v7.*

						,SCEEProjete /* T */ = 
							case 
							when SCEEtotalPrevu > 7200 then 
								(7200.0 - SCEEUnite - SCEEPlusUnite - /*2016-03-22*/ SCEEaRecevoir /**/)
							ELSE SCEEperiodiqueAuContratSansDepasserPlafondAnnuel * NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans
							end

						,IQEEProjete /* TT */ =  
							case 
							when IQEEtotalPrevu > 3600 then 
								(3600.0 - IQEEUnite - IQEEPlusUnite- /*2016-03-22*/ IQEEaRecevoir /***/)
							ELSE IQEEperiodiqueAuContratSansDepasserPlafondAnnuel * IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans * (case when ModeCotisation = 'Mensuel' then 12.0 else 1 end)
							end

						,SCEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie /* Q */ =
							case
							when SCEEtotalPrevu > 7200 then
								case 
								when ModeCotisation = 'Mensuel' then
									(
										SCEEperiodiqueAuContratSansDepasserPlafondAvie *  
										(
											POWER ( 1 + @TauxMensuelCompose , NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200 )
											-1
										)
									)
									/ @TauxMensuelCompose
								when ModeCotisation = 'Annuel' then
									(
										SCEEperiodiqueAuContratSansDepasserPlafondAvie *  
										(
											POWER ( 1 + @TauxAnnuelComposeMensuellement , NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200 )
											-1
										)
									)
									/ @TauxAnnuelComposeMensuellement
								else 0
								end
							else 0
							end

						,IQEEPerodiqueProjete_De_DateProchCot_A_PlafondAvie /* QQ */ =
							case
							when IQEEtotalPrevu > 3600 then
								case 
								when ModeCotisation = 'Mensuel' then
									(
										IQEEperiodiqueAuContratSansDepasserPlafondAvie * 12 *
										(
											POWER ( 1 + @TauxAnnuelComposeMensuellement , IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600 )
											-1
										)
									)
									/ @TauxAnnuelComposeMensuellement
								when ModeCotisation = 'Annuel' then
									(
										IQEEperiodiqueAuContratSansDepasserPlafondAvie *  
										(
											POWER ( 1 + @TauxAnnuelComposeMensuellement , IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600 )
											-1
										)
									)
									/ @TauxAnnuelComposeMensuellement
								else 0
								end
							else 0
							end

						,NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot /* K */ = 
							case 
							WHEN SCEEtotalPrevu > 7200 then 
								case 
								when NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans - NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200 < 0 then 0
								else NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans - NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200
								end
							else 0
							end		

						,IQEE_NbPeriode_Du_SoldeDuPlafondAvie_A_DateEncaissDernCot /* KK */ = 
							case 
							WHEN IQEEtotalPrevu > 3600 then 
								case 
								when IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans - IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600 < 0 then 0
								else IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans - IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600
								end
							else 0
							end		


					from (

	
						select 
							v6.*


							,SCEEperiodiqueAuContratSansDepasserPlafondAvie /* D */ = 
								case 
								WHEN SCEEtotalPrevu > 7200 and NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200 <> 0 then (7200.0 - SCEEUnite - SCEEPlusUnite) / NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200
								else 0
								end	

							,IQEEperiodiqueAuContratSansDepasserPlafondAvie /* DD */ = 
							cast(
								case
								when ModeCotisation = 'Mensuel' then
									case 
									WHEN IQEEtotalPrevu > 3600 and IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600 <> 0 then (3600.0 - IQEEUnite - IQEEPlusUnite) / (IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600 ) / 12.0	
									else 0
									end	
								when ModeCotisation = 'Annuel' then
									case 
									WHEN IQEEtotalPrevu > 3600 and IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600 <> 0 then (3600.0 - IQEEUnite - IQEEPlusUnite) / (IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600 )
									else 0
									end	
								ELSE 0
								end
							as float)

						from 	(


							select 


								V5.*
	
								,SoldeInitial_SCEE_BEC_RevenuProjete /* M */ = (SCEEUnite + SCEEPlusUnite + BECUnite + RendSCEEUnite) * power( (1+@TauxAnnuelComposeMensuellement) , NbAnneeDeDateDebutProjection_A_FinProjection )

								,IQEE_SoldeInitial_IQEE_RevenuProjete /* MM */ = (IQEEEtRevenuUnite ) * power( (1+@TauxAnnuelComposeMensuellement) , IQEE_NbAnneeDeDateDebutProjection_A_FinProjection )

								,SCEEaRecevoirProjete /* O */ = case when SCEEaRecevoir < 0 then SCEEaRecevoir else (SCEEaRecevoir) * power( (1+@TauxAnnuelComposeMensuellement) , NbAnneeDeDateEncaissPrevuSCEEaRecevoir_A_FinProjection ) end

								,IQEEaRecevoirProjete /* OO */ = case when IQEEaRecevoir < 0 then IQEEaRecevoir else (IQEEaRecevoir) * power( (1+@TauxAnnuelComposeMensuellement) , IQEE_NbAnneeDeDateEncaissPrevuIQEEaRecevoir_A_FinProjection ) end

								,SCEEPerodiqueProjete_De_DateProchCot_A_DernCot /* P */ =
									case
									when SCEEtotalPrevu <= 7200 then
										case 
										when ModeCotisation = 'Mensuel' then
											(
												SCEEperiodiqueAuContratSansDepasserPlafondAnnuel *  
												(
													POWER ( 1 + @TauxMensuelCompose , NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans )
													-1
												)
											)
											/ @TauxMensuelCompose
										when ModeCotisation = 'Annuel' then
											(
												SCEEperiodiqueAuContratSansDepasserPlafondAnnuel *  
												(
													POWER ( 1 + @TauxAnnuelComposeMensuellement , NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans )
													-1
												)
											)
											/ @TauxAnnuelComposeMensuellement
										else 0
										end
									else 0
									end


								,IQEEPerodiqueProjete_De_DateProchCot_A_DernCot /* PP */ =
									case
									when IQEEtotalPrevu <= 3600 then
										case 
										when ModeCotisation = 'Mensuel' then
											(
												IQEEperiodiqueAuContratSansDepasserPlafondAnnuel *
												(
													POWER ( 1 + @TauxMensuelCompose , IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans * 12 )
													-1
												)
											)
											/ @TauxMensuelCompose
										when ModeCotisation = 'Annuel' then
											(
												IQEEperiodiqueAuContratSansDepasserPlafondAnnuel *  
												(
													POWER ( 1 + @TauxAnnuelComposeMensuellement , IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans )
													-1
												)
											)
											/ @TauxAnnuelComposeMensuellement
										else 0
										end
									else 0.0
									end

								--,IQEEPerodiqueProjete_De_DateProchCot_A_DernCot /* PP */ =
								--	case
								--	when IQEEtotalPrevu <= 3600 then
								--		case 
								--		when ModeCotisation = 'Mensuel' then
								--			(
								--				IQEEperiodiqueAuContratSansDepasserPlafondAnnuel * 12 *
								--				(
								--					POWER ( 1 + @TauxAnnuelComposeMensuellement , IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans )
								--					-1
								--				)
								--			)
								--			/ @TauxAnnuelComposeMensuellement
								--		when ModeCotisation = 'Annuel' then
								--			(
								--				IQEEperiodiqueAuContratSansDepasserPlafondAnnuel *  
								--				(
								--					POWER ( 1 + @TauxAnnuelComposeMensuellement , IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans )
								--					-1
								--				)
								--			)
								--			/ @TauxAnnuelComposeMensuellement
								--		else 0
								--		end
								--	else 0.0
								--	end

								,NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp7200 /* J */ = 
								cast(
									case 
									WHEN SCEEtotalPrevu > 7200 and SCEEperiodiqueAuContratSansDepasserPlafondAnnuel <> 0 then
										case 
										when ( (7200.0 - SCEEUnite - SCEEPlusUnite) / SCEEperiodiqueAuContratSansDepasserPlafondAnnuel ) < 0 then 0.0
										else ( (7200.0 - SCEEUnite - SCEEPlusUnite) / SCEEperiodiqueAuContratSansDepasserPlafondAnnuel )
										end
									else 0.0
									end
								as FLOAT)
								,IQEE_NbPeriodes_De_DateProchCot_A_AtteintePlafondAvieSupp3600 /* JJ */ = 
								cast(
									case 
									WHEN IQEEtotalPrevu > 3600 and IQEEperiodiqueAuContratSansDepasserPlafondAnnuel <> 0 then
										case 
										when ModeCotisation = 'Mensuel' then
											case 
											when (3600.0 - IQEEUnite - IQEEPlusUnite) / (IQEEperiodiqueAuContratSansDepasserPlafondAnnuel ) / 12.0	< 0 then 0.0
											else (3600.0 - IQEEUnite - IQEEPlusUnite) / (IQEEperiodiqueAuContratSansDepasserPlafondAnnuel ) / 12.0
											end
										when ModeCotisation = 'Annuel' then
											case 
											when (3600.0 - IQEEUnite - IQEEPlusUnite) / (IQEEperiodiqueAuContratSansDepasserPlafondAnnuel )			< 0 then 0
											else (3600.0 - IQEEUnite - IQEEPlusUnite) / (IQEEperiodiqueAuContratSansDepasserPlafondAnnuel )
											end		
										else 0.0
										end							
									else 0.0
									end
								as float)

							from (


								select 
									V4.*
									,SCEEtotalPrevu /* E */ = (NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans * SCEEperiodiqueAuContratSansDepasserPlafondAnnuel ) + SCEEUnite + SCEEPlusUnite /*2016-03-22*/ + SCEEaRecevoir /**/

									,IQEEtotalPrevu /* EE */ = 
										case 
										when V4.ModeCotisation = 'Mensuel' then (isnull(IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans,0) * isnull(IQEEperiodiqueAuContratSansDepasserPlafondAnnuel,0) * 12 ) + V4.IQEEUnite + V4.IQEEPlusUnite /*2016-03-22*/+ V4.IQEEaRecevoir /**/
										ELSE									(isnull(IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans,0) * isnull(IQEEperiodiqueAuContratSansDepasserPlafondAnnuel,0)      ) + V4.IQEEUnite + V4.IQEEPlusUnite /*2016-03-22*/+ V4.IQEEaRecevoir /**/
										--when V4.ModeCotisation = 'Annuel'  then (IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans * IQEEperiodiqueAuContratSansDepasserPlafondAnnuel      ) + V4.IQEEUnite + V4.IQEEPlusUnite
										--ELSE 0
										end


								from (

									select 

										V2.*

										,NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans = /* I */
										--round(
											case
											when RiVerse = 'non' THEN
												case 
												when DateDernierDepot < DateFinCotisationSubventionnee THEN NbPeriodes_De_DateProchCot_A_DernCot
												else
													case
													when ModeCotisation = 'Mensuel' then
														case 
														when --((NbPeriodes_De_DateProchCot_A_DernCot - CEILING ( datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)) / 365.0 *12) ) < 0 then 0
															 (
																(
																NbPeriodes_De_DateProchCot_A_DernCot 
																	- CEILING	( 
																				datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)
																				/ 365.0 *12
																				)
																) 
															 ) < 0 THEN 0
														else 
															 (
																(
																NbPeriodes_De_DateProchCot_A_DernCot 
																	- CEILING	( 
																				datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)
																				/ 365.0 *12
																				)
																) 
															 )
														end

													when ModeCotisation = 'Annuel' then
														case 
														when 
															 (
																(
																NbPeriodes_De_DateProchCot_A_DernCot 
																	- CEILING	( 
																				datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)
																				/ 365.0 
																				)
																) 
															 ) < 0 THEN 0
														else
															 (
																(
																NbPeriodes_De_DateProchCot_A_DernCot 
																	- CEILING	( 
																				datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)
																				/ 365.0 
																				)
																) 
															 )
														end
													else 
														0
													end
												end
											else 0 
											end
										--,2)
						
		
										,IQEE_NbPeriodes_De_DateProchCot_A_DernCot_Validation17ans = /* II */
										cast(
											case
											when RiVerse = 'non' THEN
												case 
												when DateDernierDepot < DateFinCotisationSubventionnee THEN IQEE_NbAnnee_De_DateProchCot_A_DernCot
												else
													case
													when ModeCotisation = 'Mensuel' then
														case 
														when --(IQEE_NbAnnee_De_DateProchCot_A_DernCot - (CEILING ( datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)) / 365.0 *12) / 12.0  ) < 0 then 0
															 (
																(
																IQEE_NbAnnee_De_DateProchCot_A_DernCot 
																	- CEILING	( 
																				datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)
																				/ 365.0 *12
																				)
																			/ 12.0
																) 
															 ) < 0 then 0
														else --(IQEE_NbAnnee_De_DateProchCot_A_DernCot - (CEILING ( datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)) / 365.0 *12) / 12.0  )
															 (
																(
																IQEE_NbAnnee_De_DateProchCot_A_DernCot 
																	- CEILING	( 
																				datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)
																				/ 365.0 *12
																				) 
																			/ 12.0
																) 
															 )
														end
													when ModeCotisation = 'Annuel' then
														--case 
														--when ((IQEE_NbAnnee_De_DateProchCot_A_DernCot - CEILING ( datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)) / 365.0  )) < 0 then 0
														--else ((IQEE_NbAnnee_De_DateProchCot_A_DernCot - CEILING ( datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)) / 365.0  ))
														--end
														case 
														when 
															 (
																(
																IQEE_NbAnnee_De_DateProchCot_A_DernCot 
																	- CEILING	( 
																				datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)
																				/ 365.0 *12
																				)
																) 
															 ) < 0 then 0
														else 
															 (
																(
																IQEE_NbAnnee_De_DateProchCot_A_DernCot 
																	- CEILING	( 
																				datediff(DAY,DateFinCotisationSubventionnee,DateDernierDepot)
																				/ 365.0 *12
																				)
																) 
															 )
														end
													else 
														0
													end
												end
											else 0 
											end
										as float)


									from #DATASET V2
									)V4
								)V5
							)V6
						)V7
					)V8
				)V9
			)V10
		)V11
	)V12
where  
	(
		(V12.SubscriberID = @SubscriberID or @SubscriberID is null) 
		AND (V12.BeneficiaryID = @BeneficiaryID or @BeneficiaryID is null)  
		AND (V12.ConventionNo = @ConventionNo or @ConventionNo is null)	
	)
	or @SubscriberID in (1,2) -- cas de test
order by beneficiaryID, conventionno, QteUnite desc

--drop table #conv
--DROP TABLE #DATASET


end