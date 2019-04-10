CREATE TABLE [dbo].[Un_BeneficiaryCeilingCfg] (
    [BeneficiaryCeilingCfgID] [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [Effectdate]              [dbo].[MoGetDate] NOT NULL,
    [AnnualCeiling]           [dbo].[MoMoney]   NOT NULL,
    [LifeCeiling]             [dbo].[MoMoney]   NOT NULL,
    CONSTRAINT [PK_Un_BeneficiaryCeilingCfg] PRIMARY KEY CLUSTERED ([BeneficiaryCeilingCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cette table contient la configuration des plafonds de cotisation des bénéficiaires.  Le plafond de cotisation sont des limites de cotisation pour un même bénéficiaire que le gouvernment a fixé.  Il y a une limite de cotisation à vie et une limite de cotisation par année.  Les limites ne doivent pas être dépassées par l''ensemble des souscripteur qui cotise pour ce même bénéficiaire.  Les cotisations comprend les épargnes et les frais.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BeneficiaryCeilingCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BeneficiaryCeilingCfg', @level2type = N'COLUMN', @level2name = N'BeneficiaryCeilingCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur des limites.  Elles sont en vigueur jusqu''à ce qu''une configuration avec une date plus récente mais qui n''est pas dans le futur la remplace.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BeneficiaryCeilingCfg', @level2type = N'COLUMN', @level2name = N'Effectdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum de cotisation à vie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BeneficiaryCeilingCfg', @level2type = N'COLUMN', @level2name = N'AnnualCeiling';

