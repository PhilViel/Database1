CREATE PROCEDURE [dbo].[SMo_Init]
  (@ConnectID   MoID,
   @LangID      MoLang)
AS
BEGIN
  SELECT LangID AS FieldID, 'LANG' AS TableName
  FROM Mo_Lang
  UNION ALL
  SELECT DISTINCT SexID, 'SEX'
  FROM Mo_Sex
  WHERE LangID = @LangID
  UNION ALL
  SELECT DISTINCT CivilStatusID, 'CIVILSTATUS'
  FROM Mo_CivilStatus
  WHERE LangID = @LangID
  UNION ALL
  SELECT CountryID, 'COUNTRY'
  FROM Mo_Country
  UNION ALL
  SELECT DISTINCT CourtesyTitle, 'COURTESYTITLE'
  FROM dbo.Mo_Human 
  WHERE (CourtesyTitle <> '') and (CourtesyTitle IS NOT NULL)
  UNION ALL
  SELECT DISTINCT City, 'CITY'
  FROM dbo.Mo_Adr 
  WHERE (City <> '') and (City IS NOT NULL)
  UNION ALL
  SELECT DISTINCT StateName, 'STATENAME'
  FROM dbo.Mo_Adr 
  WHERE (StateName <> '') and (StateName IS NOT NULL)
END;



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_Init] TO PUBLIC
    AS [dbo];

