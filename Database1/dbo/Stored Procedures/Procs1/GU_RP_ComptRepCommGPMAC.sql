/********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	GU_RP_ComptRepCommGPMAC
Description         :	Procédure pour la création des données du fichier MAC des commissions à importer dans Great Plains 
						(Selon le rapport des commissions pour la comptabilité)
Note                :	
						PLS						2008-02-29 	Création
						PLS						2011-05-26	Possibilité de demander les actifs et les inactifs en même temps			
						Pierre-Luc Simard	2013-04-09	Exclure agence Nouveau-Brunswick
						Pierre-Luc Simard	2015-03-30	Ajouter les retenues
                        Pierre-Luc Simard   2016-06-10  Ajouter les commissions sur l'actif
                                                        Retirer la validation sur la date pour le retenus
                                                        Générer les données pour tous les représentants, actifs et inactifs
                        Pierre-Luc Simard   2016-06-16  Utilisation de la vue VtblREPR_CommissionsSurActif_Conv au lieu de la table 
                                                        tblREPR_CommissionsSurActif afin d'arrondir les montants par convention et non par unité
                        Pierre-Luc Simard   2016-09-07  Retirer Siège Social des commissions sur l'épargne
                        Pierre-Luc Simard   2017-06-09  Ajouter les commissions de suivi
                        Pierre-Luc Simard   2018-09-12  UNION ALL pour ne plus perdre certaines infos
						Donald Huppé		2018-11-20	jira mp-2414 : ajout de tblREPR_CommissionsBEC pour COMBEC
exec GU_RP_ComptRepCommGPMAC 844, 1

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_ComptRepCommGPMAC] (
	@RepTreatmentID INTEGER, -- Numéro du traitement des commissions	
	@Actif INTEGER) -- 1 = Actifs, 0 = Inactifs, 2 = Tous
AS
BEGIN
	SET NOCOUNT ON
    
    -- On génère maintenant les données pour tous les représentants, actifs et inactifs
    SET @Actif = 2

	DECLARE @RepTreatmentDate MoDate
	-- Lecture de la date du traitement choisi
	SELECT @RepTreatmentDate = RepTreatmentDate
	FROM Un_Reptreatment
	WHERE RepTreatmentID = @RepTreatmentID
	
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
		CommissionFee MONEY)
	INSERT INTO @tRepCommSum
	SELECT
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
	WHERE RT.RepTreatmentID = @RepTreatmentID
		AND ((@Actif = 2) OR (CASE WHEN R.BusinessEnd < RT.RepTreatmentDate THEN 0 ELSE 1 END = @Actif)) -- Actifs ou inactifs seulement selon le paramètre
		AND S.RepCode <> '0000' AND S.RepCode <> '6141' AND S.RepCode <> '7910' -- Directeur fictif, Outaouais-Abétimis et Agence Nouveau-Brunswick à enlever
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
	
	UNION ALL
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

	UNION ALL
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

	UNION ALL
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

	UNION ALL
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

	UNION ALL
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
	
	UNION ALL
	-- Autres retenues
	SELECT 
		RepCode = CASE S.RepCode
					WHEN '6055 - 6647' THEN '6055'  -- Marcelle Payette
					WHEN '5852 - 6404' THEN '5852'  -- Martin Mercier
					WHEN '5482-6612' THEN '6612'	-- Mario Béchard
					ELSE S.Repcode 
				END,	
		RepName = H.LastName + ' ' + H.FirstName, 
		Montant = CASE WHEN S.Montant < 0 THEN S.Montant * -1 ELSE S.Montant END,
		Signe = CASE WHEN S.Montant < 0 THEN -1 ELSE 1 END,
		Compte = S.Type
	FROM tblREPR_RetenusPaie S
	JOIN Un_Rep R ON R.RepCode = S.RepCode 
	JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	--WHERE S.DateTraitement = @RepTreatmentDate 
	
    UNION ALL 

    SELECT 
        RepCode = R.RepCode,
	    RepName = H.LastName + ' ' + H.FirstName, 
	    Montant = SUM(CSA.mMontant_ComActif),
	    Signe = 1,
	    Compte = 'COMEPG'
    FROM VtblREPR_CommissionsSurActif_Conv CSA
    JOIN Un_Rep R ON R.RepID = CSA.RepID
    JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
    WHERE CSA.RepTreatmentID = @RepTreatmentID
        AND R.RepCode <> '6141' -- Siège Social
    GROUP BY 
        CSA.RepID, 
        R.RepCode,
        H.LastName, 
        H.FirstName
    HAVING SUM(CSA.mMontant_ComActif) > 0

    UNION ALL 

    SELECT 
        RepCode = R.RepCode,
	    RepName = H.LastName + ' ' + H.FirstName, 
	    Montant = SUM(CS.mMontant_ComActif),
	    Signe = 1,
	    Compte = 'COMSVI'
    FROM VtblREPR_CommissionsSuivi_Conv CS
    JOIN Un_Rep R ON R.RepID = CS.RepID
    JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
    WHERE CS.RepTreatmentID = @RepTreatmentID
        AND R.RepCode <> '6141' -- Siège Social
    GROUP BY 
        CS.RepID, 
        R.RepCode,
        H.LastName, 
        H.FirstName
    HAVING SUM(CS.mMontant_ComActif) > 0


	UNION ALL


	SELECT
        RepCode = R.RepCode,
	    RepName = H.LastName + ' ' + H.FirstName, 
	    Montant = ABS(SUM(CB.mMontant_ComBEC)),
	    Signe = CASE WHEN SUM(CB.mMontant_ComBEC) < 0 THEN -1 ELSE 1 END,
	    Compte = 'COMBEC'
	FROM tblREPR_CommissionsBEC CB
	JOIN Un_Rep R ON R.RepID = CB.RepID
	JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	WHERE CB.RepTreatmentID = @RepTreatmentID
    GROUP BY 
        R.RepCode,
        H.LastName, 
        H.FirstName
	HAVING SUM(CB.mMontant_ComBEC) <> 0

	ORDER BY RepName, RepCode, Compte, Signe

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GU_RP_ComptRepCommGPMAC] TO [Rapport]
    AS [dbo];

