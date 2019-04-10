CREATE TABLE [dbo].[Un_RepAccount] (
    [RepTreatmentID]  [dbo].[MoID]    NOT NULL,
    [RepID]           [dbo].[MoID]    NOT NULL,
    [AjustmentAmount] [dbo].[MoMoney] NOT NULL,
    CONSTRAINT [PK_Un_RepAccount] PRIMARY KEY CLUSTERED ([RepTreatmentID] ASC, [RepID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepAccount_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_RepAccount_Un_RepTreatment__RepTreatmentID] FOREIGN KEY ([RepTreatmentID]) REFERENCES [dbo].[Un_RepTreatment] ([RepTreatmentID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutilisé - Table qui contient l''état du compte des représentants.  On fait la somme des montants pour un représentant pour connaître sont solde.  Est remplis automatiquement par le traitement de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepAccount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du traitement de commissions (Un_RepTreatment) qui à fait l''entrée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepAccount', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) à qui est le compte qu''affecte l''entrée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepAccount', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant ajouté ou retiré du compte.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepAccount', @level2type = N'COLUMN', @level2name = N'AjustmentAmount';

