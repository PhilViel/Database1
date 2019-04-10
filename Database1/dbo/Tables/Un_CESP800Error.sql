CREATE TABLE [dbo].[Un_CESP800Error] (
    [siCESP800ErrorID] SMALLINT      NOT NULL,
    [vcCESP800Error]   VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Un_CESP800Error] PRIMARY KEY CLUSTERED ([siCESP800ErrorID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des codes d''erreurs des enregistrements 800', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800Error';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code d’erreur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800Error', @level2type = N'COLUMN', @level2name = N'siCESP800ErrorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Erreur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800Error', @level2type = N'COLUMN', @level2name = N'vcCESP800Error';

