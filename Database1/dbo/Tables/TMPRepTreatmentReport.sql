CREATE TABLE [dbo].[TMPRepTreatmentReport] (
    [RepTreatmentDate]  [dbo].[MoGetDate] NOT NULL,
    [RepID]             [dbo].[MoID]      NOT NULL,
    [NewAdvance]        [dbo].[MoMoney]   NOT NULL,
    [CommAndBonus]      [dbo].[MoMoney]   NOT NULL,
    [Adjustment]        [dbo].[MoMoney]   NOT NULL,
    [Retenu]            [dbo].[MoMoney]   NOT NULL,
    [ChqNet]            [dbo].[MoMoney]   NOT NULL,
    [Advance]           [dbo].[MoMoney]   NOT NULL,
    [TerminatedAdvance] [dbo].[MoMoney]   NOT NULL,
    [SpecialAdvance]    [dbo].[MoMoney]   NOT NULL,
    [TotalAdvance]      MONEY             NULL,
    [CoveredAdvance]    [dbo].[MoMoney]   NOT NULL,
    [CommissionFee]     MONEY             NULL,
    [BusinessEnd]       DATETIME          NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_TMPRepTreatmentReport_RepID]
    ON [dbo].[TMPRepTreatmentReport]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_TMPRepTreatmentReport_RepTreatmentDate]
    ON [dbo].[TMPRepTreatmentReport]([RepTreatmentDate] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de travail pour les rapports de traitement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TMPRepTreatmentReport';

