CREATE TABLE [dbo].[Un_CESP850] (
    [iCESP850ID]         INT           IDENTITY (1, 1) NOT NULL,
    [iCESPReceiveFileID] INT           NOT NULL,
    [tiCESP850ErrorID]   TINYINT       NOT NULL,
    [vcTransaction]      VARCHAR (495) NOT NULL,
    CONSTRAINT [PK_Un_CESP850] PRIMARY KEY CLUSTERED ([iCESP850ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP850_Un_CESP850Error__tiCESP850ErrorID] FOREIGN KEY ([tiCESP850ErrorID]) REFERENCES [dbo].[Un_CESP850Error] ([tiCESP850ErrorID]),
    CONSTRAINT [FK_Un_CESP850_Un_CESPReceiveFile__iCESPReceiveFileID] FOREIGN KEY ([iCESPReceiveFileID]) REFERENCES [dbo].[Un_CESPReceiveFile] ([iCESPReceiveFileID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP850_iCESPReceiveFileID]
    ON [dbo].[Un_CESP850]([iCESPReceiveFileID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table PCEE dans enregistrement 850 (Erreurs graves)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP850';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 850', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP850', @level2type = N'COLUMN', @level2name = N'iCESP850ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier reçu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP850', @level2type = N'COLUMN', @level2name = N'iCESPReceiveFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type d’erreur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP850', @level2type = N'COLUMN', @level2name = N'tiCESP850ErrorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Transaction en erreur (ligne complète)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP850', @level2type = N'COLUMN', @level2name = N'vcTransaction';

