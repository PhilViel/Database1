CREATE TABLE [dbo].[Mo_NoteType] (
    [NoteTypeID]          [dbo].[MoID]          IDENTITY (1, 1) NOT NULL,
    [NoteTypeClassName]   [dbo].[MoCompanyName] NOT NULL,
    [NoteTypeDesc]        [dbo].[MoDesc]        NOT NULL,
    [NoteTypeVisible]     [dbo].[MoBitTrue]     NOT NULL,
    [NoteTypeLinkToAll]   [dbo].[MoBitTrue]     NOT NULL,
    [NoteTypePrivate]     [dbo].[MoBitFalse]    NOT NULL,
    [NoteTypeLogText]     [dbo].[MoBitFalse]    NOT NULL,
    [NoteTypeAllowObject] [dbo].[MoBitFalse]    NULL,
    CONSTRAINT [PK_Mo_NoteType] PRIMARY KEY CLUSTERED ([NoteTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_NoteType_NoteTypeClassName]
    ON [dbo].[Mo_NoteType]([NoteTypeClassName] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des types de notes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_NoteType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type de notes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_NoteType', @level2type = N'COLUMN', @level2name = N'NoteTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Classe de l''objet sur lequel on peut mettre ce type de notes. (Ex: ''TUNCONVENTION'' correspondant aux conventions)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_NoteType', @level2type = N'COLUMN', @level2name = N'NoteTypeClassName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du type de notes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_NoteType', @level2type = N'COLUMN', @level2name = N'NoteTypeDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si le type de note est disponible lors d''ajout de notes (=0:Non, <>0:Oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_NoteType', @level2type = N'COLUMN', @level2name = N'NoteTypeVisible';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si la note est obligatoire pour cet objet. (Ex. fictif: Tout les conventions doivent avoir une note de type Diplôme) (=0:Non, <>0:Oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_NoteType', @level2type = N'COLUMN', @level2name = N'NoteTypeLinkToAll';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Valeur True/False indiquant si le type de note est privé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_NoteType', @level2type = N'COLUMN', @level2name = N'NoteTypePrivate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si la note est de type historique.  Une note de type historique garde toujours le texte qu''on a inscrit, on ne peut qu''ajouter du texte à la suite (=0:Non, <>0:Oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_NoteType', @level2type = N'COLUMN', @level2name = N'NoteTypeLogText';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si l''on peut inscrire autre chose que du texte dans la note (=0:Non, <>0:Oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_NoteType', @level2type = N'COLUMN', @level2name = N'NoteTypeAllowObject';

