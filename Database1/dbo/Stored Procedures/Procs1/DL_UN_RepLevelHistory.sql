/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 	:	DL_UN_RepLevelHistory
Description         	:	Procédure de suppression d’un historique de niveau de représentant selon l’identifiant de l’historique
Valeurs de retours  	:	
				@ReturnValue :
						> 0 : [Réussite], ID de l'historique supprimé
						<= 0 : [Échec].

Note			: ADX0000989	IA	2006-05-19	Alain Quirion			Création
****************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_RepLevelHistory] (
@RepLevelHistID INTEGER)
AS
BEGIN
	DECLARE	@iReturn INTEGER

	SET @iReturn = @RepLevelHistID	-- Aucune erreur, ID de l'historique par défaut

	DELETE 
	FROM Un_RepLevelHist
	WHERE RepLevelHistID = @RepLevelHistID

	IF (@@ERROR <> 0)
		SET @iReturn = -1
	
	RETURN @iReturn

END


