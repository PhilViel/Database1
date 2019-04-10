CREATE TABLE [dbo].[Un_CESPSendFile] (
    [iCESPSendFileID]    INT          IDENTITY (1, 1) NOT NULL,
    [iCESPReceiveFileID] INT          NULL,
    [dtCESPSendFile]     DATETIME     NOT NULL,
    [vcCESPSendFile]     VARCHAR (75) NOT NULL,
    CONSTRAINT [PK_Un_CESPSendFile] PRIMARY KEY CLUSTERED ([iCESPSendFileID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESPSendFile_Un_CESPReceiveFile__iCESPReceiveFileID] FOREIGN KEY ([iCESPReceiveFileID]) REFERENCES [dbo].[Un_CESPReceiveFile] ([iCESPReceiveFileID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESPSendFile_iCESPReceiveFileID]
    ON [dbo].[Un_CESPSendFile]([iCESPReceiveFileID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des fichiers PCEE envoyés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPSendFile';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier d’envoi', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPSendFile', @level2type = N'COLUMN', @level2name = N'iCESPSendFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier reçu correspondant', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPSendFile', @level2type = N'COLUMN', @level2name = N'iCESPReceiveFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d’envoi du fichier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPSendFile', @level2type = N'COLUMN', @level2name = N'dtCESPSendFile';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du fichier envoyé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPSendFile', @level2type = N'COLUMN', @level2name = N'vcCESPSendFile';

