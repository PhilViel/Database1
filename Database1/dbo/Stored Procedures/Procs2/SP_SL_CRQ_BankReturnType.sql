/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 : SP_SL_CRQ_BankReturnType
Description         : Retourne la liste des type d'effets retournés 
Valeurs de retours  :
Note                :	ADX0000578	IA	2004-11-26	Bruno Lapointe		Migration
										2014-06-18	Maxime Martel		BankReturnTypeID varchar(3) -> varchar(4)
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_BankReturnType] (
  @BankReturnTypeID VARCHAR(4)) -- Code du type ('ALL'=TOUS)
AS
BEGIN
	SELECT 
		BankReturnTypeID,
		BankReturnTypeDesc
	FROM Mo_BankReturnType
	WHERE @BankReturnTypeID = 'ALL'
		OR @BankReturnTypeID = BankReturnTypeID
	ORDER BY BankReturnTypeID
END
