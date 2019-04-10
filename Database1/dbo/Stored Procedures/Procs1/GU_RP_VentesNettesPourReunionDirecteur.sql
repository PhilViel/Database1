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
Nom                 :	GU_RP_VentesNettesPourReunionDirecteur
Description         :	Procédure stockée du rapport : SSRS - Rapoort de ventes nettes pour réunion des directeurs
Valeurs de retours  :	Dataset 
Note                :	2009-08-19	Donald Huppé	    Création
						2010-01-11	Donald Huppé	    Modification pour utiliser la nouvelle SL_UN_RepGrossANDNetUnits avec le champ recrue
													    Le net des recrues est ainsi semblable au rapport de concours de recrue dans uniAccès (+/- les réinscriptions)
						2013-04-30	Donald Huppé	    GLPI 9568 : ajuster le rmeplacement de "agence Maryse Logelin" par "agence Nouveau-Brunswick"
						2013-09-19	Donald Huppé	    Demande de Vanessa Hirt du 2013-09-19
						2013-11-13	Donald Huppé	    glpi 10514 
													    Et enlever quelques attribution du 2013-09-19, qui sont remplacée par ce glpi (10514)
                        2018-10-29  Pierre-Luc Simard   N'est plus utilisée  
exec GU_RP_VentesNettesPourReunionDirecteur '2013-01-01', '2013-11-13', 0
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_VentesNettesPourReunionDirecteur] (
	@StartDate DATETIME,
	@EndDate DATETIME,
	@RFlexMajore int ) 
AS
BEGIN

SELECT 1/0
/*
declare @StartDateNow datetime
declare @EndDateNow datetime
declare @StartDateThen datetime
declare @EndDateThen datetime

set @StartDateNow = @StartDate
set @EndDateNow = @EndDate

set @StartDateThen = dateadd(yy,-1,@StartDate)
set @EndDateThen = dateadd(yy,-1,@EndDate)

print @StartDateThen
print @EndDateThen

	create table #GrossANDNetUnitsNow (
		UnitID_Ori INTEGER, 
		UnitID INTEGER,
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

	create table #GrossANDNetUnitsThen (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
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

	-- Les données de la plage demandée
	insert #GrossANDNetUnitsNow
	exec SL_UN_RepGrossANDNetUnits NULL, @StartDateNow, @EndDateNow, 0, 1

/* --2013-09-19
-	Geneviève Duguay(659765) (lui attribuer également les unités du Nouveau-Brunswick(671417))
-	Daniel Turpin(149602) (lui attribuer également les unités de Ghislain Thibeault(391561) et Dolores Dessureault(415878))
-	Jeannot Turgeon (remplacer son nom par : Cabinet Turgeon & associés(675096))
-	Maryse Breton(440176) (lui attribuer également les unités de Mario Béchard(149464) et Sylvain Bibeau(149520))
-	Pour Maryse Logelin(298925), il faut attribuer les ventes à Geneviève   Duguay(659765) sauf pour les représentants suivants qui vont au Cabinet Turgeon et Associés :
	-	Jeannot Turgeon(149614)
	-	Alain Bossé(437742)
	-	Liette Pelletier(675336)

*/

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnitsNow g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	--update #GrossANDNetUnitsNow set BossID = 659765 where BossID = 671417 -- Geneviève Duguay(659765) (lui attribuer également les unités du Nouveau-Brunswick(671417))
	update #GrossANDNetUnitsNow set BossID = 149602 where BossID in ( /*391561,*/415878) --Daniel Turpin(149602) (lui attribuer également les unités de Ghislain Thibeault(391561) et Dolores Dessureault(415878))
	update #GrossANDNetUnitsNow set BossID = 675096 where BossID = 149614 --Jeannot Turgeon (remplacer son nom par : Cabinet Turgeon & associés(675096))
	update #GrossANDNetUnitsNow set BossID = 440176 where BossID in ( 149464,149520) --Maryse Breton(440176) (lui attribuer également les unités de Mario Béchard(149464) et Sylvain Bibeau(149520))
	--update #GrossANDNetUnitsNow set BossID = 659765 where BossID = 298925 and RepID not in (149614,437742,675336) --Pour Maryse Logelin(298925), il faut attribuer les ventes à Geneviève   Duguay(659765) sauf pour les représentants suivants
	--update #GrossANDNetUnitsNow set BossID = 675096 where RepID in (149614,437742,675336) --les représentants suivants qui vont au Cabinet Turgeon et Associés : Jeannot Turgeon(149614), Alain Bossé(437742), Liette Pelletier(675336)
	
	-- Les données de la plage demandée pour l'an passée
	insert #GrossANDNetUnitsThen
	exec SL_UN_RepGrossANDNetUnits NULL, @StartDateThen, @EndDateThen, 0, 1

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnitsThen g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'
	
	--update #GrossANDNetUnitsThen set BossID = 659765 where BossID = 671417 -- Geneviève Duguay(659765) (lui attribuer également les unités du Nouveau-Brunswick(671417))
	update #GrossANDNetUnitsThen set BossID = 149602 where BossID in ( /*391561,*/415878) --Daniel Turpin(149602) (lui attribuer également les unités de Ghislain Thibeault(391561) et Dolores Dessureault(415878))
	update #GrossANDNetUnitsThen set BossID = 675096 where BossID = 149614 --Jeannot Turgeon (remplacer son nom par : Cabinet Turgeon & associés(675096))
	update #GrossANDNetUnitsThen set BossID = 440176 where BossID in ( 149464,149520) --Maryse Breton(440176) (lui attribuer également les unités de Mario Béchard(149464) et Sylvain Bibeau(149520))
	--update #GrossANDNetUnitsThen set BossID = 659765 where BossID = 298925 and RepID not in (149614,437742,675336) --Pour Maryse Logelin(298925), il faut attribuer les ventes à Geneviève   Duguay(659765) sauf pour les représentants suivants
	--update #GrossANDNetUnitsThen set BossID = 675096 where RepID in (149614,437742,675336) --les représentants suivants qui vont au Cabinet Turgeon et Associés : Jeannot Turgeon(149614), Alain Bossé(437742), Liette Pelletier(675336)

	select
		repid,
		BossID,
		Groupe,
		-- Mettre CGL et Induct. Alliance dans Courtage
		Agence = case when v3.BOSSID IN (458621,469600) then 'Courtage' else replace(HB.FirstName,'Agence','Ag.') + ' ' + HB.LastName end,
		Regime,
		SourceVente = case when sourcevente like '%(%' then replace(ltrim(rtrim(substring(SourceVente,1,Patindex( '%(%', SourceVente) ))),'(','') else sourcevente end,
		NetRepNow =  sum(NetRepNow),
		NetRecNow = sum(NetRecNow),
		NetRepThen = sum(NetRepThen),
		NetRecThen = sum(NetRecThen)
	from (
		select
			repid,
			Groupe,
			BossID,
			Regime,
			SourceVente,
			NetRepNow =  sum(case when Recrue = 0 then Net else 0 end),
			NetRecNow = sum(case when Recrue = 1 then Net else 0 end),
			NetRepThen = 0,
			NetRecThen = 0
		from (
			select 
				GuNow.repid,
				Groupe = case when BOSSID IN (458621,469600) then 'Courtage' else 'Dir' end,
						-- METTRE MARIO BÉCHARD DANS MARYSE BRETON
				BossID,-- = CASE WHEN BOSSID = 149464 THEN 440176 ELSE BOSSID END,
				Regime = p.PlanDesc,
				Recrue,
				SourceVente = case when len(ss.SaleSourceDesc) > 10 then substring(ss.SaleSourceDesc,9,200) else ss.SaleSourceDesc end,
				--Net = GuNow.Brut - GuNow.Retraits + GuNow.Reinscriptions
				Net = case 
						when @RFlexMajore = 0 then	(GuNow.Brut - GuNow.Retraits + GuNow.Reinscriptions) 
						else						(GuNow.Brut - GuNow.Retraits + GuNow.Reinscriptions) * (case when (c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') then 1.35 else 1 end) end 
			from 
				#GrossANDNetUnitsNow GuNow
				JOIN dbo.Un_Unit u on GuNow.unitid = u.unitid
				join un_salesource ss on u.SaleSourceId = ss.SaleSourceId
				JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
				join un_plan p on c.planid = p.planid
				--join un_rep r on u.repid = r.repid
			where (GuNow.Brut - GuNow.Retraits + GuNow.Reinscriptions) <> 0
			) V1
		group by
			V1.RepID,
			Groupe,
			BossID,
			Regime,
			SourceVente

		UNION

		select
			repid,
			Groupe,
			BossID,
			Regime,
			SourceVente,
			NetRepNow = 0,
			NetRecNow = 0,
			NetRepThen = sum(case when Recrue = 0 then Net else 0 end),
			NetRecThen = sum(case when Recrue = 1 then Net else 0 end)
		from (
			select 
				GuThen.repid,
				Groupe = case when BOSSID IN (458621,469600) then 'Courtage' else 'Dir' end,
						-- METTRE MARIO BÉCHARD DANS MARYSE BRETON
				Bossid,-- = CASE WHEN BOSSID = 149464 THEN 440176 ELSE BOSSID END,
				Regime = p.PlanDesc,
				Recrue,
				SourceVente = case when len(ss.SaleSourceDesc) > 10 then substring(ss.SaleSourceDesc,9,200) else ss.SaleSourceDesc end,
				-- Net = (GuThen.Brut - GuThen.Retraits + GuThen.Reinscriptions)
				Net = case 
						when @RFlexMajore = 0 then	(GuThen.Brut - GuThen.Retraits + GuThen.Reinscriptions) 
						else						(GuThen.Brut - GuThen.Retraits + GuThen.Reinscriptions) * (case when (c.planid in (10,12) and u.dtfirstdeposit <= '2010-01-10') then 1.35 else 1 end) end 
			from 
				#GrossANDNetUnitsThen GuThen
				JOIN dbo.Un_Unit u on GuThen.unitid = u.unitid
				join un_salesource ss on u.SaleSourceId = ss.SaleSourceId
				JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
				join un_plan p on c.planid = p.planid
				--join un_rep r on u.repid = r.repid
			where (GuThen.Brut - GuThen.Retraits + GuThen.Reinscriptions) <> 0
			) V2
		group by
			V2.RepID,
			Groupe,
			BossID,
			Regime,
			SourceVente
		) V3
		JOIN dbo.mo_human HB on HB.humanid = V3.BossID
	where V3.BossID not in (149484,149485,149573) -- exclure  Gilbert Perras, Michèle Derome et Marcelle Payette
	group by
		repid,--
		BossID,--
		Groupe,
		case when v3.BOSSID IN (458621,469600) then 'Courtage' else replace(HB.FirstName,'Agence','Ag.') + ' ' + HB.LastName end,
		Regime,
		SourceVente
	order by 
		BossID,
		Groupe,
		Agence,
		Regime,
		SourceVente

drop table #GrossANDNetUnitsNow
drop table #GrossANDNetUnitsThen
*/
end

/*
select h.*
from un_rep r
JOIN dbo.mo_human h on r.repid = h.humanid
where h.lastname = 'derome'

*/