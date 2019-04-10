CREATE TABLE [dbo].[Un_RepProjection] (
    [RepProjectionDate]    [dbo].[MoDate]       NOT NULL,
    [RepID]                [dbo].[MoID]         NOT NULL,
    [RepLevelID]           [dbo].[MoID]         NOT NULL,
    [ConventionID]         [dbo].[MoID]         NOT NULL,
    [FirstDepositDate]     [dbo].[MoDate]       NOT NULL,
    [InForceDate]          [dbo].[MoDate]       NOT NULL,
    [SubscriberName]       [dbo].[MoDesc]       NOT NULL,
    [ConventionNo]         [dbo].[MoDesc]       NOT NULL,
    [RepName]              [dbo].[MoDesc]       NOT NULL,
    [RepCode]              [dbo].[MoDescoption] NULL,
    [RepLicenseNo]         [dbo].[MoDescoption] NULL,
    [RepRoleDesc]          [dbo].[MoDesc]       NOT NULL,
    [RepLevelShortDesc]    [dbo].[MoDescoption] NULL,
    [UnitQty]              [dbo].[MoMoney]      NOT NULL,
    [TotalFee]             [dbo].[MoMoney]      NOT NULL,
    [CoverdAdvance]        [dbo].[MoMoney]      NOT NULL,
    [ServiceComm]          [dbo].[MoMoney]      NOT NULL,
    [PeriodComm]           [dbo].[MoMoney]      NOT NULL,
    [CumComm]              [dbo].[MoMoney]      NOT NULL,
    [ServiceBusinessBonus] [dbo].[MoMoney]      NOT NULL,
    [PeriodBusinessBonus]  [dbo].[MoMoney]      NOT NULL,
    [CumBusinessBonus]     [dbo].[MoMoney]      NOT NULL,
    [PaidAmount]           [dbo].[MoMoney]      NOT NULL,
    [CommExpenses]         [dbo].[MoMoney]      NOT NULL,
    [UnitID]               INT                  NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepProjection_RepProjectionDate_RepID_RepLevelID_ConventionID]
    ON [dbo].[Un_RepProjection]([RepProjectionDate] ASC, [RepID] ASC, [RepLevelID] ASC, [ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de détail du rapport des projections.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la projection. Permet aussi d''identifier à qu''elle projection l''enregistrement appartient', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'RepProjectionDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) auquel appartient cette projection de commission', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du niveau (Un_RepLevelID) du représentant à la date d''entrée en vigueur de ce groupe d''unités auquel appartient cette projection de commission', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'RepLevelID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la convention (Un_Convention) pour laquelle le représentant reçoit cette projection de commission', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date du premier dépôt du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'FirstDepositDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'InForceDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du souscripteur suivi d''une virgule, d''un espace et de son prénom.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'SubscriberName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'ConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du représentant suivi d''une virgule, d''un espace et de son prénom.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'RepName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'RepCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de license de vendeur du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'RepLicenseNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Rôle du représentant pour ce détail de projection.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'RepRoleDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Abbréviation du niveau du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'RepLevelShortDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre d''unités qu''avait le groupe lors de la projection.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'UnitQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant total de frais estimé par la projection à cette date (RepProjection).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'TotalFee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''avances couverte projetés pour ce groupe d''unités à cette date (RepProjection).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'CoverdAdvance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de commissions de service auquel ce représentant a le droit pour ce groupe d''unités s''il n''est pas résilié en date du dernier traitement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'ServiceComm';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de commissions de service projecté pour cette ce groupe d''unités à cette date de traitement (RepProjectionDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'PeriodComm';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de cumulatif de commissions de service projecté pour cette ce groupe d''unités à cette date de traitement (RepProjectionDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'CumComm';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de boni d''affaire auquel ce représentant a le droit pour ce groupe d''unités, si ce dernier n''est pas résilié en date du dernier traitement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'ServiceBusinessBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de boni d''affaire projecté pour cette ce groupe d''unités à cette date de traitement (RepProjectionDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'PeriodBusinessBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de cumulatif de boni d''affaire projecté pour cette ce groupe d''unités à cette date de traitement (RepProjectionDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'CumBusinessBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de la paye projecté pour cette date de traitement (RepProjectionDate). C''est les commissions de service de la période (PeriodComm) + les bonis d''afaire de la période (PeriodBusinessBonus).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'PaidAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de la dépense de commission projecté pour cette date de traitement (RepProjectionDate).  C''est les commissions de service de la période (PeriodComm) + les bonis d''afaire de la période (PeriodBusinessBonus) + les avances couvertes de la période (CoverdAdvance).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjection', @level2type = N'COLUMN', @level2name = N'CommExpenses';

