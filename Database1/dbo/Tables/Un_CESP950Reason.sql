CREATE TABLE [dbo].[Un_CESP950Reason] (
    [tiCESP950ReasonID] TINYINT       NOT NULL,
    [vcCESP950Reason]   VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Un_CESP950Reason] PRIMARY KEY CLUSTERED ([tiCESP950ReasonID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des raison de non enregistrement de conventions (950) au PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP950Reason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la raison de non enregistrement de la convention (950) au PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP950Reason', @level2type = N'COLUMN', @level2name = N'tiCESP950ReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Raison de non enregistrement de la convention (950) au PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP950Reason', @level2type = N'COLUMN', @level2name = N'vcCESP950Reason';

