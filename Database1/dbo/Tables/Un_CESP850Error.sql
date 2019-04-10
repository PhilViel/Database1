CREATE TABLE [dbo].[Un_CESP850Error] (
    [tiCESP850ErrorID] TINYINT       NOT NULL,
    [vcCESP850Error]   VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Un_CESP850Error] PRIMARY KEY CLUSTERED ([tiCESP850ErrorID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des type d''erreurs graves (850)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP850Error';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du type d''erreur grave', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP850Error', @level2type = N'COLUMN', @level2name = N'tiCESP850ErrorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type d''erreur grave', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP850Error', @level2type = N'COLUMN', @level2name = N'vcCESP850Error';

