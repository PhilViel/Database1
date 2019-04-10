CREATE TABLE [dbo].[Mo_ChequeType] (
    [ChequeTypeID]      [dbo].[MoOptionCode] NOT NULL,
    [ChequeTypeDesc]    [dbo].[MoDesc]       NOT NULL,
    [ChequeTypeVisible] [dbo].[MoBitTrue]    NOT NULL,
    CONSTRAINT [PK_Mo_ChequeType] PRIMARY KEY CLUSTERED ([ChequeTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des types de chèques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères du type de chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeType', @level2type = N'COLUMN', @level2name = N'ChequeTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Le type de chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeType', @level2type = N'COLUMN', @level2name = N'ChequeTypeDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si le type est visible lors de la création manuelle d''un chèque (=0:Non, <>0:Oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeType', @level2type = N'COLUMN', @level2name = N'ChequeTypeVisible';

