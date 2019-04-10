CREATE TABLE [dbo].[tblCONV_RaisonsChangementBeneficiaire] (
    [tiID_Raison_Changement_Beneficiaire] TINYINT       IDENTITY (1, 1) NOT NULL,
    [vcCode_Raison]                       VARCHAR (3)   NOT NULL,
    [vcDescription]                       VARCHAR (150) NOT NULL,
    [bSelectionnable_Utilisateur]         BIT           NOT NULL,
    [bRequiere_Complement_Information]    BIT           NOT NULL,
    [tiOrdre_Presentation]                TINYINT       NOT NULL,
    CONSTRAINT [PK_CONV_RaisonsChangementBeneficiaire] PRIMARY KEY CLUSTERED ([tiID_Raison_Changement_Beneficiaire] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_CONV_RaisonsChangementBeneficiaire_vcCodeRaison]
    ON [dbo].[tblCONV_RaisonsChangementBeneficiaire]([vcCode_Raison] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur le code de raison du changement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonsChangementBeneficiaire', @level2type = N'INDEX', @level2name = N'AK_CONV_RaisonsChangementBeneficiaire_vcCodeRaison';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur la clé primaire des raisons de changement d''un bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonsChangementBeneficiaire', @level2type = N'CONSTRAINT', @level2name = N'PK_CONV_RaisonsChangementBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des codes des raisons de changement de bénéficiaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonsChangementBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la raison du changement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonsChangementBeneficiaire', @level2type = N'COLUMN', @level2name = N'tiID_Raison_Changement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code interne unique d''une raison de changement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonsChangementBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcCode_Raison';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la raison de changement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonsChangementBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si l''utilisateur a le droit de sélectionner la raison du changement ou si elle est réservée à l''informatique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonsChangementBeneficiaire', @level2type = N'COLUMN', @level2name = N'bSelectionnable_Utilisateur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la raison de changement requière un complément d''information comme pour le choix "Autre".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonsChangementBeneficiaire', @level2type = N'COLUMN', @level2name = N'bRequiere_Complement_Information';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation des raisons de changement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RaisonsChangementBeneficiaire', @level2type = N'COLUMN', @level2name = N'tiOrdre_Presentation';

