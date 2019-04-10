CREATE TABLE [dbo].[tblCONV_RevenusCohorte] (
    [dDate_Effective]         DATE  NOT NULL,
    [iID_Regroupement_Regime] INT   NOT NULL,
    [YearQualif]              INT   NOT NULL,
    [mRevenus_Cohorte]        MONEY CONSTRAINT [DF_tblCONV_RevenusCohorte_mRevenus_Cohorte] DEFAULT ((0)) NOT NULL,
    [mQuantite_Unite]         MONEY CONSTRAINT [DF_tblCONV_RevenusCohorte_mQuantite_Unite] DEFAULT ((0)) NOT NULL,
    [mRevenu_CohorteParUnite] MONEY CONSTRAINT [DF_RevenusCohorte_mRevenu_CohorteParUnite] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_tblCONV_RevenusCohorte] PRIMARY KEY CLUSTERED ([dDate_Effective] ASC, [iID_Regroupement_Regime] ASC, [YearQualif] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient les valeurs actualisées des revenus pour chacune des cohortes à une date donnée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenusCohorte';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date effective où ces valeurs peuvent être utilisées', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenusCohorte', @level2type = N'COLUMN', @level2name = N'dDate_Effective';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du regroupement de régime', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenusCohorte', @level2type = N'COLUMN', @level2name = N'iID_Regroupement_Regime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Année de qualification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenusCohorte', @level2type = N'COLUMN', @level2name = N'YearQualif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valuer des revenus de la cohorte', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenusCohorte', @level2type = N'COLUMN', @level2name = N'mRevenus_Cohorte';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Quantité d''unités actives dans la cohorte', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenusCohorte', @level2type = N'COLUMN', @level2name = N'mQuantite_Unite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeurs des revenus de la cohorte, par unité', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenusCohorte', @level2type = N'COLUMN', @level2name = N'mRevenu_CohorteParUnite';

