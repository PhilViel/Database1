/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_BankType
Description         :	Procédure de suppression d’institution financière.
Valeurs de retours  :	@ReturnValue :
									>0 :	La suppression a réussie.  La valeur de retour correspond au BankTypeID de
											l’institution financière supprimée.
									<=0 :	La suppression a échouée.
										-1 :	« Vous ne pouvez supprimer cette institution financière car une ou plusieurs
												succursales sont utilisées par des comptes bancaires! ».  
										-2 :	« Vous ne pouvez supprimer cette institution financière car une ou plusieurs
												succursales sont utilisées par des prélèvements automatiques! »
 Note                :	ADX0000721	IA	2005-07-08	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_BankType] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@BankTypeID INTEGER ) -- ID de l’institution financière à supprimer.
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @BankTypeID

	IF EXISTS (
		SELECT B.BankID
		FROM Mo_Bank B
		JOIN Un_ConventionAccount CA ON CA.BankID = B.BankID
		WHERE B.BankTypeID = @BankTypeID
		)
		SET @iResult = -1

	IF @iResult > 0
	AND EXISTS (
		SELECT B.BankID
		FROM Mo_Bank B
		JOIN Un_OperAccountInfo OAI ON OAI.BankID = B.BankID
		WHERE B.BankTypeID = @BankTypeID
		)
		SET @iResult = -2

	IF @iResult > 0
	BEGIN
		DELETE
		FROM Mo_Bank
		WHERE BankTypeID = @BankTypeID

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
	BEGIN
		DELETE
		FROM Mo_BankType
		WHERE BankTypeID = @BankTypeID

		IF @@ERROR <> 0
			SET @iResult = -4
	END

	RETURN @iResult
END

