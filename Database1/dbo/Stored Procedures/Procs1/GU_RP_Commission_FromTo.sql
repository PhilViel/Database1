/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	GU_RP_Commission_FromTo
Description         :	PROCEDURE DU RAPPORT DES COMMISSIONS en tableau croisé par date de traitement
Valeurs de retours  :	
Note                :	2009-11-12	Donald Huppé Création
						2011-01-24	Donald Huppé Ajout de Futurcom
						2012-04-24	Donald Huppé GLPI 7447 : Diviser ComServBoni en Commission et Boni
						2013-11-12	Donald Huppé GLPI 10534 : ajout du RepCode en format INT

select * from Un_RepTreatment

exec GU_RP_Commission_FromTo  492, 492

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_Commission_FromTo] (
	@RepTreatmentIDFrom INTEGER,
	@RepTreatmentIDTo INTEGER) -- Numéro du traitement des commissions
AS
BEGIN

	SELECT
		S.repTreatmentID,
		S.RepTreatmentDate,
		S.RepID,
		R.RepCode,
		RepName = h.lastname + ' ' + h.firstname, -- On prend le nom du rep dans human car il arrive que des rep change de nom dans Un_Dn_RepTreatmentSumary
		R.businessStart,
		R.businessEnd,
		Avance = sum(S.NewAdvance),
		ComServBoni = sum(S.CommAndBonus),
		Futurcom = sum(S.Futurcom),
		BoniConAju = sum(S.Adjustment),
		Retenu = sum(S.Retenu),
		Net = sum(S.ChqNet),
		AvACouvrir = sum(S.Advance), --Advance
		AvResil = sum(ISNULL(AVR.AVRAmount,0)), -- TerminatedAdvance
		AvSpecial = sum(ISNULL(SA.Amount,0)) , -- SpecialAdvance
		AvTotal = sum(ISNULL(S.Advance,0) + ISNULL(SA.Amount,0)  + ISNULL(AVR.AVRAmount,0)) , -- TotalAdvance
		AvCouv = sum(S.CoveredAdvance), -- CoveredAdvance
		DepCom = sum(S.CommAndBonus + S.Adjustment + S.CoveredAdvance) -- CommissionFee
		,Commission = isnull(BC.Commission,0)
		,Boni = isnull(BC.Boni,0)
		,RepcodeINT = cast(R.RepCode as int)

	FROM Un_Dn_RepTreatmentSumary S
	JOIN Un_Rep R ON S.RepId = R.RepID 
	JOIN dbo.mo_human h on r.repid = h.humanid
	JOIN (-- Retrouve tous les représentants ayant eu des commissions de chaque traitement de l'année à ce jour 
				SELECT DISTINCT
					ReptreatmentID,
					RepID
				FROM Un_Dn_RepTreatment 
				-----
				UNION
				-----
				-- Retrouve aussi tous les représentants ayant eu des charges de chaque traitement des commissions de l'année à ce jour 
				SELECT DISTINCT
					RepTreatmentID,
					RepID
				FROM Un_RepCharge
			) T 
		ON S.RepTreatmentID = T.RepTreatmentID AND S.RepID = T.RepID
	JOIN Un_RepTreatment RT ON RT.RepTreatmentID = S.RepTreatmentID AND RT.RepTreatmentDate = S.RepTreatmentDate
	LEFT JOIN (-- Retrouve les montants d'avances sur résiliations par représentant 
				SELECT
					rt.RepTreatmentID,
					r.RepID,
					AVRAmount = SUM(isnull(RepChargeAmount,0))
				FROM un_reptreatment rt 
					left join Un_RepCharge r on rt.RepTreatmentID  >=  r.RepTreatmentID
				WHERE RepChargeTypeID = 'AVR'
					AND rt.RepTreatmentID between @RepTreatmentIDFrom and @RepTreatmentIDTo
				GROUP BY r.RepID,
					rt.RepTreatmentID
			) AVR ON AVR.RepID = S.RepID and AVR.RepTreatmentID = S.RepTreatmentID
	LEFT JOIN (-- Retrouve les montants d'avance spéciale par représentants 
				SELECT
					rt.RepTreatmentID,
					rs.RepID,
					Amount = SUM(isnull(Amount,0))
				FROM un_reptreatment rt 
					left join Un_SpecialAdvance rs on rt.RepTreatmentDate  >=  rs.EffectDate -- select * from Un_SpecialAdvance
				WHERE rt.RepTreatmentID between @RepTreatmentIDFrom and @RepTreatmentIDTo
				GROUP BY rt.RepTreatmentID, rs.RepID
			) SA ON SA.RepID = S.RepID and SA.RepTreatmentID = S.RepTreatmentID
			
	LEFT JOIN (
			SELECT 
				T.RepID,
				T.RepTreatmentID,
				Commission = sum(T.PeriodComm),
				Boni = sum(T.PeriodBusinessBonus),
				ComServBoni = sum(T.PeriodComm + T.PeriodBusinessBonus)
			FROM Un_Dn_RepTreatment T
			JOIN dbo.Mo_Human hr ON T.RepID = hr.HumanID
			WHERE T.RepTreatmentID between @RepTreatmentIDFrom and  @RepTreatmentIDTo
			GROUP BY
				T.RepID,
				T.RepTreatmentID,T.RepCode
			)BC ON BC.RepID = S.RepID AND BC.RepTreatmentID = S.RepTreatmentID		
			
	WHERE RT.RepTreatmentID between @RepTreatmentIDFrom and  @RepTreatmentIDTo
	GROUP BY
		S.repTreatmentID,
		S.RepTreatmentDate,
		S.RepID,
		R.RepCode,
		h.lastname + ' ' + h.firstname,
		R.businessStart,
		R.businessEnd
		,isnull(BC.Commission,0)
		,isnull(BC.Boni,0)
		,cast(R.RepCode as int)
	ORDER BY
		R.RepCode,
		S.RepTreatmentDate

END


