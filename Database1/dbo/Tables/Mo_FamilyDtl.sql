CREATE TABLE [dbo].[Mo_FamilyDtl] (
    [FamilyDtlID]  [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [HumanID]      [dbo].[MoID]         NOT NULL,
    [FamilyID]     [dbo].[MoID]         NOT NULL,
    [FamilyRoleID] [dbo].[MoFamilyRole] NOT NULL,
    CONSTRAINT [PK_Mo_FamilyDtl] PRIMARY KEY CLUSTERED ([FamilyDtlID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_FamilyDtl_Mo_Family__FamilyID] FOREIGN KEY ([FamilyID]) REFERENCES [dbo].[Mo_Family] ([FamilyID]),
    CONSTRAINT [FK_Mo_FamilyDtl_Mo_Human__HumanID] FOREIGN KEY ([HumanID]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Mo_FamilyDtl_HumanID_FamilyID]
    ON [dbo].[Mo_FamilyDtl]([HumanID] ASC, [FamilyID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_FamilyDtl_FamilyID]
    ON [dbo].[Mo_FamilyDtl]([FamilyID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_FamilyDtl_HumanID]
    ON [dbo].[Mo_FamilyDtl]([HumanID] ASC) WITH (FILLFACTOR = 90);


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_FamilyDtl] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des liens entre les familles et les humains qui les composents.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_FamilyDtl';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du lien.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_FamilyDtl', @level2type = N'COLUMN', @level2name = N'FamilyDtlID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''humain (Mo_Human) qui fait parti de la famille.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_FamilyDtl', @level2type = N'COLUMN', @level2name = N'HumanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la famille (Mo_Family).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_FamilyDtl', @level2type = N'COLUMN', @level2name = N'FamilyID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère identifiant le rôle de cette humain dans cette famille (''U''=Inconnu, ''O''=Autre, ''C''=Enfant, ''P''=Parent, ''G''=Grand-parent, ''S''=Cousin/cousine, ''H''=Tante/oncle, ''M''=Épouse).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_FamilyDtl', @level2type = N'COLUMN', @level2name = N'FamilyRoleID';

