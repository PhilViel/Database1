CREATE TABLE [dbo].[Mo_Sex] (
    [SexID]        [dbo].[MoSex]        NOT NULL,
    [LangID]       CHAR (3)             NOT NULL,
    [LongSexName]  [dbo].[MoDescoption] NULL,
    [ShortSexName] [dbo].[MoDescoption] NULL,
    [SexName]      [dbo].[MoDescoption] NULL,
    CONSTRAINT [PK_Mo_Sex] PRIMARY KEY CLUSTERED ([SexID] ASC, [LangID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Sex_Mo_Lang__LangID] FOREIGN KEY ([LangID]) REFERENCES [dbo].[Mo_Lang] ([LangID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des descriptions de sexe et des mots de courtoisies selon la langue et le sexe (Madame, Monsieur, Sir, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Sex';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère indiquant le sexe. (''U''=Inconnu, ''F''=Féminin, ''M''=Masculin)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Sex', @level2type = N'COLUMN', @level2name = N'SexID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère indiquant la langue. (''UNK''=Inconnu, ''FRA''=Français, ''ENU''=Anglais)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Sex', @level2type = N'COLUMN', @level2name = N'LangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Titre de courtoisie pour ce sexe dans cette langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Sex', @level2type = N'COLUMN', @level2name = N'LongSexName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Abbrégé du titre de courtoisie pour ce sexe dans cette langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Sex', @level2type = N'COLUMN', @level2name = N'ShortSexName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Le nom de ce sexe dans cette langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Sex', @level2type = N'COLUMN', @level2name = N'SexName';

