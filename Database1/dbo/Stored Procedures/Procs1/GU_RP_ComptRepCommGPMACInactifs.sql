﻿/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	GU_RP_ComptRepCommGPMACInactifs
Description         :	Procédure pour la création des données du fichier MAC des commissions à importer dans Great Plains 
						(Selon le rapport des commissions pour la comptabilité)
Note                :	
						PLS						2008-02-29 	Création			
						Pierre-Luc Simard	2013-04-09	Exclure agence Nouveau-Brunswick
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_ComptRepCommGPMACInactifs] (
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
	
	DECLARE @tRepCommSum TABLE (
		RepCode VARCHAR (15) PRIMARY KEY,
		RepName VARCHAR (100),
		NewAdvance MONEY,	
		CommAndBonus MONEY,
		Adjustment MONEY,
		Retenu MONEY,
		ChqNet MONEY,
		Advance MONEY,	
		TerminatedAdvance MONEY,
		SpecialAdvance MONEY,
		TotalAdvance MONEY,
		CoveredAdvance MONEY,
		CommissionFee MONEY,
		BusinessEnd DATETIME)
	INSERT INTO @tRepCommSum
	SELECT
		R.RepCode,
		S.RepName,
		NewAdvance = SUM(S.NewAdvance),	
		CommAndBonus = SUM(S.CommAndBonus),
		Adjustment = SUM(S.Adjustment),
		Retenu = SUM(S.Retenu),
		ChqNet = SUM(S.ChqNet),
		Advance = SUM(S.Advance),	
		TerminatedAdvance = SUM(ISNULL(AVR.AVRAmount,0)),
		SpecialAdvance = SUM(ISNULL(SA.Amount,0)),
		TotalAdvance = SUM(ISNULL(S.Advance,0) + ISNULL(SA.Amount,0) + ISNULL(AVR.AVRAmount,0)),
		CoveredAdvance = SUM(S.CoveredAdvance),
		CommissionFee = SUM(S.CommAndBonus + S.Adjustment + S.CoveredAdvance),
		Date = CASE 
				WHEN R.BusinessEnd >= RT.RepTreatmentDate THEN NULL
			ELSE R.BusinessEnd
			END 
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
	WHERE RT.RepTreatmentID BETWEEN @StartRepTreatmentID AND @EndRepTreatmentID --= @RepTreatmentID
		--AND CASE WHEN R.BusinessEnd < RT.RepTreatmentDate THEN 0 ELSE 1 END = @Actif -- Actifs ou inactifs seulement selon le paramètre
		AND S.RepCode <> '0000' AND S.RepCode <> '6141' AND S.RepCode <> '7910' -- Directeur fictif, Outaouais-Abétimis et Agence Nouveau-Brunswick à enlever
		AND CASE 
				WHEN R.BusinessEnd >= RT.RepTreatmentDate THEN NULL
			ELSE R.BusinessEnd
			END IS NOT NULL	
	GROUP BY 
		S.RepName, 
		R.RepCode, 
		CASE WHEN R.BusinessEnd >= RT.RepTreatmentDate THEN NULL ELSE R.BusinessEnd END 
	ORDER BY S.RepName, R.RepCode

	-- Avances de commissions
	SELECT 
		RepCode = CASE S.RepCode
					WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
					WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
					WHEN '5482-6612' THEN '6612'	-- Mario Béchard
					ELSE S.Repcode 
				END,	
		S.RepName, 
		Montant = CASE WHEN S.NewAdvance < 0 THEN S.NewAdvance * -1 ELSE S.NewAdvance END,
		Signe = CASE WHEN S.NewAdvance < 0 THEN -1 ELSE 1 END,
		Compte = 'AVCOM'
	FROM @tRepCommSum S
	WHERE S.NewAdvance <> 0
	
	UNION
	-- Commissions de service de Boni
	SELECT 
		RepCode = CASE S.RepCode
					WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
					WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
					WHEN '5482-6612' THEN '6612'	-- Mario Béchard
					ELSE S.Repcode 
				END,			
		S.RepName, 	
		Montant = CASE WHEN S.CommAndBonus < 0 THEN S.CommAndBonus * -1 ELSE S.CommAndBonus END,
		Signe = CASE WHEN S.CommAndBonus < 0 THEN -1 ELSE 1 END,
		Compte = 'COM'
	FROM @tRepCommSum S
	WHERE S.CommAndBonus <> 0

	UNION
	-- Boni concours
	SELECT 
		RepCode = CASE S.RepCode
					WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
					WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
					WHEN '5482-6612' THEN '6612'	-- Mario Béchard
					ELSE S.Repcode 
				END,		
		S.RepName, 
		Montant = CASE WHEN S.Adjustment < 0 THEN S.Adjustment * -1 ELSE S.Adjustment END,
		Signe = CASE WHEN S.Adjustment < 0 THEN -1 ELSE 1 END,
		Compte = 'BONIR'
	FROM @tRepCommSum S
	WHERE S.Adjustment <> 0

	UNION
	-- Retenues
	SELECT 
		RepCode = CASE S.RepCode
					WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
					WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
					WHEN '5482-6612' THEN '6612'	-- Mario Béchard
					ELSE S.Repcode 
				END,	
		S.RepName, 	
		Montant = CASE WHEN S.Retenu < 0 THEN S.Retenu * -1 ELSE S.Retenu END,
		Signe = CASE WHEN S.Retenu < 0 THEN -1 ELSE 1 END,
		Compte = 'AVCOM'
	FROM @tRepCommSum S
	WHERE S.Retenu <> 0

	UNION
	-- Avances couvertes
	SELECT 
		RepCode = CASE S.RepCode
					WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
					WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
					WHEN '5482-6612' THEN '6612'	-- Mario Béchard
					ELSE S.Repcode 
				END,		
		S.RepName, 
		Montant = CASE WHEN S.CoveredAdvance < 0 THEN S.CoveredAdvance * -1 ELSE S.CoveredAdvance END,
		Signe = CASE WHEN S.CoveredAdvance < 0 THEN 1 ELSE -1 END,
		Compte = 'AVCOUV'
	FROM @tRepCommSum S
	WHERE S.CoveredAdvance <> 0

	UNION
	-- Avances couvertes
	SELECT 
		RepCode = CASE S.RepCode
					WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
					WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
					WHEN '5482-6612' THEN '6612'	-- Mario Béchard
					ELSE S.Repcode 
				END,	
		S.RepName, 
		Montant = CASE WHEN S.CoveredAdvance < 0 THEN S.CoveredAdvance * -1 ELSE S.CoveredAdvance END,
		Signe = CASE WHEN S.CoveredAdvance < 0 THEN -1 ELSE 1 END,
		Compte = 'COMC'
	FROM @tRepCommSum S
	WHERE S.CoveredAdvance <> 0
	
	ORDER BY RepName, RepCode, Compte, Signe

END
 
-- EXEC GU_RP_ComptRepCommGPMACInactifs 334, 337
