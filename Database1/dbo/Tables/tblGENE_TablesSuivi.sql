CREATE TABLE [dbo].[tblGENE_TablesSuivi] (
    [iID_Table_Suivi] INT           IDENTITY (1, 1) NOT NULL,
    [iCode_Table]     INT           NOT NULL,
    [vcDescription]   VARCHAR (200) NOT NULL,
    [tCommentaires]   TEXT          NULL,
    CONSTRAINT [PK_GENE_TablesSuivi] PRIMARY KEY CLUSTERED ([iID_Table_Suivi] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_GENE_TablesSuivi_iCodeTable]
    ON [dbo].[tblGENE_TablesSuivi]([iCode_Table] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant sur le code de la table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TablesSuivi', @level2type = N'INDEX', @level2name = N'AK_GENE_TablesSuivi_iCodeTable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique des tables de suivi.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TablesSuivi', @level2type = N'CONSTRAINT', @level2name = N'PK_GENE_TablesSuivi';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des tables utilisées dans le suivi des modifications.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TablesSuivi';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de la table servant au suivi des modifications.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TablesSuivi', @level2type = N'COLUMN', @level2name = N'iID_Table_Suivi';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code arbitraire et unique de la table qui fait l''objet de la modification d''un enregistrement. Ce code peut être codé en dur dans la programmation. ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TablesSuivi', @level2type = N'COLUMN', @level2name = N'iCode_Table';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la table sur laquelle il y a un suivi des modifications.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TablesSuivi', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires sur le suivi de la table.  Ex.: Suivi depuis quand?', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TablesSuivi', @level2type = N'COLUMN', @level2name = N'tCommentaires';

