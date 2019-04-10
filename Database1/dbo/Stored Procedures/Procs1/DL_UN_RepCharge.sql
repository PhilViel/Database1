/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_RepCharge
Description         :	Procédure de suppression d’ajustement/retenu.
Valeurs de retours  :	@ReturnValue :
									>0 :	La suppression a réussie.  La valeur de retour correspond au RepChargeID de
											l’ajustement/retenu supprimée.
									<=0 :	La suppression a échouée.
Note                :	ADX0000734	IA	2005-07-15	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_RepCharge] (
	@ConnectID INTEGER, -- ID unique de la connexion de l’usager.	
	@RepChargeID INTEGER ) -- ID unique de l’ajustement/retenu. 
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @RepChargeID

	-- Effectue la suppression
	IF @iResult > 0
	BEGIN
		DELETE
		FROM Un_RepCharge
		WHERE RepChargeID = @RepChargeID

		IF @@ERROR <> 0
			SET @iResult = -1
	END

	RETURN @iResult
END

