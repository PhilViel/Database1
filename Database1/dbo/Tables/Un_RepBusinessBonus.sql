CREATE TABLE [dbo].[Un_RepBusinessBonus] (
    [RepBusinessBonusID]  [dbo].[MoID]        IDENTITY (1, 1) NOT NULL,
    [RepID]               [dbo].[MoID]        NOT NULL,
    [RepTreatmentID]      [dbo].[MoID]        NOT NULL,
    [UnitID]              [dbo].[MoID]        NOT NULL,
    [RepLevelID]          [dbo].[MoID]        NOT NULL,
    [UnitQty]             [dbo].[MoMoney]     NOT NULL,
    [BusinessBonusAmount] [dbo].[MoMoney]     NOT NULL,
    [InsurTypeID]         [dbo].[UnInsurType] NOT NULL,
    CONSTRAINT [PK_Un_RepBusinessBonus] PRIMARY KEY CLUSTERED ([RepBusinessBonusID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepBusinessBonus_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_RepBusinessBonus_Un_RepLevel__RepLevelID] FOREIGN KEY ([RepLevelID]) REFERENCES [dbo].[Un_RepLevel] ([RepLevelID]),
    CONSTRAINT [FK_Un_RepBusinessBonus_Un_RepTreatment__RepTreatmentID] FOREIGN KEY ([RepTreatmentID]) REFERENCES [dbo].[Un_RepTreatment] ([RepTreatmentID]),
    CONSTRAINT [FK_Un_RepBusinessBonus_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepBusinessBonus_RepID]
    ON [dbo].[Un_RepBusinessBonus]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepBusinessBonus_RepTreatmentID]
    ON [dbo].[Un_RepBusinessBonus]([RepTreatmentID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepBusinessBonus_UnitID]
    ON [dbo].[Un_RepBusinessBonus]([UnitID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepBusinessBonus_RepLevelID]
    ON [dbo].[Un_RepBusinessBonus]([RepLevelID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des bonis d''affaires.  Les bonis d''affaires sont des montants d''argent versés aux représentants pour les ventes d''unités assurées.  Il y a des bonis sur l''assurance souscripteur et sur l''assurance bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du boni d''affaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonus', @level2type = N'COLUMN', @level2name = N'RepBusinessBonusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) qui touche ce boni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonus', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du traitement de commissions (Un_RepTreatment) qui a généré ce boni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonus', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités (Un_Unit) pour lequel le représentant touche ce boni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonus', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du niveau (Un_RepLevel) qu''avait le représentant quand il a vendu le groupe d''unités pour lequel le représentant touche ce boni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonus', @level2type = N'COLUMN', @level2name = N'RepLevelID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant du boni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonus', @level2type = N'COLUMN', @level2name = N'BusinessBonusAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaine de trois caractères identifiant pour quel type d''assurance vendu ce boni a été touché (''ISB''=Assurance souscripteur, ''IB5''=Assurance bénéficiaire avec indemnité 5 000$, ''IB1''=Assurance bénéficiaire avec indemnité 10 000$, ''IB2''=Assurance bénéficiaire avec indemnité 20 000$).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonus', @level2type = N'COLUMN', @level2name = N'InsurTypeID';

