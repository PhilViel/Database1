/****************************************************************************************************

	PROCEDURE DE RECHERCHE DES REPRÉSENTANTS D'UN DIRECTEUR

*********************************************************************************
	23-02-2004 Dominic Létourneau
		Modifications pour version des représentants
	04-05-2004 Dominic Létourneau
		Migration de l'ancienne stored procedure selon les nouveaux standards
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_RepBossHist] (@BossID MoID) -- Identifiant unique du directeur

AS

BEGIN

	DECLARE @i int, -- Compteur du nombre de dossiers
		@CurrentDate datetime -- Date courante
	
	-- Sauvegarde la date courante
	SELECT @CurrentDate = GETDATE()
	
	-- Recherche de tous les représentants actifs et inactifs qui sont sous la responsabilité du directeur passé en paramètre
	-- Si un autre directeur est en dessous du directeur, on retourne aussi ses représentants, et ainsi de suite(récursif).
	SELECT DISTINCT B.RepID
	INTO #TB_RepBoss -- Résultat sauvegardé dans une table temporaire
	FROM Un_RepBossHist B
	INNER JOIN (-- Si plusieurs directeurs pour un même représentant, on conserve que celui avec le plus haut pourcentage par rôle 
					SELECT 
						RepID, 
						EndDate,
						RepRoleID,
						RepBossPct = MAX(RepBossPct)
					FROM Un_RepBossHist
					WHERE ISNULL(EndDate, @CurrentDate + 1) > @CurrentDate
						AND RepRoleID IN ('DIR', 'DIS', 'PRO', 'PRS')
					GROUP BY RepID, EndDate, RepRoleID 
				) T
		ON B.RepID = T.RepID
			AND ISNULL(B.EndDate, 0) = ISNULL(T.EndDate,0)
			AND B.RepBossPct = T.RepBossPct
			AND B.RepRoleID = B.RepRoleID
	WHERE B.BossID = @BossID  /* Selon le directeur passé en paramètre */
		
	-- Vérification si plusieurs dossiers pour le directeur 
	IF (SELECT COUNT(*) FROM #TB_RepBoss) > 1
	BEGIN 
	
		SELECT @i = 1 -- débute à 1
	
		WHILE @i > 0 -- Tant que la requête suivante retourne des nouveaux dossiers différents 
		BEGIN 
			
			-- Ajoute les représentants des directeurs qui sont sous le directeur reçu en paramètre 
			INSERT #TB_RepBoss (RepID)
			SELECT DISTINCT B.RepID
			FROM Un_RepBossHist B
			INNER JOIN (-- Si plusieurs directeurs pour un même représentant, on conserve que celui avec le plus haut pourcentage par rôle 
							SELECT RepID, 
								EndDate,
								RepBossPct = MAX(RepBossPct)
							FROM Un_RepBossHist
		 					WHERE ISNULL(EndDate, @CurrentDate + 1) > @CurrentDate 
								AND RepRoleID IN ('DIR', 'DIS', 'PRO', 'PRS')
							GROUP BY RepID, EndDate, RepRoleID 
						) T
				ON B.RepID = T.RepID
					AND ISNULL(B.EndDate, 0) = ISNULL(T.EndDate,0)
					AND B.RepBossPct = T.RepBossPct
					AND B.RepRoleID = B.RepRoleID
			INNER JOIN #TB_RepBoss R
				ON B.BossID = R.RepID
			WHERE B.RepID NOT IN (SELECT RepID FROM #TB_RepBoss) -- les représentants ne doivent pas avoir déjà été retrouvés
	
			SELECT @i = @@ROWCOUNT -- Indique le nombre de nouveaux représentants trouvés pour savoir si on refait une recherche 
	
		END -- WHILE @i > 0
	END -- IF (SELECT COUNT(*) FROM #TB_RepBoss) > 1
	
	-- Retourne les représentants et lui-même (retourne toujours au moins un dossier, dans le cas où le représentant n'est pas directeur)
	SELECT RepID
	FROM #TB_RepBoss
	-----
	UNION
	-----
	SELECT @BossID
	
	-- Suppression de la table temporaire
	DROP TABLE #TB_RepBoss
	
	-- FIN DES TRAITEMENTS
	RETURN 0

END


