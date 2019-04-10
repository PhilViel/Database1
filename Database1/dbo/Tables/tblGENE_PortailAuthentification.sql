CREATE TABLE [dbo].[tblGENE_PortailAuthentification] (
    [iUserId]              INT             NOT NULL,
    [vbMotPasse]           VARBINARY (100) NOT NULL,
    [iEtat]                INT             CONSTRAINT [DF_GENE_PortailAuthentification_iEtat] DEFAULT ((0)) NOT NULL,
    [iQS1id]               INT             NOT NULL,
    [iQS2id]               INT             NULL,
    [iQS3id]               INT             NULL,
    [vbRQ1]                VARBINARY (100) NOT NULL,
    [vbRQ2]                VARBINARY (100) NULL,
    [vbRQ3]                VARBINARY (100) NULL,
    [dtDernierAcces]       DATETIME        NULL,
    [iCompteurEssais]      INT             CONSTRAINT [DF_GENE_PortailAuthentification_iCompteurEssais] DEFAULT ((0)) NOT NULL,
    [vbCleConfirmationMD5] VARBINARY (100) CONSTRAINT [DF_GENE_PortailAuthentification_vbCleConfirmationMD5] DEFAULT ((0)) NULL,
    [dtInscription]        DATETIME        CONSTRAINT [DF_GENE_PortailAuthentification_dtInscription] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_GENE_PortailAuthentification] PRIMARY KEY CLUSTERED ([iUserId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_PortailAuthentification_Mo_Human__iUserId] FOREIGN KEY ([iUserId]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[tblGENE_PortailAuthentification] TO [svc-portailmigrationprod]
    AS [dbo];

