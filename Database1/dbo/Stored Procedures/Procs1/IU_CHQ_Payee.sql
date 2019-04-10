/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	IU_CHQ_Payee
Description         :	Procédure de sauvegarde d'ajout et modification de destinataire.
Valeurs de retours  :	@ReturnValue :
									> 0 : La sauvegarde a réussie.
									< 0 : La sauvegarde a échouée.
Note                :	ADX0000753	IA	2005-10-05	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_CHQ_Payee] (
	@iConnectID INTEGER, -- ID de connexion de l'usager
	@iPayeeID INTEGER ) -- ID du destinataire
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @iPayeeID

	IF NOT EXISTS (
		SELECT iPayeeID
		FROM CHQ_Payee
		WHERE iPayeeID = @iPayeeID )
	AND ISNULL(@iPayeeID,0) > 0
	BEGIN
		INSERT INTO CHQ_Payee ( iPayeeID )
		VALUES ( @iPayeeID )

		IF @@ERROR <> 0
			SET @iResult = -1
	END

	RETURN(@iResult)
END
