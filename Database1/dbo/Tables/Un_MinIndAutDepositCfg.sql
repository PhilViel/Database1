CREATE TABLE [dbo].[Un_MinIndAutDepositCfg] (
    [MinIndAutDepositCfgID] [dbo].[MoID]    IDENTITY (1, 1) NOT NULL,
    [Effectdate]            [dbo].[MoDate]  NOT NULL,
    [MinAmount]             [dbo].[MoMoney] NOT NULL,
    CONSTRAINT [PK_Un_MinIndAutDepositCfg] PRIMARY KEY CLUSTERED ([MinIndAutDepositCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant la configuration du montant minimum du cotisation par prélèvement automatique pour les conventions individuelles.  Ce minimum s''applique uniquement aux conventions qui on un plan de type individuel (Un_Plan.PlanTypeID = ''IND'').', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinIndAutDepositCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement de configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinIndAutDepositCfg', @level2type = N'COLUMN', @level2name = N'MinIndAutDepositCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.  Pour connaître le minimum pour une convention, il faut prendre l''enregistrement dont cette date est la plus élevé mais qui ne dépasse pas la date de vigueur de la convention.  Pour connaître le délai en vigueur aujourd''hui, il faut faire le même exercise en remplacant la date de vigueur de la convention par la date du jour.  Il est évident que le type du Plan de la convention doit être individuel (Un_Plan.PlanTypeID = ''IND'').', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinIndAutDepositCfg', @level2type = N'COLUMN', @level2name = N'Effectdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant minimum en épargnes et frais par prélèvement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinIndAutDepositCfg', @level2type = N'COLUMN', @level2name = N'MinAmount';

