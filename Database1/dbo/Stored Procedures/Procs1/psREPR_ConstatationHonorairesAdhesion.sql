/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas Inc.
Nom                 :	psREPR_ConstatationHonorairesAdhesion 
Description         :	Procédure stockée du rapport de Constatation des Honoraires d'Adhesion (remplace le  rapport de Constatation des Honoraires d'Adhesion 2011 )
Valeurs de retours  :	Dataset 
Note                :	2013-03-07	Donald Huppé	    Création
						2015-10-28	Donald Huppé	    glpi 15969 : modification du calcul de FraisErreur
			            2018-02-12  Pierre-Luc Simard   Exclure aussi les convention avec un RIN partiel

exec psREPR_ConstatationHonorairesAdhesion '2017-12-31'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ConstatationHonorairesAdhesion] (

	@EndDate DATETIME ) 
AS
BEGIN

	create table #FuturFee (
			modal varchar(25),
			conventionno varchar(50),
			UnitID int,
			UnitQty float,
			FeePaid money,
			PmtDate datetime,
			Pmt money
			)
	-- projection de frais à recevoir
	insert into #FuturFee exec psREPR_FutursEncaissementsFrais @EndDate

	SELECT 
		C.conventionno,
		u.UnitID,
		QteUniteNette = ur1.UniteNetteEnDate,
		FE.FraisEncaisses,
		FraisARecevoir = (ur1.UniteNetteEnDate * 200) - FraisEncaisses,
		FraisAvant12Mois = round(ISNULL(FraisAvant12Mois,0),2),
		FraisApres12Mois = round(isnull(FraisApres12Mois,0),2) ,
		
		FraisErreur = (/*FraisARecevoir */ (ur1.UniteNetteEnDate * 200) - FraisEncaisses)
					-ISNULL(FraisAvant12Mois,0)
					-isnull(FraisApres12Mois,0)

		/*
		-- Ici, on fait une patch.  si FraisAvant12Mois = 0 et FraisApres12Mois = 0 (cas non résulu par psREPR_FutursEncaissementsFrais) 
		-- Alors on place les frais à recevoir dans cette colonne pour que ces cas soit validés par la comptabilité
		FraisErreur = case 
					when ((ur1.UniteNetteEnDate * 200) - FraisEncaisses) <> 0 and ISNULL(FraisAvant12Mois,0) = 0 and ISNULL(FraisApres12Mois,0) = 0 
					then (ur1.UniteNetteEnDate * 200) - FraisEncaisses 
					ELSE 0 end
		*/
	FROM Un_Convention C
    LEFT JOIN dbo.fntCONV_ObtenirStatutRINConvention (NULL, GETDATE()) RIN ON RIN.ConventionID = C.ConventionID
	JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID and isnull(u.TerminatedDate,'3000-01-01') > @EndDate --AND isnull(u.IntReimbDate,'3000-01-01') > @EndDate
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
	left join ( -- projection de frais à recevoir
		SELECT  
			UnitID,
			FraisAvant12Mois = sum(case when PmtDate <= dateadd(yy,1,@EndDate) then Pmt else 0 END),
			FraisApres12Mois = sum(case when PmtDate > dateadd(yy,1,@EndDate) then Pmt else 0 END)
		from #FuturFee
		GROUP by UnitID
		) ff on u.unitID = ff.UnitID
	where 
		u.dtFirstDeposit BETWEEN '2010-01-01' and @EndDate
		AND c.PlanID <> 4
		and ((ur1.UniteNetteEnDate * 200) - FraisEncaisses) <> 0
        AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les convention avec un RIN partiel ou complet
	order by c.ConventionNo

end