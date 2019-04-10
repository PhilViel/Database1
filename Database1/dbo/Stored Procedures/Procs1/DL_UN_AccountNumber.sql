/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_AccountNumber
Description         :	Procédure de suppression de numéro de compte.
Valeurs de retours  :	@ReturnValue :
									>0 :	La suppression a réussie.  La valeur de retour correspond à l’iAccountNumberID du
											numéro de compte supprimé.
									<=0 :	La suppression a échouée.
										-1 :	« La date d’entrée en vigueur doit être supérieure à la date du jour. ».  
Note                :	ADX0000739	IA	2005-08-03	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_AccountNumber] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@iAccountNumberID INTEGER ) -- ID unique du numéro de compte à supprimer.
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @iAccountNumberID

	IF EXISTS (
		SELECT iAccountNumberID
		FROM Un_AccountNumber
		WHERE iAccountNumberID = @iAccountNumberID
			AND dtStart < dbo.FN_CRQ_DateNoTime(GETDATE())
		)
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		DELETE
		FROM Un_AccountNumber
		WHERE iAccountNumberID = @iAccountNumberID

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	RETURN @iResult
END

