/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_RepExceptionForUnitReduction 
Description         :	Traitement qui crée automatiquement toutes les exceptions de commissions et bonis d’affaires
								pour les réductions d’unités.
Valeurs de retours  :	@ReturnValue :
									>0 :	Le traitement a réussi.
									<=0 :	Le traitement a échoué.
Note                :	ADX0000696	IA	2005-08-15	Bruno Lapointe		Création
                                        2018-05-17  Pierre-Luc Simard   Ajout des PlanID dans Un_RepLevelBracket
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_RepExceptionForUnitReduction] (
	@ConnectID INTEGER, -- ID unique de connexion de l’usager qui a lancé le traitement.
	@RepTreatmentDate DATETIME ) -- Dernier jour inclusivement à traiter dans le traitement.
AS
BEGIN 
	DECLARE
		-- Variable utiliser dans le curseur.
		@RepExceptionID INTEGER,
		@UnitReductionID INTEGER,
		@RepID INTEGER,
		@UnitID INTEGER,
		@RepLevelID INTEGER,
		@RepExceptionTypeID CHAR(3),
		@RepExceptionAmount MONEY

	-- Enlève les minutes à la date de traitement
	SET @RepTreatmentDate = dbo.fn_Mo_DateNoTime(@RepTreatmentDate)

	-- Table des exceptions sur réductions d'unités pour groupe d'unités qui n'ont pas des frais non commissionnable
	CREATE TABLE #tUnitReductionRepException (
		UnitReductionID INTEGER,
		RepID INTEGER,
		UnitID INTEGER,
		RepLevelID INTEGER,
		RepExceptionTypeID VARCHAR(3),
		RepExceptionAmount MONEY )

	-- Table des exceptions sur réductions d'unités pour groupe d'unités qui ont des frais non commissionnable
	CREATE TABLE #tUnitReductionRepExceptionTFR (
		UnitReductionID INTEGER,
		RepID INTEGER,
		UnitID INTEGER,
		RepLevelID INTEGER,
		RepExceptionTypeID VARCHAR(3),
		RepExceptionAmount MONEY )

	-- Table temporaire des groupes d'unités sur lesquelles on a des frais non commissionnable.  C'est le type d'opération qui détermine
	-- s'il y a des frais non commissionables dans un groupe d'unités.
	CREATE TABLE #tTFRUnit (
		UnitID INTEGER PRIMARY KEY )
	INSERT INTO #tTFRUnit
		SELECT DISTINCT
			Ct.UnitID
		FROM dbo.Un_Unit U
		JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID AND OT.CommissionToPay = 0 
		WHERE O.OperDate <= @RepTreatmentDate
			AND Ct.Fee > 0

	-- Table temporaire des différents rôles et le pourcentage maximum qu'un directeur a pour chaque rôle ce pour chaque groupes d'unités
	-- Cela permettra de connaître les supérieurs des groupes d'unités facilement.
	CREATE TABLE #tMaxPctBoss (
		UnitID INTEGER NOT NULL,
		RepRoleID CHAR(3) NOT NULL,
		RepBossPct MONEY NOT NULL,
		CONSTRAINT PK_tMaxPctBoss PRIMARY KEY (UnitID, RepRoleID) )
	INSERT INTO #tMaxPctBoss
		SELECT
			U.UnitID,
			RBH.RepRoleID,
			RepBossPct = MAX(RBH.RepBossPct)
		FROM Un_UnitReduction UR
		JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
		JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID
		JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID
		WHERE U.InForceDate >= RBH.StartDate
			AND( U.InForceDate <= RBH.EndDate
				OR RBH.EndDate IS NULL
				)
			AND U.InForceDate >= RBB.StartDate
			AND( U.InForceDate <= RBB.EndDate
				OR RBB.EndDate IS NULL
				)
		GROUP BY
			U.UnitID,
			RBH.RepRoleID

	-- Changement de représentant :
	-- Dans le cas ou on changerait le représentant sur un groupe d'unités (Changement de représentant qui a fait la vente), on renverse
	-- toutes les exceptions de commissions affectés à l'ancien représentant.  Elles seront recréées plus tard, dans la procédure, pour
	-- le nouveau représentant.
	INSERT INTO #tUnitReductionRepException
		SELECT
			UR.UnitReductionID,
			RE.RepID,
			RE.UnitID,
			RE.RepLevelID,
			RE.RepExceptionTypeID,
			RepExceptionAmount = SUM(RE.RepExceptionAmount)*-1
		FROM (
			-- Trouve toutes les groupes d'unités qui ont des exceptions pour un représentant ou un niveau qui n'est pas le même
			-- que présentement.
			SELECT
				RE.UnitID,
				RL.RepLevelID
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
			-- Trouve le niveau qu'a le représentant pour le groupe d'unités selon l'historique des niveaux
			JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (U.InForceDate >= RLH.StartDate) AND (RLH.EndDate IS NULL OR U.InForceDate <= RLH.EndDate)
			JOIN Un_RepLevel RLU ON RLU.RepLevelID = RLH.RepLevelID AND RLU.RepRoleID = 'REP'
			-- Trouve les exceptions du groupe d'unités dont le représentant n'est pas le même ou encore que le niveau n'est pas le même.
			JOIN Un_RepException RE ON RE.UnitID = U.UnitID AND ((RE.RepID <> U.RepID) OR (RLU.RepLevelID <> RE.RepLevelID))
			JOIN Un_RepLevel RL ON RL.RepLevelID = RE.RepLevelID AND RL.RepRoleID = 'REP'
			GROUP BY
				RE.UnitID,
				RL.RepLevelID
			HAVING SUM(RE.RepExceptionAmount) > 0
			) VV
		JOIN Un_UnitReduction UR ON VV.UnitID = UR.UnitID
		JOIN Un_UnitReductionRepException URE ON URE.UnitReductionID = UR.UnitReductionID
		JOIN Un_RepException RE ON URE.RepExceptionID = RE.RepExceptionID AND RE.RepLevelID = VV.RepLevelID
		WHERE UR.ReductionDate <= @RepTreatmentDate
		GROUP BY
			UR.UnitReductionID,
			RE.RepID,
			RE.UnitID,
			RE.RepLevelID,
			RE.RepExceptionTypeID
		HAVING SUM(RE.RepExceptionAmount) > 0 -- Les exceptions insérées doivent être différente de 0.00$

	-- Changement de directeur pour bonis d'affaires :
	-- Dans le cas ou on changerait un supérieur d'un groupe d'unités (Changement de représentant qui a fait la vente ou changement
	-- dans l'historique des supérieurs du représentant qui a fait la vente), on renverse toutes les exceptions de bonis d'affaires
	-- affectés à le ou les anciens supérieurs.  Elles seront recréées plus tard, dans la procédure, pour le ou les nouveaux supérieurs.
	INSERT INTO #tUnitReductionRepException
		SELECT
			UR.UnitReductionID,
			RE.RepID,
			RE.UnitID,
			RE.RepLevelID,
			RE.RepExceptionTypeID,
			RepExceptionAmount = SUM(RE.RepExceptionAmount)*-1
		FROM (
			-- Trouve toutes les groupes d'unités qui ont des exceptions pour un supérieur qui n'est pas de ceux qui sont
			-- présentement défénis pour ce groupe d'unités selon l'historique des supérieurs du représentant qui a fait la vente.
			SELECT
				RE.UnitID,
				RL.RepLevelID
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
			-- Trouve les supérieurs qu'a le représentant pour le groupe d'unités selon l'historique des supérieurs
			JOIN #tMaxPctBoss UMPct ON UMPct.UnitID = U.UNitID
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND UMPct.RepBossPct = RBH.RepBossPct AND UMPct.RepRoleID = RBH.RepRoleID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
			-- Trouve les exceptions du groupe d'unités dont le supérieur n'est pas le même de ceux qui sont présentement défénis 
			-- pour ce groupe d'unités
			JOIN Un_RepException RE ON RE.UnitID = U.UnitID AND (RE.RepID <> RBH.BossID) AND RE.RepExceptionTypeID = 'BSR'
			JOIN Un_RepLevel RL ON RL.RepLevelID = RE.RepLevelID AND (RL.RepRoleID <> 'REP')
			GROUP BY
				RE.UnitID,
				RL.RepLevelID
			HAVING SUM(RE.RepExceptionAmount) > 0
			) VV
		JOIN Un_UnitReduction UR ON VV.UnitID = UR.UnitID
		JOIN Un_UnitReductionRepException URE ON URE.UnitReductionID = UR.UnitReductionID
		JOIN Un_RepException RE ON URE.RepExceptionID = RE.RepExceptionID AND RE.RepLevelID = VV.RepLevelID AND RE.RepExceptionTypeID = 'BSR'
		GROUP BY
			UR.UnitReductionID,
			RE.RepID,
			RE.UnitID,
			RE.RepLevelID,
			RE.RepExceptionTypeID
		HAVING SUM(RE.RepExceptionAmount) > 0 -- Les exceptions insérées doivent être différente de 0.00$

	-- Changement de directeur pour commissions :
	-- Dans le cas ou on changerait un supérieur d'un groupe d'unités (Changement de représentant qui a fait la vente ou changement
	-- dans l'historique des supérieurs du représentant qui a fait la vente), on renverse toutes les exceptions de commissions
	-- affectés à le ou les anciens supérieurs.  Elles seront recréées plus tard, dans la procédure, pour le ou les nouveaux supérieurs.
	-- Changement de directeur pour commission
	INSERT INTO #tUnitReductionRepException
		SELECT
			UR.UnitReductionID,
			RE.RepID,
			RE.UnitID,
			RE.RepLevelID,
			RE.RepExceptionTypeID,
			RepExceptionAmount = SUM(RE.RepExceptionAmount)*-1
		FROM (
			-- Trouve toutes les groupes d'unités qui ont des exceptions pour un supérieur qui n'est pas de ceux qui sont
			-- présentement défénis pour ce groupe d'unités selon l'historique des supérieurs du représentant qui a fait la vente.
			SELECT
				RE.UnitID,
				RE.RepID,
				RE.RepLevelID
			FROM Un_UnitReduction UR
			JOIN Un_RepException RE ON RE.UnitID = UR.UnitID
			JOIN Un_RepLevel RL ON RL.RepLevelID = RE.RepLevelID AND (RL.RepRoleID <> 'REP')
			-- Trouve les supérieurs qu'a le représentant pour le groupe d'unités selon l'historique des supérieurs
			LEFT JOIN (
				SELECT
					U.UnitID,
					RepID = RBH.BossID,
					RL.RepLevelID
				FROM Un_UnitReduction UR
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
				JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
				JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID AND (RL.RepRoleID <> 'REP')
				) B ON B.UnitID = RE.UnitID AND B.RepID = RE.RepID AND B.RepLevelID = RE.RepLevelID
			WHERE B.UnitID IS NULL
			GROUP BY
				RE.UnitID,
				RE.RepID,
				RE.RepLevelID
			) VV
		JOIN Un_UnitReduction UR ON VV.UnitID = UR.UnitID
		JOIN Un_UnitReductionRepException URE ON URE.UnitReductionID = UR.UnitReductionID
		JOIN Un_RepException RE ON URE.RepExceptionID = RE.RepExceptionID AND RE.RepID = VV.RepID AND RE.RepLevelID = VV.RepLevelID 
		GROUP BY
			UR.UnitReductionID,
			RE.RepID,
			RE.UnitID,
			RE.RepLevelID,
			RE.RepExceptionTypeID
		HAVING SUM(RE.RepExceptionAmount) > 0 -- Les exceptions insérées doivent être différente de 0.00$

	-- Exception de commission pour représentant :
	-- Calcul les exceptions qui devrait exister pour chaque groupe d'unités (Exception sur commissions du représentant seulement).  
	-- Ensuite il génére des exceptions pour le montant de l'exception qui n'est pas déjà géré par des exceptions déjà existente sur
	-- le groupe d'unités.
	INSERT INTO #tUnitReductionRepException
		SELECT *
		FROM (
			-- Le select avant le UNION ALL gère les exceptions sur avances de commissions et sur commissions de service.  Le représentant 
			-- conserve uniquement ce qu'il a touché pour les frais qui reste disponible et non pour les frais remboursés dans la 
			-- résiliation.
			SELECT
				UR.UnitReductionID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				RepExceptionTypeID =
					CASE RL.RepLevelBracketTypeID
						WHEN 'COM' THEN 'CRE'
						WHEN 'ADV' THEN 'ARE'
					END,
				RepExceptionAmount = 	
					CASE
						WHEN (SUM(RL.AdvanceByUnit) > UR.FeeSumByUnit) AND RL.RepLevelBracketTypeID = 'ADV' THEN
							ROUND(UR.FeeSumByUnit*UR.UnitQty,2)-ISNULL(VU.RepExceptionAmount,0)
					ELSE -- 
						ROUND(SUM(RL.AdvanceByUnit)*UR.UnitQty,2)-ISNULL(VU.RepExceptionAmount,0)
					END
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN (
				-- Pour chaque groupe d'unité, trouve le niveau du représentant qui a fait la vente selon l'historique des niveaux de
				-- ce dernier.
				SELECT
					U.UnitID,
					RH.RepLevelID
				FROM dbo.Un_Unit U
				JOIN Un_RepLevelHist RH ON RH.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID AND RL.RepRoleID = 'REP'
				WHERE U.InForceDate >= RH.StartDate 
					AND( U.InForceDate <= RH.EndDate
						OR RH.EndDate IS NULL
						)
				) RH ON RH.UnitID = U.UnitID
			JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID
			LEFT JOIN ( 
				-- Fait un cumulatif des exceptions par groupe d'unités, représentant, niveau du représentant et type d'exception 
				-- pour chaque groupe d'unités.
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount),
					Ex.RepExceptionTypeID
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID IN ('CRE','ARE') -- Avance et commission de service sur résiliation seulement
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					Ex.RepExceptionTypeID
				) VU	ON VU.UnitReductionID = UR.UnitReductionID 
						AND VU.RepID = U.RepID
						AND RH.RepLevelID = VU.RepLevelID
						AND(	( RL.RepLevelBracketTypeID = 'COM' 
								AND ISNULL(VU.RepExceptionTypeID,'') = 'CRE'
								)
							OR	( RL.RepLevelBracketTypeID = 'ADV'
								AND ISNULL(VU.RepExceptionTypeID,'') = 'ARE'
								)
							)
			LEFT JOIN #tTFRUnit F ON F.UnitID = U.UnitID -- Exclus les groupes d'unités avec frais non commissionnable
			WHERE (UR.ReductionDate <= @RepTreatmentDate) -- Gère uniquement les exceptions sur réductions d'unités fait avant ou le jour du traitement de commissions
				AND (RL.TargetFeeByUnit <= UR.FeeSumByUnit)
				AND F.UnitID IS NULL -- Exclus les groupes d'unités avec frais non commissionnable
				AND (U.InForceDate >= RL.EffectDate)
				AND( RL.TerminationDate IS NULL
					OR U.InForceDate <= RL.TerminationDate
					)
			GROUP BY
				UR.UnitReductionID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				UR.UnitQty,
				VU.RepExceptionAmount,
				UR.FeeSumByUnit,
				RL.RepLevelBracketTypeID
			---------
			UNION ALL
			---------
			-- Gère les exceptions sur avances couvertes qui pour les représentants correspond à 0,01$ d'avance couverte par 0,01$ de 
			-- frais par unités sur le groupe d'unités jusqu'à ce que la totalité des avances du représentant pour le groupe d'unités
			-- soient couvertes.  Le représentant conserve les avances couvertes selon les frais des unités résiliés qui sont conservés
			-- en frais disponible et non sur les frais remboursés dans la résiliation.
			SELECT
				UR.UnitReductionID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				RepExceptionTypeID = 'DRE',
				RepExceptionAmount = 
					CASE
						WHEN SUM(RL.AdvanceByUnit) > UR.FeeSumByUnit THEN 
							-- Avance totalement couverte
							ROUND(UR.FeeSumByUnit*UR.UnitQty,2)-ISNULL(VU.RepExceptionAmount,0)
					ELSE 
						-- Avance partiellement couverte 0,01$ pour 0,01$
						ROUND(SUM(RL.AdvanceByUnit)*UR.UnitQty,2)-ISNULL(VU.RepExceptionAmount,0)
					END
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN (
				-- Pour chaque groupe d'unité, trouve le niveau du représentant qui a fait la vente selon l'historique des niveaux de
				-- ce dernier.
				SELECT
					U.UnitID,
					RH.RepLevelID
				FROM dbo.Un_Unit U
				JOIN Un_RepLevelHist RH ON RH.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID AND RL.RepRoleID = 'REP'
				WHERE U.InForceDate >= RH.StartDate
					AND( U.InForceDate <= RH.EndDate
						OR RH.EndDate IS NULL
						)
				) RH ON RH.UnitID = U.UnitID
			JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID
			LEFT JOIN ( 
				-- Fait un cumulatif des exceptions par groupe d'unités, représentant et niveau du représentant pour chaque
				-- groupe d'unités.
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount)
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID = 'DRE' -- Avance couverte sur résiliation seulement
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID
				) VU ON VU.UnitReductionID = UR.UnitReductionID AND VU.RepID = U.RepID AND RH.RepLevelID = VU.RepLevelID
			LEFT JOIN #tTFRUnit F ON F.UnitID = U.UnitID -- Exclus les groupes d'unités avec frais non commissionnable
			WHERE (UR.ReductionDate <= @RepTreatmentDate) -- Gère uniquement les exceptions sur réductions d'unités fait avant ou le jour du traitement de commissions
				AND RL.RepLevelBracketTypeID = 'ADV' -- Avance couverte seulement
				AND (RL.TargetFeeByUnit <= UR.FeeSumByUnit)
				AND F.UnitID IS NULL
				AND (U.InForceDate >= RL.EffectDate)
				AND( RL.TerminationDate IS NULL
					OR U.InForceDate <= RL.TerminationDate
					)
			GROUP BY
				UR.UnitReductionID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				UR.UnitQty,
				VU.RepExceptionAmount,
				UR.FeeSumByUnit
			) VV
		WHERE RepExceptionAmount <> 0 -- Les exceptions insérées doivent être différente de 0.00$

	-- Exception de commission pour boss :
	-- Calcul les exceptions qui devrait exister pour chaque groupe d'unités (Exception sur commissions des supérieurs du représentant.  
	-- Ensuite il génére des exceptions pour le montant de l'exception qui n'est pas déjà géré par des exceptions déjà existente sur
	-- le groupe d'unités.
	INSERT INTO #tUnitReductionRepException
		SELECT *
		FROM (
			-- Le select avant le UNION ALL gère les exceptions sur avances couvertes et sur commissions de service.  Le supérieur 
			-- conserve uniquement ce qu'il a touché pour les frais qui reste disponible et non pour les frais remboursés dans la 
			-- résiliation.
			SELECT
				UR.UnitReductionID,
				RH.RepID,
				U.UnitID,
				RH.RepLevelID,
				RepExceptionTypeID = 
					CASE RL.RepLevelBracketTypeID
						WHEN 'COM' THEN 'CRE'
						WHEN 'CAD' THEN 'DRE'
					END,
				RepExceptionAmount = ROUND(SUM(RL.AdvanceByUnit)*UR.UnitQty*(RH.RepBossPct/100),2)-ISNULL(VU.RepExceptionAmount,0)
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN ( 
				-- Trouve le ou les supérieurs de chaque groupe d'unités.
				SELECT
					U.UnitID,
					RepID = RB.BossID,
					RB.RepBossPct,
					RH.RepLevelID
				FROM dbo.Un_Unit U
				JOIN Un_RepBossHist RB ON RB.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepRoleID = RB.RepRoleID
				JOIN Un_RepLevelHist RH ON RH.RepID = RB.BossID AND RH.RepLevelID = RL.RepLevelID
				WHERE U.InForceDate >= RH.StartDate
					AND( RH.EndDate IS NULL
						OR U.InForceDate <= RH.EndDate
						)
					AND U.InForceDate >= RB.StartDate
					AND( RB.EndDate IS NULL
						OR U.InForceDate <= RB.EndDate
						)
				) RH ON RH.UnitID = U.UnitID
			JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID AND (RL.RepLevelBracketTypeID <> 'ADV')
			LEFT JOIN (
				-- Fait un cumulatif des exceptions par groupe d'unités, supérieur(Type de supérieur aussi) et type d'exception pour chaque
				-- groupe d'unités.
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount),
					Ex.RepExceptionTypeID
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID IN ('CRE','DRE')
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					Ex.RepExceptionTypeID
				) VU	ON VU.UnitReductionID = UR.UnitReductionID
						AND VU.RepID = RH.RepID
						AND VU.RepLevelID = RH.RepLevelID
						AND(	( RL.RepLevelBracketTypeID = 'COM'
								AND ISNULL(VU.RepExceptionTypeID,'') = 'CRE'
								)
							OR ( RL.RepLevelBracketTypeID = 'CAD'
								AND ISNULL(VU.RepExceptionTypeID,'') = 'DRE'
								)
							)
			LEFT JOIN #tTFRUnit F ON F.UnitID = U.UnitID -- Exclus les groupes d'unités avec frais non commissionnable
			WHERE (UR.ReductionDate <= @RepTreatmentDate) -- Gère uniquement les exceptions sur réductions d'unités fait avant ou le jour du traitement de commissions
				AND (RL.TargetFeeByUnit <= UR.FeeSumByUnit)
				AND F.UnitID IS NULL
				AND (U.InForceDate >= RL.EffectDate)
				AND( RL.TerminationDate IS NULL
					OR U.InForceDate <= RL.TerminationDate
					)
			GROUP BY
				UR.UnitReductionID,
				RH.RepID,
				U.UnitID,
				RH.RepLevelID,
				UR.UnitQty,
				VU.RepExceptionAmount,
				UR.FeeSumByUnit,
				RH.RepBossPct,
				RL.RepLevelBracketTypeID
			---------
			UNION ALL
			---------
			-- Gère les exceptions sur avances des supérieurs.  Le supérieur conserve les avances couvertes selon les frais des unités
			-- résiliés qui sont conservés en frais disponible et non sur les frais remboursés dans la résiliation.  Le montant de 
			-- l'exception sur l'avance varie selon le montant d'avance couverte.
			SELECT
				UR.UnitReductionID,
				RH.RepID,
				U.UnitID,
				RH.RepLevelID,
				RepExceptionTypeID = 'ARE',
				RepExceptionAmount = ROUND(SUM(RL.AdvanceByUnit)*UR.UnitQty*(RH.RepBossPct/100),2)-ISNULL(VU.RepExceptionAmount,0)
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN (
				-- Trouve le ou les supérieurs de chaque groupe d'unités.
				SELECT
					U.UnitID,
					RepID = RB.BossID,
					RB.RepBossPct,
					RH.RepLevelID
				FROM dbo.Un_Unit U
				JOIN Un_RepBossHist RB ON RB.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepRoleID = RB.RepRoleID
				JOIN Un_RepLevelHist RH ON RH.RepID = RB.BossID AND RH.RepLevelID = RL.RepLevelID
				WHERE U.InForceDate >= RH.StartDate
					AND( RH.EndDate IS NULL
						OR U.InForceDate <= RH.EndDate
						)
					AND U.InForceDate >= RB.StartDate
					AND( RB.EndDate IS NULL
						OR U.InForceDate <= RB.EndDate
						)
				) RH ON RH.UnitID = U.UnitID
			JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID AND RL.RepLevelBracketTypeID = 'CAD'
			LEFT JOIN (
				-- Fait un cumulatif des exceptions par groupe d'unités et supérieur(Type de supérieur aussi) pour chaque
				-- groupe d'unités.
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount)
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID = 'ARE'
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID
				) VU ON VU.UnitReductionID = UR.UnitReductionID AND VU.RepID = RH.RepID AND VU.RepLevelID = RH.RepLevelID
			LEFT JOIN #tTFRUnit F ON F.UnitID = U.UnitID 
			WHERE (UR.ReductionDate <= @RepTreatmentDate) -- Gère uniquement les exceptions sur réductions d'unités fait avant ou le jour du traitement de commissions
				AND (RL.TargetFeeByUnit <= UR.FeeSumByUnit)
				AND F.UnitID IS NULL -- Exclus les groupes d'unités avec frais non commissionnable
				AND (U.InForceDate >= RL.EffectDate)
				AND( RL.TerminationDate IS NULL
					OR U.InForceDate <= RL.TerminationDate
					)
			GROUP BY
				UR.UnitReductionID,
				RH.RepID,
				U.UnitID,
				RH.RepLevelID,
				UR.UnitQty,
				VU.RepExceptionAmount,
				UR.FeeSumByUnit,
				RH.RepBossPct
			) VV
		WHERE RepExceptionAmount <> 0 -- Les exceptions insérées doivent être différente de 0.00$

	-- Boni sur l'assurance souscripteur pour les représentants
	-- Calcul les exceptions sur boni d'assurance souscripteur qui devrait exister pour chaque réductions d'unités (pour les
	-- représentant seulement). Ensuite il génére des exceptions pour le montant d'exception qui n'est pas déjà géré par des
	-- exceptions déjà existente sur le groupe d'unités.
	INSERT INTO #tUnitReductionRepException
		SELECT *
		FROM (
			SELECT
				UR.UnitReductionID,
				U.RepID,
				U.UnitID,
				RL.RepLevelID,
				RepExceptionTypeID = 'BSR',
				RepExceptionAmount = 
					CASE 
						-- Le maximum de boni a été versé
						WHEN FLOOR(UR.SubscInsurSumByUnit / (M.PmtByYearID * M.SubscriberInsuranceRate)) <= RBB.BusinessBonusNbrOfYears THEN
							ROUND(FLOOR(UR.SubscInsurSumByUnit / (M.PmtByYearID * M.SubscriberInsuranceRate)) * (RBB.BusinessBonusByUnit * UR.UnitQTY),2)-ISNULL(VU.RepExceptionAmount,0)
					ELSE
						-- Le maximum n'a pas été versé
						ROUND(RBB.BusinessBonusNbrOfYears * (UR.UnitQTY * RBB.BusinessBonusByUnit),2)-ISNULL(VU.RepExceptionAmount,0)
					END
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON UR.UnitID = U.UnitID
			JOIN Un_Modal M ON M.ModalID = U.ModalID AND M.BusinessBonusToPay <> 0
			JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate))
			JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = 'REP'
			JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RL.RepRoleID AND RBB.InsurTypeID = 'ISB' AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate))
			LEFT JOIN (
				-- Va chercher le montant déjà géré par les exceptions existentes
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount)
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID = 'BSR' -- Exception sur boni d'assurance souscripteur seulement
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID
				) VU ON VU.UnitReductionID = UR.UnitReductionID AND VU.RepID = U.RepID AND RL.RepLevelID = VU.RepLevelID
			WHERE (UR.ReductionDate <= @RepTreatmentDate) -- Gère uniquement les exceptions sur réductions d'unités fait avant ou le jour du traitement de commissions 
				AND (UR.SubscInsurSumByUnit > 0) -- Assurance souscripteur conservé par unité résilié lors de la réduction d'unités
				AND (U.WantSubscriberInsurance <> 0) -- Groupe d'unités qui ont de l'assurance souscripteur seulement
				AND (M.PmtByYearID * M.SubscriberInsuranceRate <> 0) -- Groupe d'unités qui on une modalité de paiement qui autorise l'assurance souscripteur (Taux différent de 0.00$)
			) VV
		WHERE RepExceptionAmount <> 0 -- Les exceptions insérées doivent être différente de 0.00$

	-- Boni sur l'assurance souscripteur pour les boss
	-- Calcul les exceptions sur boni d'assurance souscripteur qui devrait exister pour chaque réductions d'unités (pour les
	-- supérieurs seulement). Ensuite il génére des exceptions pour le montant d'exception qui n'est pas déjà géré par des
	-- exceptions déjà existente sur le groupe d'unités.
	INSERT INTO #tUnitReductionRepException
		SELECT *
		FROM (
			SELECT
				UR.UnitReductionID,
				RepID = RBH.BossID,
				U.UnitID,
				RL.RepLevelID,
				RepExceptionTypeID = 'BSR',
				RepExceptionAmount = 
					CASE
						-- Le maximum de boni a été versé
						WHEN FLOOR(UR.SubscInsurSumByUnit / (M.PmtByYearID * M.SubscriberInsuranceRate)) <= RBB.BusinessBonusNbrOfYears THEN
							ROUND(FLOOR(UR.SubscInsurSumByUnit / (M.PmtByYearID * M.SubscriberInsuranceRate)) * (RBB.BusinessBonusByUnit * UR.UnitQTY),2)-ISNULL(VU.RepExceptionAmount,0)
					ELSE
						-- Le maximum n'a pas été versé
						ROUND(RBB.BusinessBonusNbrOfYears * (UR.UnitQTY * RBB.BusinessBonusByUnit),2)-ISNULL(VU.RepExceptionAmount,0)
					END
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON UR.UnitID = U.UnitID
			JOIN Un_Modal M ON M.ModalID = U.ModalID AND (M.BusinessBonusToPay <> 0)
			JOIN #tMaxPctBoss UMPct ON UMPct.UnitID = U.UNitID
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND UMPct.RepBossPct = RBH.RepBossPct AND UMPct.RepRoleID = RBH.RepRoleID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
			JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID
			JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND RBB.InsurTypeID = 'ISB' AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate))
			LEFT JOIN (
				-- Va chercher le montant déjà géré par les exceptions existentes
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount)
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID = 'BSR' -- Exception sur boni d'assurance souscripteur seulement
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID
				) VU ON VU.UnitReductionID = UR.UnitReductionID AND VU.RepID = RBH.BossID AND RL.RepLevelID = VU.RepLevelID
			WHERE (UR.ReductionDate <= @RepTreatmentDate) -- Gère uniquement les exceptions sur réductions d'unités fait avant ou le jour du traitement de commissions 
				AND (UR.SubscInsurSumByUnit > 0) -- Assurance souscripteur conservé par unité résilié lors de la réduction d'unités
				AND (U.WantSubscriberInsurance <> 0) -- Groupe d'unités qui ont de l'assurance souscripteur seulement
				AND (M.PmtByYearID * M.SubscriberInsuranceRate <> 0) -- Groupe d'unités qui on une modalité de paiement qui autorise l'assurance souscripteur (Taux différent de 0.00$)
			) VV
		WHERE RepExceptionAmount <> 0 -- Les exceptions insérées doivent être différente de 0.00$

	-- Exception de commission pour représentant sur unité avec transfert de frais
	-- Le représentant perd toutes ses avances et ses avances couvertes sur un groupe d'unités qui a des frais non commissionable.  
	-- On ne donne pas d'avance sur ces groupes d'unités et on remplace les tombés d'avances couvertes par des tombés de commission de
	-- service.  Cette requête crée les exceptions de commissions de services des représentants pour les réductions d'unités.
	INSERT INTO #tUnitReductionRepExceptionTFR
		SELECT *
		FROM (
			-- Le représentant perd toutes les avances et avances couvertes lorsqu'il y a des frais non commissionnable sur le groupe 
			-- d'unités.  Car les avances sont payés en commission de service sur les groupes d'unités qui on des frais non commissionnable.
			-- Cette requête(avant union) gère le cas ou un groupe d'unités qui n'avait pas de frais non commissionnable reçoit des frais 
			-- non commissionnable.  Donc il enlève les exceptions d'avances et d'avances couvertes pour les réductions de ce groupe
			-- d'unités.
			SELECT
				UR.UnitReductionID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				RepExceptionTypeID = VU.RepExceptionTypeID,
				RepExceptionAmount = -VU.RepExceptionAmount
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
			JOIN (
				-- Trouve pour chaque groupe d'unités le niveau du représentant lors de la vente
				SELECT
					U.UnitID,
					RH.RepLevelID
				FROM dbo.Un_Unit U
				JOIN Un_RepLevelHist RH ON RH.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID AND RL.RepRoleID = 'REP'
				WHERE U.InForceDate >= RH.StartDate
					AND( U.InForceDate <= RH.EndDate
						OR RH.EndDate IS NULL
						)
				) RH ON RH.UnitID = U.UnitID
			JOIN (
				-- Fait la somme des exceptions sur résiliations pour chaque groupe d'unités, représentant, niveau de représentant et
				-- type d'exception
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount),
					Ex.RepExceptionTypeID
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID IN ('ARE', 'DRE')
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					Ex.RepExceptionTypeID
				) VU ON VU.UnitReductionID = UR.UnitReductionID AND VU.RepID = U.RepID AND RH.RepLevelID = VU.RepLevelID
			JOIN #tTFRUnit F ON F.UnitID = U.UnitID
			WHERE UR.ReductionDate <= @RepTreatmentDate -- Gère uniquement les réductions d'unités datant d'avant le traitement des commissions
			GROUP BY
				UR.UnitReductionID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				UR.UnitQty,
				VU.RepExceptionAmount,
				UR.FeeSumByUnit,
				VU.RepExceptionTypeID
			-----
			UNION
			-----
			SELECT
				V.UnitReductionID,
				V.RepID,
				V.UnitID,
				V.RepLevelID,
				V.RepExceptionTypeID,
				RepExceptionAmount = SUM(V.RepExceptionAmount) - ISNULL(VU.RepExceptionAmount,0)
			FROM (
				-- Calcul le montant d'exception de commission de service remplacant les avances que doit avoir le représentant pour les
				-- unités résiliés dans la réductions d'unités.
				SELECT
					UR.UnitReductionID,
					U.RepID,
					U.UnitID,
					RH.RepLevelID,
					RepExceptionTypeID = 'CRE', -- Avance versé en commission de service
					RepExceptionAmount = 
						-- Commission de service remplacant l'avance et versée 0,01$ pou 0,01$ selon les frais
						CASE 
							-- Montant de frais maximum pour avances (Commission de service) dépassé
							WHEN (SUM(RL.AdvanceByUnit) > UR.FeeSumByUnit) THEN
								ROUND(UR.FeeSumByUnit*UR.UnitQty,2)
						ELSE
							-- 0,01$ pou 0,01$ selon les frais
							ROUND(SUM(RL.AdvanceByUnit)*UR.UnitQty,2)
						END
				FROM Un_UnitReduction UR
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN (
					-- Trouve pour chaque groupe d'unités le niveau du représentant lors de la vente
					SELECT
						U.UnitID,
						RH.RepLevelID
					FROM dbo.Un_Unit U
					JOIN Un_RepLevelHist RH ON RH.RepID = U.RepID
					JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID AND RL.RepRoleID = 'REP'
					WHERE U.InForceDate >= RH.StartDate
						AND( U.InForceDate <= RH.EndDate
							OR RH.EndDate IS NULL
							)
					) RH ON RH.UnitID = U.UnitID
				JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID AND RL.RepLevelBracketTypeID = 'ADV'
				JOIN #tTFRUnit F ON F.UnitID = U.UnitID
				WHERE (UR.ReductionDate <= @RepTreatmentDate) -- Réduction datant d'avant le traitement de commission seulement.
					AND (RL.TargetFeeByUnit <= UR.FeeSumByUnit)
					AND (U.InForceDate >= RL.EffectDate)
					AND( RL.TerminationDate IS NULL
						OR U.InForceDate <= RL.TerminationDate
						)
				GROUP BY
					UR.UnitReductionID,
					U.RepID,
					U.UnitID,
					RH.RepLevelID,
					UR.UnitQty,
					UR.FeeSumByUnit
				---------
				UNION ALL
				---------
				-- Calcul le montant d'exception de commission de service que doit avoir le représentant pour les unités résiliés dans la
				-- réductions d'unités.
				SELECT
					UR.UnitReductionID,
					U.RepID,
					U.UnitID,
					RH.RepLevelID,
					RepExceptionTypeID = 'CRE',
					RepExceptionAmount = ROUND(SUM(RL.AdvanceByUnit)*UR.UnitQty,2)
				FROM Un_UnitReduction UR
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN (
					-- Trouve pour chaque groupe d'unités le niveau du représentant lors de la vente
					SELECT
						U.UnitID,
						RH.RepLevelID
					FROM dbo.Un_Unit U
					JOIN Un_RepLevelHist RH ON RH.RepID = U.RepID
					JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID AND RL.RepRoleID = 'REP'
					WHERE U.InForceDate >= RH.StartDate
						AND( U.InForceDate <= RH.EndDate
							OR RH.EndDate IS NULL
							)
					) RH ON RH.UnitID = U.UnitID
				JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID AND RL.RepLevelBracketTypeID = 'COM'
				JOIN #tTFRUnit F ON F.UnitID = U.UnitID
				WHERE (UR.ReductionDate <= @RepTreatmentDate) -- Réduction datant d'avant le traitement de commission seulement.
					AND (RL.TargetFeeByUnit <= UR.FeeSumByUnit)
					AND (U.InForceDate >= RL.EffectDate)
					AND( RL.TerminationDate IS NULL
						OR U.InForceDate <= RL.TerminationDate
						)
				GROUP BY
					UR.UnitReductionID,
					U.RepID,
					U.UnitID,
					RH.RepLevelID,
					UR.UnitQty
				) V
			LEFT JOIN (
				-- Trouve le montant d'exception sur commission de service déjà existante pour la réduction d'unités, les représentants, 
				-- leurs niveaux
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount),
					Ex.RepExceptionTypeID
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID = 'CRE'
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					Ex.RepExceptionTypeID
				) VU ON VU.UnitReductionID = V.UnitReductionID AND VU.RepID = V.RepID AND V.RepLevelID = VU.RepLevelID
			GROUP BY
				V.UnitReductionID,
				V.RepID,
				V.UnitID,
				V.RepLevelID,
				V.RepExceptionTypeID,
				VU.RepExceptionAmount
			) VV
		WHERE RepExceptionAmount <> 0 -- Les exceptions insérées doivent être différente de 0.00$

	-- Exception de commission pour boss sur unité avec transfert de frais
	-- Les supérieurs perdent leurs avances et avances couvertes sur un groupe d'unités qui a des frais non commissionable.  On ne donne
	-- pas d'avance sur ces groupes d'unités et on remplace les tombés d'avances couvertes par des tombés de commission de service.  
	-- Cette requête crée les exceptions de commissions de services des supérieurs pour les réductions d'unités.
	INSERT INTO #tUnitReductionRepExceptionTFR
		SELECT *
		FROM (
			-- Les supérieurs perdent toutes les avances et avances couvertes lorsqu'il y a des frais non commissionnable sur le groupe 
			-- d'unités.  Car les avances sont payés en commission de service sur les groupes d'unités qui on des frais non commissionnable.
			-- Cette requête(avant union) gère le cas ou un groupe d'unités qui n'avait pas de frais non commissionnable reçoit des frais 
			-- non commissionnable.  Donc il enlève les exceptions d'avances et d'avances couvertes pour les réductions de ce groupe
			-- d'unités.
			SELECT
				UR.UnitReductionID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				VU.RepExceptionTypeID,
				RepExceptionAmount = 0-VU.RepExceptionAmount
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
			JOIN (
				-- Trouve pour chaque groupe d'unités les supérieurs, leurs niveaux et leurs pourcentage de commission pour leurs niveaux
				SELECT
					U.UnitID,
					RepID = RB.BossID,
					RB.RepBossPct,
					RH.RepLevelID
				FROM dbo.Un_Unit U
				JOIN Un_RepBossHist RB ON RB.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepRoleID = RB.RepRoleID
				JOIN Un_RepLevelHist RH ON RH.RepID = RB.BossID AND RH.RepLevelID = RL.RepLevelID
				WHERE U.InForceDate >= RH.StartDate
					AND( RH.EndDate IS NULL
						OR U.InForceDate <= RH.EndDate
						)
					AND U.InForceDate >= RB.StartDate
					AND( RB.EndDate IS NULL
						OR U.InForceDate <= RB.EndDate
						)
				) RH ON RH.UnitID = U.UnitID
			JOIN (
				-- Trouve la somme des exceptions pour chaque réduction d'unités, représentant, niveaux et type d'exception sur réduction
				-- d'unités.
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount),
					Ex.RepExceptionTypeID
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID IN ('ARE', 'DRE')
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					Ex.RepExceptionTypeID
				) VU ON VU.UnitReductionID = UR.UnitReductionID AND VU.RepID = U.RepID AND RH.RepLevelID = VU.RepLevelID
			JOIN #tTFRUnit F ON F.UnitID = U.UnitID
			WHERE UR.ReductionDate <= @RepTreatmentDate
			GROUP BY
				UR.UnitReductionID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				UR.UnitQty,
				VU.RepExceptionAmount,
				UR.FeeSumByUnit,
				VU.RepExceptionTypeID
			-----
			UNION
			-----
			SELECT
				V.UnitReductionID,
				V.RepID,
				V.UnitID,
				V.RepLevelID,
				V.RepExceptionTypeID,
				RepExceptionAmount = SUM(V.RepExceptionAmount) - ISNULL(VU.RepExceptionAmount,0)
			FROM (
				-- Calcul le montant d'exception de commission de service remplacant les avances que doit avoir le ou les supérieurs pour les
				-- unités résiliés dans la réductions d'unités.
				SELECT
					UR.UnitReductionID,
					RH.RepID,
					U.UnitID,
					RH.RepLevelID,
					RepExceptionTypeID = 'CRE',
					RepExceptionAmount = ROUND(SUM(RL.AdvanceByUnit)*UR.UnitQty*(RH.RepBossPct/100),2)
				FROM Un_UnitReduction UR
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN (
					-- Trouve pour chaque groupe d'unités les supérieurs, leurs niveaux et leurs pourcentage de commission pour leurs niveaux
					SELECT
						U.UnitID,
						RepID = RB.BossID,
						RB.RepBossPct,
						RH.RepLevelID
					FROM dbo.Un_Unit U
					JOIN Un_RepBossHist RB ON RB.RepID = U.RepID
					JOIN Un_RepLevel RL ON RL.RepRoleID = RB.RepRoleID
					JOIN Un_RepLevelHist RH ON RH.RepID = RB.BossID AND RH.RepLevelID = RL.RepLevelID
					WHERE U.InForceDate >= RH.StartDate
						AND( RH.EndDate IS NULL
							OR U.InForceDate <= RH.EndDate
							)
						AND U.InForceDate >= RB.StartDate
						AND( RB.EndDate IS NULL
							OR U.InForceDate <= RB.EndDate
							)
					) RH ON RH.UnitID = U.UnitID
				JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID AND RL.RepLevelBracketTypeID = 'CAD'
				JOIN #tTFRUnit F ON F.UnitID = U.UnitID
				WHERE (UR.ReductionDate <= @RepTreatmentDate)
					AND (RL.TargetFeeByUnit <= UR.FeeSumByUnit)
					AND (U.InForceDate >= RL.EffectDate)
					AND( RL.TerminationDate IS NULL
						OR U.InForceDate <= RL.TerminationDate
						)
				GROUP BY
					UR.UnitReductionID,
					RH.RepID,
					RH.RepBossPct,
					U.UnitID,
					RH.RepLevelID,
					UR.UnitQty,
					UR.FeeSumByUnit
				---------
				UNION ALL
				---------
				-- Calcul le montant d'exception de commission de service que doit avoir le ou les supérieurs pour les unités résiliés dans
				-- la réductions d'unités.
				SELECT
					UR.UnitReductionID,
					RH.RepID,
					U.UnitID,
					RH.RepLevelID,
					RepExceptionTypeID = 'CRE',
					RepExceptionAmount = ROUND(SUM(RL.AdvanceByUnit)*UR.UnitQty*(RH.RepBossPct/100),2)
				FROM Un_UnitReduction UR
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN (
					-- Trouve pour chaque groupe d'unités les supérieurs, leurs niveaux et leurs pourcentage de commission pour leurs niveaux
					SELECT
						U.UnitID,
						RepID = RB.BossID,
						RB.RepBossPct,
						RH.RepLevelID
					FROM dbo.Un_Unit U
					JOIN Un_RepBossHist RB ON RB.RepID = U.RepID
					JOIN Un_RepLevel RL ON RL.RepRoleID = RB.RepRoleID
					JOIN Un_RepLevelHist RH ON RH.RepID = RB.BossID AND RH.RepLevelID = RL.RepLevelID
					WHERE U.InForceDate >= RH.StartDate
						AND( RH.EndDate IS NULL
							OR U.InForceDate <= RH.EndDate
							)
						AND U.InForceDate >= RB.StartDate
						AND( RB.EndDate IS NULL
							OR U.InForceDate <= RB.EndDate
							)
					) RH ON RH.UnitID = U.UnitID
				JOIN Un_RepLevelBracket RL ON (RL.RepLevelID = RH.RepLevelID) AND RL.PlanID = C.PlanID AND (RL.RepLevelBracketTypeID = 'COM')
				JOIN #tTFRUnit F ON (F.UnitID = U.UnitID)
				WHERE (UR.ReductionDate <= @RepTreatmentDate)
					AND (RL.TargetFeeByUnit <= UR.FeeSumByUnit)
					AND (U.InForceDate >= RL.EffectDate)
					AND( RL.TerminationDate IS NULL
						OR U.InForceDate <= RL.TerminationDate
						)
				GROUP BY
					UR.UnitReductionID,
					RH.RepID,
					RH.RepBossPct,
					U.UnitID,
					RH.RepLevelID,
					UR.UnitQty
				) V
			LEFT JOIN (
				-- Trouve le montant d'exception sur commission de service déjà existante pour la réduction d'unités, les supérieurs, 
				-- leurs niveaux
				SELECT
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					RepExceptionAmount = SUM(Ex.RepExceptionAmount),
					Ex.RepExceptionTypeID
				FROM Un_UnitReductionRepException UR
				JOIN Un_RepException Ex ON Ex.RepExceptionID = UR.RepExceptionID
				WHERE Ex.RepExceptionTypeID = 'CRE'
				GROUP BY
					UR.UnitReductionID,
					Ex.RepID,
					Ex.RepLevelID,
					Ex.RepExceptionTypeID
				) VU ON VU.UnitReductionID = V.UnitReductionID AND VU.RepID = V.RepID AND V.RepLevelID = VU.RepLevelID
			GROUP BY
				V.UnitReductionID,
				V.RepID,
				V.UnitID,
				V.RepLevelID,
				V.RepExceptionTypeID,
				VU.RepExceptionAmount
			) VV
		WHERE RepExceptionAmount <> 0 -- Les exceptions insérées doivent être différente de 0.00$

	-- Les prochaines lignes insères toutes les exceptions calculé qui sont dans les tables temporaires dans les tables permanentes de 
	-- l'application.  On insère aussi des liens entre les réductions d'unités et les exceptions qu'ils générent pour les cas de 
	-- suppression de réduction d'unités.  C'est aussi la raison pour laquel on utilise un curseur.
	DECLARE UnToDo CURSOR FOR
		SELECT
			UnitReductionID,
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount
		FROM #tUnitReductionRepException
		---------
		UNION ALL
		--------- 
		SELECT
			UnitReductionID,
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount
		FROM #tUnitReductionRepExceptionTFR;

	OPEN UnToDo

	FETCH NEXT FROM UnToDo
	INTO
		@UnitReductionID,
		@RepID,
		@UnitID,
		@RepLevelID,
		@RepExceptionTypeID,
		@RepExceptionAmount

	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO Un_RepException (
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount,
			RepExceptionDate )
		VALUES (
			@RepID,
			@UnitID,
			@RepLevelID,
			@RepExceptionTypeID,
			@RepExceptionAmount,
			@RepTreatmentDate )

		IF @@ERROR = 0 
		BEGIN
			-- Il faut connaître le ID de l'exception avant d'insérer le lien entre cette dernière et la réduction d'unités.
			SET @RepExceptionID = IDENT_CURRENT('Un_RepException')
			INSERT INTO Un_UnitReductionRepException (
				RepExceptionID,
				UnitReductionID )
			VALUES (
				@RepExceptionID,
				@UnitReductionID )
		END

		FETCH NEXT FROM UnToDo
		INTO
			@UnitReductionID,
			@RepID,
			@UnitID,
			@RepLevelID,
			@RepExceptionTypeID,
			@RepExceptionAmount
	END

	CLOSE UnToDo
	DEALLOCATE UnToDo

	-- Supprime les tables temporaires
	DROP TABLE #tUnitReductionRepException
	DROP TABLE #tUnitReductionRepExceptionTFR
	DROP TABLE #tMaxPctBoss
	DROP TABLE #tTFRUnit

	IF @@ERROR = 0
		RETURN(1)
	ELSE
		RETURN(0)
END