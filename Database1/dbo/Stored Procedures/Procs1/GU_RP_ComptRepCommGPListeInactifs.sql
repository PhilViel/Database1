/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	GU_RP_ComptRepCommGPListeInactifs
Description         :	Procédure pour la création des données du fichier MAC des commissions à importer dans Great Plains 
						(Selon le rapport des commissions pour la comptabilité)
						Inactifs uniquement pour les traitements demandés
Note                :	
						PLS						2008-02-29 	Création			
						Pierre-Luc Simard	2013-04-09	Exclure agence Nouveau-Brunswick
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_ComptRepCommGPListeInactifs] (
	@StartRepTreatmentID INTEGER, -- Numéro du traitement des commissions	
	@EndRepTreatmentID INTEGER)
	--@Actif BIT) -- 1 = Actifs, 0 = Inactifs
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @RepTreatmentDate MoDate
	-- Lecture de la date du traitement choisi
	SELECT @RepTreatmentDate = MAX(RepTreatmentDate)
	FROM Un_Reptreatment
	WHERE RepTreatmentID BETWEEN @StartRepTreatmentID AND @EndRepTreatmentID
	
/*	SELECT
		R.RepCode
	FROM Un_Dn_RepTreatmentSumary S
	JOIN Un_Rep R ON S.RepId = R.RepID
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
		ON S.RepTreatmentID = T.RepTreatmentID 
		AND S.RepID = T.RepID
	JOIN Un_RepTreatment RT 
		ON RT.RepTreatmentID = S.RepTreatmentID 
		AND RT.RepTreatmentDate = S.RepTreatmentDate
	WHERE RT.RepTreatmentID = @RepTreatmentID
		AND CASE WHEN R.BusinessEnd < RT.RepTreatmentDate THEN 0 ELSE 1 END = @Actif -- Actifs ou inactifs seulement selon le paramètre
		AND S.RepCode <> '0000' AND S.RepCode <> '6141' -- Directeur fictif et Outaouais-Abétimis à enlever 
	ORDER BY R.RepCode
*/

SELECT 
	RepCode = CASE V.RepCode
					WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
					WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
					WHEN '5482-6612' THEN '6612'	-- Mario Béchard
					ELSE V.Repcode 
				END
FROM
	(SELECT
		R.RepCode,
		S.RepName,
		S.NewAdvance,	
		S.CommAndBonus,
		S.Adjustment,
		S.Retenu,
		S.ChqNet,
		S.Advance,	
		TerminatedAdvance = ISNULL(AVR.AVRAmount,0) ,
		SpecialAdvance = ISNULL(SA.Amount,0) ,
		TotalAdvance = ISNULL(S.Advance,0) + ISNULL(SA.Amount,0) + ISNULL(AVR.AVRAmount,0) ,
		S.CoveredAdvance,
		CommissionFee = S.CommAndBonus + S.Adjustment + S.CoveredAdvance
	FROM Un_Dn_RepTreatmentSumary S
	JOIN Un_Rep R ON S.RepId = R.RepID
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
		ON S.RepTreatmentID = T.RepTreatmentID 
		AND S.RepID = T.RepID
	JOIN Un_RepTreatment RT 
		ON RT.RepTreatmentID = S.RepTreatmentID 
		AND RT.RepTreatmentDate = S.RepTreatmentDate
	LEFT JOIN (-- Retrouve les montants d'avances sur résiliations par représentant 
				SELECT
					RepID,
					AVRAmount = SUM(RepChargeAmount)
				FROM Un_RepCharge
				WHERE RepChargeTypeID = 'AVR'
					AND RepChargeDate <= @RepTreatmentDate
				GROUP BY RepID
			) AVR 
		ON AVR.RepID = S.RepID
	LEFT JOIN (-- Retrouve les montants d'avance spéciale par représentants 
				SELECT
					RepID,
					Amount = SUM(Amount)
				FROM Un_SpecialAdvance
				WHERE EffectDate <= @RepTreatmentDate
				GROUP BY RepID
			) SA 
		ON SA.RepID = S.RepID
	WHERE RT.RepTreatmentID BETWEEN @StartRepTreatmentID AND @EndRepTreatmentID
		--AND CASE WHEN R.BusinessEnd < RT.RepTreatmentDate THEN 0 ELSE 1 END = @Actif -- Actifs ou inactifs seulement selon le paramètre
		AND S.RepCode <> '0000' AND S.RepCode <> '6141' AND S.RepCode <> '7910' -- Directeur fictif, Outaouais-Abétimis et Agence Nouveau-Brunswick à enlever
		AND R.BusinessEnd IS NOT NULL
	) V	
WHERE V.NewAdvance <> 0	
	OR V.CommAndBonus <> 0	
	OR V.Adjustment <> 0	
	OR V.Retenu <> 0	
	OR V.ChqNet <> 0	
	OR V.Advance <> 0	
	OR V.TerminatedAdvance <> 0	
	OR V.SpecialAdvance <> 0	
	OR V.TotalAdvance <> 0	
	OR V.CoveredAdvance <> 0	
	OR V.CommissionFee <> 0
GROUP BY 
	CASE V.RepCode
		WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
		WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
		WHEN '5482-6612' THEN '6612'	-- Mario Béchard
		ELSE V.Repcode 
	END
ORDER BY 
	CASE V.RepCode
		WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
		WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
		WHEN '5482-6612' THEN '6612'	-- Mario Béchard
		ELSE V.Repcode 
	END

END
 

-- GU_RP_ComptRepCommGPListeInactifs 278, 282
