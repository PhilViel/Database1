/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_AccountMoneyType
Description         :	Procédure qui retournera la liste des types d’argent liés à un compte comptable.
Valeurs de retours  :	Dataset :
									iAccountID		INTEGER		ID unique du compte comptable.
									iMoneyTypeID	INTEGER		ID unique du type d’argent.
									vcMoneyType		VARCHAR(75)	Type d’argent (Description)
Note                :	ADX0000739	IA	2005-08-03	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_AccountMoneyType] (
	@iAccountID INTEGER ) -- Identifiant unique du compte comptable.
AS
BEGIN
	SELECT 
		AMT.iAccountID, -- ID unique du compte comptable.
		AMT.iMoneyTypeID, -- ID unique du type d’argent.
		MT.vcMoneyType -- Type d’argent (Description)
	FROM Un_AccountMoneyType AMT
	JOIN Un_MoneyType MT ON MT.iMoneyTypeID = AMT.iMoneyTypeID
	WHERE @iAccountID = AMT.iAccountID
		AND dbo.FN_CRQ_DateNoTime(GETDATE()) BETWEEN AMT.dtStart AND ISNULL(AMT.dtEnd,GETDATE())
	ORDER BY
		MT.vcMoneyType
END

