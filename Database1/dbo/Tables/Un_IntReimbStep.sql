CREATE TABLE [dbo].[Un_IntReimbStep] (
    [iIntReimbStepID]    INT      IDENTITY (1, 1) NOT NULL,
    [UnitID]             INT      NULL,
    [iIntReimbStep]      INT      NULL,
    [dtIntReimbStepTime] DATETIME NULL,
    [ConnectID]          INT      NULL,
    CONSTRAINT [PK_Un_IntReimbStep] PRIMARY KEY CLUSTERED ([iIntReimbStepID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_IntReimbStep_iIntReimbStep]
    ON [dbo].[Un_IntReimbStep]([iIntReimbStep] ASC)
    INCLUDE([UnitID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_IntReimbStep_UnitID_iIntReimbStep]
    ON [dbo].[Un_IntReimbStep]([UnitID] ASC, [iIntReimbStep] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table conservant l''historique des étapes des remboursements intégral fait dans l''outil.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbStep';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l’historique des étapes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbStep', @level2type = N'COLUMN', @level2name = N'iIntReimbStepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du groupe d’unités auquel appartient l’historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbStep', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Étape (1 à 6).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbStep', @level2type = N'COLUMN', @level2name = N'iIntReimbStep';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure ou on a passé à cette étape.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbStep', @level2type = N'COLUMN', @level2name = N'dtIntReimbStepTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’usager qui a provoqué le changement d’étape.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbStep', @level2type = N'COLUMN', @level2name = N'ConnectID';

