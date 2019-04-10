/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom			: IU_UN_RepBossHistory
Description		: Procédure d’insertion et de mise à jour d’un historique de supérieurs sur représentant selon 
			  l’identifiant de l’historique de supérieur, l’identifiant du représentant, la date de début et la date de fin
Valeurs de retours	: 
			@ReturnValue :
					> 0 : [Réussite], ID de l'historique de supérieur sur représentant
					<= 0 : [Échec].

Note			: ADX0000990	IA	2006-05-19	Alain Quirion			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_RepBossHistory] (
@RepBossHistID INTEGER,
@RepID INTEGER,
@BossID INTEGER, 
@RepRoleID CHAR(3),
@RepBossPct DECIMAL(10,4),
@StartDate DATETIME,
@EndDate DATETIME) 
AS
BEGIN
	IF (@RepBossHistID = 0)
	BEGIN	
		INSERT INTO Un_RepBossHist (
			RepID,
			BossID, 
			RepRoleID,
			RepBossPct,
			StartDate,
			EndDate) 
		VALUES (
			@RepID,
			@BossID, 
			@RepRoleID,
			@RepBossPct,
			@StartDate,
			@EndDate)
	
		IF (@@ERROR = 0)			
			SET @RepBossHistID = SCOPE_IDENTITY()
		ELSE
			SET @RepBossHistID = -1	
	END
	ELSE
		BEGIN	
			UPDATE Un_RepBossHist 
			SET
				RepID = @RepID,
				BossID = @BossID, 
				RepRoleID = @RepRoleID,
				RepBossPct = @RepBossPct,
				StartDate = @StartDate,
				EndDate = @EndDate  
			WHERE (RepBossHistID = @RepBossHistID)
		
		IF (@@ERROR <> 0)
			SET @RepBossHistID = -1		
	END

	RETURN @RepBossHistID
END


