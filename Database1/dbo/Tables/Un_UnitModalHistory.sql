CREATE TABLE [dbo].[Un_UnitModalHistory] (
    [UnitModalHistoryID] [dbo].[MoID]   IDENTITY (1, 1) NOT NULL,
    [UnitID]             [dbo].[MoID]   NOT NULL,
    [ModalID]            [dbo].[MoID]   NOT NULL,
    [ConnectID]          [dbo].[MoID]   NOT NULL,
    [StartDate]          [dbo].[MoDate] NOT NULL,
    CONSTRAINT [PK_Un_UnitModalHistory] PRIMARY KEY CLUSTERED ([UnitModalHistoryID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_UnitModalHistory_Un_Modal__ModalID] FOREIGN KEY ([ModalID]) REFERENCES [dbo].[Un_Modal] ([ModalID]),
    CONSTRAINT [FK_Un_UnitModalHistory_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_UnitModalHistory_UnitID]
    ON [dbo].[Un_UnitModalHistory]([UnitID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des entrées d''historique de modalité de paiement des groupes d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitModalHistory';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''entrée d''historique de modalité de paiement sur groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitModalHistory', @level2type = N'COLUMN', @level2name = N'UnitModalHistoryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités (Un_Unit) auquel appartient l''entrée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitModalHistory', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la modalité de paiement (Un_Modal).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitModalHistory', @level2type = N'COLUMN', @level2name = N'ModalID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect) de l''usager qui a provocté la création de l''entrée soit en créant le groupe d''unités ou en modifiant la modalité d''un groupe existant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitModalHistory', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la modalité de paiement.  N''est plus en vigueur quand un entrée avec un date supérieure apparaît.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitModalHistory', @level2type = N'COLUMN', @level2name = N'StartDate';

