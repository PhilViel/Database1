/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_RepExceptionForUncommissionFees 
Description         :	Traitement qui crée automatiquement toutes les exceptions de commissions et bonis d’affaires
								pour les frais non commissionnés (Ex : TFR).
Valeurs de retours  :	@ReturnValue :
									>0 :	Le traitement a réussi.
									<=0 :	Le traitement a échoué.
Note                :	ADX0000696	IA	2005-08-16	Bruno Lapointe		Création
                                        2018-05-17  Pierre-Luc Simard   Ajout des PlanID dans Un_RepLevelBracket
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_RepExceptionForUncommissionFees] (
	@ConnectID INTEGER, -- ID unique de connexion de l’usager qui a lancé le traitement.
	@RepTreatmentDate DATETIME ) -- Dernier jour inclusivement à traiter dans le traitement.
AS
BEGIN
	DECLARE 
		@ZeroMoney MONEY

	-- Variable money de valeur 0
	SET @ZeroMoney = 0

	-- Table temporaire des groupes d'unités sur lesquelles on a des frais non commissionnable.  C'est le type d'opération qui détermine
	-- s'il y a des frais non commissionables dans un groupe d'unités.
	SELECT  
		Ct.UnitID, -- ID unique du groupe d'unités
		FeeSumByUnit = Ct.Fee/(U.UnitQty + SUM(ISNULL(UR.UnitQty,0))), -- Frais non commissionnable par unités
		UnitQty = U.UnitQty + SUM(ISNULL(UR.UnitQty,0)), -- Nombre d'unités du groupe d'unités lors de l'opération
		O.OperID, -- ID de l'opération
		O.OperDate, -- Date de l'opération
		NonCommFeeBefore = @ZeroMoney -- Montant de frais non commissionnable par unité pour ce groupe d'unités avant cette opération
	INTO #tTFRUnit
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID AND OT.CommissionToPay = 0 -- Opération avec frais non-commissionnable
	LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID -- Opération d'annulation
	-- Enlève les unités résiliés après l'opération de frais non commissionnable
	LEFT JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID AND (UR.ReductionDate > O.OperDate) 
	WHERE	O.OperDate <= @RepTreatmentDate -- Exclus les opérations avec frais non commissionnable datant d'après le traitement de commissions
		-- Prend seulement les opérations avec frais non commissionnable positif qui ne sont pas des annulations ou négatif qui sont des 
		-- annulations d'opérations avec frais non commissionnable
		AND(	(	(Ct.Fee > 0) -- Frais positif
				AND OC.OperID IS NULL -- Pas une annulation d'opération
				)
			OR	(	(Ct.Fee < 0) -- Frais négatif
				AND OC.OperID IS NOT NULL -- Une annulation d'opération
				)
			)
	GROUP BY 
		Ct.UnitID,
		Ct.Fee,
		U.UnitQty,
		O.OperID,
		O.OperDate
	-- Exclus les opérations de frais non commissionnable s'il n'y a pas de groupe
	HAVING U.UnitQty + SUM(ISNULL(UR.UnitQty,0)) > 0 
	
	-- Met à jour le montant des frais non commissionble provenant d'opérations antérieures
	UPDATE #tTFRUnit
	SET 
		FeeSumByUnit = FeeSumByUnit + VV.NonCommFeeBefore, -- Montant de frais non commissionné par unités de l'opération, on y ajout le montant de frais non commissionné des opérations antérieures
		NonCommFeeBefore = VV.NonCommFeeBefore -- Montant de frais non commissionné des opérations antérieures
	FROM #tTFRUnit
	JOIN (
		-- Va chercher le montant des frais non commissionble provenant d'opérations antérieures
		SELECT 
			TU1.UnitID, -- ID unique du groupe d'unités
			TU1.OperID, -- ID de l'opération
			NonCommFeeBefore = SUM(TU.FeeSumByUnit) -- Montant de frais non commissionné des opérations antérieures 
		FROM #tTFRUnit TU1
		JOIN #tTFRUnit TU ON TU.UnitID = TU1.UnitID
		WHERE	(TU.OperDate < TU1.OperDate) 
			OR (	TU.OperDate = TU1.OperDate
				AND (TU.OperID < TU1.OperID)
				)
		GROUP BY 
			TU1.UnitID,
			TU1.OperID
		) VV ON VV.UnitID = #tTFRUnit.UnitID AND VV.OperID = #tTFRUnit.OperID

	-- Table temporaire contenant toutes les exceptions pour frais non commissionnable.
	CREATE TABLE #Un_RepException (
		RepID INTEGER, -- ID du représentant
		UnitID INTEGER, -- ID du groupe d'unités
		RepLevelID INTEGER, -- ID du niveau du représentant
		RepExceptionTypeID CHAR(3), -- ID du type d'exception
		RepExceptionAmount MONEY, -- Montant de l'exception
		RepExceptionDate DATETIME) -- Date d'insertion de l'exception

	-- Changement de représentant :
	-- Dans le cas ou on changerait le représentant sur un groupe d'unités (Changement de représentant qui a fait la vente), on renverse
	-- toutes les exceptions de commissions de frais non commissionnable affectés à l'ancien représentant.  Elles seront recréées plus
	-- tard, dans la procédure, pour le nouveau représentant.
	INSERT INTO #Un_RepException (
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount,
			RepExceptionDate)
		SELECT 
			RE.RepID, -- ID du représentant
			RE.UnitID, -- ID du groupe d'unités
			RE.RepLevelID, -- ID du niveau du représentant
			RE.RepExceptionTypeID, -- ID du type d'exception
			RepExceptionAmount = SUM(RE.RepExceptionAmount)*-1, -- Montant de l'exception
			RepExceptionDate = @RepTreatmentDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
		FROM (
			-- Trouve le représentant et le niveau de ce dernier pour chaque groupe d'unités qui ont des frais non commissionnables
			SELECT 
				RE.UnitID, -- ID du groupe d'unités
				RE.RepID, -- ID du représentant
				RL.RepLevelID -- ID du niveau du représentant
			FROM (
				-- Limite la rechercher aux unités qui ont des frais non commissionnables
				SELECT DISTINCT UnitID -- ID du groupe d'unités
				FROM #tTFRUnit
				) TU
			JOIN dbo.Un_Unit U ON U.UnitID = TU.UnitID
			JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (U.InForceDate >= RLH.StartDate) AND (RLH.EndDate IS NULL OR U.InForceDate <= RLH.EndDate)
			JOIN Un_RepLevel RLU ON RLU.RepLevelID = RLH.RepLevelID AND RLU.RepRoleID = 'REP'
			JOIN Un_RepException RE ON RE.UnitID = U.UnitID AND RE.RepExceptionTypeID = 'CTF' AND ((RE.RepID <> U.RepID) OR (RLU.RepLevelID <> RE.RepLevelID))
			JOIN Un_RepLevel RL ON RL.RepLevelID = RE.RepLevelID AND RL.RepRoleID = 'REP'
			GROUP BY
				RE.UnitID,
				RE.RepID,
				RL.RepLevelID
			HAVING SUM(RE.RepExceptionAmount) < 0
			) VV 
		JOIN Un_RepException RE ON RE.UnitID = VV.UnitID AND RE.RepID = VV.RepID AND RE.RepLevelID = VV.RepLevelID AND RE.RepExceptionTypeID = 'CTF'
		GROUP BY
			RE.RepID,
			RE.UnitID,
			RE.RepLevelID,
			RE.RepExceptionTypeID
		HAVING SUM(RE.RepExceptionAmount) < 0 -- Ne génére pas d'exception à 0.00$

	-- Changement de directeur pour commissions :
	-- Dans le cas ou on changerait un supérieur d'un groupe d'unités (Changement de représentant qui a fait la vente ou changement
	-- dans l'historique des supérieurs du représentant qui a fait la vente), on renverse toutes les exceptions de commissions de
	-- frais non commissionnable affectés à le ou les anciens supérieurs.  Elles seront recréées plus tard, dans la procédure, pour le ou
	-- les nouveaux supérieurs.
	INSERT INTO #Un_RepException (
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount,
			RepExceptionDate)
		SELECT
			RE.RepID, -- ID du représentant
			RE.UnitID, -- ID du groupe d'unités
			RE.RepLevelID, -- ID du niveau du représentant
			RE.RepExceptionTypeID, -- ID du type d'exception
			RepExceptionAmount = SUM(RE.RepExceptionAmount)*-1, -- Montant de l'exception
			RepExceptionDate = @RepTreatmentDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
    FROM (
		-- Trouve le ou les supérieurs et leurs niveaux pour chaque groupe d'unités qui ont des frais non commissionnables
		SELECT
			RE.UnitID, -- ID du groupe d'unités
			RE.RepID, -- ID du représentant
			RE.RepLevelID -- ID du niveau du représentant
		FROM (
			-- Limite la rechercher aux unités qui ont des frais non commissionnables
			SELECT DISTINCT UnitID -- ID du groupe d'unités
			FROM #tTFRUnit
			) TU
		JOIN Un_RepException RE ON RE.UnitID = TU.UnitID
		JOIN Un_RepLevel RL ON RL.RepLevelID = RE.RepLevelID AND (RL.RepRoleID <> 'REP') 
		LEFT JOIN (
			SELECT
				U.UnitID, -- ID du groupe d'unités
				RepID = RBH.BossID, -- ID du représentant(supérieur)
				RL.RepLevelID -- ID du niveau du représentant
			FROM (
				-- Limite la rechercher aux unités qui ont des frais non commissionnables
				SELECT DISTINCT UnitID -- ID du groupe d'unités
				FROM #tTFRUnit
				) TU
			JOIN dbo.Un_Unit U ON U.UnitID = TU.UnitID
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
			JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID AND (RL.RepRoleID <> 'REP')
			) B ON B.UnitID = RE.UnitID AND B.RepID = RE.RepID AND B.RepLevelID = RE.RepLevelID 
		WHERE B.UnitID IS NULL 
		GROUP BY
			RE.UnitID,
			RE.RepID,
			RE.RepLevelID
		) VV 
	JOIN Un_RepException RE ON VV.UnitID = RE.UnitID AND RE.RepID = VV.RepID AND RE.RepLevelID = VV.RepLevelID AND RE.RepExceptionTypeID = 'CTF'
	GROUP BY
		RE.RepID,
		RE.UnitID,
		RE.RepLevelID,
		RE.RepExceptionTypeID
	HAVING SUM(RE.RepExceptionAmount) < 0 -- Ne génére pas d'exception à 0.00$

	-- Insère les exception de la table temporaire dans la table permanente.
	INSERT INTO Un_RepException (
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount,
			RepExceptionDate)
		SELECT 
			RepID, -- ID du représentant
			UnitID, -- ID du groupe d'unités
			RepLevelID, -- ID du niveau du représentant
			RepExceptionTypeID, -- ID du type d'exception
			RepExceptionAmount, -- Montant de l'exception
			RepExceptionDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
		FROM #Un_RepException

	-- Vide la table temporaire des exceptions
	DELETE FROM #Un_RepException

	-- Exception de commission pour représentant :
	-- Calcul les exceptions de frais non commissionés qui devrait exister pour les groupes d'unités (Exception du représentant
	-- seulement).  Ensuite il génére des exceptions pour le montant de l'exception qui n'est pas déjà géré par des exceptions
	-- de frais non commissionnés déjà existentes sur le groupe d'unités.
	INSERT INTO #Un_RepException (
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount,
			RepExceptionDate)
		SELECT 
			VV.RepID, -- ID du représentant
			VV.UnitID, -- ID du groupe d'unités
			VV.RepLevelID, -- ID du niveau du représentant
			VV.RepExceptionTypeID, -- ID du type d'exception
			RepExceptionAmount = SUM(VV.RepExceptionAmount-ISNULL(NCB.RepExceptionAmount,0))-ISNULL(VU.RepExceptionAmount,0), -- Montant de l'exception
			VV.RepExceptionDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
		FROM (
			-- Calcul le montant des exceptions (représentants seulement) qui devrait exister pour chaque opération de frais non
			-- commissionnées et les opérations de frais non commissionnés antérieures. On leurs soustrait ensuite le montant des
			-- exceptions qui devrait exister pour les opérations de frais non commissionnées antérieures pour connaître le montant
			-- d'exception affecté à l'opération courante.
			SELECT
				TU.OperID, -- ID de l'opération
				U.RepID, -- ID du représentant
				U.UnitID, -- ID du groupe d'unités
				RH.RepLevelID, -- ID du niveau du représentant
				RepExceptionTypeID = 'CTF', -- ID du type d'exception (Frais sans commission)
				RepExceptionAmount = -- Montant de l'exception
					CASE 
						WHEN (SUM(ISNULL(RL.AdvanceByUnit,0)) > TU.FeeSumByUnit) THEN 
							ROUND(TU.FeeSumByUnit*TU.UnitQty,2)*-1
					ELSE
						ROUND(SUM(ISNULL(RL.AdvanceByUnit,0))*TU.UnitQty,2)*-1
					END,
				RepExceptionDate = @RepTreatmentDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
			FROM #tTFRUnit TU
			JOIN dbo.Un_Unit U ON U.UnitID = TU.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN (
				-- Trouve les niveaux des représentants pour tout les groupes d'unités
				SELECT
					U.UnitID, -- ID du groupe d'unités
					RH.RepLevelID -- ID du niveau du représentant
				FROM dbo.Un_Unit U   
				JOIN Un_RepLevelHist RH ON RH.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID AND RL.RepRoleID = 'REP'
				WHERE		U.InForceDate >= RH.StartDate 
					AND	(	U.InForceDate <= RH.EndDate 
							OR RH.EndDate IS NULL
							)
				) RH ON RH.UnitID = U.UnitID
			LEFT JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID AND (RL.TargetFeeByUnit <= TU.FeeSumByUnit) AND (U.InForceDate >= RL.EffectDate) AND (RL.TerminationDate IS NULL OR U.InForceDate <= RL.TerminationDate)
			GROUP BY
				TU.OperID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				TU.UnitQty,
				TU.FeeSumByUnit,
				TU.OperID
			) VV
		LEFT JOIN (
			-- Calcul le montant des exceptions qui devrait exister pour les opérations de frais non commissionnées antéreures
			SELECT 
				TU.OperID, -- ID de l'opération
				U.RepID, -- ID du représentant
				U.UnitID, -- ID du groupe d'unités
				RH.RepLevelID, -- ID du niveau du représentant
				RepExceptionTypeID = 'CTF', -- ID du type d'exception (Frais sans commissions)
				RepExceptionAmount = -- Montant de l'exception
					CASE 
						WHEN (SUM(RL.AdvanceByUnit) > TU.NonCommFeeBefore) THEN 
							ROUND(TU.NonCommFeeBefore*TU.UnitQty,2)*-1
					ELSE
						ROUND(SUM(RL.AdvanceByUnit)*TU.UnitQty,2)*-1
					END,
				RepExceptionDate = @RepTreatmentDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
			FROM #tTFRUnit TU
			JOIN dbo.Un_Unit U ON U.UnitID = TU.UnitID
            JOIN Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN (
				-- Trouve les différent niveau de représentant pour chaque groupe d'unités
				SELECT
					U.UnitID, -- ID du groupe d'unités
					RH.RepLevelID -- ID du niveau du représentant
				FROM dbo.Un_Unit U   
				JOIN Un_RepLevelHist RH ON RH.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID AND RL.RepRoleID = 'REP'
				WHERE U.InForceDate >= RH.StartDate 
					AND(	U.InForceDate <= RH.EndDate 
						OR RH.EndDate IS NULL
						)
				) RH ON RH.UnitID = U.UnitID
			JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID
			WHERE (TU.NonCommFeeBefore > 0) -- Calcul seulement s'il y a des opérations antérieures avec frais non commissionnés
				AND(RL.TargetFeeByUnit <= TU.NonCommFeeBefore)
				AND(U.InForceDate >= RL.EffectDate) 
				AND(	RL.TerminationDate IS NULL 
					OR U.InForceDate <= RL.TerminationDate
					)
			GROUP BY
				TU.OperID,
				U.RepID,
				U.UnitID,
				RH.RepLevelID,
				TU.UnitQty,
				TU.NonCommFeeBefore,
				TU.OperID
			) NCB ON NCB.UnitID = VV.UnitID AND NCB.OperID = VV.OperID AND NCB.RepID = VV.RepID AND NCB.RepLevelID = VV.RepLevelID AND NCB.RepExceptionTypeID = VV.RepExceptionTypeID
		LEFT JOIN (
			-- Trouve le montant la somme des exceptions de frais non commissionnés déjà existantes par groupe d'unités, représentant,
			-- niveau de représentant.
			SELECT 
				Ex.UnitID, -- ID du groupe d'unités
				Ex.RepID, -- ID du représentant
				Ex.RepLevelID, -- ID du niveau du représentant
				RepExceptionAmount = SUM(Ex.RepExceptionAmount), -- Montant de l'exception
				Ex.RepExceptionTypeID -- ID du type d'exception
			FROM Un_RepException Ex
			WHERE Ex.RepExceptionTypeID = 'CTF'
			GROUP BY
				Ex.UnitID,
				Ex.RepID,
				Ex.RepLevelID,
				Ex.RepExceptionTypeID
			) VU ON VU.UnitID = VV.UnitID AND VU.RepID = VV.RepID AND VV.RepLevelID = VU.RepLevelID AND VU.RepExceptionTypeID = VV.RepExceptionTypeID
		GROUP BY
			VV.RepID,
			VV.UnitID,
			VV.RepLevelID,
			VV.RepExceptionTypeID,
			VV.RepExceptionDate,
			VU.RepExceptionAmount
		HAVING (SUM(VV.RepExceptionAmount-ISNULL(NCB.RepExceptionAmount,0))-ISNULL(VU.RepExceptionAmount,0)) <> 0  -- Ne génére pas d'exception à 0.00$

	-- Exception de commission pour boss  
	INSERT INTO #Un_RepException (
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount,
			RepExceptionDate)
		SELECT 
			VV.RepID, -- ID du représentant
			VV.UnitID, -- ID du groupe d'unités
			VV.RepLevelID, -- ID du niveau du représentant
			VV.RepExceptionTypeID, -- ID du type d'exception
			RepExceptionAmount = SUM(VV.RepExceptionAmount-ISNULL(NCB.RepExceptionAmount,0))-ISNULL(VU.RepExceptionAmount,0), -- Montant de l'exception
			VV.RepExceptionDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
		FROM (
			-- Calcul le montant des exceptions (supérieurs seulement) qui devrait exister pour chaque opération de frais non commissionnées
			-- et les opérations de frais non commissionnés antérieures. On leurs soustrait ensuite le montant des exceptions qui devrait
			-- exister pour les opérations de frais non commissionnées antérieures pour connaître le montant d'exception affecté à
			-- l'opération courante.
			SELECT 
				TU.OperID, -- ID de l'opération
				RH.RepID, -- ID du représentant
				U.UnitID, -- ID du groupe d'unités
				RH.RepLevelID, -- ID du niveau du représentant
				RepExceptionTypeID = 'CTF', -- ID du type d'exception (Frais sans commissions)
				RepExceptionAmount = ROUND((SUM(ISNULL(RL.AdvanceByUnit,0))*TU.UnitQty)*(RH.RepBossPct/100),2)*-1, -- Montant de l'exception
				RepExceptionDate = @RepTreatmentDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
			FROM #tTFRUnit TU
			JOIN dbo.Un_Unit U ON U.UnitID = TU.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN (
				-- Trouve pour chaque groupe d'unités la liste des supérieurs, leurs niveaux et leurs pourcentages de commissions qu'ils ont
				-- droit pour ce rôle
				SELECT
					U.UnitID, -- ID du groupe d'unités
					RepID = RB.BossID, -- ID du représentant (Supérieur)
					RB.RepBossPct, -- Pourcentage de commission pour ce représentant(supérieur) pour ce rôle
					RH.RepLevelID -- ID du niveau du représentant
				FROM dbo.Un_Unit U   
				JOIN Un_RepBossHist RB ON RB.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepRoleID = RB.RepRoleID
				JOIN Un_RepLevelHist RH ON RH.RepID = RB.BossID AND RH.RepLevelID = RL.RepLevelID
				WHERE	(	U.InForceDate >= RH.StartDate 
						AND(	RH.EndDate IS NULL 
							OR U.InForceDate <= RH.EndDate
							)
						)
					AND(	U.InForceDate >= RB.StartDate
						AND(	RB.EndDate IS NULL 
							OR U.InForceDate <= RB.EndDate
							)
						)
				) RH ON RH.UnitID = U.UnitID
			LEFT JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID AND (RL.RepLevelBracketTypeID <> 'ADV') AND (RL.TargetFeeByUnit <= TU.FeeSumByUnit) AND (U.InForceDate >= RL.EffectDate) AND (RL.TerminationDate IS NULL OR U.InForceDate <= RL.TerminationDate)
			GROUP BY
				TU.OperID,
				RH.RepID,
				U.UnitID,
				RH.RepLevelID,
				TU.UnitQty,
				TU.FeeSumByUnit,
				RH.RepBossPct
			) VV
		LEFT JOIN (
			-- Calcul le montant des exceptions qui devrait exister pour les opérations de frais non commissionnées antéreures
			SELECT 
				TU.OperID, -- ID de l'opération
				RH.RepID, -- ID du représentant
				U.UnitID, -- ID du groupe d'unités
				RH.RepLevelID, -- ID du niveau du représentant
				RepExceptionTypeID = 'CTF', -- ID du type d'exception (CTF = Frais sans commission)
				RepExceptionAmount = ROUND((SUM(RL.AdvanceByUnit)*TU.UnitQty)*(RH.RepBossPct/100),2)*-1, -- Montant de l'exception
				RepExceptionDate = @RepTreatmentDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
			FROM #tTFRUnit TU
			JOIN dbo.Un_Unit U ON U.UnitID = TU.UnitID
            JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN (
				-- Trouve pour chaque groupe d'unités la liste des supérieurs, leurs niveaux et leurs pourcentages de commissions qu'ils ont
				-- droit pour ce rôle
				SELECT
					U.UnitID, -- ID du groupe d'unités
					RepID = RB.BossID, -- ID du représentant (Supérieur)
					RB.RepBossPct, -- Pourcentage de commission pour ce représentant (supérieur) pour ce rôle
					RH.RepLevelID -- ID du niveau du représentant
				FROM dbo.Un_Unit U   
				JOIN Un_RepBossHist RB ON RB.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepRoleID = RB.RepRoleID
				JOIN Un_RepLevelHist RH ON RH.RepID = RB.BossID AND RH.RepLevelID = RL.RepLevelID
				WHERE	(	U.InForceDate >= RH.StartDate 
						AND( RH.EndDate IS NULL 
							OR	U.InForceDate <= RH.EndDate
							)
						)
					AND(	U.InForceDate >= RB.StartDate
						AND(	RB.EndDate IS NULL 
							OR U.InForceDate <= RB.EndDate
							)
						)
				) RH ON RH.UnitID = U.UnitID
			JOIN Un_RepLevelBracket RL ON RL.RepLevelID = RH.RepLevelID AND RL.PlanID = C.PlanID AND (RL.RepLevelBracketTypeID <> 'ADV')
			WHERE		(TU.NonCommFeeBefore > 0)
				AND 	(RL.TargetFeeByUnit <= TU.NonCommFeeBefore)
				AND 	(U.InForceDate >= RL.EffectDate) 
				AND 	(	RL.TerminationDate IS NULL 
						OR U.InForceDate <= RL.TerminationDate
						)
	      GROUP BY
				TU.OperID,
				RH.RepID,
				U.UnitID,
				RH.RepLevelID,
				TU.UnitQty,
				TU.NonCommFeeBefore,
				RH.RepBossPct
			) NCB ON NCB.UnitID = VV.UnitID AND NCB.OperID = VV.OperID AND NCB.RepID = VV.RepID AND NCB.RepLevelID = VV.RepLevelID AND NCB.RepExceptionTypeID = VV.RepExceptionTypeID
		LEFT JOIN (
			-- Trouve le montant la somme des exceptions de frais non commissionnés déjà existantes par groupe d'unités, représentant 
			-- (supérieur) et niveau de représentant.
			SELECT 
				Ex.UnitID, -- ID du groupe d'unités
				Ex.RepID, -- ID du représentant
				Ex.RepLevelID, -- ID du niveau du représentant
				RepExceptionAmount = SUM(Ex.RepExceptionAmount), -- Montant de l'exception
				Ex.RepExceptionTypeID -- ID du type d'exception
			FROM Un_RepException Ex
			WHERE Ex.RepExceptionTypeID = 'CTF'
			GROUP BY
				Ex.UnitID,
				Ex.RepID,
				Ex.RepLevelID,
				Ex.RepExceptionTypeID
			) VU ON VU.UnitID = VV.UnitID AND VU.RepID = VV.RepID AND VV.RepLevelID = VU.RepLevelID AND VU.RepExceptionTypeID = VV.RepExceptionTypeID
		GROUP BY
			VV.RepID,
			VV.UnitID,
			VV.RepLevelID,
			VV.RepExceptionTypeID,
			VU.RepExceptionAmount,
			VV.RepExceptionDate
		HAVING SUM(VV.RepExceptionAmount-ISNULL(NCB.RepExceptionAmount,0))-ISNULL(VU.RepExceptionAmount,0) <> 0  -- Ne génére pas d'exception à 0.00$

	-- Insère les exception de la table temporaire dans la table permanente.
	INSERT INTO Un_RepException (
			RepID,
			UnitID,
			RepLevelID,
			RepExceptionTypeID,
			RepExceptionAmount,
			RepExceptionDate)
		SELECT 
			RepID, -- ID du représentant
			UnitID, -- ID du groupe d'unités
			RepLevelID, -- ID du niveau du représentant
			RepExceptionTypeID, -- ID du type d'exception
			RepExceptionAmount, -- Montant de l'exception
			RepExceptionDate -- Date d'insertion de l'exception (Date du traitement de commissions en cours)
		FROM #Un_RepException

	-- Supprime les tables temporaires
	DROP TABLE #Un_RepException
	DROP TABLE #tTFRUnit
	
	IF @@ERROR = 0
		RETURN (1)
	ELSE 
		RETURN (0)
END