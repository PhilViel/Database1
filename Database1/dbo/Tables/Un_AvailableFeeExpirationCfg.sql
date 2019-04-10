CREATE TABLE [dbo].[Un_AvailableFeeExpirationCfg] (
    [AvailableFeeExpirationCfgID] [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [StartDate]                   [dbo].[MoGetDate] NOT NULL,
    [MonthAvailable]              [dbo].[MoID]      NOT NULL,
    CONSTRAINT [PK_Un_AvailableFeeExpirationCfg] PRIMARY KEY CLUSTERED ([AvailableFeeExpirationCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cette table contient la configuration pour l''expiration des frais disponibles.  Cette table est utilisé par le traitement de retrait des frais disponibles qui lors de leurs expirations transfert les frais dans le compte de Gestion Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AvailableFeeExpirationCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement de configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AvailableFeeExpirationCfg', @level2type = N'COLUMN', @level2name = N'AvailableFeeExpirationCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.  La configuration est en vigueur jusqu''à ce qu''une configuration avec une date plus récente mais qui n''est pas dans le futur la remplace.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AvailableFeeExpirationCfg', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Durée de vie des frais disponibles.  Par exemple les frais disponibles provenant d''une résiliation seront disponible pendant les X mois suivant la date de résiliation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AvailableFeeExpirationCfg', @level2type = N'COLUMN', @level2name = N'MonthAvailable';

