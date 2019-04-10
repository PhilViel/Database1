CREATE TABLE [dbo].[Un_SpecialAdvance] (
    [SpecialAdvanceID]     [dbo].[MoID]       IDENTITY (1, 1) NOT NULL,
    [RepID]                [dbo].[MoID]       NOT NULL,
    [EffectDate]           [dbo].[MoGetDate]  NOT NULL,
    [Amount]               [dbo].[MoMoney]    NOT NULL,
    [RepTreatmentID]       [dbo].[MoIDoption] NULL,
    [vcSpecialAdvanceDesc] VARCHAR (100)      CONSTRAINT [DF_Un_SpecialAdvance_vcSpecialAdvanceDesc] DEFAULT ('') NULL,
    CONSTRAINT [PK_Un_SpecialAdvance] PRIMARY KEY CLUSTERED ([SpecialAdvanceID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_SpecialAdvance_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_SpecialAdvance_RepID]
    ON [dbo].[Un_SpecialAdvance]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_SpecialAdvance_EffectDate]
    ON [dbo].[Un_SpecialAdvance]([EffectDate] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_SpecialAdvance_RepID_EffectDate]
    ON [dbo].[Un_SpecialAdvance]([RepID] ASC, [EffectDate] ASC)
    INCLUDE([Amount]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des avances spéciales.  Pour connaître le solde des avances spéciales pour un représentant, il suffit de faire la somme des avances spéciales de ce dernier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SpecialAdvance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''avances spéciales.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SpecialAdvance', @level2type = N'COLUMN', @level2name = N'SpecialAdvanceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) auquel appartient cette avances spéciales.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SpecialAdvance', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à laquelle a été fait l''avance spéciale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SpecialAdvance', @level2type = N'COLUMN', @level2name = N'EffectDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de l''avance spéciale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SpecialAdvance', @level2type = N'COLUMN', @level2name = N'Amount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du traitement de commissions (Un_RepTreatment) qui a généré cette avances spéciales. Null = Entrée manuelle.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SpecialAdvance', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champ contenant la description justifiant l''avance spéciale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_SpecialAdvance', @level2type = N'COLUMN', @level2name = N'vcSpecialAdvanceDesc';

