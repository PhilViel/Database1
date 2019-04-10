/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	GU_RP_Commission_FromTo_GroupeDePaie
Description         :	PROCEDURE DU RAPPORT DES COMMISSIONS en tableau croisé par date de traitement
Valeurs de retours  :	
Note                :	2011-03-03	Donald Huppé Création
						2012-01-05	Donald Huppé Ajout de AvAcouvrir qu'il faut aller chercher dans Un_RepCommission

exec GU_RP_Commission_FromTo_GroupeDePaie  476 , 476

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_Commission_FromTo_GroupeDePaie] (
	@RepTreatmentIDFrom INTEGER,
	@RepTreatmentIDTo INTEGER) -- Numéro du traitement des commissions
AS
BEGIN

	DECLARE @RepTreatmentDateTo DATETIME

	SELECT @RepTreatmentDateTo = RepTreatmentDate FROM Un_RepTreatment WHERE RepTreatmentID = @RepTreatmentIDTo

	SELECT
		R.RepTreatmentID, -- ID du traitement de commissions
		R.RepTreatmentDate, -- Date du traitement de commissions
		LastRepTreatmentDate = MAX(ISNULL(R2.RepTreatmentDate,0)) -- Date du traitement précédent
	INTO #tbYearRepTreatment
	FROM Un_RepTreatment R
	LEFT JOIN Un_RepTreatment R2 ON (R2.RepTreatmentDate < R.RepTreatmentDate) OR (R2.RepTreatmentDate = R.RepTreatmentDate AND R2.RepTreatmentID < R.RepTreatmentID)
	WHERE	R.RepTreatmentID BETWEEN @RepTreatmentIDFrom and  @RepTreatmentIDTo
		AND	YEAR(R.RepTreatmentDate) = YEAR(@RepTreatmentDateTo)
		AND R.RepTreatmentDate <= @RepTreatmentDateTo
	GROUP BY
		R.RepTreatmentID,
		R.RepTreatmentDate

	SELECT 
		C.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		Periode = case when u.dtFirstDeposit < '2011-01-01' then '1-Avant' else '2-Après' end,
		AvAcouvrir  = SUM(C.AdvanceAmount-C.CoveredAdvanceAmount) -- CumAdvance : Somme des avances non couvertes
		--,CumComm = SUM(C.CommissionAmount) -- Sommes des commissions de services
	INTO #AvAcouvrir
	FROM #tbYearRepTreatment Y
	JOIN Un_RepCommission C ON C.RepTreatmentID <= Y.RepTreatmentID
	JOIN dbo.Un_Unit u ON C.UnitID = u.UnitID 
	--WHERE Y.RepTreatmentID = 475 --AND C.RepID = 424870
	GROUP BY
		C.RepID
		,Y.RepTreatmentID 
		,case when u.dtFirstDeposit < '2011-01-01' then '1-Avant' else '2-Après' end
	ORDER by 
		Y.RepTreatmentID ,
		case when u.dtFirstDeposit < '2011-01-01' then '1-Avant' else '2-Après' end

SELECT 
	repTreatmentID,
	RepTreatmentDate,
	RepID,
	RepCode,
	RepName,
	businessStart,
	businessEnd,
	Periode,
	
	Avance = sum(Avance),
	ComServBoni = sum(ComServBoni),
	Futurcom = sum(Futurcom),
	AvCouv = sum(AvCouv),
	AvAcouvrir = sum(AvAcouvrir)
from (
	SELECT 
		RT.repTreatmentID,
		RT.RepTreatmentDate,
		RT.RepID,
		R.RepCode,
		RepName = h.lastname + ' ' + h.firstname, -- On prend le nom du rep dans human car il arrive que des rep change de nom dans Un_Dn_RepTreatmentSumary
		R.businessStart,
		R.businessEnd,
		
		Periode = case when FirstDepositDate < '2011-01-01' then '1-Avant' else '2-Après' end,
		Avance = sum(PeriodAdvance),
		ComServBoni = sum(PaidAmount),
		Futurcom = sum(  CumAdvance + FuturComm ),
		AvCouv = sum(CoverdAdvance),
		AvAcouvrir = 0
		
	FROM Un_Dn_RepTreatment  RT
	JOIN Un_Rep R ON RT.RepId = R.RepID 
	JOIN dbo.Mo_Human h on r.repid = h.humanid

	WHERE 
		RT.RepTreatmentID between @RepTreatmentIDFrom and  @RepTreatmentIDTo
		--AND RT.ConventionNo = 'U-20080708023'
		and RT.RepID <> 149876 -- exclure siège social

	GROUP BY 
		RT.repTreatmentID,
		RT.RepTreatmentDate,
		RT.RepID,
		R.RepCode,
		h.lastname + ' ' + h.firstname, -- On prend le nom du rep dans human car il arrive que des rep change de nom dans Un_Dn_RepTreatmentSumary
		R.businessStart,
		R.businessEnd
		,case when FirstDepositDate < '2011-01-01' then '1-Avant' else '2-Après' end

	--order by
	--	case when FirstDepositDate < '2011-01-01' then '1-Avant' else '2-Après' end
	--	,RT.RepID
	--	,RT.RepTreatmentDate
		
	union ALL
	
	SELECT 
		RT.repTreatmentID,
		RT.RepTreatmentDate,
		R.RepID,
		R.RepCode,
		RepName = h.lastname + ' ' + h.firstname, -- On prend le nom du rep dans human car il arrive que des rep change de nom dans Un_Dn_RepTreatmentSumary
		R.businessStart,
		R.businessEnd,
		av.Periode,
		Avance = 0,
		ComServBoni = 0,
		Futurcom = 0,
		AvCouv = 0,
		av.AvAcouvrir
	from #AvAcouvrir av --ON V.RepID = av.repid AND V.RepTreatmentID = av.RepTreatmentID and V.Periode = av.Periode
	JOIN Un_RepTreatment rt ON av.repTreatmentID = RT.RepTreatmentID
	JOIN Un_Rep R ON av.RepId = R.RepID 
	JOIN dbo.Mo_Human h on r.repid = h.humanid
) V

GROUP BY
	repTreatmentID,
	RepTreatmentDate,
	RepID,
	RepCode,
	RepName,
	businessStart,
	businessEnd,
	Periode
order by
	Periode,
	RepID,
	RepTreatmentDate
		
END

/*
select * from Un_Dn_RepTreatment where repid = 149497 and reptreatmentid = 455
select * from Un_RepCommission where reptreatmentid = 427
select * from Un_Dn_RepTreatment where reptreatmentid = 427

	SELECT 
		--RepID, -- ID du représentant
		--UnitID, -- ID du groupe d'unités
		--RepLevelID, -- ID du niveau
		--UnitQty, -- Nombre d'unités du groupe d'unités
		--RepPct, -- Pourcentage de commissions
		--TotalFee, -- Total des frais cotisés pour ce groupe d'unités
		PeriodAdvance = SUM(AdvanceAmount), -- Avances versés dans ce traitement de commissions
		CoveredAdvance = SUM(CoveredAdvanceAmount), -- Avances couvertes dans ce traitement de commissions
		PeriodComm = SUM(CommissionAmount) -- Commissions de service versés dans ce traitement de commissions
	FROM Un_RepCommission C
	where reptreatmentid = 427

select VvanceDétail = n.avance ,AvanceSommaire = o.avance,n.repname,*
from tmp_old o
join tmp_new n on o.repid = n.repid
where n.avance <> o.avance

select --sum(n.ComServBoni-o.ComServBoni)
	ComServBoniDétail = n.ComServBoni ,ComServBoniSommaire = o.ComServBoni,*
from tmp_old o
join tmp_new n on o.repid = n.repid
where abs(n.ComServBoni - o.ComServBoni) > 0.01
select 2377.98	- 2224.56

select * from Un_Dn_RepTreatmentSumary where reptreatmentid = 427 and reptreatmentdate = '2011-01-16 00:00:00.000'

-- Sommaire	 - Détail
NewAdvance = PeriodAdvance = 1796.39
CommAndBonus = PaidAmount = 1119,52
FuturCom = CumAdvance + FuturComm = 45860,87
CoverdAdvance = CoveredAdvance = 1637,57
*/


