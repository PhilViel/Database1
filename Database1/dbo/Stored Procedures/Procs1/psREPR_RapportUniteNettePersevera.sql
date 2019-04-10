/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psREPR_RapportUnitéNettePersevera
Nom du service		: Obtenir un rapport d'unité nettes pour la source de vente Persevera
But 				: 
Facette				: REPR

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psREPR_RapportUniteNettePersevera '2012-01-01','2012-05-31'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-11-16		Donald Huppé						Création du service	 GLPI 7595
        2018-05-17      Pierre-Luc Simard                   Ajout des PlanID dans Un_RepLevelBracket

*********************************************************************************************************************/
CREATE procedure [dbo].[psREPR_RapportUniteNettePersevera] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	) 

as
BEGIN

	create table #GrossANDNetUnits (
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

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, 0, 1

	SELECT 
		Remun.repid,
		Directeur = hb.LastName + ' ' + hb.FirstName,
		c.ConventionNo,
		Remun.Niveau,
		RemunUnitaire = TotalLevelCommAmount + TotalLevelAdvanceAmount,
		Reduction = sum(Brut - Retraits + Reinscriptions) * (TotalLevelCommAmount + TotalLevelAdvanceAmount) * 0.5,
		brut = sum(brut),
		net = sum(Brut - Retraits + Reinscriptions),
		Reinscription = sum(Reinscriptions)
	from 
		#GrossANDNetUnits gnu
		JOIN dbo.Un_Unit u2 ON gnu.unitid = u2.UnitID AND u2.SaleSourceID = 235 --UNI-EPP-Éducaide Programme Persevera
		
		JOIN dbo.Un_Convention c ON u2.ConventionID = c.ConventionID
		join (
			SELECT 
				V.UnitID, -- ID du groupe d'unités
				V.RepID, -- ID du représentant
				V.RepLevelID, -- ID du niveau
				V.RepPct, -- Pourcentage de commissions pour ce niveau
				Niveau,
				TotalLevelCommAmount = SUM(V.SumComByUnit), -- Total de commissions de service que devrait toucher ce supérieur (% pas calculé) pour ce niveau par unité de ce groupe d'unités 
				TotalLevelAdvanceAmount = SUM(V.SumAdvByUnit) -- Total des avances que devrait toucher ce supérieur (% pas calculé) pour ce niveau par unité de ce groupe d'unités 
			FROM (
				SELECT DISTINCT
					U.UnitID, -- ID du groupe d'unités
					RepID = RH.BossID, -- ID du supérieur
					RLH.RepLevelID, -- ID du niveau
					VRB.SumComByUnit, -- Montant de la tombés de commissions de service
					VRB.SumAdvByUnit, -- Montant de la tombés d'avance
					RepPct = RH.RepBossPct -- Pourcentage de commissions du supérieur
					,Niveau = RL.LevelDesc
				FROM dbo.Un_Unit U
                JOIN Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN (select DISTINCT g1.unitid from #GrossANDNetUnits g1 JOIN dbo.Un_Unit u1 ON g1.unitid = u1.UnitID WHERE U1.SaleSourceID = 235) g ON g.UnitID = U.UnitID
				JOIN Un_RepBossHist RH ON RH.RepID = U.RepID
				JOIN Un_RepLevelHist RLH ON RLH.RepID = RH.BossID
				JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = RH.RepRoleID AND (RL.RepRoleID <> 'REP')
				JOIN (
					-- Retourne les configurations des tombés dans on format de définition de colonne différent
					SELECT  
						RepLevelID, -- ID du niveau
                        PlanID, -- Plan de la convention
						TargetFeeByUnit, -- Frais par unités à atteindre pour que la tombé soit versée
						EffectDate, -- Date d'Entrée en vigueur de la configuration 
						TerminationDate, -- Date de fin de vigueur de la configuration 
						SumComByUnit = AdvanceByUnit, -- Montant de la tombés de commissions de service
						SumAdvByUnit = 0 -- Montant de la tombés d'avances
					FROM Un_RepLevelBracket 
					WHERE RepLevelBracketTypeID = 'COM' -- Configuration de tombés de commissions de service seulement
					-----
					UNION
					----- 
					SELECT  
						RepLevelID, -- ID du niveau
                        PlanID, -- Plan de la convention
						TargetFeeByUnit, -- Frais par unités à atteindre pour que la tombé soit versée
						EffectDate, -- Date d'Entrée en vigueur de la configuration
						TerminationDate, -- Date de fin de vigueur de la configuration 
						SumComByUnit = 0, -- Montant de la tombés de commissions de service
						SumAdvByUnit = AdvanceByUnit -- Montant de la tombés d'avances
					FROM Un_RepLevelBracket 
					WHERE RepLevelBracketTypeID = 'ADV' -- Configuration de tombés d'avances seulement
					) VRB ON VRB.RepLevelID = RL.RepLevelID AND VRB.PlanID = C.PlanID
				-- Filtre sur le niveau qu'avait le supérieur lors de la vente (Date d'entrée en vigueur du groupe d'unités)
				WHERE ( U.InForceDate > = RLH.StartDate
						AND( U.InForceDate <= RLH.EndDate
							OR RLH.EndDate IS NULL
							)
						)
					-- Filtre sur les supérieurs qu'avait le représentant lors de la vente (Date d'entrée en vigueur du groupe d'unités)
					AND( U.InForceDate > = RH.StartDate
						AND( U.InForceDate <= RH.EndDate
							OR RH.EndDate IS NULL
							)
						)
					-- Filtre les configurations de tombés pour avoir seulement ceux en vigueur pour le groupe d'unités
					AND( U.InForceDate > = VRB.EffectDate
						AND( U.InForceDate <= VRB.TerminationDate
							OR VRB.TerminationDate IS NULL
							)
						)
					--and U.UnitID = 599692
				) V
			GROUP BY
				V.UnitID,
				V.RepID,
				V.RepLevelID,
				V.RepPct
				,Niveau
			) Remun ON Remun.UnitID = u2.UnitID
	JOIN dbo.Mo_Human hb ON Remun.RepID = hb.HumanID
	GROUP by 
		Remun.repid,
		hb.LastName + ' ' + hb.FirstName,
		c.ConventionNo,
		Remun.Niveau,
		TotalLevelCommAmount + TotalLevelAdvanceAmount
	having sum(Brut - Retraits + Reinscriptions) <> 0
END