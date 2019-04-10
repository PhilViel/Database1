/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	SL_UN_CheckStubWithDetail
Description         :	Sauvegarde la configuration du niveau de détail des talons de chèques.
Valeurs de retours  :	@ReturnValue :
									> 0 : La sauvegarde a réussit.
									<= 0 : La sauvegarde a échoué.
Note                :	ADX0001098	IA	2006-09-08	Bruno Lapointe		Création				
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_CheckStubWithDetail] (
	@ConnectID INTEGER, -- ID de connexion de l’usager
	@vcRefTypes VARCHAR(8000) ) -- Liste des types d’opération séparés par des virgules pour lesquelles le talon des chèques doit être détaillé.
AS 
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = 1
	-----------------
	BEGIN TRANSACTION
	-----------------

	DELETE 
	FROM CHQ_CheckStubWithDetail

	IF @@ERROR <> 0
		SET @iResult = -1
	
	IF @iResult > 0
	BEGIN
		INSERT INTO CHQ_CheckStubWithDetail
			SELECT CAST(val AS VARCHAR(10))
			FROM dbo.fn_Mo_StringTable(@vcRefTypes)

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
END

