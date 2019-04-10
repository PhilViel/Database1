CREATE PROCEDURE [dbo].[SMo_BankReturnTypeList] (
  @ConnectID MoID )
AS
BEGIN
  SELECT BankReturnTypeID,
         BankReturnTypeDesc,
         BankReturnTypeIDAndDesc = BankReturnTypeID + '-' + BankReturnTypeDesc
  FROM Mo_BankReturnType
  ORDER BY BankReturnTypeID
END
