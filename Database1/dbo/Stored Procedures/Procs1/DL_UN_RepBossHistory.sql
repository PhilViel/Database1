/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 	:	DL_UN_RepBossHistory
Description         	:	Procédure de suppression d’un historique de supérieurs sur représentant selon l’identifiant de l’historique
Valeurs de retours  	:	
				@ReturnValue :
						> 0 : [Réussite], ID de l'historique supprimé
						<= 0 : [Échec].

Note			: ADX0000990	IA	2006-05-19	Alain Quirion			Création
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_RepBossHistory] (
@RepBossHistID INTEGER)
AS
BEGIN
	DECLARE	@iReturn INTEGER
	
	SET @iReturn = 1	-- Aucune erreur, ID de l'historique par défaut
	
	DELETE 
	FROM Un_RepBossHist
	WHERE RepBossHistID = @RepBossHistID
	
	IF (@@ERROR <> 0)
		SET @iReturn = -1
	
	RETURN @iReturn

END


