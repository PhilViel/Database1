/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_DL_UN_UnitModalHistory
Description         :	Suppression d'un historique de modalité.  Elle s'assure aussi que la modalité du groupe 
								d'unités est le plus récent de l'historique après la suppression.  Elle empêche la 
								suppression si l'historique est le seul du groupe d'unités.
Valeurs de retours  :	>0  :	Tout à fonctionné
                     	<=0 :	Erreur lors de la suppression
Note                :	ADX0000652	IA	2005-02-03	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_UN_UnitModalHistory] (
	@UnitModalHistoryID MoID ) -- Id unique de l'historique de modalité à supprimer
AS
BEGIN
	DECLARE
		@iResultID MoIDOption

	SET @iResultID = 1

	-----------------
	BEGIN TRANSACTION
	-----------------

	DELETE
	FROM Un_UnitModalHistory
	WHERE UnitModalHistoryID = @UnitModalHistoryID

	IF @@ERROR <> 0
		SET @iResultID = -1 -- Erreur lors de la suppression

	IF @iResultID = 1
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResultID
END

