CREATE TABLE [dbo].[tblREPR_CommissionsSuivi] (
    [iRepComSuivi]        INT            IDENTITY (1, 1) NOT NULL,
    [dDate_Calcul]        DATE           NOT NULL,
    [RepID]               INT            NOT NULL,
    [UnitID]              INT            NOT NULL,
    [mEpargne_SoldeDebut] MONEY          NOT NULL,
    [mEpargne_Periode]    MONEY          NOT NULL,
    [mEpargne_SoldeFin]   MONEY          NOT NULL,
    [mEpargne_Calcul]     MONEY          NOT NULL,
    [dTaux_Calcul]        DECIMAL (7, 5) NOT NULL,
    [bTaux_ApresEcheance] BIT            NOT NULL,
    [mMontant_ComSuivi]   MONEY          NOT NULL,
    [RepTreatmentID]      INT            NULL,
    [dDate_Insertion]     DATETIME       CONSTRAINT [DF_tblREPR_CommissionsSuivi_dDate_Insertion] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_tblREPR_CommissionsSuivi] PRIMARY KEY CLUSTERED ([iRepComSuivi] ASC),
    CONSTRAINT [FK_tblREPR_CommissionsSuivi_RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_tblREPR_CommissionsSuivi_Un_RepTreatment] FOREIGN KEY ([RepTreatmentID]) REFERENCES [dbo].[Un_RepTreatment] ([RepTreatmentID]),
    CONSTRAINT [FK_tblREPR_CommissionsSuivi_Un_Unit] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient les commissions de suivi calculées pour chaque groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'iRepComSuivi';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date effective du calcul de la commission de suivi.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'dDate_Calcul';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du représentant à qui la commission de suivi est versée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du groupe d''unité sur lequel la commisison de suivi a été calculée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Solde de l''épargne du groupe d''unité, un mois avant la date du calcul.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'mEpargne_SoldeDebut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Épargne entrée et sortie dans le mois avant la date du calcul.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'mEpargne_Periode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Solde de l''épargne du groupe d''unité, à la date du calcul. ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'mEpargne_SoldeFin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Moyenne de l''épargne du groupe d''unité, un mois avant et à la date du calcul. ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'mEpargne_Calcul';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Taux utilisé pour la calcul de la commission de suivi.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'dTaux_Calcul';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le taux utilisé est celui après l''échéance.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'bTaux_ApresEcheance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de la commission de suivi.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'mMontant_ComSuivi';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du traitement de commissions sur laquel cette commission de suivi sera payée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuivi', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';

