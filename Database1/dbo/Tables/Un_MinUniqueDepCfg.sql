CREATE TABLE [dbo].[Un_MinUniqueDepCfg] (
    [MinUniqueDepCfgID] [dbo].[MoID]    IDENTITY (1, 1) NOT NULL,
    [Effectdate]        [dbo].[MoDate]  NOT NULL,
    [MinAmount]         [dbo].[MoMoney] NOT NULL,
    CONSTRAINT [PK_Un_MinUniqueDepCfg] PRIMARY KEY CLUSTERED ([MinUniqueDepCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant la configuration du montant minimum du cotisation pour un ajout d''unités en mode de dépôt unique.  Ce minimum s''applique uniquement aux ajouts d''unités dont la modalité de paiement a comme mode de dépôt unique (Un_Modal.PmtQty = 1).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinUniqueDepCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement de configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinUniqueDepCfg', @level2type = N'COLUMN', @level2name = N'MinUniqueDepCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.  Pour connaître le minimum pour un nouveau groupe d''unités, il faut prendre l''enregistrement dont cette date est la plus élevé mais qui ne dépasse pas la date de vigueur du nouveau groupe d''unités.  Pour connaître le délai en vigueur aujourd''hui, il faut faire le même exercise en remplacant la date de vigueur du nouveau groupe d''unités par la date du jour.  Il est évident que le type du mode de dépôt de la modalité doit être Unique (Un.Modal.PmtQty = 1)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinUniqueDepCfg', @level2type = N'COLUMN', @level2name = N'Effectdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant minimum en épargnes et frais du dépôt unique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MinUniqueDepCfg', @level2type = N'COLUMN', @level2name = N'MinAmount';

