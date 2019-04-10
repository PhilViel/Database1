
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_Modal_DL
Description         :	Suppression d'une modalité de dépôt
Valeurs de retours  :	@ReturnValue :
								> 0 : Réussite
								<= 0 : Échec

Note                :			ADX0001317	IA	2007-05-01	Alain Quirion	Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_Modal (	
	@ModalID INTEGER) -- ID de la modalité de dépôt
AS
BEGIN
	DECLARE @iResult INT

	SET @iResult = 1

	DELETE 
	FROM Un_UnitModalHistory
	WHERE ModalID = @ModalID

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		DELETE 
		FROM Un_Modal
		WHERE ModalID = @ModalID
	
		IF @@ERROR <> 0
			SET @iResult = -2
	END
	
	RETURN @iResult
END

