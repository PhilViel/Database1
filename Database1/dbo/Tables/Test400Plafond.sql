CREATE TABLE [dbo].[Test400Plafond] (
    [CotisationID] INT NOT NULL,
    [iCESP400ID]   INT NOT NULL,
    CONSTRAINT [PK_Test400Plafond] PRIMARY KEY CLUSTERED ([CotisationID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de liaison entre les cotisations et les transactions 400', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Test400Plafond';

