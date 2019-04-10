CREATE TABLE [dbo].[Mo_AttributeType] (
    [AttributeTypeID]        [dbo].[MoID]          IDENTITY (1, 1) NOT NULL,
    [AttributeTypeClassName] [dbo].[MoCompanyName] NOT NULL,
    [AttributeTypeDesc]      [dbo].[MoLongDesc]    NOT NULL,
    [AttributeTypeVisible]   [dbo].[MoBitTrue]     NOT NULL,
    [AttributeTypeLinkToAll] [dbo].[MoBitTrue]     NOT NULL,
    [AttributeTypeMultiple]  [dbo].[MoBitTrue]     NOT NULL,
    CONSTRAINT [PK_Mo_AttributeType] PRIMARY KEY CLUSTERED ([AttributeTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_AttributeType_AttributeTypeClassName]
    ON [dbo].[Mo_AttributeType]([AttributeTypeClassName] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des types d''attributs.  Les attributs sont des tables génériques de liste.  Cette tables contient les types de listes (Ex : Métiers, Régions, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type d''attribut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeType', @level2type = N'COLUMN', @level2name = N'AttributeTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'La classe de l''objet auquel appartient ce type d''attribut. (Ex : ''TUNCONVETION''(Convention), ''TUNSUBSCRIBER''(Souscripteur))', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeType', @level2type = N'COLUMN', @level2name = N'AttributeTypeClassName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du type d''attribut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeType', @level2type = N'COLUMN', @level2name = N'AttributeTypeDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si ce type d''attribut est encore disponible à l''ajout d''attribut. (=0:non, <>0:oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeType', @level2type = N'COLUMN', @level2name = N'AttributeTypeVisible';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si ce type d''attribut est obligatoire sur ce type d''objet. (=0:non, <>0:oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeType', @level2type = N'COLUMN', @level2name = N'AttributeTypeLinkToAll';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si on peut donner plus d''un attribut de ce type à un même objet. (=0:non, <>0:oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_AttributeType', @level2type = N'COLUMN', @level2name = N'AttributeTypeMultiple';

