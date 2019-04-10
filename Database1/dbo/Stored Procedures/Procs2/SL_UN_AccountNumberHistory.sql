/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_AccountNumberHistory
Description         :	Procédure qui retournera un ou plusieurs comptes comptables.
Valeurs de retours  :	Dataset :
									iAccountNumberID	INTEGER		ID unique du numéro de compte.
									iAccountID			INTEGER		ID unique du compte comptable.
									dtEffective			DATETIME		Date d’entrée en vigueur du numéro de compte.
									vcAccountNumber 	VARCHAR(75)	Numéro de compte.
Note                :	ADX0000739	IA	2005-08-03	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_AccountNumberHistory] (
	@iAccountID INTEGER ) -- Identifiant unique du compte comptable.
AS
BEGIN
	SELECT 
		iAccountNumberID, -- ID unique du numéro de compte.
		iAccountID, -- ID unique du compte comptable.
		dtStart, -- Date d’entrée en vigueur du numéro de compte.
		dtEnd, -- Date de fin de vigueur du numéro de compte.
		vcAccountNumber -- Numéro de compte.
	FROM Un_AccountNumber
	WHERE @iAccountID = iAccountID
	ORDER BY
		iAccountID,
		dtStart
END

