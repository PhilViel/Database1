/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 : 	SL_UN_BossOfRep
Description         : 	Procedure de recherche des représentants d'un directeur
Valeurs de retours  : 	Dataset de données
Note                :	ADX0000831	IA	2006-05-08	Bruno Lapointe			Création
								ADX0001185	IA	2006-11-22	Bruno Lapointe			Optimisation, normalisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_BossOfRep] (
	@BossID MoID )
AS
BEGIN
	IF @BossID <= 0 -- Pas un représentant, donc peut voir tout
		SELECT 0
	ELSE
	BEGIN
		DECLARE 
			@i INTEGER, -- Compteur du nombre de dossiers
			@CurrentDate DATETIME
		
		-- Sauvegarde la date courante 
		SELECT @CurrentDate = GETDATE()

		CREATE TABLE #tBossOfRep (
			RepID INTEGER PRIMARY KEY )
		
		-- Recherche de tous les représentants actifs et inactifs qui sont sous la responsabilité du directeur passé en paramètre 
		-- Si un autre directeur est en dessous du directeur, on retourne aussi ses représentants, et ainsi de suite(récursif).   
		INSERT INTO #tBossOfRep
			SELECT DISTINCT B.RepID
			FROM Un_RepBossHist B
			JOIN (	-- Si plusieurs directeurs pour un même représentant, on conserve que celui avec le plus haut pourcentage par rôle 
						SELECT 
							RepID, 
							EndDate,
							RepRoleID,
							RepBossPct = MAX(RepBossPct)
						FROM Un_RepBossHist
						WHERE BossID = @BossID
							AND ISNULL(EndDate, @CurrentDate + 1) > @CurrentDate
							AND RepRoleID IN ('DIR', 'DIS', 'PRO', 'PRS')
						GROUP BY RepID, EndDate, RepRoleID 
					) T ON B.RepID = T.RepID
			WHERE B.BossID = @BossID  -- Selon le directeur passé en paramètre 
				AND ISNULL(B.EndDate, 0) = ISNULL(T.EndDate,0)
				AND B.RepBossPct = T.RepBossPct
				AND B.RepRoleID = B.RepRoleID
		
		-- Vérification si plusieurs dossiers pour le directeur 
		IF (SELECT COUNT(*) FROM #tBossOfRep) > 1
		BEGIN --[1]
			SELECT @i = 1
		
			WHILE @i > 0 -- Tant que la requête suivante retourne des nouveaux dossiers différents 
			BEGIN --[2]
				-- Ajoute les représentants des directeurs qui sont sous le directeur reçu en paramètre 
				INSERT #tBossOfRep (RepID)
					SELECT DISTINCT B.RepID
					FROM Un_RepBossHist B
					JOIN (-- Si plusieurs directeurs pour un même représentant, on conserve que celui avec le plus haut pourcentage par rôle 
								SELECT 
									B.RepID, 
									B.EndDate,
									RepBossPct = MAX(B.RepBossPct)
								FROM Un_RepBossHist B
								JOIN #tBossOfRep R ON B.BossID = R.RepID
			 					WHERE ISNULL(B.EndDate, @CurrentDate + 1) > @CurrentDate 
									AND B.RepRoleID IN ('DIR', 'DIS', 'PRO', 'PRS')
								GROUP BY 
									B.RepID, 
									B.EndDate, 
									B.RepRoleID 
						) T
						ON B.RepID = T.RepID
					JOIN #tBossOfRep R ON B.BossID = R.RepID
					WHERE B.RepID NOT IN (SELECT RepID FROM #tBossOfRep) -- les représentants ne doivent pas avoir déjà été retrouvés
						AND ISNULL(B.EndDate, 0) = ISNULL(T.EndDate,0)
						AND B.RepBossPct = T.RepBossPct
						AND B.RepRoleID = B.RepRoleID
		
				SELECT @i = @@ROWCOUNT -- Indique le nombre de nouveaux représentants trouvés pour savoir si on refait une recherche 
			END --[2]
		END --[1]
		
		-- Retourne les représentants et lui-même 
		SELECT RepID
		FROM #tBossOfRep
		-----
		UNION
		-----
		SELECT @BossID
		
		-- Suppression de la table temporaire 
		DROP TABLE #tBossOfRep
	END
END


