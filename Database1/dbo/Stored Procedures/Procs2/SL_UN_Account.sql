/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Account
Description         :	Procédure qui retournera un ou plusieurs comptes comptables.
Valeurs de retours  :	Dataset :
									iAccountID			INTEGER		ID unique du compte comptable.
									vcAccount			VARCHAR(75)	Nom du compte.
									vcAccountNumber 	VARCHAR(75)	Numéro de compte en vigueur actuellement.
Note                :	ADX0000739	IA	2005-08-03	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Account] (
	@iAccountID INTEGER ) -- Identifiant unique du compte comptable, 0 = Tous.
AS
BEGIN
	SELECT 
		A.iAccountID, -- ID unique du compte comptable.
		A.vcAccount, -- Nom du compte.
		AN.vcAccountNumber -- Numéro de compte en vigueur actuellement.
	FROM Un_Account A
	LEFT JOIN (
		SELECT 
			iAccountID,
			dtStart = MAX(dtStart)
		FROM Un_AccountNumber
		GROUP BY iAccountID
		) VAN ON VAN.iAccountID = A.iAccountID
	LEFT JOIN Un_AccountNumber AN ON AN.iAccountID = A.iAccountID AND AN.dtStart = VAN.dtStart
	WHERE @iAccountID = 0
		OR @iAccountID = A.iAccountID
	ORDER BY
		ISNULL(AN.vcAccountNumber,''),
		vcAccount
END

