/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepBossCommissionForPeriod 
Description         :	Retourne toutes les groupes d’unités avec le montant d’avance et de commission de service que
								devrait avoir touché les supérieurs du représentant par unité selon les frais cotisés
								antérieurement ou à la date passée en paramètre.
Valeurs de retours  :	Dataset :
									UnitID			INTEGER	ID unique du groupe d’unité.
									RepID				INTEGER	ID unique du représentant qui a fait la vente.
									RepLevelID		INTEGER	ID unique du niveau pour lequel le supérieur touche ces
																	commissions.
									RepBossID		INTEGER	ID unique du supérieur qui devrait avoir touché ces commissions.
									SumComByUnit	MONEY		Commission de service que devrait avoir touché le supérieur par
																	unité à la date saisie.
									SumCadByUnit	MONEY		Avance qui devrait être couverte par unité pour ce supérieur à la
																	date saisie.
									SumAdvByUnit	MONEY		Avance que devrait avoir touché le supérieur par unité à la date
																	saisie.
									TotalFee			MONEY		Frais cotisés pour le groupe d’unités à la date saisie.
Note                :	ADX0000696	IA	2005-08-16	Bruno Lapointe		Création
								ADX0002077	BR	2006-08-31	Bruno Lapointe		Modifier pour qu'elle ne tienne pas compte des 
																				opérations BEC pour déterminer si le premier dépôt a été effectué.
                                                2018-02-16  Pierre-Luc Simard   Exclure aussi les groupes d'unités avec un RIN partiel
                                                2018-05-17  Pierre-Luc Simard   Ajout des PlanID dans Un_RepLevelBracket
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepBossCommissionForPeriod] (
	@RepTreatmentDate DATETIME ) -- Dernier jour inclusivement à traiter.
AS
BEGIN
	-- Table temporaire des représentants, supérieurs, niveaux des supérieurs et pourcentage du supérieur pour ce rôle 
	-- de chaque groupe d'unités
	SELECT
		U.UnitID, -- ID du groupe d'unités
		RB.RepID, -- ID du représentant
		RepBossID = RB.BossID, -- ID du représentant qui est le supérieur
		RB.RepBossPct, -- Pourcentage de commissions du supérieur pour ce rôle
		RH.RepLevelID -- ID du niveau
	INTO #TRepLevel 
	FROM dbo.Un_Unit U   
	JOIN Un_RepBossHist RB ON RB.RepID = U.RepID
	JOIN Un_RepLevel RL ON RL.RepRoleID = RB.RepRoleID
	JOIN Un_RepLevelHist RH ON RH.RepID = RB.BossID AND RH.RepLevelID = RL.RepLevelID
    LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @RepTreatmentDate) RIN ON RIN.UnitID = U.UnitID
	WHERE	( U.InForceDate >= RH.StartDate
			AND( RH.EndDate IS NULL
				OR U.InForceDate <= RH.EndDate
				)
			)
		AND( U.InForceDate >= RB.StartDate
			AND( RB.EndDate IS NULL
				OR U.InForceDate <= RB.EndDate
				)
			)
        AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
	
	SELECT 
		U.UnitID, -- ID du groupe d'unités
		RH.RepID, -- ID du représentant
		RH.RepLevelID, -- ID du niveau du supérieur
		RH.RepBossID, -- ID du supérieur
		RepBossPct = MIN(RH.RepBossPct), -- Pourcentage de commissions du supérieur pour ce rôle
		SumComByUnit = SUM(VRL.SumComByUnit), -- Somme des tombés de commission de service par unités pour ce niveau, ce supérieur et ce groupe d'unités
		SumCadByUnit = SUM(VRL.SumCadByUnit), -- Somme des tombés d'avance couverte par unités pour ce niveau, ce supérieur et ce groupe d'unités
		SumAdvByUnit = SUM(VRL.SumAdvByUnit), -- Somme des tombés d'avance par unités pour ce niveau, ce supérieur et ce groupe d'unités
		TotalFee = MIN(VC.TotalFee) -- Total des frais pour le groupe d'unités
	FROM dbo.Un_Unit U 
    JOIN Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN #TRepLevel RH ON RH.UnitID = U.UnitID
	JOIN (
		-- Trouve le total des frais pour chaque groupe d'unités
		SELECT 
			C.UnitID, -- ID du groupe d'unités
			TotalFee = ROUND(SUM(C.Fee), 2) -- Total des frais pour le groupe d'unités
		FROM Un_Cotisation C 
		JOIN Un_Oper O ON O.OperID = C.OperID
		WHERE O.OperDate <= @RepTreatmentDate -- Exclus les opérations datées ultérieurement à la date du traitement de commissions
			AND O.OperTypeID NOT IN ('BEC', 'RIN') -- Exclus les remboursements intégraux.  Les commissions ne sont pas affectés par les variations de frais du à des remboursements intégraux
		GROUP BY C.UnitID
		) VC ON VC.UnitID = U.UnitID
	JOIN (
		-- Avant UNION, sort la configuration des tombés de commissions de service
		SELECT  
			RepLevelID, -- Niveau du représentant 
            PlanID, -- Plan de la convention
			TargetFeeByUnit, -- Montant de frais par unités à atteindre pour déclancher la tombée
			EffectDate, -- Date d'entrée en vigueur de la configuration de la tombé
			TerminationDate, -- Date de fin de vigueur de la configuration de la tombé 
			SumComByUnit = AdvanceByUnit, -- Montant de la tombée de commissions de service 
			SumCadByUnit = 0, -- Montant de la tombée d'avance couverte
			SumAdvByUnit = 0 -- Montant de la tombée d'avance
		FROM Un_RepLevelBracket 
		WHERE RepLevelBracketTypeID = 'COM'
		-----
		UNION 
		-----
		-- Entre les deux UNION sort la configuration des tombés d'avances couvertes
		SELECT  
			RepLevelID, -- Niveau du représentant 
            PlanID, -- Plan de la convention
			TargetFeeByUnit, -- Montant de frais par unités à atteindre pour déclancher la tombée
			EffectDate, -- Date d'entrée en vigueur de la configuration de la tombé
			TerminationDate, -- Date de fin de vigueur de la configuration de la tombé 
			SumComByUnit = 0, -- Montant de la tombée de commissions de service 
			SumCadByUnit = AdvanceByUnit, -- Montant de la tombée d'avance couverte
			SumAdvByUnit = 0 -- Montant de la tombée d'avance
		FROM Un_RepLevelBracket 
		WHERE RepLevelBracketTypeID = 'CAD'
		-----
		UNION 
		-----
		--	Sort la configuration des tombés d'avances
		SELECT  
			RepLevelID, -- Niveau du représentant 
            PlanID, -- Plan de la convention
			TargetFeeByUnit, -- Montant de frais par unités à atteindre pour déclancher la tombée
			EffectDate, -- Date d'entrée en vigueur de la configuration de la tombé
			TerminationDate, -- Date de fin de vigueur de la configuration de la tombé 
			SumComByUnit = 0, -- Montant de la tombée de commissions de service 
			SumCadByUnit = 0, -- Montant de la tombée d'avance couverte
			SumAdvByUnit = AdvanceByUnit -- Montant de la tombée d'avance
		FROM Un_RepLevelBracket 
		WHERE RepLevelBracketTypeID = 'ADV'
		) VRL ON VRL.RepLevelID = RH.RepLevelID AND VRL.PlanID = C.PlanID
	LEFT JOIN (
		-- Trouve par groupe d'unités, le nombre d'unités résiliés ultérieurement à la date du traitement de commissions
		SELECT 
			UnitID, -- ID du groupe d'unités
			UnitReductQty = SUM(UnitQty) -- Nombre d'unités résilés du groupe d'unités
		FROM Un_UnitReduction
		WHERE ReductionDate > @RepTreatmentDate -- Trouve les réductions d'unités datées ultérieurement au traitement de commissions
		GROUP BY UnitID
		) VU ON VU.UnitID = U.UnitID
    WHERE U.StopRepComConnectID IS NULL -- Pas d'arrêt de paiement de commissions sur groupe d'unités
		AND(	U.UnitQty + ISNULL(VU.UnitReductQty, 0) = 0 -- Plus d'unités dans le groupe d'unités
			OR (VRL.TargetFeeByUnit <= VC.TotalFee / (U.UnitQty + ISNULL(VU.UnitReductQty, 0))) -- Frais atteint pour la tombés
			)
		AND(	U.InForceDate >= VRL.EffectDate -- Filtre sur les configuration en vigueur pour le groupe d'unités
			AND( VRL.TerminationDate IS NULL 
				OR U.InForceDate <= VRL.TerminationDate
				)
			)
		--AND( U.IntReimbDate IS NULL -- Pas de remboursement intégral
		--	OR (U.IntReimbDate > @RepTreatmentDate) -- ou remboursement intégral ultérieure au traitement de commissions 
			--)
	GROUP BY
		U.UnitID,
		RH.RepID,
		RH.RepLevelID,
		RH.RepBossID 
	
	-- Supprime la table temporaire
	DROP TABLE #TRepLevel
	
	IF @@ERROR = 0
		RETURN (1)
	ELSE 
		RETURN (0)
END