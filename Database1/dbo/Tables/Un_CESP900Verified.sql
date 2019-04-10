CREATE TABLE [dbo].[Un_CESP900Verified] (
    [iCESP900ID]         INT      NOT NULL,
    [iVerifiedConnectID] INT      NOT NULL,
    [dtVerified]         DATETIME NOT NULL,
    [bCESP400Resend]     BIT      NOT NULL,
    CONSTRAINT [PK_Un_CESP900Verified] PRIMARY KEY CLUSTERED ([iCESP900ID] ASC, [iVerifiedConnectID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP900Verified_Un_CESP900__iCESP900ID] FOREIGN KEY ([iCESP900ID]) REFERENCES [dbo].[Un_CESP900] ([iCESP900ID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des enregistrements 900 vérifiés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900Verified';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement 900 véréfié', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900Verified', @level2type = N'COLUMN', @level2name = N'iCESP900ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager qui a fait la vérification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900Verified', @level2type = N'COLUMN', @level2name = N'iVerifiedConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la vérification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900Verified', @level2type = N'COLUMN', @level2name = N'dtVerified';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si un enregistrement 400 a été renvoyé suite à la vérification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900Verified', @level2type = N'COLUMN', @level2name = N'bCESP400Resend';

