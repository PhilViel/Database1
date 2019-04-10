CREATE TABLE [dbo].[tblREPR_CumulatifsGreatPlains] (
    [iID_CumulatifGP] INT          IDENTITY (1, 1) NOT NULL,
    [RepTreatmentID]  INT          NULL,
    [RepCode]         VARCHAR (75) NOT NULL,
    [Nom_Rep]         VARCHAR (50) NULL,
    [Prenom_Rep]      VARCHAR (35) NULL,
    [COMDIF]          FLOAT (53)   NULL,
    [COMFIX]          FLOAT (53)   NULL,
    [DUIPAD]          FLOAT (53)   NULL,
    CONSTRAINT [PK_REPR_CumulatifsGreatPlains] PRIMARY KEY CLUSTERED ([iID_CumulatifGP] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_REPR_CumulatifsGreatPlains_RepTreatmentID_RepCode]
    ON [dbo].[tblREPR_CumulatifsGreatPlains]([RepTreatmentID] ASC, [RepCode] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cumulatifs de Great Plains par représentant, au moment où le traitement des commisisons à été calculé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CumulatifsGreatPlains';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro du traitement de commissions associé à ce solde', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CumulatifsGreatPlains', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du représentant dans Great Plains', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CumulatifsGreatPlains', @level2type = N'COLUMN', @level2name = N'RepCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de famille du représentant', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CumulatifsGreatPlains', @level2type = N'COLUMN', @level2name = N'Nom_Rep';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du représentant', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CumulatifsGreatPlains', @level2type = N'COLUMN', @level2name = N'Prenom_Rep';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cumulatif à la date du traitement de commissions pour le compte COMDIF, avant que ce traitement soit payé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CumulatifsGreatPlains', @level2type = N'COLUMN', @level2name = N'COMDIF';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cumulatif à la date du traitement de commissions pour le compte COMFIX, avant que ce traitement soit payé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_CumulatifsGreatPlains', @level2type = N'COLUMN', @level2name = N'COMFIX';

