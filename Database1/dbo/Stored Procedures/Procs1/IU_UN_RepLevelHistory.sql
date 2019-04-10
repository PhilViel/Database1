/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom			: IU_UN_RepLevelHistory
Description		: Procédure d’insertion et de mise à jour d’un historique de niveaux d’un représentant selon l’identifiant du niveau, 
			  l’identifiant du représentant, la date de début et la date de fin.
Valeurs de retours	: 
			@ReturnValue :
					> 0 : [Réussite], ID de l'historique de niveau de représentant
					<= 0 : [Échec].

Note			: ADX0000989	IA	2006-05-19	Alain Quirion			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_RepLevelHistory] (
@RepLevelHistID INTEGER,
@RepLevelID INTEGER,
@RepID INTEGER,
@StartDate DATETIME,
@EndDate DATETIME) 
AS
BEGIN
	IF (@RepLevelHistID = 0)
	BEGIN
	
		INSERT INTO Un_RepLevelHist (
			RepID,
			RepLevelID,
			StartDate,
			EndDate)
		VALUES (
			@RepID,
			@RepLevelID,
			@StartDate,
			@EndDate)
		
		IF (@@ERROR = 0)
			SET @RepLevelHistID = SCOPE_IDENTITY()
		ELSE
			SET @RepLevelHistID = -1	
	END
	ELSE
	BEGIN		
		UPDATE Un_RepLevelHist 
		SET
			RepID = @RepID,
			RepLevelID = @RepLevelID,
			StartDate = @StartDate,
			EndDate = @EndDate 
		WHERE RepLevelHistID = @RepLevelHistID;
		
		IF (@@ERROR <> 0)
			SET @RepLevelHistID = -1
	END	
	
	RETURN @RepLevelHistID
END


