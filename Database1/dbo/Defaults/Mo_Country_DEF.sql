CREATE DEFAULT [dbo].[Mo_Country_DEF]
    AS 'CAN';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Country_DEF]', @objname = N'[dbo].[Mo_State].[CountryID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Country_DEF]', @objname = N'[dbo].[Mo_Def].[DefaultCountryID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Country_DEF]', @objname = N'[dbo].[Mo_Human].[ResidID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Country_DEF]', @objname = N'[dbo].[Mo_Adr_Old].[CountryID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Country_DEF]', @objname = N'[dbo].[Mo_City].[CountryID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Country_DEF]', @objname = N'[dbo].[Mo_Cheque].[CountryID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Country_DEF]', @objname = N'[dbo].[Mo_Country].[CountryID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Country_DEF]', @objname = N'[dbo].[Mo_Document].[DocSubjectVisibility]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Country_DEF]', @objname = N'[dbo].[MoCountry]';

