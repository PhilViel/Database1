CREATE TABLE [dbo].[tblCONV_FacteurConversion] (
    [iID_FacteurConv]        INT            IDENTITY (1, 1) NOT NULL,
    [iID_Plan]               INT            NOT NULL,
    [dtDate_DebutModalite]   DATE           NOT NULL,
    [dtDate_FinModalite]     DATE           NULL,
    [iAnnee_DebutQualif]     INT            NOT NULL,
    [iAnnee_FinQualif]       INT            NULL,
    [dFacteurConv]           DECIMAL (5, 2) NOT NULL,
    [iNb_JourSupplementaire] INT            CONSTRAINT [DF_tblCONV_FacteurConversion_iNb_JourPeriodeSupplementaire] DEFAULT ((15)) NOT NULL,
    CONSTRAINT [PK_CONV_FacteurConversion] PRIMARY KEY CLUSTERED ([iID_FacteurConv] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CONV_FacteurConversion_Un_Plan__iIDPlan] FOREIGN KEY ([iID_Plan]) REFERENCES [dbo].[Un_Plan] ([PlanID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique des facteurs de conversion d''unités admissible au PAE.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_FacteurConversion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du facteur de conversion (automatique).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_FacteurConversion', @level2type = N'COLUMN', @level2name = N'iID_FacteurConv';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_FacteurConversion', @level2type = N'COLUMN', @level2name = N'iID_Plan';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de début de l''intervalle des modalités de dépôt pour l''utilisation du facteur de conversion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_FacteurConversion', @level2type = N'COLUMN', @level2name = N'dtDate_DebutModalite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de fin de l''intervalle des modalités de dépôt pour l''utilisation du facteur de conversion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_FacteurConversion', @level2type = N'COLUMN', @level2name = N'dtDate_FinModalite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Année de début de l''intervalle de la cohorte du premier PAE (Un_Convention.iAnnee_DebutQualifPremierPAE, sinon Un_Beneficiray.iAnnee_AdmissiblePAE) pour l''utilisation du facteur de conversion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_FacteurConversion', @level2type = N'COLUMN', @level2name = N'iAnnee_DebutQualif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Année de fin de l''intervalle de la cohorte du premier PAE (Un_Convention.iAnnee_DebutQualifPremierPAE, sinon Un_Beneficiray.iAnnee_AdmissiblePAE) pour l''utilisation du facteur de conversion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_FacteurConversion', @level2type = N'COLUMN', @level2name = N'iAnnee_FinQualif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Facteur de conversion des unités admissible au PAE.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_FacteurConversion', @level2type = N'COLUMN', @level2name = N'dFacteurConv';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre de jours supplémentaires alloué comme période de grâce, pour la validation de la date de signmature et la date de début des opérations financières.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_FacteurConversion', @level2type = N'COLUMN', @level2name = N'iNb_JourSupplementaire';

