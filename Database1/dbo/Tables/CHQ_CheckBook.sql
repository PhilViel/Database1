CREATE TABLE [dbo].[CHQ_CheckBook] (
    [iCheckBookID]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCheckBookDesc] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_CHQ_CheckBook] PRIMARY KEY CLUSTERED ([iCheckBookID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant le descriptif du CheckBook', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckBook';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique du livret de chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckBook', @level2type = N'COLUMN', @level2name = N'iCheckBookID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du livret de chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckBook', @level2type = N'COLUMN', @level2name = N'vcCheckBookDesc';

