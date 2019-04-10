CREATE TABLE [dbo].[Un_TFRCfg] (
    [TFRCfgID]       [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [StartDate]      [dbo].[MoGetDate]    NOT NULL,
    [EndDate]        [dbo].[MoDateoption] NULL,
    [AvailableMonth] [dbo].[MoOrder]      NOT NULL,
    CONSTRAINT [PK_Un_TFRCfg] PRIMARY KEY CLUSTERED ([TFRCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de configuration des frais disponibles.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TFRCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TFRCfg', @level2type = N'COLUMN', @level2name = N'TFRCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TFRCfg', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de vigueur de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TFRCfg', @level2type = N'COLUMN', @level2name = N'EndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de mois pendant lesquelles les frais disponibles sont disponibles.  Les frais disponibles sont des frais provenant de résiliation ou transfert OUT.  Les souscripteurs peuvent les réutiliser dans d''autres conventions avant ce nombre de mois.  Un traitement journalier déplace les frais disponibles échus dans le compte de Gestion Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TFRCfg', @level2type = N'COLUMN', @level2name = N'AvailableMonth';

