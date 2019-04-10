CREATE TABLE [dbo].[Un_MinConvUnitQtyCfg] (
    [MinConvUnitQtyCfgID] [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [Effectdate]          [dbo].[MoGetDate] NOT NULL,
    [MinUnitQty]          [dbo].[MoMoney]   NOT NULL,
    CONSTRAINT [PK_Un_MinConvUnitQtyCfg] PRIMARY KEY CLUSTERED ([MinConvUnitQtyCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant la configuration du minimum d''unités d''une convention.  Le seul moyen d''être sous ce minimum est de résilier la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinConvUnitQtyCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement de configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinConvUnitQtyCfg', @level2type = N'COLUMN', @level2name = N'MinConvUnitQtyCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.  Pour connaître le minimum d''unités pour une convention, il faut prendre l''enregistrement dont cette date est la plus élevé mais qui ne dépasse pas la date de vigueur de la convention.  Pour connaître le délai en vigueur aujourd''hui, il faut faire le même exercise en remplacant la date de vigueur de la convention par la date du jour.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinConvUnitQtyCfg', @level2type = N'COLUMN', @level2name = N'Effectdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Minimum d''unités que doit avoir la convention si elle n''est pas résiliée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinConvUnitQtyCfg', @level2type = N'COLUMN', @level2name = N'MinUnitQty';

