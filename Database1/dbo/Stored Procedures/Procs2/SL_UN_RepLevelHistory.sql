/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepLevelHistory
Description         :	Procédure qui renvoi l’historique des niveaux d’un représentant selon l’identifiant de l’historique de niveau et/ou l’identifiant du représentant
Valeurs de retours  :	Dataset :
					RepLevelHistID	INTEGER		Identifiant unique de l’historique de niveau du représentant
					RepID			INTEGER		Identifiant unique du représentant (aussi HumanID)
					StartDate		DATETIME	Date de début de l’historique de niveau
					EndDate			DATETIME	Date de fin de l’historique de niveau
					RepLevelID		INTEGER		Identifiant unique du niveau
					LevelDesc		VARCHAR(75)	Description du niveau
					RepRoleID		CHAR(3)		Identifiant unique du rôle du niveau
					RepRoleDesc		VARCHAR(75)	Description du rôle du niveau
			@ReturnValue :
					> 0 : [Réussite]
					<= 0 : [Échec].

Note                :	ADX0000989	IA	2006-05-19	Alain Quirion		Création								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepLevelHistory] (
@RepLevelHistID INTEGER,		-- 0 = Tous
@RepID  INTEGER)			-- 0 = Tous 	Note : SI @RepLevelHistoryID est !=0, Aucune valeur ne sera renvoyée si @RepID est différent de 0 ou du bon RepID lié à l'historique
AS
BEGIN
	DECLARE 
		@iReturn INTEGER,
		@dtMaxDate DATETIME	--Date maximale nécessaire pour le tri déseendant avec les NULL au début

	SET @iRETURN = 1		--Aucune erreur par défaut

	-- Recherche la date maximale de fin du représentant
	SELECT @dtMaxDate = MAX(EndDate)
	FROM Un_RepLevelHist H
	WHERE (@RepLevelHistID = 0
		OR @RepLevelHistID = H.RepLevelHistID)
		AND (@RepID = 0
		OR @RepID = H.RepID)

	SELECT
		H.RepLevelHistID,
		H.RepID,		
    		StartDate = dbo.fn_Mo_DateNoTime(H.StartDate),
    		EndDate = dbo.fn_Mo_DateNoTime(H.EndDate),
		H.RepLevelID,
		L.LevelDesc,
    		L.RepRoleID,
    		R.RepRoleDesc
  	FROM Un_RepLevelHist H
  	JOIN Un_RepLevel L ON (L.RepLevelID = H.RepLevelID) 
  	JOIN Un_RepRole R ON (R.RepRoleID = L.RepRoleID)
  	WHERE (@RepLevelHistID = 0
		OR @RepLevelHistID = H.RepLevelHistID)
		AND (@RepID = 0
		OR @RepID = H.RepID)
	ORDER BY ISNULL(EndDate, @dtMaxDate+1) DESC

	IF @@ERROR<>0
		SET @iReturn = -1

	RETURN @iReturn
END


