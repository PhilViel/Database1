/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepBossHistory
Description         :	Procédure qui renvoi l’historique des niveaux d’un représentant selon l’identifiant de l’historique de niveau et/ou l’identifiant du représentant
Valeurs de retours  :	Dataset :
					RepBossHistID	INTEGER		Identifiant unique de l’historique de supérieur du représentant
					RepID		INTEGER		Identifiant unique du représentant (aussi HumanID)
					StartDate	DATETIME	Date de début de l’historique de niveau
					EndDate		DATETIME	Date de fin de l’historique de niveau
					RepRoleID	CHAR(3)		Identifiant unique du rôle du niveau
					RepRoleDesc	VARCHAR(75)	Description du rôle du niveau
					RepBossPct	FLOAT		Pourcentage des commissions du rôle que touchait ce supérieur
					BossName	VARCHAR(75)	Nom du supérieur (Nom, Prénom)
			@ReturnValue :
					> 0 : [Réussite]
					<= 0 : [Échec].

Note                :	ADX0000990	IA	2006-05-19	Alain Quirion		Création								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepBossHistory] (
@RepBossHistID INTEGER,		-- 0 = Tous
@RepID INTEGER)			-- 0 = Tous
AS
BEGIN
	DECLARE 
		@iReturn INTEGER,
		@dtMaxDate DATETIME		--Date Maximale nécessaire au tri dessendant

	SET @iReturn = 1			-- Aucune erreur par défaut

	SELECT @dtMaxDate = MAX(EndDate)
	FROM Un_RepBossHist
	WHERE (@RepBossHistID = 0
		OR @RepBossHistID = RepBossHistID)
		AND (@RepID = 0
		OR @RepID = RepID)

	SELECT 
		B.RepBossHistID,
		B.RepID,
		B.BossID,
		StartDate = dbo.fn_Mo_DateNoTime(B.StartDate),
		EndDate = dbo.fn_Mo_DateNoTime(B.EndDate),
		B.RepRoleID,	
		R.RepRoleDesc,
		RepBossPct = ISNULL(B.RepBossPct, 0),
		BossName = H.LastName + ', ' + H.FirstName
	FROM Un_RepBossHist B 
	JOIN Un_RepRole R ON (R.RepRoleID = B.RepRoleID)
	JOIN dbo.Mo_Human H ON (H.HumanID = B.BossID)
	WHERE (@RepBossHistID = 0
		OR @RepBossHistID = B.RepBossHistID)
		AND (@RepID = 0
		OR @RepID = B.RepID)
	ORDER BY ISNULL(EndDate, @dtMaxDate+1) DESC, R.RepRoleDesc, ISNULL(B.RepBossPct, 0)

	IF @@ERROR<>0
		SET @iReturn = -1

	RETURN @iReturn
END


