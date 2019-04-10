CREATE TABLE [dbo].[Un_UnitUnitState] (
    [UnitUnitStateID] [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [UnitID]          [dbo].[MoID]         NOT NULL,
    [UnitStateID]     [dbo].[MoOptionCode] NOT NULL,
    [StartDate]       [dbo].[MoGetDate]    NOT NULL,
    CONSTRAINT [PK_Un_UnitUnitState] PRIMARY KEY CLUSTERED ([UnitUnitStateID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_UnitUnitState_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID]),
    CONSTRAINT [FK_Un_UnitUnitState_Un_UnitState__UnitStateID] FOREIGN KEY ([UnitStateID]) REFERENCES [dbo].[Un_UnitState] ([UnitStateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_UnitUnitState_UnitID]
    ON [dbo].[Un_UnitUnitState]([UnitID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_UnitUnitState_UnitStateID]
    ON [dbo].[Un_UnitUnitState]([UnitStateID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_UnitUnitState_UnitID_StartDate]
    ON [dbo].[Un_UnitUnitState]([UnitID] ASC, [StartDate] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de lien entre les états de groupes d’unités et les groupes d’unités', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitUnitState';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique des enregistrements', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitUnitState', @level2type = N'COLUMN', @level2name = N'UnitUnitStateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique du groupe d’unités (Un_Unit) à qui appartient l’état', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitUnitState', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique de l’état (Un_UnitState)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitUnitState', @level2type = N'COLUMN', @level2name = N'UnitStateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure à laquelle l’état est entré en vigueur pour le groupe d''unité', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitUnitState', @level2type = N'COLUMN', @level2name = N'StartDate';

