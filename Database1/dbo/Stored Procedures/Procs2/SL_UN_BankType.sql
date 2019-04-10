/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_BankType
Description         :	Procédure retournant une ou toutes les institutions financières.
Valeurs de retours  :	Dataset :
									BankTypeID		INTEGER		ID unique de l'institution financière à sauvegarder, 0 pour ajouter.
									BankTypeCode	VARCHAR(75)	Code de l'institution financière.
									BankTypeName	VARCHAR(75)	Nom de l'institution financière.
Note                :	ADX0000721	IA	2005-07-08	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_BankType] (
	@BankTypeID INTEGER ) -- ID de la région voulue, 0 pour tous.
AS
BEGIN
	SELECT 
		BankTypeID, -- ID unique de l'institution financière à sauvegarder, 0 pour ajouter.
		BankTypeCode, -- Code de l'institution financière.
		BankTypeName -- Nom de l'institution financière.
	FROM Mo_BankType
	WHERE @BankTypeID = 0
		OR @BankTypeID = BankTypeID
	ORDER BY
		BankTypeName,
		BankTypeCode
END

