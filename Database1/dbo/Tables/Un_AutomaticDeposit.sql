CREATE TABLE [dbo].[Un_AutomaticDeposit] (
    [AutomaticDepositID]        [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [UnitID]                    [dbo].[MoID]         NOT NULL,
    [StartDate]                 [dbo].[MoGetDate]    NOT NULL,
    [EndDate]                   [dbo].[MoDateoption] NULL,
    [FirstAutomaticDepositDate] [dbo].[MoGetDate]    NOT NULL,
    [TimeUnit]                  [dbo].[UnTimeOut]    NOT NULL,
    [TimeUnitLap]               [dbo].[MoID]         NOT NULL,
    [CotisationFee]             [dbo].[MoMoney]      NOT NULL,
    [SubscInsur]                [dbo].[MoMoney]      NOT NULL,
    [BenefInsur]                [dbo].[MoMoney]      NOT NULL,
    CONSTRAINT [PK_Un_AutomaticDeposit] PRIMARY KEY CLUSTERED ([AutomaticDepositID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_AutomaticDeposit_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_AutomaticDeposit_UnitID]
    ON [dbo].[Un_AutomaticDeposit]([UnitID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cette table contient les horaires de prélèvements.  Les horaires de prélèvement permettent de céduler des prélèvements automatiques CPA pour un groupe d''unités de montant et à interval désiré.  Un horaire de prélèvement agit aussi d''arrêt des paiements réguliers pendant qu''il est en vigueur.  Donc les prélèvements automatiques de la modalité de paiement ne sont pas effectué quand un horaire de prélèvement est en vigueur sur le groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''horaire de prélèvement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit', @level2type = N'COLUMN', @level2name = N'AutomaticDepositID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités (Un_Unit) auquel appartient l''horaire de prélèvement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de l''horaire de prélèvement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de vigueur de l''horaire de prélèvement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit', @level2type = N'COLUMN', @level2name = N'EndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à laquel à lieu le premier dépôt de l''horaire de prélèvement.  Tout les dépôts suivants sont basés sur cette date.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit', @level2type = N'COLUMN', @level2name = N'FirstAutomaticDepositDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type d''unités temporelle 0 = unique, 1 = jour, 2 = semaine 3 = mois, 4 = année.  Combiné avec le champs TimeUnitLap ce champs permet de déterminer l''interval entre les dépôts.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit', @level2type = N'COLUMN', @level2name = N'TimeUnitLap';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''épargnes et frais par prélèvement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit', @level2type = N'COLUMN', @level2name = N'CotisationFee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''assurance souscripteur par prélèvement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit', @level2type = N'COLUMN', @level2name = N'SubscInsur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''assurance bénéficiaire par prélèvement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AutomaticDeposit', @level2type = N'COLUMN', @level2name = N'BenefInsur';

