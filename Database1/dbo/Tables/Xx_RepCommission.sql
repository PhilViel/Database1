CREATE TABLE [dbo].[Xx_RepCommission] (
    [XxCommissionID]  [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [RepID]           [dbo].[MoID]         NOT NULL,
    [CommissionDate]  [dbo].[MoGetDate]    NOT NULL,
    [Advance]         [dbo].[MoMoney]      NOT NULL,
    [AnnualBonus]     [dbo].[MoMoney]      NOT NULL,
    [Commission]      [dbo].[MoMoney]      NOT NULL,
    [FormationFee]    [dbo].[MoMoney]      NOT NULL,
    [OtherFee]        [dbo].[MoMoney]      NOT NULL,
    [UserDescription] [dbo].[MoDescoption] NULL,
    CONSTRAINT [PK_Xx_RepCommission] PRIMARY KEY CLUSTERED ([XxCommissionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Xx_RepCommission_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de comparaison des commissions.  Elle contient le contenu de feuilles Excel de commissions données au représentant durant le système Paradox.  On s''en est servi pour comparer les données de la comptabilité versus le résultat des premiers traitements de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission', @level2type = N'COLUMN', @level2name = N'XxCommissionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) qui a eu ce paiement de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à laquel le paiement a été fait.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission', @level2type = N'COLUMN', @level2name = N'CommissionDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''avances payées.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission', @level2type = N'COLUMN', @level2name = N'Advance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de bonis annuel payés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission', @level2type = N'COLUMN', @level2name = N'AnnualBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de commissions de service payés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission', @level2type = N'COLUMN', @level2name = N'Commission';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de frais de formation payés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission', @level2type = N'COLUMN', @level2name = N'FormationFee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''autres frais payés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission', @level2type = N'COLUMN', @level2name = N'OtherFee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description entrée par l''usager.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Xx_RepCommission', @level2type = N'COLUMN', @level2name = N'UserDescription';

