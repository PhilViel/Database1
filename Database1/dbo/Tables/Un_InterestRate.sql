CREATE TABLE [dbo].[Un_InterestRate] (
    [InterestRateID]              [dbo].[MoID]       IDENTITY (1, 1) NOT NULL,
    [OperID]                      [dbo].[MoIDoption] NULL,
    [YearPeriod]                  [dbo].[MoID]       NOT NULL,
    [MonthPeriod]                 [dbo].[MoID]       NOT NULL,
    [InterestRate]                [dbo].[MoPct100]   NOT NULL,
    [GovernmentGrantInterestRate] [dbo].[MoPct100]   NOT NULL,
    CONSTRAINT [PK_Un_Interestrate] PRIMARY KEY CLUSTERED ([InterestRateID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_InterestRate_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_InterestRate_OperID]
    ON [dbo].[Un_InterestRate]([OperID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de configuration contenant les taux d''intérêts pour le calcul d''intérêt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_InterestRate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_InterestRate', @level2type = N'COLUMN', @level2name = N'InterestRateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération financière (Un_Oper) généré par le calcul d''intérêt pour le mois.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_InterestRate', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Il y a un calcul d''intérêt par mois.  Donc avec le mois et l''année on peut savoir exactement le mois de qu''elle année il s''agit.  Ce champs contient l''année.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_InterestRate', @level2type = N'COLUMN', @level2name = N'YearPeriod';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Il y a un calcul d''intérêt par mois.  Donc avec le mois et l''année on peut savoir exactement le mois de qu''elle année il s''agit.  Ce champs contient le mois.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_InterestRate', @level2type = N'COLUMN', @level2name = N'MonthPeriod';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Taux d''intérêts pour ce mois.  Ce taux est celui utilisé pour générer l''intérêt sur capital, l''intérêt sur intérêt transfert IN et l''intérêt sur intérêt sur subventions transfert IN.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_InterestRate', @level2type = N'COLUMN', @level2name = N'InterestRate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Taux d''intérêts pour ce mois.  Ce taux est celui utilisé pour générer l''intérêt sur subventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_InterestRate', @level2type = N'COLUMN', @level2name = N'GovernmentGrantInterestRate';

