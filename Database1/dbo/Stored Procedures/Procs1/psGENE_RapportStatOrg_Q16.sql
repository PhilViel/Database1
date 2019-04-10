
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q16
Nom du service		:		psGENE_RapportStatOrg_Q16
But					:		Pour le rapport de statistiques orrganisationelles - Q16 (JIRA TI-6275)
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q16 '2011-01-31', 0
						exec psGENE_RapportStatOrg_Q16 '2012-01-31', 0
						exec psGENE_RapportStatOrg_Q16 '2013-01-31', 0
						exec psGENE_RapportStatOrg_Q16 '2014-01-31', 0
						exec psGENE_RapportStatOrg_Q16 '2015-01-31', 0
						exec psGENE_RapportStatOrg_Q16 '2016-01-31', 0
						exec psGENE_RapportStatOrg_Q16 '2018-01-31', 0

						exec psGENE_RapportStatOrg_Q16 '2011-12-31', 0
						exec psGENE_RapportStatOrg_Q16 '2012-12-31', 0
						exec psGENE_RapportStatOrg_Q16 '2013-12-31', 0
						exec psGENE_RapportStatOrg_Q16 '2014-12-31', 0
						exec psGENE_RapportStatOrg_Q16 '2015-12-31', 0
						exec psGENE_RapportStatOrg_Q16 '2017-10-31', 0
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2017-01-10					Donald Huppé							Création du Service
						2017-02-10					Donald Huppé							Ajout au jira 6275
						2017-11-15					Donald Huppé							jira ti-10064 : ajout du nb de souscripteurs pour Q1 à Q4
						2018-10-23					Donald Huppé							jira prod-12588 : regroupement par régime
						2018-10-31					Donald Huppé							jira prod-12705 : Remplacer Mensuel par Ajout d''engagement (pour inclure les annuels)
																							EXCLURE LES TIN DES AUTRES CATÉGORIES
																							inclure les i-bec
						2018-11-01					Donald Huppé							Ajout de Q5 - Nouveau Client
						2018-11-02					Donald Huppé							Ajout des dépôts subséquents dans les individuel  11 ans et mois et 12 ans et plus
						2018-11-05					Donald Huppé							Seulement les opérations d'encaissement 
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q16] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

	set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,Demande varchar(100)
			,Regime varchar(100)
			,UnitésSouscrites float
			,MontantSouscrit float

			,EpargneEncaissePeriode float
			--,SceeEtBECEncaissePeriode float
			,EpargneTIN float
			,FraisTIN float
			,SubvTIN float
			,RendementTIN float
			,NbSouscripteur int

			)

	create table #Final (
		Sort int,
		Quoi varchar(100),
		v0 float,
		v1 float,
		v2 float,
		v3 float,
		v4 float,
		v5 float
		)

	CREATE TABLE #TIN ( 
			UnitID INT
			,Epargne MONEY
			,Frais MONEY
			,Subv MONEY
			,Rendement MONEY
		)	

	SELECT * 
	INTO #tUnite_T_IBEC
	FROM fntREPR_ObtenirUniteConvT (1) t

	declare	 @DateFrom datetime
	declare	 @DateTo datetime
	declare @i int = 0

	while @i <= @QtePeriodePrecedent
	begin 



		set @DateFrom = cast(year(@EnDateDu)-@i as VARCHAR(4))+ '-01-01'
		set @DateTo = @EnDateDu -- cast(year(@EnDateDu)-@i as VARCHAR(4)) + '-12-31'

		if @i = 0
			set @DateTo  = @EnDateDu

		DELETE FROM #TIN

		INSERT INTO #TIN
		SELECT 
			UnitID
			,Epargne = sum(Epargne)
			,Frais = sum(Frais)
			,Subv = sum(Subv)
			,Rendement = sum(Rendement)	
		FROM (
			SELECT u1.UnitID
				,Epargne = sum( ct.Cotisation)
				,Frais = sum( ct.Fee)
				,Subv = 0
				,Rendement = 0

			FROM 
				Un_Convention C
				JOIN Un_Unit U1 ON C.ConventionID= U1.ConventionID
				JOIN Un_Cotisation CT ON U1.UnitID = CT.UnitID
				JOIN Un_Oper O ON CT.OperID = O.OperID
				--LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				--LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
				LEFT JOIN Un_TIO TIO ON O.OperID = TIO.iTINOperID
			WHERE 1=1
				AND o.OperTypeID = 'TIN'
				and TIO.iTINOperID is null
				and o.OperDate BETWEEN @DateFrom AND @DateTo
				--AND OC1.OperSourceID IS NULL
				--AND OC2.OperID IS NULL
			GROUP BY 
				u1.UnitID

			union all

			select 
				scee.UnitID
				,Epargne = 0
				,Frais = 0
				,Subv = sum( scee.fCESG + scee.fACESG + scee.fCLB)
				,Rendement = 0
			from (
				select DISTINCT ct.UnitID,ct.CotisationID, ce.fCESG, ce.fACESG, ce.fCLB
				from 
					Un_Oper o
					join Un_Cotisation ct on ct.OperID = o.OperID
					JOIN Un_CESP ce on o.OperID = ce.OperID
					LEFT JOIN Un_TIO TIO ON O.OperID = TIO.iTINOperID
				WHERE 1=1
					AND o.OperTypeID = 'TIN'
					and TIO.iTINOperID is null
					and o.OperDate BETWEEN @DateFrom AND @DateTo
				--order by ct.CotisationID
				)scee
			GROUP BY 
				scee.UnitID

			union all

			select 
				iqee_rend.UnitID
				,Epargne = 0
				,Frais = 0
				,Subv = sum( case when iqee_rend.ConventionOperTypeID in ('CBQ','MMQ') then iqee_rend.ConventionOperAmount else 0 end )
				,Rendement = sum( case when iqee_rend.ConventionOperTypeID in ('IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','MIM','IQI','ITR') then iqee_rend.ConventionOperAmount else 0 end )
			from (

				select DISTINCT ct.UnitID,ct.CotisationID, co.*
				from 
					Un_Oper o
					join Un_Cotisation ct on ct.OperID = o.OperID
					JOIN Un_ConventionOper co ON o.OperID	 = co.OperID
					LEFT JOIN Un_TIO TIO ON O.OperID = TIO.iTINOperID
				WHERE 1=1
					AND o.OperTypeID = 'TIN'
					and TIO.iTINOperID is null
					and co.conventionopertypeid in( 'CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','MIM','IQI','ITR')
					and o.OperDate BETWEEN @DateFrom AND @DateTo
				--order by ct.CotisationID
				)iqee_rend
			GROUP by iqee_rend.UnitID
		) v2
		GROUP BY v2.UnitID


			insert into #Result
				SELECT
					DateFrom = @DateFrom
					,DateTo = @DateTo
					,Demande = 'Jira TI-6275 Q1 : Unité TIN'
					,Regime = RR.vcDescription
					,UnitésSouscrites = SUM(U.UnitQty +isnull(qtyreduct,0))
					,MontantSouscrit = SUM	(
											CONVERT(money,
											CASE
												WHEN P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
												else (ROUND( (U.UnitQty +isnull(qtyreduct,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
											END
												)
											)

					,EpargneEncaissePeriode = sum(isnull(v1.CotisationFee,0))
					--,SceeEtBECEncaissePeriode = 0
					,EpargneTIN = sum(Epargne)
					,FraisTIN = sum(Frais)
					,SubvTIN = sum(Subv)
					,RendementTIN = sum(Rendement)
					,NbSouscripteur = COUNT(DISTINCT c.SubscriberID)


				FROM 
					dbo.Un_Convention C
					JOIN un_unit U ON U.ConventionID = C.ConventionID
					JOIN #TIN TIN on TIN.UnitID = u.UnitID

					LEFT join (select qtyreduct = sum(unitqty), unitid from un_unitreduction group by unitid) r on u.unitid = r.unitid
					JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
					JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
					JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
					LEFT JOIN dbo.Mo_Connect Co ON Co.ConnectID = U.PmtEndConnectID
					LEFT JOIN dbo.Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
					LEFT JOIN (
						SELECT 
							U.UnitID,Cotisation = SUM(Ct.Cotisation),CotisationFee = SUM(Ct.Cotisation + Ct.Fee)
						FROM 
							dbo.Un_Unit U
							JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
							JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE o.OperDate BETWEEN @DateFrom AND @DateTo
						GROUP BY 
							U.UnitID
							) V1 ON V1.UnitID = U.UnitID
					LEFT JOIN (
						SELECT ConventionID, MIN_UnitID = min(UnitID)
						from Un_Unit
						group by ConventionID
						) mu on u.UnitID = mu.MIN_UnitID
					LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
				WHERE 
					ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') BETWEEN @DateFrom AND @DateTo
				GROUP BY 
					RR.vcDescription
			insert into #Result

 				SELECT
					DateFrom = @DateFrom
					,DateTo = @DateTo
					,Demande = 'Jira TI-6275 Q2 : Ajout d''engagement Déjà Client'  --' Jira TI-6275 Q2 : Unité Mensuelle Déjà Client '
					,Regime = RR.vcDescription
					,UnitésSouscrites = SUM(U.UnitQty +isnull(qtyreduct,0))
					,MontantSouscrit = SUM	(
											CONVERT(money,
												(ROUND( (U.UnitQty +isnull(qtyreduct,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
												)
											)
					,EpargneEncaissePeriode = sum(isnull(v1.CotisationFee,0))
					--,SceeEtBECEncaissePeriode = 0
					,EpargneTIN = 0
					,FraisTIN =0
					,SubvTIN = 0
					,RendementTIN = 0
					,NbSouscripteur = COUNT(DISTINCT c.SubscriberID)

				FROM 
					dbo.Un_Convention C
					JOIN (
						-- LES SOUSC ET BENEF DÉJÀ CLIENT AU DEBUT DE LA PÉRIODE
						SELECT DISTINCT C1.SubscriberID, C1.BeneficiaryID
						FROM Un_Convention C1
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
									where startDate < @DateFrom
									group by conventionid
									) ccs on ccs.conventionid = cs.conventionid 
										and ccs.startdate = cs.startdate 
										and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
							) css on C1.conventionid = css.conventionid
						)DEJA ON DEJA.SubscriberID = C.SubscriberID AND DEJA.BeneficiaryID = C.BeneficiaryID
					JOIN un_unit U ON U.ConventionID = C.ConventionID
					LEFT join (select qtyreduct = sum(unitqty), unitid from un_unitreduction group by unitid) r on u.unitid = r.unitid
					JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
					JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
					JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
					LEFT JOIN (
						SELECT 
							U.UnitID,Cotisation = SUM(Ct.Cotisation),CotisationFee = SUM(Ct.Cotisation + Ct.Fee)
						FROM 
							dbo.Un_Unit U
							JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
							JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE o.OperDate BETWEEN @DateFrom AND @DateTo
							AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI NSF COU', 1) > 0
						GROUP BY 
							U.UnitID
							) V1 ON V1.UnitID = U.UnitID
					LEFT JOIN #TIN TIN on TIN.UnitID = u.UnitID
					LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
				WHERE 
					ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') BETWEEN @DateFrom AND @DateTo
					AND M.PmtQty > 1 --périodique --M.PmtByYearID = 12 -- MENSUEL
					AND TIN.UnitID IS NULL
				GROUP BY 
					RR.vcDescription

			INSERT INTO #Result

				SELECT
					DateFrom = @DateFrom
					,DateTo = @DateTo 
					,Demande = 'Jira TI-6275 Q3 : Unité Forfait 12 ans et plus Déjà Client'
					,Regime
					,UnitésSouscrites = SUM(UnitésSouscrites)
					,MontantSouscrit = SUM(MontantSouscrit)
					,EpargneEncaissePeriode = sum(EpargneEncaissePeriode)
					--,SceeEtBECEncaissePeriode = 0
					,EpargneTIN = 0
					,FraisTIN =0
					,SubvTIN = 0
					,RendementTIN = 0
					,NbSouscripteur = COUNT(DISTINCT V.NbSouscripteur)

				FROM (
 					SELECT
						DateFrom = @DateFrom
						,DateTo = @DateTo 
						,Demande = 'Jira TI-6275 Q3 : Unité Forfait 12 ans et plus Déjà Client'
						,Regime = RR.vcDescription
						,UnitésSouscrites = SUM(U.UnitQty +isnull(qtyreduct,0))
						,MontantSouscrit = SUM	(
												CONVERT(money,
												CASE
													WHEN P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
													else (ROUND( (U.UnitQty +isnull(qtyreduct,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
												END
													)
												)
						,EpargneEncaissePeriode = sum(isnull(v1.CotisationFee,0))
						--,SceeEtBECEncaissePeriode = 0
						,EpargneTIN = 0
						,FraisTIN =0
						,SubvTIN = 0
						,RendementTIN = 0
						,NbSouscripteur = c.SubscriberID
					FROM 
						dbo.Un_Convention C
						JOIN (
							-- LES SOUSC ET BENEF DÉJÀ CLIENT AU DEBUT DE LA PÉRIODE
							SELECT DISTINCT C1.SubscriberID, C1.BeneficiaryID
							FROM Un_Convention C1
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
										where startDate < @DateFrom
										group by conventionid
										) ccs on ccs.conventionid = cs.conventionid 
											and ccs.startdate = cs.startdate 
											and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
								) css on C1.conventionid = css.conventionid
							)DEJA ON DEJA.SubscriberID = C.SubscriberID AND DEJA.BeneficiaryID = C.BeneficiaryID
						JOIN un_unit U ON U.ConventionID = C.ConventionID
						LEFT join (select qtyreduct = sum(unitqty), unitid from un_unitreduction group by unitid) r on u.unitid = r.unitid
						JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
						JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
						JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
						LEFT JOIN (
							SELECT 
								U.UnitID,Cotisation = SUM(Ct.Cotisation),CotisationFee = SUM(Ct.Cotisation + Ct.Fee)
							FROM 
								dbo.Un_Unit U
								JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
								JOIN Un_Oper O ON O.OperID = Ct.OperID
							WHERE o.OperDate BETWEEN @DateFrom AND @DateTo
								AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI NSF COU', 1) > 0
							GROUP BY 
								U.UnitID
								) V1 ON V1.UnitID = U.UnitID
						LEFT JOIN #TIN TIN on TIN.UnitID = u.UnitID
						LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
					WHERE 
						ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') BETWEEN @DateFrom AND @DateTo
						AND M.PmtQty = 1 -- unique ...
						AND m.BenefAgeOnBegining >= 12 --  ... de 12 ans ou plus
						AND TIN.UnitID IS NULL
					GROUP BY 
						RR.vcDescription,c.SubscriberID

					UNION ALL
				--INSERT INTO #Result
				------------------------Ajout de dépôt dans individuel
					SELECT
						DateFrom = @DateFrom
						,DateTo = @DateTo 
						,Demande = 'Jira TI-6275 Q3 : Unité Forfait 12 ans et plus Déjà Client'
						,Regime = RR.vcDescription
						,UnitésSouscrites = 0 -- 
						,MontantSouscrit = SUM(CT.Cotisation + CT.Fee)
						,EpargneEncaissePeriode = SUM(CT.Cotisation + CT.Fee)
						--,SceeEtBECEncaissePeriode = 0
						,EpargneTIN = 0
						,FraisTIN =0
						,SubvTIN = 0
						,RendementTIN = 0
						,NbSouscripteur = c.SubscriberID
					FROM 
						dbo.Un_Convention C
						JOIN Mo_Human HB on HB.HumanID = C.BeneficiaryID
						JOIN (
							-- LES SOUSC ET BENEF DÉJÀ CLIENT AU DEBUT DE LA PÉRIODE
							SELECT DISTINCT C1.SubscriberID, C1.BeneficiaryID
							FROM Un_Convention C1
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
										where startDate < @DateFrom
										group by conventionid
										) ccs on ccs.conventionid = cs.conventionid 
											and ccs.startdate = cs.startdate 
											and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
								) css on C1.conventionid = css.conventionid
							)DEJA ON DEJA.SubscriberID = C.SubscriberID AND DEJA.BeneficiaryID = C.BeneficiaryID
						JOIN un_unit U ON U.ConventionID = C.ConventionID
						LEFT join (select qtyreduct = sum(unitqty), unitid from un_unitreduction group by unitid) r on u.unitid = r.unitid
						JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
						JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
						JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
						JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
						JOIN Un_Oper O ON O.OperID = CT.OperID
						LEFT JOIN #TIN TIN on TIN.UnitID = u.UnitID
						LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
					WHERE p.PlanTypeID = 'IND'
						AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI NSF COU', 1) > 0
						AND TIN.UnitID IS NULL
						AND ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') < @DateFrom
						AND O.OperDate BETWEEN @DateFrom AND @DateTo
						AND dbo.fn_Mo_Age(HB.BirthDate,o.OperDate) >= 12
					GROUP BY RR.vcDescription, c.SubscriberID
				)V

				GROUP BY 
					Regime

			INSERT INTO #Result

				SELECT
					DateFrom = @DateFrom
					,DateTo = @DateTo 
					,Demande = 'Jira TI-6275 Q4 : Unité Forfait 11 ans et moins Déjà Client'
					,Regime
					,UnitésSouscrites = SUM(UnitésSouscrites)
					,MontantSouscrit = SUM(MontantSouscrit)
					,EpargneEncaissePeriode = sum(EpargneEncaissePeriode)
					--,SceeEtBECEncaissePeriode = 0
					,EpargneTIN = 0
					,FraisTIN =0
					,SubvTIN = 0
					,RendementTIN = 0
					,NbSouscripteur = COUNT(DISTINCT V.NbSouscripteur)

				FROM (
 					SELECT
						DateFrom = @DateFrom
						,DateTo = @DateTo 
						,Demande = 'Jira TI-6275 Q4 : Unité Forfait 11 ans et moins Déjà Client'
						,Regime = RR.vcDescription
						,UnitésSouscrites = SUM(U.UnitQty +isnull(qtyreduct,0))
						,MontantSouscrit = SUM	(
												CONVERT(money,
												CASE
													WHEN P.PlanTypeID = 'IND' THEN ISNULL(V1.Cotisation,0)
													else (ROUND( (U.UnitQty +isnull(qtyreduct,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
												END
													)
												)
						,EpargneEncaissePeriode = sum(isnull(v1.CotisationFee,0))
						--,SceeEtBECEncaissePeriode = 0
						,EpargneTIN = 0
						,FraisTIN =0
						,SubvTIN = 0
						,RendementTIN = 0
						,NbSouscripteur = c.SubscriberID
					FROM 
						dbo.Un_Convention C
						JOIN (
							-- LES SOUSC ET BENEF DÉJÀ CLIENT AU DEBUT DE LA PÉRIODE
							SELECT DISTINCT C1.SubscriberID, C1.BeneficiaryID
							FROM Un_Convention C1
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
										where startDate < @DateFrom
										group by conventionid
										) ccs on ccs.conventionid = cs.conventionid 
											and ccs.startdate = cs.startdate 
											and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
								) css on C1.conventionid = css.conventionid
							)DEJA ON DEJA.SubscriberID = C.SubscriberID AND DEJA.BeneficiaryID = C.BeneficiaryID
						JOIN un_unit U ON U.ConventionID = C.ConventionID
						LEFT join (select qtyreduct = sum(unitqty), unitid from un_unitreduction group by unitid) r on u.unitid = r.unitid
						JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
						JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
						JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
						LEFT JOIN (
							SELECT 
								U.UnitID,Cotisation = SUM(Ct.Cotisation),CotisationFee = SUM(Ct.Cotisation + Ct.Fee)
							FROM 
								dbo.Un_Unit U
								JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
								JOIN Un_Oper O ON O.OperID = Ct.OperID
							WHERE o.OperDate BETWEEN @DateFrom AND @DateTo
								AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI NSF COU', 1) > 0
							GROUP BY 
								U.UnitID
								) V1 ON V1.UnitID = U.UnitID
						LEFT JOIN #TIN TIN on TIN.UnitID = u.UnitID
						LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
					WHERE 
						ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') BETWEEN @DateFrom AND @DateTo
						AND M.PmtQty = 1 -- unique ...
						AND m.BenefAgeOnBegining <= 11 --  ...
						AND TIN.UnitID IS NULL
					GROUP BY 
						RR.vcDescription,c.SubscriberID

					UNION ALL
				--INSERT INTO #Result
				------------------------ individuel
					SELECT
						DateFrom = @DateFrom
						,DateTo = @DateTo 
						,Demande = 'Jira TI-6275 Q3 : Unité Forfait 12 ans et plus Déjà Client'
						,Regime = RR.vcDescription
						,UnitésSouscrites = 0 -- 
						,MontantSouscrit = SUM(CT.Cotisation + CT.Fee)
						,EpargneEncaissePeriode = SUM(CT.Cotisation + CT.Fee)
						--,SceeEtBECEncaissePeriode = 0
						,EpargneTIN = 0
						,FraisTIN =0
						,SubvTIN = 0
						,RendementTIN = 0
						,NbSouscripteur = c.SubscriberID
					FROM 
						dbo.Un_Convention C
						JOIN Mo_Human HB on HB.HumanID = C.BeneficiaryID
						JOIN (
							-- LES SOUSC ET BENEF DÉJÀ CLIENT AU DEBUT DE LA PÉRIODE
							SELECT DISTINCT C1.SubscriberID, C1.BeneficiaryID
							FROM Un_Convention C1
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
										where startDate < @DateFrom
										group by conventionid
										) ccs on ccs.conventionid = cs.conventionid 
											and ccs.startdate = cs.startdate 
											and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
								) css on C1.conventionid = css.conventionid
							)DEJA ON DEJA.SubscriberID = C.SubscriberID AND DEJA.BeneficiaryID = C.BeneficiaryID
						JOIN un_unit U ON U.ConventionID = C.ConventionID
						LEFT join (select qtyreduct = sum(unitqty), unitid from un_unitreduction group by unitid) r on u.unitid = r.unitid
						JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
						JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
						JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
						JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
						JOIN Un_Oper O ON O.OperID = CT.OperID
						LEFT JOIN #TIN TIN on TIN.UnitID = u.UnitID
						LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
					WHERE p.PlanTypeID = 'IND'
						AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI NSF COU', 1) > 0
						AND TIN.UnitID IS NULL
						AND ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') < @DateFrom
						AND O.OperDate BETWEEN @DateFrom AND @DateTo
						AND dbo.fn_Mo_Age(HB.BirthDate,o.OperDate) <= 11
					GROUP BY RR.vcDescription, c.SubscriberID
				)V

				GROUP BY 
					Regime


		insert into #Result

 				SELECT
					DateFrom = @DateFrom
					,DateTo = @DateTo
					,Demande = 'Q5 - Nouveau Client'
					,Regime = RR.vcDescription
					,UnitésSouscrites = SUM(U.UnitQty +isnull(qtyreduct,0))
					,MontantSouscrit = SUM	(
											CONVERT(money,
											CASE
												WHEN P.PlanTypeID = 'IND' THEN isnull(v1.CotisationFee,0)
												else (ROUND( (U.UnitQty +isnull(qtyreduct,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
											END
												)
											)
					,EpargneEncaissePeriode = sum(isnull(v1.CotisationFee,0))
					--,SceeEtBECEncaissePeriode = 0
					,EpargneTIN = 0
					,FraisTIN =0
					,SubvTIN = 0
					,RendementTIN = 0
					,NbSouscripteur = COUNT(DISTINCT c.SubscriberID)
					

				FROM 
					dbo.Un_Convention C

					JOIN un_unit U ON U.ConventionID = C.ConventionID
					LEFT join (select qtyreduct = sum(unitqty), unitid from un_unitreduction group by unitid) r on u.unitid = r.unitid
					JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
					JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
					join tblCONV_RegroupementsRegimes rr on rr.iID_Regroupement_Regime = p.iID_Regroupement_Regime --and rr.vcCode_Regroupement = @vcCode_Regroupement -- select	* from tblCONV_RegroupementsRegimes
					LEFT JOIN (
						SELECT 
							U.UnitID,Cotisation = SUM(Ct.Cotisation),CotisationFee = SUM(Ct.Cotisation + Ct.Fee), Fee = SUM(Ct.Fee)
						FROM 
							dbo.Un_Unit U
							JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
							JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE o.OperDate BETWEEN @DateFrom AND @DateTo
							AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI NSF COU', 1) > 0
						GROUP BY 
							U.UnitID
							) V1 ON V1.UnitID = U.UnitID
					left JOIN (
						-- LES SOUSC ET BENEF DÉJÀ CLIENT AU DEBUT DE LA PÉRIODE
						SELECT DISTINCT C1.SubscriberID, C1.BeneficiaryID
						FROM Un_Convention C1
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
									where startDate < @DateFrom
									group by conventionid
									) ccs on ccs.conventionid = cs.conventionid 
										and ccs.startdate = cs.startdate 
										and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
							) css on C1.conventionid = css.conventionid
						)DEJA ON DEJA.SubscriberID = C.SubscriberID AND DEJA.BeneficiaryID = C.BeneficiaryID
					LEFT JOIN #TIN TIN on TIN.UnitID = u.UnitID
					LEFT JOIN #tUnite_T_IBEC t ON t.UnitID = u.UnitID
				WHERE 
					ISNULL(ISNULL(u.dtFirstDeposit,t.dtFirstDeposit),'9999-12-31') BETWEEN @DateFrom AND @DateTo
					and DEJA.SubscriberID is null
					AND TIN.UnitID IS NULL
				GROUP BY RR.vcDescription




		set @i = @i + 1
	end	 --while


	--select *  from #Result

	--RETURN



	INSERT into #Final values (
		100
		,'jira ti-6275 - Q1: TIN - Unités Souscrites - Universitas'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Universitas'),0)

	)

	INSERT into #Final values (
		101
		,'jira ti-6275 - Q1: TIN - Unités Souscrites - Reeeflex'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)

	)


	INSERT into #Final values (
		102
		,'jira ti-6275 - Q1: TIN - Unités Souscrites - Individuel'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Individuel'),0)

	)

	INSERT into #Final values (
		200
		,'jira ti-6275 - Q1: TIN - Montant Souscrit - Universitas'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Universitas'),0)

	)


	INSERT into #Final values (
		201
		,'jira ti-6275 - Q1: TIN - Montant Souscrit - Reeeflex'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)

	)


	INSERT into #Final values (
		202
		,'jira ti-6275 - Q1: TIN - Montant Souscrit - Individuel'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Individuel'),0)

	)


	INSERT into #Final values (
		210
		,'jira ti-6275 - Q1: TIN - EpargneEncaissePeriode - Universitas'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		)

	INSERT into #Final values (
		211
		,'jira ti-6275 - Q1: TIN - EpargneEncaissePeriode - Reeeflex'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		)


	INSERT into #Final values (
		212
		,'jira ti-6275 - Q1: TIN - EpargneEncaissePeriode - Individuel'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		)



	--INSERT into #Final values (
	--	220
	--	,'jira ti-6275 - Q1: TIN - SceeEtBECEncaissePeriode - Universitas'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
	--	)


	--INSERT into #Final values (
	--	221
	--	,'jira ti-6275 - Q1: TIN - SceeEtBECEncaissePeriode - Reeeflex'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
	--	)


	--INSERT into #Final values (
	--	222
	--	,'jira ti-6275 - Q1: TIN - SceeEtBECEncaissePeriode - Individuel'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
	--	)

	INSERT into #Final values (
		230
		,'jira ti-6275 - Q1: TIN - EpargneTIN - Universitas'
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Universitas'),0)

	)

	INSERT into #Final values (
		231
		,'jira ti-6275 - Q1: TIN - EpargneTIN - Reeeflex'
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)

	)

	INSERT into #Final values (
		232
		,'jira ti-6275 - Q1: TIN - EpargneTIN - Individuel'
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Individuel'),0)

	)

	INSERT into #Final values (
		240
		,'jira ti-6275 - Q1: TIN - FraisTIN - Universitas'
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Universitas'),0)

	)


	INSERT into #Final values (
		241
		,'jira ti-6275 - Q1: TIN - FraisTIN - Reeeflex'
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)

	)

	INSERT into #Final values (
		242
		,'jira ti-6275 - Q1: TIN - FraisTIN - Individuel'
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select FraisTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Individuel'),0)

	)

	INSERT into #Final values (
		250
		,'jira ti-6275 - Q1: TIN - SubvTIN - Universitas'
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Universitas'),0)

	)

	INSERT into #Final values (
		251
		,'jira ti-6275 - Q1: TIN - SubvTIN - Reeeflex'
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)

	)

	INSERT into #Final values (
		252
		,'jira ti-6275 - Q1: TIN - SubvTIN - Individuel'
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select SubvTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Individuel'),0)

	)

	INSERT into #Final values (
		260
		,'jira ti-6275 - Q1: TIN - RendementTIN - Universitas'
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
	)

	INSERT into #Final values (
		261
		,'jira ti-6275 - Q1: TIN - RendementTIN - Reeeflex'
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
	)

	INSERT into #Final values (
		262
		,'jira ti-6275 - Q1: TIN - RendementTIN - Individuel'
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select RendementTIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
	)

	INSERT into #Final values (
		270
		,'jira ti-6275 - Q1: TIN - NbSouscripteur = Universitas'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Universitas'),0)
	)
	INSERT into #Final values (
		271
		,'jira ti-6275 - Q1: TIN - NbSouscripteur - Reeeflex'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Reeeflex'),0)
	)
	INSERT into #Final values (
		272
		,'jira ti-6275 - Q1: TIN - NbSouscripteur - Individuel'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q1%' AND Regime = 'Individuel'),0)
	)

	INSERT into #Final values (
		300
		,'jira ti-6275 - Q2: Ajout d''engagement - Unités Souscrites - Universitas'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
	)
	INSERT into #Final values (
		301
		,'jira ti-6275 - Q2: Ajout d''engagement - Unités Souscrites - Reeeflex'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
	)
	INSERT into #Final values (
		302
		,'jira ti-6275 - Q2: Ajout d''engagement - Unités Souscrites - Individuel'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
	)

	INSERT into #Final values (
		400
		,'jira ti-6275 - Q2: Ajout d''engagement - Montant Souscrit - Universitas'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
	)

	INSERT into #Final values (
		401
		,'jira ti-6275 - Q2: Ajout d''engagement - Montant Souscrit - Reeeflex'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
	)


	INSERT into #Final values (
		402
		,'jira ti-6275 - Q2: Ajout d''engagement - Montant Souscrit - Individuel'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
	)


	INSERT into #Final values (
		410
		,'jira ti-6275 - Q2: Ajout d''engagement - EpargneEncaissePeriode - Universitas'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		)


	INSERT into #Final values (
		411
		,'jira ti-6275 - Q2: Ajout d''engagement - EpargneEncaissePeriode - Reeeflex'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		)

	INSERT into #Final values (
		412
		,'jira ti-6275 - Q2: Ajout d''engagement - EpargneEncaissePeriode - Individuel'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		)

	--INSERT into #Final values (
	--	420
	--	,'jira ti-6275 - Q2: Ajout d''engagement - SceeEtBECEncaissePeriode - Universitas'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
	--	)
	--INSERT into #Final values (
	--	421
	--	,'jira ti-6275 - Q2: Ajout d''engagement - SceeEtBECEncaissePeriode - Reeeflex'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
	--	)
	--INSERT into #Final values (
	--	422
	--	,'jira ti-6275 - Q2: Ajout d''engagement - SceeEtBECEncaissePeriode - Individuel'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
	--	)

	INSERT into #Final values (
		430
		,'jira ti-6275 - Q2: Ajout d''engagement - NbSouscripteur - Universitas'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Universitas'),0)
		)
	INSERT into #Final values (
		431
		,'jira ti-6275 - Q2: Ajout d''engagement - NbSouscripteur - Reeeflex'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Reeeflex'),0)
		)
	INSERT into #Final values (
		432
		,'jira ti-6275 - Q2: Ajout d''engagement - NbSouscripteur - Individuel'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q2%' AND Regime = 'Individuel'),0)
		)

	INSERT into #Final values (
		500
		,'jira ti-6275 - Q3: Forfait 12 ans - Unités Souscrites - Universitas'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
	)
	INSERT into #Final values (
		501
		,'jira ti-6275 - Q3: Forfait 12 ans - Unités Souscrites - Reeeflex'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
	)
	INSERT into #Final values (
		502
		,'jira ti-6275 - Q3: Forfait 12 ans - Unités Souscrites = Individuel'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
	)

	INSERT into #Final values (
		600
		,'jira ti-6275 - Q3: Forfait 12 ans - Montant Souscrit - Universitas'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
	)
	INSERT into #Final values (
		601
		,'jira ti-6275 - Q3: Forfait 12 ans - Montant Souscrit - Reeeflex'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
	)
	INSERT into #Final values (
		602
		,'jira ti-6275 - Q3: Forfait 12 ans - Montant Souscrit - Individuel'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
	)

	INSERT into #Final values (
		610
		,'jira ti-6275 - Q3: Forfait 12 ans - EpargneEncaissePeriode - Universitas'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		)
	INSERT into #Final values (
		611
		,'jira ti-6275 - Q3: Forfait 12 ans - EpargneEncaissePeriode - Reeeflex'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		)
	INSERT into #Final values (
		612
		,'jira ti-6275 - Q3: Forfait 12 ans - EpargneEncaissePeriode - Individuel'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		)


	--INSERT into #Final values (
	--	620
	--	,'jira ti-6275 - Q3: Forfait 12 ans - SceeEtBECEncaissePeriode - Universitas'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
	--	)
	--INSERT into #Final values (
	--	621
	--	,'jira ti-6275 - Q3: Forfait 12 ans - SceeEtBECEncaissePeriode - Reeeflex'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
	--	)
	--INSERT into #Final values (
	--	622
	--	,'jira ti-6275 - Q3: Forfait 12 ans - SceeEtBECEncaissePeriode - Individuel'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
	--	)


	INSERT into #Final values (
		630
		,'jira ti-6275 - Q3: Forfait 12 ans - NbSouscripteur - Universitas'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Universitas'),0)
		)
	INSERT into #Final values (
		631
		,'jira ti-6275 - Q3: Forfait 12 ans - NbSouscripteur - Reeeflex'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Reeeflex'),0)
		)

	INSERT into #Final values (
		632
		,'jira ti-6275 - Q3: Forfait 12 ans - NbSouscripteur - Individuel'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q3%' AND Regime = 'Individuel'),0)
		)


	INSERT into #Final values (
		700
		,'jira ti-6275 - Q4: Forfait 11 ans - Unités Souscrites - Universitas'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
	)
	INSERT into #Final values (
		701
		,'jira ti-6275 - Q4: Forfait 11 ans - Unités Souscrites - Reeeflex'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
	)

	INSERT into #Final values (
		702
		,'jira ti-6275 - Q4: Forfait 11 ans - Unités Souscrites - Individuel'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
	)

	INSERT into #Final values (
		800
		,'jira ti-6275 - Q4: Forfait 11 ans - Montant Souscrit - Universitas'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
	)
	INSERT into #Final values (
		801
		,'jira ti-6275 - Q4: Forfait 11 ans - Montant Souscrit - Reeeflex'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
	)
	INSERT into #Final values (
		802
		,'jira ti-6275 - Q4: Forfait 11 ans - Montant Souscrit - Individuel'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
	)


	INSERT into #Final values (
		810
		,'jira ti-6275 - Q4: Forfait 11 ans - EpargneEncaissePeriode - Universitas'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		)
	INSERT into #Final values (
		811
		,'jira ti-6275 - Q4: Forfait 11 ans - EpargneEncaissePeriode - Reeeflex'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		)
	INSERT into #Final values (
		812
		,'jira ti-6275 - Q4: Forfait 11 ans - EpargneEncaissePeriode - Individuel'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		)


	--INSERT into #Final values (
	--	820
	--	,'jira ti-6275 - Q4: Forfait 11 ans - SceeEtBECEncaissePeriode - Universitas'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
	--	)
	--INSERT into #Final values (
	--	821
	--	,'jira ti-6275 - Q4: Forfait 11 ans - SceeEtBECEncaissePeriode - Reeeflex'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
	--	)
	--INSERT into #Final values (
	--	822
	--	,'jira ti-6275 - Q4: Forfait 11 ans - SceeEtBECEncaissePeriode - Individuel'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
	--	)


	INSERT into #Final values (
		830
		,'jira ti-6275 - Q4: Forfait 11 ans - NbSouscripteur - Universitas'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Universitas'),0)
		)
	INSERT into #Final values (
		831
		,'jira ti-6275 - Q4: Forfait 11 ans - NbSouscripteur - Reeeflex'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Reeeflex'),0)
		)
	INSERT into #Final values (
		832
		,'jira ti-6275 - Q4: Forfait 11 ans - NbSouscripteur - Individuel'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q4%' AND Regime = 'Individuel'),0)
		)


--'Q5 - Nouveau Client'


	INSERT into #Final values (
		840
		,'Q5 - Nouveau Client - Unités Souscrites - Universitas'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
	)
	INSERT into #Final values (
		841
		,'Q5 - Nouveau Client - Unités Souscrites - Reeeflex'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
	)

	INSERT into #Final values (
		842
		,'Q5 - Nouveau Client - Unités Souscrites - Individuel'
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
	)

	INSERT into #Final values (
		843
		,'Q5 - Nouveau Client - Montant Souscrit - Universitas'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
	)
	INSERT into #Final values (
		844
		,'Q5 - Nouveau Client - Montant Souscrit - Reeeflex'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
	)
	INSERT into #Final values (
		845
		,'Q5 - Nouveau Client - Montant Souscrit - Individuel'
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
	)


	INSERT into #Final values (
		846
		,'Q5 - Nouveau Client - EpargneEncaissePeriode - Universitas'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		)
	INSERT into #Final values (
		847
		,'Q5 - Nouveau Client - EpargneEncaissePeriode - Reeeflex'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		)
	INSERT into #Final values (
		848
		,'Q5 - Nouveau Client - EpargneEncaissePeriode - Individuel'
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select EpargneEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		)


	--INSERT into #Final values (
	--	849
	--	,'Q5 - Nouveau Client - SceeEtBECEncaissePeriode - Universitas'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
	--	)
	--INSERT into #Final values (
	--	850
	--	,'Q5 - Nouveau Client - SceeEtBECEncaissePeriode - Reeeflex'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
	--	)
	--INSERT into #Final values (
	--	851
	--	,'Q5 - Nouveau Client - SceeEtBECEncaissePeriode - Individuel'
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
	--	,ISNULL((select SceeEtBECEncaissePeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
	--	)


	INSERT into #Final values (
		852
		,'Q5 - Nouveau Client - NbSouscripteur - Universitas'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Universitas'),0)
		)
	INSERT into #Final values (
		853
		,'Q5 - Nouveau Client - NbSouscripteur - Reeeflex'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Reeeflex'),0)
		)
	INSERT into #Final values (
		854
		,'Q5 - Nouveau Client - NbSouscripteur - Individuel'
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		,ISNULL((select NbSouscripteur from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND demande like '%Q5%' AND Regime = 'Individuel'),0)
		)


	SELECT * from #Final order by Sort


	--drop table #Result

END
