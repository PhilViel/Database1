CREATE TABLE [dbo].[Mo_DocumentGroupDtl] (
    [DocGroupDtlID] [dbo].[MoID] IDENTITY (1, 1) NOT NULL,
    [DocGroupID]    [dbo].[MoID] NOT NULL,
    [DocID]         [dbo].[MoID] NOT NULL,
    CONSTRAINT [PK_Mo_DocumentGroupDtl] PRIMARY KEY CLUSTERED ([DocGroupDtlID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_DocumentGroupDtl_Mo_Document__DocID] FOREIGN KEY ([DocID]) REFERENCES [dbo].[Mo_Document] ([DocID]),
    CONSTRAINT [FK_Mo_DocumentGroupDtl_Mo_DocumentGroup__DocGroupID] FOREIGN KEY ([DocGroupID]) REFERENCES [dbo].[Mo_DocumentGroup] ([DocGroupID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_DocumentGroupDtl_DocGroupID]
    ON [dbo].[Mo_DocumentGroupDtl]([DocGroupID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_DocumentGroupDtl_DocID]
    ON [dbo].[Mo_DocumentGroupDtl]([DocID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'UniSQL seulement - Table des documents du groupe.  Permet de lier des documents à un groupe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentGroupDtl';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du lien.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentGroupDtl', @level2type = N'COLUMN', @level2name = N'DocGroupDtlID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe (Mo_DocumentGroup).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentGroupDtl', @level2type = N'COLUMN', @level2name = N'DocGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du doucment (Mo_Document).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentGroupDtl', @level2type = N'COLUMN', @level2name = N'DocID';

