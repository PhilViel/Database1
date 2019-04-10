/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_VentesRepStat (ancien GU_RP_Stats_Ventes_Rep)
Description         :	Pour le rapport vente trimestriel
Valeurs de retours  :	Dataset 
Note                :	2009-06-30	Donald Huppé	    Créaton 
						2010-01-11	Donald Huppé	    Ajout du plan 12
						2010-01-11	Donald Huppé	    Modification pour gérer la nouvelle SL_UN_RepGrossANDNetUnits avec le champ recrue
													    On Regroupe sans le champ "Recrue"
						2010-03-29	Donald Huppé	    GLPI 3353 + correction d'un bug qui faussait les données sur les retrait et réinscription (à cause d'une clause where sur dtfirstdeposit dans GNU)
						2010-04-06	Donald Huppé	    correction d'un bug sur le calcul du nombre de contrat. on additionnne pour les net > 0
						2010-04-09	Donald Huppé	    PctCtrRflex, PctCtrUniv et NbUnitMoy : on exclu les retraits à la demande de P Gilbert et I Biron
						2010-04-22	Donald Huppé	    Modification pour ne plus associr les rep au directeur en date de fin.
													    GLPI 3469 : ajout du calcul du taux de cons de chaque directeur, afin de l'afficher sur le rapport
													    s'il est unique dans le rapport (voir code dans le rapport)
						2010-07-02	Donald Huppé	    Associer les vente de Mario Béchard à Maryse Breton (GLPI 3852)
													    Ajout du % cons de la cie pour quand on sélectionne tous les rep
						2011-06-14	Donald Huppé	    GLPI 5589 - Ajout du nombre de bénéficiaire et enlever "% cons de la période"
						2013-11-14	Donald Huppé	    glpi 10514 : Attribution des reps aux nouveaux directeurs
						2014-01-06	Donald Huppé	    Suite à glpi 10514, modifier l'utilisation du paramètre @RepID.  filtrer dessu à la fin seulement. 
													    Sinon, l'appel de SL_UN_RepGrossANDNetUnits avec ce paramètre empêche de voir des vente associé à des rep qui change de directeur
						2015-01-14	Donald Huppé	    Le directeur de certain rep est non déterminé (bossID = 0) dans certain cas comme le siège social, donc on fait un left join un Mo_human afin qu'il sorte quand même
						2015-01-27	Donald Huppé	    Correction suite au projet corpo, prendre gnu.repid au lieu de u.repid
						2016-08-09	Donald Huppé	    modifier attribution des rep au agence avec tblREPR_LienAgenceRepresentantConcours (pour faire comme dans le bulletin)
						2016-11-30	Donald Huppé	    Clarifier paramètre d'appel de SL_UN_RepGrossANDNetUnits
                        2018-10-29  Pierre-Luc Simard   Utilisation des regroupements de régime

exec GU_RP_VentesRepStat '2018-01-01', '2018-01-05', 149602

BossPctCons24	CieCons24
0,921275357903167

select * 
from mo_human h
join un_rep r on h.humanid = r.repid
where h.lastname = 'turpin' Ghislain Thibeault
****************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_VentesRepStat] (
	@StartDate DATETIME,
	@EndDate DATETIME,
	@RepID INTEGER) 
as

BEGIN

	Declare @RepIDIsBoss integer -- = 0 ou 1

	create table #Rep (RepID Integer) --, BossID integer)

	Create table #GrossANDNetUnitsOri (
			UnitID_Ori INTEGER, -- Le unitID_Ori permettra à la sp appelante de lier NewSale, terminated et ReUsed ensemble.
			UnitID INTEGER, -- Le unitID et égale au unitID_Ori partout sauf pour la réinscription. Dans ce cas le le unitId représente le nouveau groupe d'unité et le Ori est le group d'unité original.
			RepID INTEGER,
			Recrue INTEGER,
			BossID INTEGER,
			RepTreatmentID INTEGER,
			RepTreatmentDate DATETIME,
			Brut FLOAT,
			Retraits FLOAT,
			Reinscriptions FLOAT,
			Brut24 FLOAT,
			Retraits24 FLOAT,
			Reinscriptions24 FLOAT) 

	Create table #GrossANDNetUnitsConsPct (
			UnitID_Ori INTEGER, -- Le unitID_Ori permettra à la sp appelante de lier NewSale, terminated et ReUsed ensemble.
			UnitID INTEGER, -- Le unitID et égale au unitID_Ori partout sauf pour la réinscription. Dans ce cas le le unitId représente le nouveau groupe d'unité et le Ori est le group d'unité original.
			RepID INTEGER,
			Recrue INTEGER,
			BossID INTEGER,
			RepTreatmentID INTEGER,
			RepTreatmentDate DATETIME,
			Brut FLOAT,
			Retraits FLOAT,
			Reinscriptions FLOAT,
			Brut24 FLOAT,
			Retraits24 FLOAT,
			Reinscriptions24 FLOAT) 

	-- si ce n'est pas un directeur, on load ce rep
	--insert into #Rep select RepID = @RepID where not exists (select RepID from #Rep where RepID = @RepID and @RepID <> 0)

	insert into #GrossANDNetUnitsOri
	exec SL_UN_RepGrossANDNetUnits --NULL, @StartDate, @EndDate, 0 /*@RepID*/, 1
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 

	-- glpi 10514
	-- 2016-08-09 : changer le directeur actuel du rep pour les rep du NB
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnitsOri g
	--JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where LA.BossID = 671417
	--where u.dtFirstDeposit >= '2011-01-01'

	-- 2016-08-09 :
	update #GrossANDNetUnitsOri set BossID = 436381 where BossID = 436873
	update #GrossANDNetUnitsOri set BossID = 149489 where BossID = 440176
	--------------------------------------


	-- glpi 10514-- Associer les unités de Mario Béchard et Sylvain Bibeau(149520) à Maryse Breton
	update #GrossANDNetUnitsOri set bossid = 440176 where bossid in ( 149464,149520) 
	
	-- glpi 10514
	update #GrossANDNetUnitsOri SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602)	

	update #GrossANDNetUnitsOri set BossID = 675096 where BossID = 149614 --Jeannot Turgeon (remplacer son nom par : Cabinet Turgeon & associés(675096))

	-- glpi 10514
	delete from #GrossANDNetUnitsOri 
	where (RepID <> @RepID AND BossID <> @RepID) and @RepID <> 0

	insert into #GrossANDNetUnitsConsPct -- Pour le calcul du taux cons des directeur présent dans la liste finale.
	exec SL_UN_RepGrossANDNetUnits --NULL, @EndDate, @EndDate, 0, 1 -- On demande en date de la fin pour seulement avoir les vente 24 mois
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @EndDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 

	-- glpi 10514
	-- 2016-08-09 : changer le directeur actuel du rep pour les rep du NB
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnitsConsPct g
	--JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	--where u.dtFirstDeposit >= '2011-01-01'
	where LA.BossID = 671417

	-- 2016-08-09 :
	update #GrossANDNetUnitsConsPct set BossID = 436381 where BossID = 436873
	update #GrossANDNetUnitsConsPct set BossID = 149489 where BossID = 440176
	----------------------------------------


	-- glpi 10514-- Associer les unités de Mario Béchard et Sylvain Bibeau(149520) à Maryse Breton
	update #GrossANDNetUnitsConsPct set bossid = 440176 where bossid in ( 149464,149520) 
	
	-- glpi 10514
	update #GrossANDNetUnitsConsPct SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602)	

	update #GrossANDNetUnitsConsPct set BossID = 675096 where BossID = 149614 --Jeannot Turgeon (remplacer son nom par : Cabinet Turgeon & associés(675096))

	-- glpi 10514
	delete from #GrossANDNetUnitsConsPct 
	where (RepID <> @RepID AND BossID <> @RepID) and @RepID <> 0

	-- Regrouper sans le champ "Recrue"
	select 
		UnitID_Ori,
		UnitID,
		RepID,
		BossID,-- = case when BossID = 149464 then 440176 else BossID end, -- GLPI 3852
		RepTreatmentID,
		RepTreatmentDate,
		Brut = sum(Brut),
		Retraits = sum(Retraits),
		Reinscriptions = sum(Reinscriptions),
		Brut24 = sum(Brut24),
		Retraits24 = sum(Retraits24),
		Reinscriptions24 = sum(Reinscriptions24)
	into #GrossANDNetUnits
	from #GrossANDNetUnitsOri
	group by 
		UnitID_Ori,
		UnitID,
		RepID,
		BossID,
		RepTreatmentID,
		RepTreatmentDate

	CREATE INDEX #GNU_UNITID ON #GrossANDNetUnits(UNITID)
	CREATE INDEX #GNU_REPID ON #GrossANDNetUnits(REPID)
	CREATE INDEX #GNU_BOSSID ON #GrossANDNetUnits(BOSSID)

	SELECT 
		groupe = 'bidon', -- Patch car on doit grouper dans SSRS afin d'afficher les entêtes de colone sur toute les pages
		DirFirstName, 
		DirLastName, 
		Ventes_RepUnit.RepID, 
		Ventes_RepUnit.RepCode, 
		Ventes_RepUnit.LastName, 
		Ventes_RepUnit.FirstName, 
		NbCtrRflex = Sum(case when RR.vcCode_Regroupement = 'REF' and Net > 0 then 1 else 0 end),  -- Net > 0 : veut dire qu'on exclut les retraits des ventes faite avant.
		NbCtrUniv = Sum(case when RR.vcCode_Regroupement = 'UNI' and Net > 0 then 1 else 0 end), 
		NbCtrTotal = Sum(case when Net > 0 then 1 else 0 end), -- Est le Nb de groupe d'unité. 

		PctCtrRflex = case 
						when Sum(case when Net > 0 then 1 else 0 end) = 0 then 0
						else CONVERT(FLOAT,Sum(case when RR.vcCode_Regroupement = 'REF' and Net > 0 then 1 else 0 end)) / CONVERT(FLOAT,Sum(case when Net > 0 then 1 else 0 end)) -- on exclu les retrait (de vente faite avant) avec Net > 0
						end , --PourcContratRflex =  CONVERT(FLOAT,NbContratRflex) / CONVERT(FLOAT,NbContratTotal), 
		PctCtrUniv = case 
						when Sum(case when Net > 0 then 1 else 0 end) = 0 then 0
						else CONVERT(FLOAT,Sum(case when RR.vcCode_Regroupement = 'UNI' and Net > 0 then 1 else 0 end)) / CONVERT(FLOAT,Sum(case when Net > 0 then 1 else 0 end))-- on exclu les retrait (de vente faite avant) avec Net > 0
						end,  --PourcContratUniv = CONVERT(FLOAT,NbContratUniv) / CONVERT(FLOAT,NbContratTotal), 

		NbUnitRflex = Sum(case when RR.vcCode_Regroupement = 'REF' and Net > 0 then Net else 0 end), -- Le Net représente le net de la période et exlu les retraits de vente fait avant
		NbUnitUniv = Sum(case when RR.vcCode_Regroupement = 'UNI' and Net > 0 then Net else 0 end), -- Le Net représente le net de la période et exlu les retraits de vente fait avant

		PctUnitRflex = case 
						when Sum(case when Net > 0 then Net else 0 end) = 0 then 0
						else Sum(case when RR.vcCode_Regroupement = 'REF' and Net > 0 then Net else 0 end) / Sum(case when Net > 0 then Net else 0 end)
						End, 
		PctUnitUniv = case 
						when Sum(case when Net > 0 then Net else 0 end) = 0 then 0
						else Sum(case when RR.vcCode_Regroupement = 'UNI' and Net > 0 then Net else 0 end) / Sum(case when Net > 0 then Net else 0 end)
						End, 

		Cons24.PctCons24,
		PctConsPer = case -- Peut être plus que 100 car les réinscriptions(inclu dans le Net) peuvent correspondre à un retraits précédent la plage demandée
						when Sum(Ventes_RepUnit.Brut) = 0 then 0 
						else Sum(Ventes_RepUnit.Net) / Sum(Ventes_RepUnit.Brut) 
						end,
		NbUnitBrut = Sum(Ventes_RepUnit.Brut), 
		NbUnitNet = Sum(Ventes_RepUnit.Net), 
		NbUnitRetrait = Sum(Ventes_RepUnit.Retraits), 
		NbUnitReinsc = Sum(Ventes_RepUnit.Reinscriptions), 
		NbUnitMoy = case
					when sum(case when Ventes_RepUnit.Net > 0 then 1 else 0 end) = 0 then 0
					else sum(case when Ventes_RepUnit.Net > 0 then Ventes_RepUnit.Net else 0 end)  / sum(case when Ventes_RepUnit.Net > 0 then 1 else 0 end)-- : unités brutes ÷ nombre contrats. On ne tient pas compte des retraits, donc le brut doit être > 0. -- Avg(Ventes_RepUnit.Brut), 
					end,
		MntAnnuelNet = Sum(case when Net > 0 then (case when PmtQty = 1 then isnull(CotisationFrais,0) else Net * PmtByYearID * PmtRate end) else 0 end) ,
		AgeBenefMoy = case
						when Sum(case when Net > 0 then 1 else 0 end) = 0 then 0 
						else sum(case when Net > 0 then Ventes_RepUnit.AgeBenef else 0 end) / Sum(case when Net > 0 then 1 else 0 end)
					end,
					--Avg(Ventes_RepUnit.AgeBenef), 
		Provenance_G = Sum(case when Left(ZipCode,1) = 'G' and Net > 0 then Net else 0 end), 
		Provenance_H = Sum(case when Left(ZipCode,1) = 'H' and Net > 0 then Net else 0 end), 
		Provenance_J = Sum(case when Left(ZipCode,1) = 'J' and Net > 0 then Net else 0 end), 
		Ventes_RepUnit.AgeRep, 
		Ventes_RepUnit.AnneeService, 
		NbUnitAutonomie = Sum(case when SaleSourceID in (4,5,7,8,9) and Net > 0 then Net else 0 end)
		,PctAutonomie = case
						when Sum(case when Net > 0 then Net else 0 end) = 0 then 0
						else Sum(case when SaleSourceID in (4,5,7,8,9) and Net > 0 then Net else 0 end) / Sum(case when Net > 0 then Net else 0 end)
						end 

		,NbUnitUnivNet = Sum(case when RR.vcCode_Regroupement = 'UNI' then Net else 0 end)   
		,NbUnitRflexNet = Sum(case when RR.vcCode_Regroupement = 'REF' then Net else 0 end)
		,NbUnitIndNet = Sum(case when RR.vcCode_Regroupement = 'IND' then Net else 0 end)
		,NbUnitUnivBrut = Sum(case when RR.vcCode_Regroupement = 'UNI' then Brut else 0 end)   
		,NbUnitRflexBrut = Sum(case when RR.vcCode_Regroupement = 'REF' then Brut else 0 end)  
		,NbUnitIndBrut = Sum(case when RR.vcCode_Regroupement = 'IND' then Brut else 0 end)
		,BossCons24.BossPctCons24
		,CieCons24.CieCons24
		,NbBenefRep
		,NbBenefBoss
		,NbBenefCie

	from
		(
		select 
			GNU.RepID,  --2015-01-27
			GNU.BossID,
			U.UnitID, 
			GNU.Brut,-- = UnitQty + isnull(UnitResilPendantApres,0), 
			Retraits = GNU.Retraits, -- = Stats_Ventes_RepUnit_Resil_Pendant.UnitResilPendant, 
			GNU.Reinscriptions,
			Net = GNU.Brut - GNU.Retraits + GNU.Reinscriptions, --= UnitQty + isnull(UnitResilPendantApres,0)-isnull(UnitResilPendant,0), 
			C.PlanID, 
			R.RepCode, 
			HRep.LastName, 
			HRep.FirstName, 
			DirFirstName = isnull(HDir.FirstName,'ND'),
			DirLastName = isnull(HDir.LastName,'ND'),
			AgeRep = dbo.fn_Mo_Age(HRep.BirthDate, @EndDate),
			AnneeService = round(DATEDIFF(DAY, BusinessStart, @EndDate)/365.25,1),
			RepActif = case when R.BusinessEnd = Null Or R.BusinessEnd >= @EndDate then -1 else 0 end, 
			A.ZipCode, 
			AgeBenef = dbo.fn_Mo_Age(HB.BirthDate, U.dtFirstDeposit),
			U.SaleSourceID,
			M.PmtByYearID, 
			M.PmtRate, 
			M.PmtQty, 
			CF.CotisationFrais 

		from 
			#GrossANDNetUnits GNU
			JOIN dbo.Un_Unit U ON U.UnitID = GNU.UnitID
			JOIN dbo.Un_Convention C on U.Conventionid = C.Conventionid
			JOIN Un_Rep R ON GNU.RepID = R.RepID  --2015-01-27
			JOIN dbo.Mo_Human HRep ON GNU.RepID = HRep.HumanID
			JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
			JOIN dbo.Mo_Adr A ON HS.AdrID = A.AdrID
			JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
			JOIN Un_Modal M ON U.ModalID = M.ModalID
			LEFT JOIN dbo.Mo_Human HDir ON GNU.BossID = HDir.HumanID
			LEFT JOIN 
				(
				SELECT 
					UN.UnitID, 
					CotisationFrais = Sum(Cotisation + Fee)
				FROM 
					Un_Unit UN
					INNER JOIN Un_Cotisation CT ON UN.UnitID = CT.UnitID
					INNER JOIN Un_Modal M ON UN.ModalID = M.ModalID
				WHERE 
					CT.EffectDate Between @StartDate And @EndDate 
					AND M.PmtByYearID = 1
				GROUP BY UN.UnitID
				)CF ON GNU.UnitID = CF.UnitID
		where
			(GNU.Brut <> 0 or GNU.Retraits <> 0 or GNU.Reinscriptions <> 0)
			AND (
				GNU.bossid = @RepID
				OR GNU.repid = @RepID
				or @RepID = 0
				)
		
		) Ventes_RepUnit
    JOIN Un_Plan P ON P.PlanID = Ventes_RepUnit.PlanID
    JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	join 
		(
		select
			repid,
			PctCons24 =	CASE
							WHEN SUM(Brut24) = 0 THEN 0
							ELSE (sum( Brut24 - Retraits24 + Reinscriptions24 ) / SUM(Brut24))
						END
		from #GrossANDNetUnits GNU24
		group by repid
		) Cons24 on Ventes_RepUnit.repid = Cons24.repid
		
	left join 
		(
		select
			bossID,
			BossPctCons24 =	CASE
							WHEN SUM(Brut24) <= 0 THEN 0
							ELSE (sum( Brut24 - Retraits24 + Reinscriptions24 ) / SUM(Brut24))
						END
		from #GrossANDNetUnitsConsPct GNUPct24
		group by bossID
		) BossCons24 on BossCons24.BossID = @RepID -- Ventes_RepUnit.BossID = BossCons24.BossID

	join 
		(
		select
			CieCons24 =	CASE
							WHEN SUM(Brut24) <= 0 THEN 0
							ELSE (sum( Brut24 - Retraits24 + Reinscriptions24 ) / SUM(Brut24))
						END
		from #GrossANDNetUnitsConsPct GNUPct24
		) CieCons24 on 1=1

	LEFT JOIN 
		(
		select 
			U.RepID, 
			NbBenefRep = count(DISTINCT C.BeneficiaryID)
		from 
			#GrossANDNetUnits GNU
			JOIN dbo.Un_Unit U ON U.UnitID = GNU.UnitID
			JOIN dbo.Un_Convention C on U.Conventionid = C.Conventionid
		WHERE GNU.Brut - GNU.Retraits + GNU.Reinscriptions > 0
		GROUP BY U.RepID
		)NbBenefRep ON NbBenefRep.RepID = Ventes_RepUnit.repid
		
	LEFT JOIN 
		(
		select 
			GNU.BossID,
			NbBenefBoss = count(DISTINCT C.BeneficiaryID)
		from 
			#GrossANDNetUnits GNU
			JOIN dbo.Un_Unit U ON U.UnitID = GNU.UnitID
			JOIN dbo.Un_Convention C on U.Conventionid = C.Conventionid
		WHERE GNU.Brut - GNU.Retraits + GNU.Reinscriptions > 0
		GROUP BY GNU.BossID
		)NbBenefBoss ON NbBenefBoss.BossID = @RepID		
		
	LEFT JOIN 
		(
		select 
			NbBenefCie = count(DISTINCT C.BeneficiaryID)
		from 
			#GrossANDNetUnits GNU
			JOIN dbo.Un_Unit U ON U.UnitID = GNU.UnitID
			JOIN dbo.Un_Convention C on U.Conventionid = C.Conventionid
		WHERE GNU.Brut - GNU.Retraits + GNU.Reinscriptions > 0
		)NbBenefCie ON 1=1
		
	GROUP BY 
		DirLastName, 
		DirFirstName, 
		Ventes_RepUnit.LastName, 
		Ventes_RepUnit.FirstName, 
		Ventes_RepUnit.RepCode, 
		Ventes_RepUnit.RepID, 
		Ventes_RepUnit.AgeRep, 
		Ventes_RepUnit.AnneeService,
		Cons24.PctCons24,
		BossCons24.BossPctCons24,
		CieCons24.CieCons24
		,NbBenefRep
		,NbBenefBoss
		,NbBenefCie

	order by
		DirLastName, 
		DirFirstName, 
		Ventes_RepUnit.LastName, 
		Ventes_RepUnit.FirstName, 
		Ventes_RepUnit.RepCode

end
/*************

De : Isabelle Biron 
Envoyé : 13 avril 2010 12:13
À : Donald Huppe
Cc : Annie Bergeron; Pascal Gilbert
Objet : Rapport mensuel de vente

Bonjour Donald,

Voici le résultat de ma conversation avec Pascal.

Nombre de contrats : Nombre de contrats brutes de la période. Nous ne devons pas déduire les résiliations reliées à des ventes de périodes précédentes. Par contre s’il y a ventes et résiliations de cette même vente dans la période il faut la déduire.

% contrats : le pourcentage brute des contrats vendu. Donc par exemple : le nombre contrats brutes REEEFLEX de la période/ le nombre total de contrats brutes de la période. Ne pas tenir compte des résiliations reliées aux ventes de périodes précédentes.

Unités brutes : unités brutes de la période
Unités nettes : unités brutes moins les résiliations de ventes de périodes précédentes et de la période.

% unités : pourcentage des unités brutes de la période. Ne tiens pas compte des résiliations des ventes de périodes précédentes

% conservation 24 dernier mois : pourcentage des unités nettes sur brutes des derniers 24 mois.

% conservation période : pourcentage des unités nettes sur brutes de la période.

Cotisations annuelles : J’aimerais savoir comment est calculé cette élément. Il faudrait normalement prendre les montant mensuel * 12 mois + montant annuel + forfaitaire de la période. Ne pas tenir compte des résiliations des ventes de période précédente. S’il y a vente et résiliation de la vente dans la même période en tenir compte.

Nombre unités moyen : Nombre d’unité brutes de la période / Nombre de groupe d’unités brutes de la période. Donc ne pas tenir compte des résiliations reliées aux ventes de périodes précédentes.

Âge Bénéficiaire moyen : La moyenne des âges des bénéficiaires reliés aux ventes de la période. N’inclus pas les résiliations des ventes de périodes précédentes.

*************/