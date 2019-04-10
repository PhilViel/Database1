/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 			:	FN_UN_RepOfBoss
Description 		:	Retourne tous les représentants sous le représentant passé en paramètre ainsi que lui-même.
Valeurs de retour	:	Table temporaire
Note			:	ADX00001110	IA	2006-09-18	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_RepOfBoss (
	@BossID INTEGER,
	@Today DATETIME) -- ID Unique du représentant
RETURNS @tRep
	TABLE (
		RepID INTEGER PRIMARY KEY)
BEGIN
	IF @BossID > 0 -- Est un représentant, sinon peut voir tout
	BEGIN
		DECLARE 
			@i INTEGER -- Compteur du nombre de dossiers

		-- Recherche de tous les représentants actifs et inactifs qui sont sous la responsabilité du directeur passé en paramètre 
		-- Si un autre directeur est en dessous du directeur, on retourne aussi ses représentants, et ainsi de suite(récursif).   
		INSERT INTO @tRep (RepID)
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
							AND ISNULL(EndDate, @Today + 1) > @Today
							AND RepRoleID IN ('DIR', 'DIS', 'PRO', 'PRS')
						GROUP BY RepID, EndDate, RepRoleID 
					) T ON B.RepID = T.RepID
			WHERE B.BossID = @BossID  -- Selon le directeur passé en paramètre 
				AND ISNULL(B.EndDate, 0) = ISNULL(T.EndDate,0)
				AND B.RepBossPct = T.RepBossPct
				AND B.RepRoleID = B.RepRoleID
		
		-- Vérification si plusieurs dossiers pour le directeur 
		IF (SELECT COUNT(*) FROM @tRep) > 1
		BEGIN --[1]
			SELECT @i = 1
		
			WHILE @i > 0 -- Tant que la requête suivante retourne des nouveaux dossiers différents 
			BEGIN --[2]
				-- Ajoute les représentants des directeurs qui sont sous le directeur reçu en paramètre 
				INSERT INTO @tRep (RepID)
					SELECT DISTINCT B.RepID
					FROM Un_RepBossHist B
					JOIN (-- Si plusieurs directeurs pour un même représentant, on conserve que celui avec le plus haut pourcentage par rôle 
								SELECT 
									B.RepID, 
									B.EndDate,
									RepBossPct = MAX(B.RepBossPct)
								FROM Un_RepBossHist B
								JOIN @tRep R ON B.BossID = R.RepID
			 					WHERE ISNULL(B.EndDate, @Today + 1) > @Today 
									AND B.RepRoleID IN ('DIR', 'DIS', 'PRO', 'PRS')
								GROUP BY 
									B.RepID, 
									B.EndDate, 
									B.RepRoleID 
						) T
						ON B.RepID = T.RepID
					JOIN @tRep R ON B.BossID = R.RepID
					WHERE B.RepID NOT IN (SELECT RepID FROM @tRep) -- les représentants ne doivent pas avoir déjà été retrouvés
						AND ISNULL(B.EndDate, 0) = ISNULL(T.EndDate,0)
						AND B.RepBossPct = T.RepBossPct
						AND B.RepRoleID = B.RepRoleID
		
				SELECT @i = @@ROWCOUNT -- Indique le nombre de nouveaux représentants trouvés pour savoir si on refait une recherche 
			END --[2]
		END --[1]
		
		-- Retourne les représentants et lui-même 
		IF NOT EXISTS (SELECT RepID FROM @tRep WHERE RepID = @BossID)
		INSERT INTO @tRep (RepID)
			SELECT @BossID
	END

	-- Fin des traitements
	RETURN
END

