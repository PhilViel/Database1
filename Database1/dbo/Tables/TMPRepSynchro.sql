CREATE TABLE [dbo].[TMPRepSynchro] (
    [RepID]                         [dbo].[MoID]              NOT NULL,
    [RepCode]                       [dbo].[MoDescoption]      NULL,
    [RepLicenseNo]                  [dbo].[MoDescoption]      NULL,
    [BusinessStart]                 [dbo].[MoDateoption]      NULL,
    [BusinessEnd]                   [dbo].[MoDateoption]      NULL,
    [iNumeroBDNI]                   INT                       NULL,
    [SexID]                         [dbo].[MoSex]             NOT NULL,
    [LangID]                        [dbo].[MoLang]            NOT NULL,
    [FirstName]                     [dbo].[MoFirstNameoption] NULL,
    [LastName]                      [dbo].[MoLastNameoption]  NULL,
    [BirthDate]                     [dbo].[MoDateoption]      NULL,
    [LoginNameID]                   [dbo].[MoLoginName]       NOT NULL,
    [dRepStatutHistoriqueDateDebut] DATETIME                  NULL,
    [iStatutID]                     INT                       NULL,
    [vcStatut]                      VARCHAR (100)             NOT NULL,
    [iRaisonID]                     INT                       NULL,
    [iEtatID]                       INT                       NULL,
    [ProvinceID]                    INT                       NOT NULL,
    [Tel]                           VARCHAR (37)              NULL,
    [EMail]                         VARCHAR (80)              NULL
);

