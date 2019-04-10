CREATE TABLE [dbo].[Un_MaxConvDepositDateCfg] (
    [MaxConvDepositDateCfgID] [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [Effectdate]              [dbo].[MoGetDate] NOT NULL,
    [YearQty]                 [dbo].[MoID]      NOT NULL,
    CONSTRAINT [PK_Un_MaxConvDepositDateCfg] PRIMARY KEY CLUSTERED ([MaxConvDepositDateCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant la configuration du délai maximum pour cotiser le REER.  Le gouvernement impose un délai pour cotiser un REER.  Cette permet de configurer la validation de ce délai.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MaxConvDepositDateCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement de configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MaxConvDepositDateCfg', @level2type = N'COLUMN', @level2name = N'MaxConvDepositDateCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.  Pour connaître le délai de cotisation pour une convention, il faut prendre l''enregistrement dont cette date est la plus élevé mais qui ne dépasse pas la date de vigueur de la convention.  Pour connaître le délai en vigueur aujourd''hui, il faut faire le même exercise en remplacant la date de vigueur de la convention par la date du jour.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MaxConvDepositDateCfg', @level2type = N'COLUMN', @level2name = N'Effectdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre d''année aprés la date de vigueur pendant lesquelles le souscripteur à le droit de cotiser.  La date de vigueur de la convention additionné de ce délai - 1 jour nous donne la date du dernier jour ou le souscripteur peut cotiser, dépassé ce jour il ne peut plus.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MaxConvDepositDateCfg', @level2type = N'COLUMN', @level2name = N'YearQty';

