CREATE TABLE [dbo].[tblCONV_RistournesAssurance] (
    [iID_RistourneAss]       INT   IDENTITY (1, 1) NOT NULL,
    [iID_Plan]               INT   NOT NULL,
    [dtDate_DebutModalite]   DATE  NOT NULL,
    [dtDate_FinModalite]     DATE  NULL,
    [iAnnee_DebutQualif]     INT   NOT NULL,
    [iAnnee_FinQualif]       INT   NULL,
    [mRistourneAss]          MONEY NOT NULL,
    [bValiderAssSousc]       BIT   CONSTRAINT [DF_CONV_RistournesAssurance_bValiderAssSousc] DEFAULT ((0)) NOT NULL,
    [iNb_JourSupplementaire] INT   CONSTRAINT [DF_tblCONV_RistournesAssurance_iNb_JourSupplementaire] DEFAULT ((15)) NOT NULL,
    CONSTRAINT [PK_CONV_RistournesAssurance] PRIMARY KEY CLUSTERED ([iID_RistourneAss] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique des primes de ristourne versées pour chaque unité souscrite lors des PAE. ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de la ristourne d''assurance (automatique).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance', @level2type = N'COLUMN', @level2name = N'iID_RistourneAss';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du plan (régime) pour lequel s''applique cette ristourne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance', @level2type = N'COLUMN', @level2name = N'iID_Plan';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de début d''utilisation de cette prime de ristourne d''assurance, selon la date de la modalité des unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance', @level2type = N'COLUMN', @level2name = N'dtDate_DebutModalite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de fin d''utilisation de cette prime de ristoure d''assurance, selon la date de la modalité des unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance', @level2type = N'COLUMN', @level2name = N'dtDate_FinModalite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Année de début de l''intervalle de la cohorte du premier PAE (Un_Convention.iAnnee_DebutQualifPremierPAE, sinon Un_Beneficiray.iAnnee_AdmissiblePAE) pour l''utilisation de la ristourne d''assurance.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance', @level2type = N'COLUMN', @level2name = N'iAnnee_DebutQualif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Année de fin de l''intervalle de la cohorte du premier PAE (Un_Convention.iAnnee_DebutQualifPremierPAE, sinon Un_Beneficiray.iAnnee_AdmissiblePAE) pour l''utilisation de la ristourne d''assurance.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance', @level2type = N'COLUMN', @level2name = N'iAnnee_FinQualif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de la prime de ristourne pour chaque unité souscrite.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance', @level2type = N'COLUMN', @level2name = N'mRistourneAss';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si on doit valider si le souscripteur a payé ou non de l''assurances (WantSubscriberInsurance dans Uni_Unit et SubscriberInsuranceRate dans Un_Modal).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance', @level2type = N'COLUMN', @level2name = N'bValiderAssSousc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre de jours supplémentaires alloué comme période de grâce, pour la validation de la date de signmature et la date de début des opérations financières.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RistournesAssurance', @level2type = N'COLUMN', @level2name = N'iNb_JourSupplementaire';

