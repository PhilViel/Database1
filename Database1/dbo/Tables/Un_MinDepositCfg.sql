CREATE TABLE [dbo].[Un_MinDepositCfg] (
    [MinDepositCfgID] [dbo].[MoID]        IDENTITY (1, 1) NOT NULL,
    [PlanID]          [dbo].[MoID]        NOT NULL,
    [Effectdate]      [dbo].[MoDate]      NOT NULL,
    [ModalTypeID]     [dbo].[UnModalType] NOT NULL,
    [MinAmount]       [dbo].[MoMoney]     NOT NULL,
    CONSTRAINT [PK_Un_MinDepositCfg] PRIMARY KEY CLUSTERED ([MinDepositCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant la configuration du montant minimum pour chaque cotisation d''une convention.  Le montant peut varier selon le plan et le mode de cotisation (Unique, annuel, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinDepositCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement de configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinDepositCfg', @level2type = N'COLUMN', @level2name = N'MinDepositCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du plan (Un_Plan) auquel s''applique ce minimum.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinDepositCfg', @level2type = N'COLUMN', @level2name = N'PlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.  Pour connaître le minimum pour une convention, il faut prendre l''enregistrement dont le plan et le mode de cotisation est le même et dont cette date est la plus élevé mais qui ne dépasse pas la date de vigueur de la convention.  Pour connaître le délai en vigueur aujourd''hui, il faut faire le même exercise en remplacant la date de vigueur de la convention par la date du jour.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinDepositCfg', @level2type = N'COLUMN', @level2name = N'Effectdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de mode de cotisation auquel s''applique ce minimum (0=Unique, 1=Annuel, 2=Semi-annuel, 4=Trimestriel, 12=Mensuel).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinDepositCfg', @level2type = N'COLUMN', @level2name = N'ModalTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant minimum par cotisation (Dépôt) en épargnes et frais.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinDepositCfg', @level2type = N'COLUMN', @level2name = N'MinAmount';

