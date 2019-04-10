/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas Inc.
Nom                 :	psREPR_RapportFraisMensuelSelonPRDAvantApres 
Description         :	Procédure stockée du rapport de Constatation des Honoraires d'Adhesion 2011 
						Probablement un rapport temporaire pour 2011 (voir Anne Mainguy).
Valeurs de retours  :	Dataset 
Note                :	2011-03-15	Donald Huppé	Création
						2011-10-21	Donald Huppé	GLPI 6246 - Ne plus exclure les RIO
						2011-11-29	Donald Huppé	glpi 6462 : annulation du glpi 6246
						2012-01-06	Donald Huppé	glpi 6700 : on exclut les RIO et TRI mais on inclut les frais transféré dans les individuels des RIO et TRI 
						2012-02-08	Donald Huppé	glpi 6880 : Nouveau calcul pour les frais à recevoir. Il faut prendre le solde des frais totaux dans la convention qui est 
																ouverte en date demandée et non l'ancien calcul qui n'incluait pas les TFR entre entre
						2013-03-01	Donald Huppé	ne plus faire comme dans le sommaire des cotisation	voir "2013-03-01"
																
exec psREPR_ConstatationHonorairesAdhesion2011 '2011-12-31'

drop proc psREPR_CodeDeCommissionConstatation2011
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ConstatationHonorairesAdhesion2011] (
	--@StartDate DATETIME,
	@EndDate DATETIME ) 
AS
BEGIN

declare @FraisARecevoirAvant money
declare @FraisARecevoirApres money

-- CALCUL LES FRAIS À RECEVOIR POUR LES CONVENTION OUVERTES EN DATE DE @EndDate
SELECT 
	AvantApres = CASE WHEN u.dtFirstDeposit >= '2011-01-01' then 'Apres' ELSE 'Avant' End,
	FraisARecevoir = sum((ur1.UniteNetteEnDate * 200) - FraisEncaisses)
INTO #FraisARecevoir
FROM 
	Un_Convention c
	JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID and isnull(u.TerminatedDate,'3000-01-01') > @EndDate AND isnull(u.IntReimbDate,'3000-01-01') > @EndDate
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
				where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= @EndDate -- Si je veux l'état à une date précise 
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
		) css on C.conventionid = css.conventionid
		
	JOIN ( 
		select u1.unitid, UniteNetteEnDate = u1.unitqty + isnull(ur2.QteReduite,0)
		from  un_unit u1 
		LEFT JOIN (
			select unitid, QteReduite = sum(unitqty) 
			from un_unitreduction 
			where ReductionDate > @EndDate 
			group by unitid) ur2 on u1.unitid = ur2.unitid
		where 
			isnull(u1.TerminatedDate,'3000-01-01') > @EndDate
		) ur1 on u.unitid = ur1.unitid
		
	JOIN (	
			SELECT 
				U.UnitID, FraisEncaisses = sum(Ct.Fee)
			FROM 
				dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
			where 
				operdate <= @EndDate
				and isnull(u.TerminatedDate,'3000-01-01') > @EndDate
			GROUP BY 
				U.UnitID
		) FE ON u.UnitID = FE.UnitID
	where 
		1=1
		AND c.PlanID <> 4
	Group BY
		CASE WHEN u.dtFirstDeposit >= '2011-01-01' then 'Apres' ELSE 'Avant' End
	
	select @FraisARecevoirAvant = FraisARecevoir from #FraisARecevoir where AvantApres = 'Avant'
	select @FraisARecevoirApres = FraisARecevoir from #FraisARecevoir where AvantApres = 'Apres'

	select u1.unitid, UniteNetteEnDate = u1.unitqty + isnull(ur2.QteReduite,0)
	into #un
	from  un_unit u1 
	LEFT JOIN (
		select unitid, QteReduite = sum(unitqty) 
		from un_unitreduction 
		where ReductionDate > @EndDate 
		group by unitid) ur2 on u1.unitid = ur2.unitid
	
	CREATE index #ind1 on #un (unitid)
	
		-- CALCUL DES FRAIS REÇU EN DATE DE @EndDate

		SELECT 
			--top 5
			AvantApres,
			ConventionNo,
			F.unitid,
			ur1.UniteNetteEnDate,
			Frais01,
			Frais02,
			Frais03,
			Frais04,
			Frais05,
			Frais06,
			Frais07,
			Frais08,
			Frais09,
			Frais10,
			Frais11,
			Frais12,
			FraisEncaisses,
			
			-- Pour FraisARecevoir, on met la valeur totale à chaque ligne, on va prendre le max dans le rapport
			FraisARecevoir = CASE WHEN AvantApres = 'Avant' THEN @FraisARecevoirAvant ELSE @FraisARecevoirApres end,
			
			FraisRestant = 0 -- On met 0 car on ne veut pas définir les frais restant (ou frais à recevoir) par convention dans ce rapport
			
		INTO #TMP1
		FROM (
		
			SELECT
				C.conventionNo,
				u.unitid,
				AvantApres = case when u.dtfirstdeposit < '2011-01-01' then 'Avant' else 'Apres' end,
				Frais01 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 1 then Ct.Fee else 0 end),
				Frais02 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 2 then Ct.Fee else 0 end),
				Frais03 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 3 then Ct.Fee else 0 end),
				Frais04 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 4 then Ct.Fee else 0 end),
				Frais05 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 5 then Ct.Fee else 0 end),
				Frais06 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 6 then Ct.Fee else 0 end),
				Frais07 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 7 then Ct.Fee else 0 end),
				Frais08 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 8 then Ct.Fee else 0 end),
				Frais09 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 9 then Ct.Fee else 0 end),
				Frais10 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 10 then Ct.Fee else 0 end),
				Frais11 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 11 then Ct.Fee else 0 end),
				Frais12 = SUM(case when year(o.operdate) = year(@EndDate) and month(o.operdate) = 12 then Ct.Fee else 0 end),
		
				FraisEncaisses = SUM(Ct.Fee)
			from 
				Un_oper O 
				JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
				JOIN Un_Cotisation Ct  on Ct.operID = O.operID
				JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
				JOIN dbo.Un_Convention C on U.ConventionID = C.ConventionID
				LEFT JOIN tblOPER_OperationsRIO RIO on ct.operid = RIO.iID_Oper_RIO /*suivant : glpi 6700*/ AND C.ConventionNo NOT LIKE 'I%'/*TRI*/ AND C.ConventionNo NOT LIKE 'T%'/*RIO*/
			where 
				O.OperDate <= @EndDate
				
				AND O.OperTypeID <> 'RIN' -- Exclure les remboursement de RI
				
				-- pour faire comme dans le sommaire des cotisation ---------------
				/*
				AND( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
						OR O.OperTypeID = 'TRA' -- Inclus les TRA
						)
						*/ -- "2013-03-01"
				--------------------------------------------------------------------						
						
				AND RIO.iID_Oper_RIO is null -- Exclure les RIO

			group by
				C.conventionNo,
				u.unitid,
				case when u.dtfirstdeposit < '2011-01-01' /*@StartDate*/ then 'Avant' else 'Apres' end
			having SUM(case when year(o.operdate) = year(@EndDate) then Ct.Fee else 0 end) <> 0
					
			) F
		JOIN #un ur1 on F.unitid = ur1.unitid
		-- Les frais ne sont pas atteints
		--where (ur1.UniteNetteEnDate * 200) - FraisEncaisses > 0
		order by
			AvantApres desc,
			Conventionno
			
		-- Résultat final
		SELECT * from #TMP1
			
END

	/*
	Doit balancer avec le total de la colonne "frais" du rapport "Sommaire par plan et année de qualification" 
	+ colonne "frais" du rapport "Opérations journalières décaissements RIN" 
	+ colonne "frais de la section collectif du rapport "RIO" 
	- colonne "frais" de la section individuel du rapport "RIO"
	*/


