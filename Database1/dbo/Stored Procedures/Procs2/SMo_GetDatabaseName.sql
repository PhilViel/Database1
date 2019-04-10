CREATE PROCEDURE SMo_GetDatabaseName
AS
BEGIN
  SELECT DISTINCT Table_Catalog AS DatabaseName
  FROM Information_Schema.Tables
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_GetDatabaseName] TO PUBLIC
    AS [dbo];

