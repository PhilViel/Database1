CREATE TABLE [dbo].[Un_ConventionState] (
    [ConventionStateID]   [dbo].[MoOptionCode] NOT NULL,
    [ConventionStateName] [dbo].[MoDesc]       NOT NULL,
    [PriorityLevelID]     [dbo].[MoID]         NOT NULL,
    [UnitStateID]         [dbo].[MoOptionCode] NOT NULL,
    CONSTRAINT [PK_Un_ConventionState] PRIMARY KEY CLUSTERED ([ConventionStateID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ConventionState_Un_UnitState__UnitStateID] FOREIGN KEY ([UnitStateID]) REFERENCES [dbo].[Un_UnitState] ([UnitStateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionState_UnitStateID]
    ON [dbo].[Un_ConventionState]([UnitStateID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des différents états possibles des conventions', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionState';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l’état de convention qui est composé de trois lettres', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionState', @level2type = N'COLUMN', @level2name = N'ConventionStateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de l’état', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionState', @level2type = N'COLUMN', @level2name = N'ConventionStateName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Permet de déterminer qu’elle état prédomine sur les autres', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionState', @level2type = N'COLUMN', @level2name = N'PriorityLevelID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID d’un état de groupe d’unités', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionState', @level2type = N'COLUMN', @level2name = N'UnitStateID';

