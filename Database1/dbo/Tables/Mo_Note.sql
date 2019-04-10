CREATE TABLE [dbo].[Mo_Note] (
    [NoteID]     [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [ConnectID]  [dbo].[MoID]         NOT NULL,
    [NoteTypeID] [dbo].[MoID]         NOT NULL,
    [NoteCodeID] [dbo].[MoID]         NOT NULL,
    [NoteText]   [dbo].[MoTextoption] NULL,
    CONSTRAINT [PK_Mo_Note] PRIMARY KEY CLUSTERED ([NoteID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Note_Mo_Connect__ConnectID] FOREIGN KEY ([ConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID]),
    CONSTRAINT [FK_Mo_Note_Mo_NoteType__NoteTypeID] FOREIGN KEY ([NoteTypeID]) REFERENCES [dbo].[Mo_NoteType] ([NoteTypeID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Mo_Note_NoteTypeID_NoteCodeID]
    ON [dbo].[Mo_Note]([NoteTypeID] ASC, [NoteCodeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Note_NoteTypeID]
    ON [dbo].[Mo_Note]([NoteTypeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Note_NoteCodeID]
    ON [dbo].[Mo_Note]([NoteCodeID] ASC) WITH (FILLFACTOR = 90);


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_Note] TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON [dbo].[Mo_Note] ([NoteText]) TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des notes.  Les notes sont des memos qu''on peut laisser sur des objets (Convention, souscripteur, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Note';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la note.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Note', @level2type = N'COLUMN', @level2name = N'NoteID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect) de l''usager qui a créé la note.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Note', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type de notes (Mo_NoteType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Note', @level2type = N'COLUMN', @level2name = N'NoteTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''objet sur lequel la note est.  Combiné avec le champ Mo_NoteType.NoteTypeClassName permet de connaître cette objet.  Le champ Mo_NoteType.NoteTypeClassName nous donne le type d''objet dont il s''agit et ce champs nous donne le ID unique de cette objet.  Si Mo_NoteType.NoteTypeClassName = ''TUNCONVENTION'', alors ce champs correspondra au ConventionID de la convention qui a la note.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Note', @level2type = N'COLUMN', @level2name = N'NoteCodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est la note.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Note', @level2type = N'COLUMN', @level2name = N'NoteText';

