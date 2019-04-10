CREATE TABLE [dbo].[Un_CESP900Origin] (
    [tiCESP900OriginID] TINYINT       NOT NULL,
    [vcCESP900Origin]   VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_Un_CESP900Origin] PRIMARY KEY CLUSTERED ([tiCESP900OriginID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des origines de transactions 900', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900Origin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l''origine de la transaction 900', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900Origin', @level2type = N'COLUMN', @level2name = N'tiCESP900OriginID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Origine de la transaction 900', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900Origin', @level2type = N'COLUMN', @level2name = N'vcCESP900Origin';

