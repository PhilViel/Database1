CREATE PROCEDURE SMo_IntegerNull
/* Retourne la valeur d'un entier Null Modulex pour éviter le transport de "NULL" */
  (@IntegerNull         MoID OUTPUT)
AS
BEGIN
  SET @IntegerNull = -2147483648;
END;
