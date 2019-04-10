

CREATE FUNCTION [RedGate].[MigrationHistory] ()
RETURNS @Tbl TABLE (PropertyKey VARCHAR(30) UNIQUE, PropertyValue NVARCHAR(MAX))
AS 
BEGIN
    
INSERT  @Tbl  VALUES  ('MigrationHistory' , N'[
  {
    "UpScript": "/*\r\nWrite the migration script to be included in the deployment script.\r\n\r\nMigration scripts are run at the beginning of the deployment. We \r\nrecommend you include guard clauses to make sure the objects you''re \r\nmodifying exist before the rest of the script runs.\r\n\r\nYou can see examples of migration scripts at http://documentation.red-gate.com/display/MV2.\r\n*/\r\nSELECT 1 FROM tblREPR_Formations\r\n\r\n",
    "DownScript": null,
    "Name": "Test migration script",
    "Timestamp": "2013-09-30T13:05:05",
    "Order": 0,
    "Description": "Testing..."
  }
]')
    RETURN
END
