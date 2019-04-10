CREATE TABLE [dbo].[Un_CESP800Corrected] (
    [iCESP800ID]          INT      NOT NULL,
    [iCorrectedConnectID] INT      NOT NULL,
    [dtCorrected]         DATETIME NOT NULL,
    [bCESP400Resend]      BIT      NOT NULL,
    CONSTRAINT [PK_Un_CESP800Corrected] PRIMARY KEY CLUSTERED ([iCESP800ID] ASC, [iCorrectedConnectID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP800Corrected_Un_CESP800__iCESP800ID] FOREIGN KEY ([iCESP800ID]) REFERENCES [dbo].[Un_CESP800] ([iCESP800ID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des enregistrements 800 corrigés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800Corrected';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement 800 corrigé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800Corrected', @level2type = N'COLUMN', @level2name = N'iCESP800ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager qui a fait la correction', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800Corrected', @level2type = N'COLUMN', @level2name = N'iCorrectedConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la correction', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800Corrected', @level2type = N'COLUMN', @level2name = N'dtCorrected';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si un enregistrement 400 a été renvoyé suite à la correction', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800Corrected', @level2type = N'COLUMN', @level2name = N'bCESP400Resend';

