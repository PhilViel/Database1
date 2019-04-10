/****************************************************************************************************
  Description : Dit si un fichier dont on veut faire la lecture existe déjà.

  Variables :
   @ConnectID            : Id unique de la connection de l'usager

 ******************************************************************************
  03-11-2003 Bruno      Création #0776
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SMo_BankReturnLink] (
@ConnectID MoID,
@BankReturnCodeID MoDesc)
AS
BEGIN

  SELECT 
    L.BankReturnFileID,
    L.BankReturnCodeID,
    L.BankReturnSourceCodeID,
    L.BankReturnTypeID,
    F.BankReturnFileName,
    F.BankReturnFileDate,
    T.BankReturnTypeDesc
  FROM Mo_BankReturnLink L
  LEFT JOIN Mo_BankReturnFile F ON (F.BankReturnFileID = L.BankReturnFileID)
  JOIN Mo_BankReturnType T ON (T.BankReturnTypeID = L.BankReturnTypeID)
  WHERE BankReturnCodeID = @BankReturnCodeID
 
END;
