/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	FN_UN_RepContestREP_Bulletin (basé sur RP_UN_RepContestREP pour le rapport Concours)
Description         :	Fonction utilisée par la SP RP_UN_BulletinHebdo pour le rappport BulletinHebdoRep
Valeurs de retours  :	Table 
Note                :		2009-02-22	Donald Huppé	    Création
							2009-03-18	Donald Huppé	    Ajustement suite au ajustement du 2009-01-30 fait dans RP_UN_RepContestREP
							2009-04-27	Donald Huppé	    Sortir les Net ventilés par plan afin d'afficer les % de chaque plan
							2009-05-19	Donald Huppé
														    -Retiré le 21-09-09 avant mise en prod :  Correction du calcul de la rétention dans #tTransferedUnits.  
														    On part maintenant des unités brutes (UnitQty + réduction) au lieu des unités nettes (UnitQty). 
														    Cela et plus logique et stabilise les résultats peu importe quand on sort le rapport

														    -Correction du calcul de la rétention.  On vérifie qu'il s'agit du même rep et même souscripteur.  
														    On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert.

														    -Modification des Réinscriptions de frais non couverts.  (Demande de Pascal Gilbert)
														    On les sépare des retraits de frais non couverts eu lieu de les soustraire de ceux-ci. 
														    Et on les sort à la date de la réinscription (et non à la date du retrait). 
														    Cela stabilise les résultats peu importe quand on sort le rapport. 

							2009-09-30	Donald Huppé	    Mise en production

							2009-10-02	donald Huppé	    Enlever le critère : La réinscription doit correspondre à une réduction de moins de 24 mois

							2009-12-17	Donald Huppé	    GLPI 2761 : correction d'une erreur dans le calcul du brut par rapport à la rétention.  
														    Faire "WHEN NbUnitesAjoutees > 0 THEN" au lieu de "WHEN NbUnitesAjoutees >= 0 THEN"
														    N'aurait jamais du être comme ça
							2010-01-08	Donald Huppé	    Ajustement pour les cas de divorce quand il n'y a pas de Directeur associé au inforceDate du Unitid
														    Alors on met "nd", et on gère cette valeur dans la SP appelante
							2010-01-11	Donald Huppé	    Ajout du plan 12
                            2018-10-29  Pierre-Luc Simard   N'est plus utilisée

select * from FN_UN_RepContestREP_Bulletin ('2009-01-01', '2009-12-31') where repid = 436873

*********************************************************************************************************************/
CREATE FUNCTION [dbo].[FN_UN_RepContestREP_Bulletin] (

	@StartDate DATETIME,
	@EndDate DATETIME ) 

RETURNS @Final
	TABLE (
		RepID int,
		Recruit int,
		RepCode varchar(75),
		AgencyRepCode varchar(75),
		LastName varchar(255),
		FirstName varchar(255),
		BusinessStart DATETIME,
		Agency varchar(255),
		Province varchar(255),
		Region varchar(255),
		Brut float,
		Terminated float,
		ReUsed float,
		Net float,
		NetInd float,
		NetUniv float,
		NetRflex float

		)
BEGIN

	declare @TauxReeeflex float
	set @TauxReeeflex = 1.25/0 -- Pour faire planter

	-- Final
	insert into @Final

	SELECT
		Final.RepID,
		Recruit,
		R.RepCode,
		AgencyRepCode = ISNULL(AgencyRepCode,'nd'),
		LastName,
		FirstName,
		BusinessStart,
		Agency = ISNULL(Agency,'nd'),
		Province = case when Agency like '%Logelin%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end, 
		Region,
		Brut = sum(Brut),
		Terminated = sum(Terminated),
		ReUsed = SUM(ReUsed),
		Net = sum(Net),				-- Net Total pour tous les Plans
		NetInd = sum(NetInd),		-- Net Individuel
		NetUniv = sum(NetUniv),		-- Net Universitas
		NetRflex = sum(NetRflex)	-- Net ReeeFlex

	from (

		SELECT
			V.RepID,
			V.Recruit,
			V.AgencyRepCode,
			V.LastName,
			V.FirstName,
			V.Agency,
			V.Region,
			V.Brut,
			V.Terminated,
			v.ReUsed,
			V.Net,
			V.NetInd,
			V.NetUniv,
			V.NetRflex

		FROM (
			SELECT
				R.RepID,
				Recruit = dbo.fn_Un_IsRecruit(R.BusinessStart, U.dtFirstDeposit),
				AgencyRepCode = RB.RepCode,
				H.LastName,
				H.FirstName,
				Agency = B.FirstName + ' ' + B.LastName,
				Region,
				C.PlanID, -- 
				Brut = ISNULL(SUM(N.UnitQty),0) * case when c.planid in (10,12) then @TauxReeeflex else 1 end,
				Terminated = ISNULL(SUM(T.UnitQty),0) * case when c.planid in (10,12) then @TauxReeeflex else 1 end,
				ReUsed = ISNULL(SUM(RE.UnitQty),0) * case when c.planid in (10,12) then @TauxReeeflex else 1 end,
				Net = (ISNULL(SUM(N.UnitQty),0) - (ISNULL(SUM(T.UnitQty),0)-ISNULL(SUM(RE.UnitQty),0))) * case when c.planid in (10,12) then @TauxReeeflex else 1 end,
				NetInd = case when c.planid = 4 then (ISNULL(SUM(N.UnitQty),0) - (ISNULL(SUM(T.UnitQty),0)-ISNULL(SUM(RE.UnitQty),0)))  else 0 end,
				NetUniv =  case when c.planid = 8 then (ISNULL(SUM(N.UnitQty),0) - (ISNULL(SUM(T.UnitQty),0)-ISNULL(SUM(RE.UnitQty),0)))  else 0 end,
				NetRflex =  case when c.planid in (10,12) then  @TauxReeeflex * (ISNULL(SUM(N.UnitQty),0) - (ISNULL(SUM(T.UnitQty),0)-ISNULL(SUM(RE.UnitQty),0)))  else 0 end
			FROM dbo.Un_Unit U
			JOIN dbo.Un_Convention C on u.conventionid = c.conventionid
			JOIN dbo.Mo_Human HS on HS.humanid = c.subscriberid
			join (
				select
					adrid, 
					a.zipcode,
					CP2.CO_POSTL,
					Region =	case 
								when CP2.CO_POSTL is not null then case when CP2.CO_REGN_ADMNS = 11 then 'Gaspésie-Îles-Madeleine' else CP2.NM_REGN_ADMNS end 
								when CP2.CO_POSTL is null and a.zipcode like 'E%' then 'N.-Brunswick' 
								when CP2.CO_POSTL is null then '**Code postal inconnu**' 
								end
				FROM dbo.Mo_Adr a 
				left join (
						select CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						from GUI.dbo.CodePostalRegionAdm  CP
						join (
							select CO_POSTL, CO_REGN_ADMNS = max(CO_REGN_ADMNS) from GUI.dbo.CodePostalRegionAdm group by CO_POSTL
							) MaxCP on CP.CO_POSTL = MaxCP.CO_POSTL and CP.CO_REGN_ADMNS = MaxCP.CO_REGN_ADMNS
						group by CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						) CP2 on CP2.CO_POSTL = replace(a.zipcode,' ','')
					) AdrS on hs.adrID = AdrS.adrID
			JOIN Un_Rep R ON U.RepID = R.RepID
			JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
/*			JOIN ( -- #MaxPctBoss
					SELECT
						RB.RepID,
						BossID = MAX(BossID)
					FROM Un_RepBossHist RB
					JOIN (
						SELECT
							RepID,
							RepBossPct = MAX(RepBossPct)
						FROM Un_RepBossHist RB
						WHERE RepRoleID = 'DIR'
							AND StartDate IS NOT NULL
							AND (StartDate <= @EndDate)
							AND (EndDate IS NULL OR EndDate >= @EndDate)
						GROUP BY
							RepID
						) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
					WHERE RB.RepRoleID = 'DIR'
						AND RB.StartDate IS NOT NULL
						AND (RB.StartDate <= @EndDate)
						AND (RB.EndDate IS NULL OR RB.EndDate >= @EndDate)
					GROUP BY
						RB.RepID
				) M ON U.RepID = M.RepID
*/
			-- Le boss du groupe d'unité
			LEFT JOIN (
				SELECT 
					M.UnitID,
					BossID = MAX(RBH.BossID)
				FROM (
					SELECT 
						U.UnitID,
						U.RepID,
						RepBossPct = MAX(RBH.RepBossPct)
					FROM dbo.Un_Unit U
					JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
					JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
					JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
					GROUP BY U.UnitID, U.RepID
					) M
				JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
				JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
				GROUP BY 
					M.UnitID
				) M on U.unitid = M.unitid

			LEFT JOIN UN_REP RB on M.BossID = RB.RepID
			LEFT JOIN dbo.Mo_Human B ON B.HumanID = M.BossID

			LEFT JOIN ( -- #NewSales
					SELECT
						U.UnitID,
						U.RepID,
						UnitQty =	SUM(CASE
											WHEN NbUnitesAjoutees > /*=*/ 0 THEN -- GLPI 2761
												NbUnitesAjoutees
											ELSE 
												U.UnitQty + ISNULL(UR.UnitQty,0)  - ISNULL(S1.fUnitQtyUse, 0)
										END
										)
					FROM dbo.Un_Unit U
						LEFT JOIN (
								SELECT 
									U1.UnitID,
									(U1.UnitQty /*+ isnull(UR1.UnitQty,0)*/)- SUM(A.fUnitQtyUse) AS NbUnitesAjoutees,
									fUnitQtyUse = SUM(A.fUnitQtyUse)
								FROM Un_AvailableFeeUse A 
								JOIN Un_Oper O ON O.OperID = A.OperID
								JOIN Un_Cotisation C ON C.OperID = O.OperID
								JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
								/*LEFT JOIN (
									SELECT 
										UR.UnitID,
										UnitQty = SUM(UR.UnitQty)
									FROM Un_UnitReduction UR
									GROUP BY UR.UnitID
									) UR1 ON UR1.UnitID = U1.UnitID*/
								JOIN dbo.Un_Convention Cv on U1.conventionid = Cv.conventionid
								JOIN Un_UnitReduction UR on a.unitreductionid = UR.unitreductionid 
								JOIN dbo.Un_Unit Uori on UR.unitid = Uori.unitid and Uori.repID = U1.repid -- doit être le même Rep
								JOIN dbo.Un_Convention CvOri on Uori.conventionid = CvOri.conventionid 
												and CvOri.SubscriberID = Cv.SubscriberID -- doit être le même Souscripteur 	--and CvOri.BeneficiaryID = Cv.BeneficiaryID -- On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert 2009-04-15

								WHERE O.OperTypeID = 'TFR'
								  AND (U1.UnitQty - A.fUnitQtyUse) >= 0
								GROUP BY
									U1.UnitID,
									U1.UnitQty--,UR1.UnitQty
								) AS S1 ON (S1.UnitID = U.UnitID)
						LEFT JOIN (
							SELECT 
								UR.UnitID,
								UnitQty = SUM(UR.UnitQty)
							FROM Un_UnitReduction UR
							WHERE UR.ReductionDate >= @StartDate
							GROUP BY UR.UnitID
							) UR ON UR.UnitID = U.UnitID

					WHERE U.dtFirstDeposit BETWEEN @StartDate AND @EndDate
						/*U.dtFirstDeposit >= @StartDate 
						AND( @EndDate IS NULL
							OR U.dtFirstDeposit <= @EndDate )*/
							
					GROUP BY
						U.UnitID,
						U.RepID

					) N ON R.RepID = N.RepID AND U.UnitID = N.UnitID
			LEFT JOIN ( -- #Terminated
					SELECT
						U.UnitID,
						U.RepID,
						UnitQty = SUM( UR.UnitQty)
					FROM Un_UnitReduction UR
					JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
					JOIN Un_Modal M ON M.ModalID = U.ModalID
					LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
					WHERE UR.FeeSumByUnit < M.FeeByUnit
						AND UR.ReductionDate >= @StartDate 
						AND( @EndDate IS NULL OR UR.ReductionDate <= @EndDate )
						AND (URR.bReduitTauxConservationRep = 1	OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
					GROUP BY
						U.UnitID,
						U.RepID
					) T ON R.RepID = T.RepID AND U.UnitID = T.UnitID

			LEFT JOIN ( -- #ReUsed
					SELECT 
						U1.unitid,
						U1.repID,
						UnitQty = SUM(A.fUnitQtyUse)
					FROM Un_AvailableFeeUse A
					JOIN Un_Oper O ON O.OperID = A.OperID
					JOIN Un_Cotisation C ON C.OperID = O.OperID
					JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
					JOIN dbo.Un_Convention Cv on U1.conventionid = Cv.conventionid
					JOIN Un_UnitReduction UR on a.unitreductionid = UR.unitreductionid 
					JOIN dbo.Un_Unit Uori on UR.unitid = Uori.unitid and Uori.repID = U1.repid -- doit être le même Rep
					JOIN dbo.Un_Convention CvOri on Uori.conventionid = CvOri.conventionid 
									and CvOri.SubscriberID = Cv.SubscriberID -- doit être le même Souscripteur 	--and CvOri.BeneficiaryID = Cv.BeneficiaryID -- On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert 2009-04-15
					LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
					JOIN Un_Modal M  ON M.ModalID = Uori.ModalID	
					WHERE U1.dtFirstDeposit BETWEEN @StartDate AND @EndDate

						-- La réinscription doit correspondre à une réduction de moins de 24 mois, pour faire comme dans les unités brutes et nettes
						-- AND (UR.reductionDate > DATEADD(MONTH,-24,@EndDate) and UR.reductionDate <= @EndDate)

						-- La réinscription doit provenir d'une réduction valide (tel que programmé dans les retraits)
						AND  UR.FeeSumByUnit < M.FeeByUnit
						AND (URR.bReduitTauxConservationRep = 1	OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
					GROUP BY
						U1.UnitID,
						U1.RepID
					) RE on	RE.RepID = R.RepID AND RE.UnitID = U.UnitID

			WHERE N.UnitID IS NOT NULL OR T.UnitID IS NOT NULL or RE.UnitID IS NOT NULL -- Il y a un Brut OU un Terminated OU un ReUsed dans la plage de date

			GROUP BY
				R.RepID,
				dbo.fn_Un_IsRecruit(R.BusinessStart, U.dtFirstDeposit),
				RB.RepCode,
				H.LastName,
				H.FirstName,
				B.FirstName,
				B.LastName,
				c.planid,
				AdrS.region
			) V
		) Final

		join un_rep R on R.RepID = Final.RepID

	group by
		Final.RepID,
		Recruit,
		R.RepCode,
		Final.AgencyRepCode,
		LastName,
		FirstName,
		BusinessStart,
		Agency,
		Region

return

END