CREATE TABLE [dbo].[Un_RepFormationFeeCfg] (
    [RepFormationFeeCfgID] [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [StartDate]            [dbo].[MoGetDate] NOT NULL,
    [FormationFeeAmount]   [dbo].[MoMoney]   NOT NULL,
    CONSTRAINT [PK_Un_RepFormationFeeCfg] PRIMARY KEY CLUSTERED ([RepFormationFeeCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de configuration des frais de formations.  Des frais de X$ par unités sont inscrit en retenu au directeur du représentant qui a fait la vente si le premier dépôt a eu lieu lors de la période couverte par le traitement de commissions.  Cette table déféni le X$.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepFormationFeeCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepFormationFeeCfg', @level2type = N'COLUMN', @level2name = N'RepFormationFeeCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.  Pour savoir celle a utiliser pour connaître les frais de formation d''un groupe d''unités, il faut prendre celle dont cette date est la plus élevé parmis celles dont cette date est plus petit ou égal à la date d''entrée en vigueur du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepFormationFeeCfg', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de frais de formation retenus par unités pour cette configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepFormationFeeCfg', @level2type = N'COLUMN', @level2name = N'FormationFeeAmount';

