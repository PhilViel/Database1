CREATE TABLE [dbo].[Un_RepLevel] (
    [RepLevelID]       [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [RepRoleID]        [dbo].[MoOptionCode] NOT NULL,
    [LevelDesc]        [dbo].[MoDesc]       NOT NULL,
    [TargetUnit]       [dbo].[MoMoney]      NOT NULL,
    [ConservationRate] [dbo].[MoPctPos]     NOT NULL,
    [LevelShortDesc]   [dbo].[MoDescoption] NULL,
    CONSTRAINT [PK_Un_RepLevel] PRIMARY KEY CLUSTERED ([RepLevelID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepLevel_Un_RepRole__RepRoleID] FOREIGN KEY ([RepRoleID]) REFERENCES [dbo].[Un_RepRole] ([RepRoleID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepLevel_RepRoleID]
    ON [dbo].[Un_RepLevel]([RepRoleID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de niveau des représentants.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevel';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du niveau.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevel', @level2type = N'COLUMN', @level2name = N'RepLevelID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères du rôle (Un_RepRole) auquel appartient ce niveau.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevel', @level2type = N'COLUMN', @level2name = N'RepRoleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description du niveau.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevel', @level2type = N'COLUMN', @level2name = N'LevelDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de nouvelles ventes d''unités minimum pour être illigible à ce niveau.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevel', @level2type = N'COLUMN', @level2name = N'TargetUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage de conservation minimum pour être illigible à ce niveau.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevel', @level2type = N'COLUMN', @level2name = N'ConservationRate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description abrégée du niveau.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevel', @level2type = N'COLUMN', @level2name = N'LevelShortDesc';

