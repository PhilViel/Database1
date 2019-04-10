CREATE TABLE [dbo].[Mo_DocumentGroup] (
    [DocGroupID]        [dbo].[MoID]          IDENTITY (1, 1) NOT NULL,
    [DocGroupName]      [dbo].[MoCompanyName] NOT NULL,
    [DocGroupClassName] [dbo].[MoCompanyName] NOT NULL,
    [DocGroupDesc]      [dbo].[MoDescoption]  NULL,
    CONSTRAINT [PK_Mo_DocumentGroup] PRIMARY KEY CLUSTERED ([DocGroupID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'UniSQL seulement - Table des documents.  Le module de document permet les fusions automatique de documents.  Cette table contient des groupes de documents.  Cela permet de faire un regroupement de document, permettant de créer un seul menu pour l''impression de plus d''un document.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentGroup';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentGroup', @level2type = N'COLUMN', @level2name = N'DocGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du groupe.  C''est lui qui apparaît dans les menus.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentGroup', @level2type = N'COLUMN', @level2name = N'DocGroupName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Classe de l''objet ou le menu dynamique doit apparaître.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentGroup', @level2type = N'COLUMN', @level2name = N'DocGroupClassName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description du groupe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentGroup', @level2type = N'COLUMN', @level2name = N'DocGroupDesc';

