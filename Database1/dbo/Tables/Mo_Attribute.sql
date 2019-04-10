CREATE TABLE [dbo].[Mo_Attribute] (
    [AttributeID]     [dbo].[MoID]       IDENTITY (1, 1) NOT NULL,
    [AttributeTypeID] [dbo].[MoID]       NOT NULL,
    [AttributeName]   [dbo].[MoLongDesc] NOT NULL,
    CONSTRAINT [PK_Mo_Attribute] PRIMARY KEY CLUSTERED ([AttributeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Attribute_Mo_AttributeType__AttributeTypeID] FOREIGN KEY ([AttributeTypeID]) REFERENCES [dbo].[Mo_AttributeType] ([AttributeTypeID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Attribute_AttributeTypeID]
    ON [dbo].[Mo_Attribute]([AttributeTypeID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des attributs.  Les attributs sont des tables génériques de liste.  Cette table contient les éléments de la liste (Par exemple pour une type d''attribut ''Métier'' on peut avoir ceci comme attributs : architech, bucheron, informaticien, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Attribute';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''attribut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Attribute', @level2type = N'COLUMN', @level2name = N'AttributeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type d''attribut (Mo_AttributeType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Attribute', @level2type = N'COLUMN', @level2name = N'AttributeTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de l''attribut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Attribute', @level2type = N'COLUMN', @level2name = N'AttributeName';

