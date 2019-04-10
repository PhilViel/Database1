CREATE TABLE [dbo].[TypeDocument] (
    [Code]         VARCHAR (25)  NOT NULL,
    [Description]  VARCHAR (250) NOT NULL,
    [TypeObjetLie] INT           NULL,
    CONSTRAINT [PK_TypeDocument] PRIMARY KEY CLUSTERED ([Code] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''objet relié à l''impression de ce type de document. (0=Convention, 1=Groupe d''unités, 2=Humain, 3=Demande) ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TypeDocument', @level2type = N'COLUMN', @level2name = N'TypeObjetLie';

