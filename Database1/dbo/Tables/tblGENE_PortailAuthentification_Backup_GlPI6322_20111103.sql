CREATE TABLE [dbo].[tblGENE_PortailAuthentification_Backup_GlPI6322_20111103] (
    [iUserId]              INT             NOT NULL,
    [vbMotPasse]           VARBINARY (100) NOT NULL,
    [iEtat]                INT             NOT NULL,
    [iQS1id]               INT             NOT NULL,
    [iQS2id]               INT             NULL,
    [iQS3id]               INT             NULL,
    [vbRQ1]                VARBINARY (100) NOT NULL,
    [vbRQ2]                VARBINARY (100) NULL,
    [vbRQ3]                VARBINARY (100) NULL,
    [dtDernierAcces]       DATETIME        NOT NULL,
    [iCompteurEssais]      INT             NOT NULL,
    [vbCleConfirmationMD5] VARBINARY (100) NULL
);

