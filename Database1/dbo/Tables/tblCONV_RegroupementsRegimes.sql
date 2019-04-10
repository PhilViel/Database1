CREATE TABLE [dbo].[tblCONV_RegroupementsRegimes] (
    [iID_Regroupement_Regime]         INT          IDENTITY (1, 1) NOT NULL,
    [vcCode_Regroupement]             VARCHAR (3)  NOT NULL,
    [vcDescription]                   VARCHAR (50) NOT NULL,
    [vcCode_Compte_Comptable_Fiducie] VARCHAR (12) NOT NULL,
    [vcCode_Chequier_GreatPlains]     VARCHAR (50) NULL,
    [NumeroCompteBancaire]            VARCHAR (20) NULL,
    [NumeroGRADS]                     VARCHAR (20) NULL,
    [FournisseurServiceFinancierID]   INT          CONSTRAINT [DF_CONV_RegroupementsRegimes_FournisseurServiceFinancierID] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CONV_RegroupementsRegimes] PRIMARY KEY CLUSTERED ([iID_Regroupement_Regime] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_CONV_RegroupementsRegimes_vcCodeRegroupement]
    ON [dbo].[tblCONV_RegroupementsRegimes]([vcCode_Regroupement] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code de regroupement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RegroupementsRegimes', @level2type = N'INDEX', @level2name = N'AK_CONV_RegroupementsRegimes_vcCodeRegroupement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant des regroupements de régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RegroupementsRegimes', @level2type = N'CONSTRAINT', @level2name = N'PK_CONV_RegroupementsRegimes';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Les regroupements de régime sont la représentation  des "régimes" pour les utilisateurs, les gestionnaires de GUI et pour les clients.  Les régimes dans UniAccès (Un_Plan) peuvent être scindé en plusieurs enregistrements pour des raisons de paramètrages.  Exemple: Sélect 2000, Plan B et Universitas font partie du regroupement de régimes "Universitas".  ReeeFlex et ReeeFlex 2010 font partie du regroupement de régime "ReeeFlex".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RegroupementsRegimes';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du regroupement de régime.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RegroupementsRegimes', @level2type = N'COLUMN', @level2name = N'iID_Regroupement_Regime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code interne identifiant de façon unique un regroupement de régimes et pouvant être codé en dur dans le code.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RegroupementsRegimes', @level2type = N'COLUMN', @level2name = N'vcCode_Regroupement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du regroupement de régime.  Cette description correspond à la notion de "Régime" pour les utilisateurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RegroupementsRegimes', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du compte comptable de la banque de la fiducie du regroupement de régime.  Le code est utilisé pour déterminer le numéro comptable pour la banque dans le module des chèques puisse que les chèques sont créés/fusionnés par regroupement de régime.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RegroupementsRegimes', @level2type = N'COLUMN', @level2name = N'vcCode_Compte_Comptable_Fiducie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du chéquier correspondant à ce regroupement de régime dans Great Plains. Le code est utilisé par l''application Integration Manager.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RegroupementsRegimes', @level2type = N'COLUMN', @level2name = N'vcCode_Chequier_GreatPlains';

