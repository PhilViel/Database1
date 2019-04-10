/********************************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psREPR_RapportCotisationEncaissePourCalculBoniDirecteur
Nom du service		: Obtenir les solde de cotisation pour le calcul des bonis des directeurs
But 				: jira ti-7265  Obtenir les solde de cotisation pour le calcul des bonis des directeurs 

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						

Exemple d’appel		:	EXECUTE psREPR_RapportCotisationEncaissePourCalculBoniDirecteur '2018-01-01', '2018-01-31'

Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------- -----------------------------------------	------------
		2017-03-15		Donald Huppé		Création du service				
		2018-02-08		Donald Huppé		Ajout des contrat T après le UNION ALL
		2018-05-02		Donald Huppé		ajout de or c.PlanID = 4
		2018-09-07		Maxime Martel		JIRA MP-699 Ajout de OpertypeID COU
*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psREPR_RapportCotisationEncaissePourCalculBoniDirecteur]
    (
		@DateDu datetime
		,@DateAu datetime
    )
AS 
BEGIN



	CREATE table #Mois (id int, nom varchar(30))
		insert INTO #Mois values ( 1, 'Janvier')
		insert INTO #Mois values ( 2, 'Février')
		insert INTO #Mois values ( 3, 'Mars')
		insert INTO #Mois values ( 4, 'Avril')
		insert INTO #Mois values ( 5, 'Mai')
		insert INTO #Mois values ( 6, 'Juin')
		insert INTO #Mois values ( 7, 'Juillet')
		insert INTO #Mois values ( 8, 'Août')
		insert INTO #Mois values ( 9, 'Septembre')
		insert INTO #Mois values ( 10, 'Octobre')
		insert INTO #Mois values ( 11, 'Novembre')
		insert INTO #Mois values ( 12, 'Décembre')


	SELECT UnitID,	RepID,	BossID,	dtFirstDeposit 
	INTO #Unit_T
	FROM fntREPR_ObtenirUniteConvT (1)	


	CREATE TABLE #tOperTable(
		OperID INT PRIMARY KEY)

	INSERT INTO #tOperTable(OperID)
		SELECT 
			OperID
		FROM Un_Oper o WITH(NOLOCK) 
		WHERE OperDate BETWEEN @DateDu AND @DateAu
				AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI TIN NSF OUT RES RET COU', 1) > 0
		


	select 
		v2.AnneeDepot
		,v2.Mois
		,v2.NoMois
		,v2.Directeur
		,EpargeNouveauContrat = SUM(CASE WHEN v2.NouveauContrat_vs_AjoutUnité = 'NouveauContrat' THEN v2.Epargne ELSE 0 END)
		,FraisNouveauContrat = SUM(CASE WHEN v2.NouveauContrat_vs_AjoutUnité = 'NouveauContrat' THEN v2.frais ELSE 0 END)
		,EpargeAjoutCotisation = SUM(CASE WHEN v2.NouveauContrat_vs_AjoutUnité = 'AjoutUnité' THEN v2.Epargne ELSE 0 END)
		,FraisAjoutCotisation = SUM(CASE WHEN v2.NouveauContrat_vs_AjoutUnité = 'AjoutUnité' THEN v2.frais ELSE 0 END)
		,TotalEpargne = SUM(v2.Epargne)
		,TotalFrais = SUM(v2.Frais)
		,TotalCotisation = SUM(v2.Epargne + v2.Frais)

	from (


			select 

				Directeur
				,AnneeDepot
				,NoMois
				,Mois = M.nom
				,Epargne = sum(Epargne)
				,Frais = sum(Frais)

				,Statut1erDepotDansAnnee

				,NouveauContrat_vs_AjoutUnité
				,Regime
				,Modalité

			from (

						select 

							Directeur = CASE 
										WHEN HB.HumanID IS NULL OR HB.HumanID = 149876 THEN HBS.FirstName + ' ' + HBS.LastName 
										ELSE hb.FirstName + ' ' + hb.LastName
										END
							,AnneeDepot = year(o.OperDate)
							,NoMois = month(o.OperDate)
							,Epargne = sum(ct.Cotisation)
							,Frais =sum(ct.Fee)

							,Statut1erDepotDansAnnee = case 
												WHEN YEAR(u.dtFirstDeposit) < year(o.OperDate) then 'AVANT_Annee'
												WHEN YEAR(u.dtFirstDeposit) = year(o.OperDate) then 'DANS_Annee'
												ELSE 'ND'
												END


							,NouveauContrat_vs_AjoutUnité = CASE WHEN u.UnitID = mu.MinUnitID then 'NouveauContrat' else 'AjoutUnité' end
							,Regime = CASE 
											when p.PlanTypeID = 'IND' then rr.vcDescription + '_' +  SUBSTRING(c.ConventionNo,1,1)
											else rr.vcDescription
										END


							,Modalité = case
									when m.PmtQty = 1 then 'Unique'
									WHEN m.PmtByYearID = 12 then 'Mensuelle'
									when m.PmtQty > 1 and m.PmtByYearID = 1 then 'Annuelle'
									end

							,c.ConventionNo
							,u.UnitID
							,mu.MinUnitID
							,mu.Date1erDepotConv

						from 
							un_cotisation ct --on ct.UnitID = u.UnitID
							join un_oper o on ct.OperID = o.OperID
							join #tOperTable ot on ot.OperID = o.OperID
							join Un_Unit u on u.UnitID = ct.UnitID
							join Un_Convention c on c.ConventionID = u.ConventionID
							JOIN Un_Subscriber S ON C.SubscriberID = S.SubscriberID
							join Un_Modal m on u.ModalID = m.ModalID
							join Un_Plan P on p.PlanID = c.PlanID
							join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime


						
							--JOIN Un_OperType OT  ON OT.OperTypeID = O.OperTypeID
							left join (
								SELECT 
									M.UnitID,
									BossID = MAX(RBH.BossID)
								FROM (
									SELECT 
										U.UnitID,
										U.RepID,
										RepBossPct = MAX(RBH.RepBossPct)
									FROM Un_Unit U
									JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
									JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
									JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
									GROUP BY U.UnitID, U.RepID
									) M
								JOIN Un_Unit U ON U.UnitID = M.UnitID
								JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
								GROUP BY 
									M.UnitID
									)bu on bu.UnitID = u.UnitID
							left join Mo_Human hb on bu.BossID = hb.HumanID
							LEFT JOIN (
								SELECT
									RB.RepID,
									BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
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
								)BR ON BR.RepID = S.RepID
							LEFT JOIN Mo_Human HBS ON HBS.HumanID = BR.BossID
							left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
							left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
							left join (
								select u1.ConventionID, MinUnitID =  min(u1.UnitID), Date1erDepotConv = min(u1.dtFirstDeposit)
								from Un_Unit u1
								GROUP BY u1.ConventionID
								) mu on  mu.ConventionID = u.ConventionID --and mu.MinUnitID = u.UnitID
							left join #Unit_T t on t.unitid = u.UnitID
						where 1=1
							and t.unitid is null
							AND (u.dtFirstDeposit BETWEEN @DateDu and @DateAu or c.PlanID = 4)
							------------------- Même logique que dans les rapports d'opération cashing et payment --------------------

							AND tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
							AND tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
							-----------------------------------------------------------------------------------------------------------

						

						group by 
							bu.BossID
							,hb.FirstName + ' ' +hb.LastName
							,c.ConventionNo
							,u.UnitID
							,mu.MinUnitID
							,u.dtFirstDeposit


							,mu.Date1erDepotConv

							,m.PmtQty
							,m.PmtByYearID
				
							,HB.HumanID
							,HBS.FirstName
							,HBS.LastName 


							,p.PlanTypeID
							,rr.vcDescription
							,year(o.OperDate)
							,month(o.OperDate)

					UNION ALL

						-- contrat T et I BEC

						select 
							--Rep = hr.FirstName + ' ' + hr.LastName,
							--r.RepCode,
							Directeur = hb.FirstName + ' ' + hb.LastName
							,AnneeDepot = year(o.OperDate)
							,NoMois = month(o.OperDate)
							,Epargne = sum(ct.Cotisation)
							,Frais =sum(ct.Fee)

							,Statut1erDepotDansAnnee = case 
												WHEN YEAR(u.dtFirstDeposit) < year(o.OperDate) then 'AVANT_Annee'
												WHEN YEAR(u.dtFirstDeposit) = year(o.OperDate) then 'DANS_Annee'
												ELSE 'ND'
												END


							,NouveauContrat_vs_AjoutUnité = 'AjoutUnité'
							,Regime = CASE 
											when p.PlanTypeID = 'IND' then rr.vcDescription + '_' +  SUBSTRING(c.ConventionNo,1,1)
											else rr.vcDescription
										END


							,Modalité = case
									when m.PmtQty = 1 then 'Unique'
									WHEN m.PmtByYearID = 12 then 'Mensuelle'
									when m.PmtQty > 1 and m.PmtByYearID = 1 then 'Annuelle'
									end

							,c.ConventionNo
							,u.UnitID
							,mu.MinUnitID
							,mu.Date1erDepotConv

						from 
							un_cotisation ct --on ct.UnitID = u.UnitID
							join un_oper o on ct.OperID = o.OperID
							join #tOperTable ot on ot.OperID = o.OperID
							join Un_Unit u on u.UnitID = ct.UnitID

							join #Unit_T t on t.unitid = u.UnitID

							join Un_Convention c on c.ConventionID = u.ConventionID
							JOIN Un_Subscriber S ON C.SubscriberID = S.SubscriberID
							join Un_Modal m on u.ModalID = m.ModalID
							join Un_Plan P on p.PlanID = c.PlanID
							join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
							JOIN Un_Rep r on r.RepID = t.RepID
							join Mo_Human hr on hr.HumanID = r.RepID

							join Mo_Human hb on hb.HumanID = T.BossID

							left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
							left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
							left join (
								select u1.ConventionID, MinUnitID =  min(u1.UnitID), Date1erDepotConv = min(u1.dtFirstDeposit)
								from Un_Unit u1
								GROUP BY u1.ConventionID
								) mu on  mu.ConventionID = u.ConventionID --and mu.MinUnitID = u.UnitID
							
						where 1=1
							
							--AND u.dtFirstDeposit BETWEEN @DateDu and @DateAu
							------------------- Même logique que dans les rapports d'opération cashing et payment --------------------

							AND tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
							AND tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
							-----------------------------------------------------------------------------------------------------------

						

						group by 
							hr.FirstName + ' ' + hr.LastName,
							r.RepCode,
							 hb.FirstName + ' ' + hb.LastName
							, year(o.OperDate)
							, month(o.OperDate)
							,p.PlanTypeID,rr.vcDescription,c.ConventionNo
							,m.PmtQty,m.PmtByYearID
							,u.UnitID
							,mu.MinUnitID
							,mu.Date1erDepotConv
							,u.dtFirstDeposit


					) v
				join #Mois m on v.NoMois = m.id
			GROUP BY
				Directeur
				,AnneeDepot
				,NoMois
				,M.nom
				,Statut1erDepotDansAnnee

				,NouveauContrat_vs_AjoutUnité
				,Regime
				,Modalité

		)v2
	GROUP by 
		v2.AnneeDepot
		,v2.Mois
		,v2.Directeur
		,v2.NoMois
	ORDER BY
		v2.AnneeDepot
		,v2.NoMois
		,v2.Directeur
	

END