
CREATE PROCEDURE SMo_StringNull
  (@StringNull          MoDesc OUTPUT)
AS
BEGIN
  /* Retourne la valeur d'une string Null Modulex pour éviter le transport de "NULL" */
  SET @StringNull = '**NULL**';
END;
