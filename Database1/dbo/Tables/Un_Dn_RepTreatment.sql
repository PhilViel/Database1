CREATE TABLE [dbo].[Un_Dn_RepTreatment] (
    [RepTreatmentID]       [dbo].[MoID]         NOT NULL,
    [RepID]                [dbo].[MoID]         NOT NULL,
    [RepTreatmentDate]     [dbo].[MoGetDate]    NOT NULL,
    [FirstDepositDate]     [dbo].[MoGetDate]    NOT NULL,
    [InforceDate]          [dbo].[MoGetDate]    NOT NULL,
    [Subscriber]           [dbo].[MoDesc]       NOT NULL,
    [ConventionNo]         [dbo].[MoDesc]       NOT NULL,
    [RepName]              [dbo].[MoDesc]       NOT NULL,
    [RepCode]              [dbo].[MoDescoption] NULL,
    [RepLicenseNo]         [dbo].[MoDescoption] NULL,
    [RepRoleDesc]          [dbo].[MoDesc]       NOT NULL,
    [LevelShortDesc]       [dbo].[MoDescoption] NULL,
    [PeriodUnitQty]        [dbo].[MoMoney]      NOT NULL,
    [UnitQty]              [dbo].[MoMoney]      NOT NULL,
    [TotalFee]             [dbo].[MoMoney]      NOT NULL,
    [PeriodAdvance]        [dbo].[MoMoney]      NOT NULL,
    [CoverdAdvance]        [dbo].[MoMoney]      NOT NULL,
    [CumAdvance]           [dbo].[MoMoney]      NOT NULL,
    [ServiceComm]          [dbo].[MoMoney]      NOT NULL,
    [PeriodComm]           [dbo].[MoMoney]      NOT NULL,
    [CummComm]             [dbo].[MoMoney]      NOT NULL,
    [FuturComm]            [dbo].[MoMoney]      NOT NULL,
    [BusinessBonus]        [dbo].[MoMoney]      NOT NULL,
    [PeriodBusinessBonus]  [dbo].[MoMoney]      NOT NULL,
    [CummBusinessBonus]    [dbo].[MoMoney]      NOT NULL,
    [FuturBusinessBonus]   [dbo].[MoMoney]      NOT NULL,
    [SweepstakeBonusAjust] [dbo].[MoMoney]      NOT NULL,
    [PaidAmount]           [dbo].[MoMoney]      NOT NULL,
    [CommExpenses]         [dbo].[MoMoney]      NOT NULL,
    [Notes]                [dbo].[MoDesc]       NOT NULL,
    [UnitID]               INT                  NULL,
    [UnitRepID]            INT                  NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Dn_RepTreatment_RepTreatmentID]
    ON [dbo].[Un_Dn_RepTreatment]([RepTreatmentID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Dn_RepTreatment_RepID]
    ON [dbo].[Un_Dn_RepTreatment]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Dn_RepTreatment_RepTreatmentID_RepID]
    ON [dbo].[Un_Dn_RepTreatment]([RepTreatmentID] ASC, [RepID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table dénormalisé qui contient le détails des rapports de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du traitement de commissions (Un_RepTreatment) dont fait parti l''enregistrement du détail du rapport de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date du traitement de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'RepTreatmentDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date du premier dépôt du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'FirstDepositDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'InforceDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom, Prénom du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'Subscriber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'ConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom, Prénom du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'RepName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'RepCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de license du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'RepLicenseNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom long du rôle du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'RepRoleDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description courte du niveau du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'LevelShortDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de nouvelles unités de la période couverte par le traitement pour cette convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'PeriodUnitQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre d''unités du groupe d''unités à la fin de la période.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'UnitQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de frais total pour le groupe d''unités à la fin de la période.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'TotalFee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Avances émises dans ce traitement pour ce groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'PeriodAdvance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Avances couvertes dans ce traitement pour ce groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'CoverdAdvance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Total d''avances non-couvertes à la fin de ce traitement pour ce groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'CumAdvance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Commission de service dont le représentant aura le droit pour ces unités s''il ne sont pas résiliés dans le futur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'ServiceComm';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Commission de service payés dans la période pour ces unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'PeriodComm';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Commissions de service total payées à la fin de la période (incluant les traitements précédents) pour ces unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'CummComm';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Commission de service à venir à la fin de la période couverte par ce traitement. (ServiceComm - CummComm)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'FuturComm';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Bonis d''assurance dont le représentant aura le droit pour ces unités s''il ne sont pas résiliés dans le futur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'BusinessBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Bonis d''assurance payés dans la période pour ces unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'PeriodBusinessBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Bonis d''assurance total payées à la fin de la période (incluant les traitements précédents) pour ces unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'CummBusinessBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Bonis d''assurance à venir à la fin de la période couverte par ce traitement. (BusinessBonus - CummBusinessBonus)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'FuturBusinessBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Bonis, concours, ajustements de la période couverte par ce traitement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'SweepstakeBonusAjust';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant payés. C''est les commissions de service de la période (PeriodComm) + les bonis d''afaire de la période (BusinessBonusComm)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'PaidAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Dépense de commissions de la période pour ces unités.  C''est les commissions de service de la période (PeriodComm) + les bonis d''afaire de la période (BusinessBonusComm) + les avances couvertes de la période (CoverdAdvance)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'CommExpenses';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Notes sur des évènements spéciaux de la période : TFR = Transfert de frais, RES pour résiliation et NSF pour effets retournées.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'Notes';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du groupe d''unité', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du représentant associé au groupe d''unité au moment où le calcul a été effectué.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatment', @level2type = N'COLUMN', @level2name = N'UnitRepID';

