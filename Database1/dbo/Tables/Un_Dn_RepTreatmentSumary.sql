CREATE TABLE [dbo].[Un_Dn_RepTreatmentSumary] (
    [RepTreatmentID]   [dbo].[MoID]         NOT NULL,
    [RepID]            [dbo].[MoID]         NOT NULL,
    [TreatmentYear]    [dbo].[MoID]         NOT NULL,
    [RepCode]          [dbo].[MoDescoption] NULL,
    [RepName]          [dbo].[MoDesc]       NOT NULL,
    [RepTreatmentDate] [dbo].[MoGetDate]    NOT NULL,
    [REPPeriodUnit]    [dbo].[MoMoney]      NOT NULL,
    [CumREPPeriodUnit] [dbo].[MoMoney]      NOT NULL,
    [DIRPeriodUnit]    [dbo].[MoMoney]      NOT NULL,
    [CumDIRPeriodUnit] [dbo].[MoMoney]      NOT NULL,
    [REPConsPct]       [dbo].[MoMoney]      NOT NULL,
    [DIRConsPct]       [dbo].[MoMoney]      NOT NULL,
    [ConsPct]          [dbo].[MoMoney]      NOT NULL,
    [BusinessBonus]    [dbo].[MoMoney]      NOT NULL,
    [CoveredAdvance]   [dbo].[MoMoney]      NOT NULL,
    [NewAdvance]       [dbo].[MoMoney]      NOT NULL,
    [CommANDBonus]     [dbo].[MoMoney]      NOT NULL,
    [Adjustment]       [dbo].[MoMoney]      NOT NULL,
    [ChqBrut]          [dbo].[MoMoney]      NOT NULL,
    [CumChqBrut]       [dbo].[MoMoney]      NOT NULL,
    [Retenu]           [dbo].[MoMoney]      NOT NULL,
    [ChqNet]           [dbo].[MoMoney]      NOT NULL,
    [Mois]             [dbo].[MoMoney]      NOT NULL,
    [CumMois]          [dbo].[MoMoney]      NOT NULL,
    [Advance]          [dbo].[MoMoney]      NOT NULL,
    [FuturCom]         [dbo].[MoMoney]      NOT NULL,
    [CommPct]          [dbo].[MoMoney]      NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Dn_RepTreatmentSumary_RepTreatmentID]
    ON [dbo].[Un_Dn_RepTreatmentSumary]([RepTreatmentID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Dn_RepTreatmentSumary_RepID]
    ON [dbo].[Un_Dn_RepTreatmentSumary]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Dn_RepTreatmentSumary_RepTreatmentID_RepTreatmentDate_RepID_RepName]
    ON [dbo].[Un_Dn_RepTreatmentSumary]([RepTreatmentID] ASC, [RepTreatmentDate] ASC, [RepID] ASC, [RepName] ASC)
    INCLUDE([CoveredAdvance], [NewAdvance], [CommANDBonus], [Adjustment], [Retenu], [ChqNet], [Advance]) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [_dta_stat_281208202_6_1]
    ON [dbo].[Un_Dn_RepTreatmentSumary]([RepTreatmentDate], [RepTreatmentID]);


GO
CREATE STATISTICS [_dta_stat_281208202_2_6]
    ON [dbo].[Un_Dn_RepTreatmentSumary]([RepID], [RepTreatmentDate]);


GO
CREATE STATISTICS [_dta_stat_281208202_5_2]
    ON [dbo].[Un_Dn_RepTreatmentSumary]([RepName], [RepID]);


GO
CREATE STATISTICS [_dta_stat_281208202_1_5_2]
    ON [dbo].[Un_Dn_RepTreatmentSumary]([RepTreatmentID], [RepName], [RepID]);


GO
CREATE STATISTICS [_dta_stat_281208202_1_2_6_5]
    ON [dbo].[Un_Dn_RepTreatmentSumary]([RepTreatmentID], [RepID], [RepTreatmentDate], [RepName]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table dénormalisé qui contient les sommaires des rapports de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du traitement de commissions (Un_RepTreatment) dont fait parti l''enregistrement de sommaire du rapport de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) à qui appartient l''enregistrement de sommaire du rapport de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Année de traitement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'TreatmentYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code unique du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'RepCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom et prénom du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'RepName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Le sommaire du rapport des commissions donne non seulement le sommaire du traitement courant mais aussi celui de tout les traitements précédent de l''année.  Dans ce cas cette date est la date du traitement de commissions appartenantau sommaire, donc pas nécessairement la date date correspondant avec le RepTreatmentID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'RepTreatmentDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de nouvelle unités vendus en tant que représentant dans la période du RepTreatmentDate.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'REPPeriodUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de nouvelle unités vendus en tant que représentant depuis le début de l''année jusqu''à la date du RepTreatmentDate.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'CumREPPeriodUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de nouvelle unités vendus en tant que directeur dans la période couverte par le traitement correspondant à la RepTreatmentDate.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'DIRPeriodUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de nouvelle unités vendus en tant que directeur depuis le début de l''année jusqu''à la date du RepTreatmentDate.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'CumDIRPeriodUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage de conservation en tant que représentant pour la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'REPConsPct';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage de conservation en tant que directeur pour la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'DIRConsPct';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage de conservation total (représentant et directeur) pour la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'ConsPct';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de nouveau bonis d''affaire versée pour la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'BusinessBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de nouvelle avances versées pour la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'NewAdvance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de nouveau bonis d''affaires et de nouvelles commissions de service versées pour la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'CommANDBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant des nouveaux ajustements pour la période (RepTreatmentDate).  Un ajustement ce sont des montants enlevés ou ajoutés à la payes qui sont inclus dans le cheque brut, montant imposable et considéré comme une commission. (Ex : Allocation de formation, dernière paye versée en double, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'Adjustment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant du cheque brut pour la période (RepTreatmentDate). NewAdvance + CommAndBonus + Adjustment', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'ChqBrut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Somme des chèques brutes depuis le début de l''année jusqu''à la fin de la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'CumChqBrut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant des nouvelles retenues pour la période (RepTreatmentDate).  Des retenues ce sont des montants enlevés ou ajoutés à la payes qui ne sont pas inclus dans le cheque brut. (Ex : Paiement de pension, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'Retenu';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant que le représentant reçoit pour la période (RepTreatmentDate).  ChqBrut + Retenu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'ChqNet';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Dépense de commissions pour la période (RepTreatmentDate).  CommAndBonus + Adjustement + CoveredAdvance', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'Mois';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Dépense de commissions du début de l''année jusqu''à la fin de la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'CumMois';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''avance non couverte à la fin de la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'Advance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Commission de service à recevoir et avances non couverte à la fin de la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'FuturCom';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage de commissions = Avances non couverte à la fin de la période (RepTreatmentDate) / Commission de service à recevoir et avances non couverte à la fin de la période (RepTreatmentDate).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Dn_RepTreatmentSumary', @level2type = N'COLUMN', @level2name = N'CommPct';

