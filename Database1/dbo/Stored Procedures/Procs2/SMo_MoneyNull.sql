
CREATE PROCEDURE SMo_MoneyNull
  (@MoneyNull           MoMoney OUTPUT)
AS
BEGIN
  /* Retourne la valeur d'un valeur monétaire Null Modulex pour éviter le transport de "NULL" */
  SET @MoneyNull = -922337203685477.5808;
END;
