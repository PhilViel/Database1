CREATE TABLE [dbo].[Un_CESP100] (
    [iCESP100ID]        INT          IDENTITY (1, 1) NOT NULL,
    [iCESPSendFileID]   INT          NULL,
    [ConventionID]      INT          NOT NULL,
    [iCESP800ID]        INT          NULL,
    [vcTransID]         VARCHAR (15) NOT NULL,
    [dtTransaction]     DATETIME     NOT NULL,
    [iPlanGovRegNumber] INT          NOT NULL,
    [ConventionNo]      VARCHAR (15) NOT NULL,
    CONSTRAINT [PK_Un_CESP100] PRIMARY KEY CLUSTERED ([iCESP100ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP100_Un_CESP800__iCESP800ID] FOREIGN KEY ([iCESP800ID]) REFERENCES [dbo].[Un_CESP800] ([iCESP800ID]),
    CONSTRAINT [FK_Un_CESP100_Un_CESPSendFile__iCESPSendFileID] FOREIGN KEY ([iCESPSendFileID]) REFERENCES [dbo].[Un_CESPSendFile] ([iCESPSendFileID]),
    CONSTRAINT [FK_Un_CESP100_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP100_iCESPSendFileID]
    ON [dbo].[Un_CESP100]([iCESPSendFileID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP100_ConventionID]
    ON [dbo].[Un_CESP100]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP100_iCESP800ID]
    ON [dbo].[Un_CESP100]([iCESP800ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP100_vcTransID]
    ON [dbo].[Un_CESP100]([vcTransID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table PCEE dans enregistrement 100 (Convention)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP100';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 100', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP100', @level2type = N'COLUMN', @level2name = N'iCESP100ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier d’envoi', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP100', @level2type = N'COLUMN', @level2name = N'iCESPSendFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP100', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 800 d’erreur s’il y en a un', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP100', @level2type = N'COLUMN', @level2name = N'iCESP800ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de transaction unique expédié à la SCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP100', @level2type = N'COLUMN', @level2name = N'vcTransID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la transaction', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP100', @level2type = N'COLUMN', @level2name = N'dtTransaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d’enregistrement du régime au gouvernement (ARC)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP100', @level2type = N'COLUMN', @level2name = N'iPlanGovRegNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP100', @level2type = N'COLUMN', @level2name = N'ConventionNo';

