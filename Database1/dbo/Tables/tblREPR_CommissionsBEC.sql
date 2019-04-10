CREATE TABLE [dbo].[tblREPR_CommissionsBEC] (
    [iRepComBEC]      INT         IDENTITY (1, 1) NOT NULL,
    [dDate_Calcul]    DATE        NOT NULL,
    [RepID]           INT         NOT NULL,
    [RepRoleID]       VARCHAR (3) NULL,
    [UnitID]          INT         NOT NULL,
    [BeneficiaryID]   INT         NOT NULL,
    [mMontant_ComBEC] MONEY       NOT NULL,
    [RepTreatmentID]  INT         NULL,
    [dDate_Insertion] DATETIME    CONSTRAINT [DF_tblREPR_CommissionsBEC_dDate_Insertion] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_tblREPR_CommissionsBEC] PRIMARY KEY CLUSTERED ([iRepComBEC] ASC),
    CONSTRAINT [FK_tblREPR_CommissionsBEC_RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_tblREPR_CommissionsBEC_Un_RepTreatment] FOREIGN KEY ([RepTreatmentID]) REFERENCES [dbo].[Un_RepTreatment] ([RepTreatmentID]),
    CONSTRAINT [FK_tblREPR_CommissionsBEC_Un_Unit] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient les commissions de BEC calculées pour chaque groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsBEC';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsBEC', @level2type = N'COLUMN', @level2name = N'iRepComBEC';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date effective du calcul de la commission de BEC.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsBEC', @level2type = N'COLUMN', @level2name = N'dDate_Calcul';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du représentant à qui la commission de BEC est versée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsBEC', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du rôle de représentant (REP ou DIR) à qui la commission de BEC est versée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsBEC', @level2type = N'COLUMN', @level2name = N'RepRoleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du groupe d''unité sur lequel la commisison de BEC a été calculée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsBEC', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du Bénéficiaire sur lequel la commisison de BEC a été calculée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsBEC', @level2type = N'COLUMN', @level2name = N'BeneficiaryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de la commission de BEC.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsBEC', @level2type = N'COLUMN', @level2name = N'mMontant_ComBEC';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du traitement de commissions sur laquel cette commission de BEC sera payée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsBEC', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';

