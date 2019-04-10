/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_Bank
Description         :	Procédure de suppression de succursale d’institution financière.
Valeurs de retours  :	@ReturnValue :
									>0 :	La suppression a réussie.  La valeur de retour correspond au BankID de la succursale
											supprimée.
									<=0 :	La suppression a échouée.
										-1 :	« Vous ne pouvez supprimer cette succursale car elle est utilisée par des comptes
												bancaires! ».  
										-2 :	« Vous ne pouvez supprimer cette succursale car elle est utilisée par des
												prélèvements automatiques! »
Note                :	ADX0000721	IA	2005-07-08	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Bank] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@BankID INTEGER ) -- ID de la succursale d’institution financière à supprimer.
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @BankID

	IF EXISTS (
		SELECT B.BankID
		FROM Mo_Bank B
		JOIN Un_ConventionAccount CA ON CA.BankID = B.BankID
		WHERE B.BankID = @BankID
		)
		SET @iResult = -1

	IF @iResult > 0
	AND EXISTS (
		SELECT B.BankID
		FROM Mo_Bank B
		JOIN Un_OperAccountInfo OAI ON OAI.BankID = B.BankID
		WHERE B.BankID = @BankID
		)
		SET @iResult = -2

	IF @iResult > 0
	BEGIN
		DELETE
		FROM Mo_Bank
		WHERE BankID = @BankID

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	RETURN @iResult
END

