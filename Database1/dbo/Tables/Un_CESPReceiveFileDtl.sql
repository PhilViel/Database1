CREATE TABLE [dbo].[Un_CESPReceiveFileDtl] (
    [iCESPReceiveFileDtlID] INT           IDENTITY (1, 1) NOT NULL,
    [iCESPReceiveFileID]    INT           NOT NULL,
    [vcCESPReceiveFileName] VARCHAR (100) NULL,
    CONSTRAINT [PK_Un_CESPReceiveFileDtl] PRIMARY KEY CLUSTERED ([iCESPReceiveFileDtlID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESPReceiveFileDtl_Un_CESPReceiveFile__iCESPReceiveFileID] FOREIGN KEY ([iCESPReceiveFileID]) REFERENCES [dbo].[Un_CESPReceiveFile] ([iCESPReceiveFileID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESPReceiveFileDtl_iCESPReceiveFileID]
    ON [dbo].[Un_CESPReceiveFileDtl]([iCESPReceiveFileID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de détails des fichiers PCEE reçus (Nom physique des différents fichier)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFileDtl';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du détail du fichier reçu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFileDtl', @level2type = N'COLUMN', @level2name = N'iCESPReceiveFileDtlID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier reçu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFileDtl', @level2type = N'COLUMN', @level2name = N'iCESPReceiveFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du fichier physique reçu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFileDtl', @level2type = N'COLUMN', @level2name = N'vcCESPReceiveFileName';

