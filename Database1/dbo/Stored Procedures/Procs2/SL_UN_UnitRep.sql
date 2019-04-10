/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_UnitRep
Description         :	Procédure retournant la liste des représentants liés à un groupe d’unités avec leurs rôles
								(représentant, directeur, directeur des ventes, etc.).
Valeurs de retours  :	Dataset :
									RepID				INTEGER			ID du représentant affecté par l’exception.
									RepCode			VARCHAR(75)		Code du représentant.
									RepName			VARCHAR(87)		Nom, prénom du représentant.
									RepLevelID		INTEGER			ID du niveau du représentant.
									RepLevelDesc	VARCHAR(150)	Description du niveau (incluant le rôle).
Note                :	ADX0000723	IA	2005-07-13	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_UnitRep] (
	@UnitID INTEGER ) -- ID du groupe d’unités dont on veut la liste des représentants
AS
BEGIN
	-- Représentant
	SELECT
		U.RepID, -- ID du représentant affecté par l’exception.
		R.RepCode, -- Code du représentant.
		RepName = HR.LastName + ', ' + HR.FirstName, -- Nom, prénom du représentant.
		RL.RepLevelID, -- ID du niveau du représentant.
		RepLevelDesc = RR.RepRoleDesc + ' ' + RL.LevelDesc -- Description du niveau (incluant le rôle).
	FROM dbo.Un_Unit U 
	JOIN Un_Rep R ON R.RepID = U.RepID
	JOIN dbo.Mo_Human HR ON HR.HumanID = R.RepID
	JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND RLH.StartDate <= U.InForceDate AND (RLH.EndDate IS NULL OR RLH.EndDate >= U.InForceDate)
	JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = 'REP'
	JOIN Un_RepRole RR ON RR.RepRoleID = RL.RepRoleID
	WHERE U.UnitID = @UnitID
	-----
	UNION
	-----
	-- Supérieurs au représentant
	SELECT
		RepID = RBH.BossID, -- ID du représentant affecté par l’exception.
		BR.RepCode, -- Code du représentant.
		RepName = HR.LastName + ', ' + HR.FirstName, -- Nom, prénom du représentant.
		RL.RepLevelID, -- ID du niveau du représentant.
		RepLevelDesc = RR.RepRoleDesc + ' ' + RL.LevelDesc -- Description du niveau (incluant le rôle).
	FROM dbo.Un_Unit U 
	JOIN Un_Rep R ON R.RepID = U.RepID
	JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND RBH.StartDate <= U.InForceDate AND (RBH.EndDate IS NULL OR RBH.EndDate >= U.InForceDate)
	JOIN Un_Rep BR ON BR.RepID = RBH.BossID
	JOIN dbo.Mo_Human HR ON HR.HumanID = BR.RepID
	JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID
	JOIN Un_RepRole RR ON RR.RepRoleID = RL.RepRoleID
	WHERE U.UnitID = @UnitID
	ORDER BY
		RepName,
		RepLevelDesc
END


