CREATE TABLE [dbo].[Un_CESP700] (
    [iCESP700ID]        INT          IDENTITY (1, 1) NOT NULL,
    [iCESPSendFileID]   INT          NOT NULL,
    [ConventionID]      INT          NOT NULL,
    [iPlanGovRegNumber] INT          NOT NULL,
    [ConventionNo]      VARCHAR (15) NOT NULL,
    [fMarketValue]      MONEY        NOT NULL,
    CONSTRAINT [PK_Un_CESP700] PRIMARY KEY CLUSTERED ([iCESP700ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP700_Un_CESPSendFile__iCESPSendFileID] FOREIGN KEY ([iCESPSendFileID]) REFERENCES [dbo].[Un_CESPSendFile] ([iCESPSendFileID]),
    CONSTRAINT [FK_Un_CESP700_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP700_iCESPSendFileID]
    ON [dbo].[Un_CESP700]([iCESPSendFileID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP700_ConventionID]
    ON [dbo].[Un_CESP700]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table PCEE dans enregistrement 700 (Valeur marchande des conventions)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP700';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 700', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP700', @level2type = N'COLUMN', @level2name = N'iCESP700ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier d’envoi', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP700', @level2type = N'COLUMN', @level2name = N'iCESPSendFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP700', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d’enregistrement du régime au gouvernement (ARC)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP700', @level2type = N'COLUMN', @level2name = N'iPlanGovRegNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP700', @level2type = N'COLUMN', @level2name = N'ConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Valeur marchande de la convention au dernier jour du mois.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP700', @level2type = N'COLUMN', @level2name = N'fMarketValue';

