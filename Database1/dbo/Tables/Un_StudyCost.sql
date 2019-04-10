CREATE TABLE [dbo].[Un_StudyCost] (
    [YearQualif]  [dbo].[MoID]    NOT NULL,
    [StudyCost]   [dbo].[MoMoney] NOT NULL,
    [StudyCostCA] [dbo].[MoMoney] NULL,
    CONSTRAINT [PK_Un_StudyCost] PRIMARY KEY CLUSTERED ([YearQualif] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des coûts des études.  C''est une donnée affichée dans les relevés de dépôts.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_StudyCost';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Année de qualification à laquel s''applique cette estimation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_StudyCost', @level2type = N'COLUMN', @level2name = N'YearQualif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Coûts estimés des études.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_StudyCost', @level2type = N'COLUMN', @level2name = N'StudyCost';

