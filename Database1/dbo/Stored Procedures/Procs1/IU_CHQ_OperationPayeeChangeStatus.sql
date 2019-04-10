/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	IU_CHQ_OperationPayeeChangeStatus
Description         :	Procédure qui changera le statut du ou des changements de destinataires passés en paramètres.
Valeurs de retours  :	@ReturnValue :
									> 0 : L’opération a réussie.
									< 0 : L’opération a échouée.
Note                :	ADX0000714	IA	2005-09-12	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_CHQ_OperationPayeeChangeStatus] (
	@iBlobID INTEGER,	-- ID du blob qui contient les iOperationPayeeID séparés par des virgules des changements de 
							-- destinataires qu’il faut changer à ce statut.
	@iPayeeChangeAccepted INTEGER )	-- Le statut que doit avoir les changements de destinataires passés en paramètre.
AS
BEGIN

	SET NOCOUNT ON

	DECLARE
		@iResult INTEGER

	SET @iResult = 1

	-----------------
	BEGIN TRANSACTION
	-----------------

	UPDATE CHQ_OperationPayee
	SET iPayeeChangeAccepted = @iPayeeChangeAccepted
	FROM CHQ_OperationPayee
	JOIN dbo.FN_CRI_BlobToIntegerTable(@iBlobID) T ON CHQ_OperationPayee.iOperationPayeeID = T.iVal

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		-- Supprime les barrures des changements de destinataires accepté ou refusé.
		DELETE CHQ_OperationLocked
		FROM CHQ_OperationLocked
		JOIN CHQ_OperationPayee P ON P.iOperationID = CHQ_OperationLocked.iOperationID
		JOIN dbo.FN_CRI_BlobToIntegerTable(@iBlobID) T ON P.iOperationPayeeID = T.iVal

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

	RETURN(@iResult)

END
