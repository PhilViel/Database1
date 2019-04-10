CREATE TABLE [dbo].[tblREPR_CommissionsSuiviEligibilite] (
    [idEligibilite]            INT  IDENTITY (1, 1) NOT NULL,
    [DateEligibilite]          DATE NOT NULL,
    [RepID]                    INT  NOT NULL,
    [EstEligible]              BIT  CONSTRAINT [DF__tblREPR_C__EstEL__17D7C732] DEFAULT ((0)) NOT NULL,
    [EstDirecteur]             BIT  CONSTRAINT [DF__tblREPR_C__EstDi__13131215] DEFAULT ((0)) NOT NULL,
    [EstInactif]               BIT  CONSTRAINT [DF__tblREPR_C__EstAc__1407364E] DEFAULT ((0)) NOT NULL,
    [EstBloque]                BIT  CONSTRAINT [DF__tblREPR_C__EstBo__14FB5A87] DEFAULT ((0)) NOT NULL,
    [EpargneMinNonAtteint]     BIT  CONSTRAINT [DF__tblREPR_C__ACapi__15EF7EC0] DEFAULT ((0)) NULL,
    [AncienneteMinNonAtteinte] BIT  CONSTRAINT [DF__tblREPR_C__AAnci__16E3A2F9] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_tblREPR_EligibiliteCommissionSuivi] PRIMARY KEY CLUSTERED ([idEligibilite] ASC),
    CONSTRAINT [FK_tblREPR_EligibiliteCommissionSuivi] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique de l''éligibilité d''un représentant à la commissions de suivi.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite', @level2type = N'COLUMN', @level2name = N'idEligibilite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date à laquelle l''éligibilité a été déterminée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite', @level2type = N'COLUMN', @level2name = N'DateEligibilite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du représentant', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le représentant est éligible ou non selon les différents critères.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite', @level2type = N'COLUMN', @level2name = N'EstEligible';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le représentant est un directeur (non-éligible).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite', @level2type = N'COLUMN', @level2name = N'EstDirecteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le représentant est inactif (non-éligible).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite', @level2type = N'COLUMN', @level2name = N'EstInactif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le représentant est bloqué pour la commission de suivi (non-éligible).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite', @level2type = N'COLUMN', @level2name = N'EstBloque';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le représentant n''atteint pas l''épargne minimal exigé (non-éligible).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite', @level2type = N'COLUMN', @level2name = N'EpargneMinNonAtteint';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le représentant n''atteint pas l''ancienneté minimale exigée (non-éligible).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CommissionsSuiviEligibilite', @level2type = N'COLUMN', @level2name = N'AncienneteMinNonAtteinte';

