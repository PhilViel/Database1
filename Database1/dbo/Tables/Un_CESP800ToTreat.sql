CREATE TABLE [dbo].[Un_CESP800ToTreat] (
    [iCESP800ID] INT          NOT NULL,
    [vcNote]     VARCHAR (75) NOT NULL,
    CONSTRAINT [PK_Un_CESP800ToTreat] PRIMARY KEY CLUSTERED ([iCESP800ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP800ToTreat_Un_CESP800__iCESP800ID] FOREIGN KEY ([iCESP800ID]) REFERENCES [dbo].[Un_CESP800] ([iCESP800ID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des enregistrements 800 à traités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800ToTreat';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement 800 à traité', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800ToTreat', @level2type = N'COLUMN', @level2name = N'iCESP800ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Note de l''usager sur ce dossier en correction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800ToTreat', @level2type = N'COLUMN', @level2name = N'vcNote';

