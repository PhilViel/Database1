CREATE TABLE [dbo].[Un_UnitState] (
    [UnitStateID]      [dbo].[MoOptionCode]       NOT NULL,
    [OwnerUnitStateID] [dbo].[MoOptionCodeOption] NULL,
    [UnitStateName]    [dbo].[MoDesc]             NOT NULL,
    CONSTRAINT [PK_Un_UnitState] PRIMARY KEY CLUSTERED ([UnitStateID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_UnitState_Un_UnitState__OwnerUnitStateID] FOREIGN KEY ([OwnerUnitStateID]) REFERENCES [dbo].[Un_UnitState] ([UnitStateID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des différents états possibles des groupes d’unités', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitState';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique de l’état de groupe d’unités qui est composé de 3 caractères alphanumériques', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitState', @level2type = N'COLUMN', @level2name = N'UnitStateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique de l’état de groupe d’unités qui est le parent de cet état', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitState', @level2type = N'COLUMN', @level2name = N'OwnerUnitStateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de l’état', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitState', @level2type = N'COLUMN', @level2name = N'UnitStateName';

