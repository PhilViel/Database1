CREATE TABLE [dbo].[Un_CESP950] (
    [iCESP950ID]         INT      IDENTITY (1, 1) NOT NULL,
    [ConventionID]       INT      NOT NULL,
    [iCESPReceiveFileID] INT      NOT NULL,
    [tiCESP950ReasonID]  TINYINT  NULL,
    [dtCESPReg]          DATETIME NOT NULL,
    CONSTRAINT [PK_Un_CESP950] PRIMARY KEY CLUSTERED ([iCESP950ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP950_Un_CESP950Reason__tiCESP950ReasonID] FOREIGN KEY ([tiCESP950ReasonID]) REFERENCES [dbo].[Un_CESP950Reason] ([tiCESP950ReasonID]),
    CONSTRAINT [FK_Un_CESP950_Un_CESPReceiveFile__iCESPReceiveFileID] FOREIGN KEY ([iCESPReceiveFileID]) REFERENCES [dbo].[Un_CESPReceiveFile] ([iCESPReceiveFileID]),
    CONSTRAINT [FK_Un_CESP950_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP950_ConventionID]
    ON [dbo].[Un_CESP950]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP950_iCESPReceiveFileID]
    ON [dbo].[Un_CESP950]([iCESPReceiveFileID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table PCEE dans enregistrement 950 (Enregistrement de convention)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP950';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 950', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP950', @level2type = N'COLUMN', @level2name = N'iCESP950ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP950', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier reçu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP950', @level2type = N'COLUMN', @level2name = N'iCESPReceiveFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Raison du non enregistrement de la convention (NULL=enregistré)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP950', @level2type = N'COLUMN', @level2name = N'tiCESP950ReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d’enregistrement de la convention au PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP950', @level2type = N'COLUMN', @level2name = N'dtCESPReg';

