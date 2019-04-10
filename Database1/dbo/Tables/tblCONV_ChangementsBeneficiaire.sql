CREATE TABLE [dbo].[tblCONV_ChangementsBeneficiaire] (
    [iID_Changement_Beneficiaire]                            INT           IDENTITY (1, 1) NOT NULL,
    [iID_Convention]                                         INT           NOT NULL,
    [dtDate_Changement_Beneficiaire]                         DATETIME      NOT NULL,
    [iID_Nouveau_Beneficiaire]                               INT           NOT NULL,
    [tiID_Raison_Changement_Beneficiaire]                    TINYINT       NOT NULL,
    [vcAutre_Raison_Changement_Beneficiaire]                 VARCHAR (150) NULL,
    [bLien_Frere_Soeur_Avec_Ancien_Beneficiaire]             BIT           NULL,
    [bLien_Sang_Avec_Souscripteur_Initial]                   BIT           NULL,
    [tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire]   TINYINT       NULL,
    [tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire] TINYINT       NULL,
    [iID_Utilisateur_Creation]                               INT           NOT NULL,
    CONSTRAINT [PK_CONV_ChangementsBeneficiaire] PRIMARY KEY CLUSTERED ([iID_Changement_Beneficiaire] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CONV_ChangementsBeneficiaire_CONV_RaisonsChangementBeneficiaire__tiIDRaisonChangementBeneficiaire] FOREIGN KEY ([tiID_Raison_Changement_Beneficiaire]) REFERENCES [dbo].[tblCONV_RaisonsChangementBeneficiaire] ([tiID_Raison_Changement_Beneficiaire]),
    CONSTRAINT [FK_CONV_ChangementsBeneficiaire_Un_Convention__iIDConvention] FOREIGN KEY ([iID_Convention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_ChangementsBeneficiaire_iIDNouveauBeneficiaire]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([iID_Nouveau_Beneficiaire] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_ChangementsBeneficiaire_iIDConvention]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([iID_Convention] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_ChangementsBeneficiaire_dtDateChangementBeneficiaire]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([dtDate_Changement_Beneficiaire] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_ChangementsBeneficiaire_tiIDRaisonChangementBeneficiaire]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([tiID_Raison_Changement_Beneficiaire] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_ChangementsBeneficiaire_iIDConvention_dtDateChangementBeneficiaire_iIDChangementBeneficiaire]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([iID_Convention] ASC, [dtDate_Changement_Beneficiaire] ASC, [iID_Changement_Beneficiaire] ASC)
    INCLUDE([iID_Nouveau_Beneficiaire]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_ChangementsBeneficiaire_iIDConvention_dtDateChangementBeneficiaire_iIDChangementBeneficiaire_tiIDRaisonChangementBenefic]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([iID_Convention] ASC, [dtDate_Changement_Beneficiaire] ASC, [iID_Changement_Beneficiaire] ASC, [tiID_Raison_Changement_Beneficiaire] ASC)
    INCLUDE([bLien_Frere_Soeur_Avec_Ancien_Beneficiaire], [bLien_Sang_Avec_Souscripteur_Initial], [iID_Nouveau_Beneficiaire], [iID_Utilisateur_Creation], [tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire], [tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire], [vcAutre_Raison_Changement_Beneficiaire]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_ChangementsBeneficiaire_tiIDRaisonChangementBeneficiaire_dtDateChangementBeneficiaire_iIDConvention_iIDChangementBenefic]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([tiID_Raison_Changement_Beneficiaire] ASC, [dtDate_Changement_Beneficiaire] ASC, [iID_Convention] ASC, [iID_Changement_Beneficiaire] ASC)
    INCLUDE([bLien_Frere_Soeur_Avec_Ancien_Beneficiaire], [bLien_Sang_Avec_Souscripteur_Initial], [iID_Nouveau_Beneficiaire], [iID_Utilisateur_Creation], [tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire], [tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire], [vcAutre_Raison_Changement_Beneficiaire]) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [stat_tblCONV_ChangementsBeneficiaire_IQEE_1]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([dtDate_Changement_Beneficiaire], [iID_Convention]);


GO
CREATE STATISTICS [stat_tblCONV_ChangementsBeneficiaire_IQEE_2]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([iID_Changement_Beneficiaire], [dtDate_Changement_Beneficiaire]);


GO
CREATE STATISTICS [stat_tblCONV_ChangementsBeneficiaire_IQEE_3]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([iID_Changement_Beneficiaire], [iID_Convention], [dtDate_Changement_Beneficiaire]);


GO
CREATE STATISTICS [_dta_stat_1933458162_2_1_5]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([iID_Changement_Beneficiaire], [iID_Convention], [tiID_Raison_Changement_Beneficiaire]);


GO
CREATE STATISTICS [_dta_stat_1933458162_3_1]
    ON [dbo].[tblCONV_ChangementsBeneficiaire]([dtDate_Changement_Beneficiaire], [iID_Changement_Beneficiaire]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le bénéficiaire d''un changement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'INDEX', @level2name = N'IX_CONV_ChangementsBeneficiaire_iIDNouveauBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index des changements de bénéficiaire par convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'INDEX', @level2name = N'IX_CONV_ChangementsBeneficiaire_iIDConvention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la date de changement d''un bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'INDEX', @level2name = N'IX_CONV_ChangementsBeneficiaire_dtDateChangementBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la raison du changement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'INDEX', @level2name = N'IX_CONV_ChangementsBeneficiaire_tiIDRaisonChangementBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur la clé primaire des changements de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'CONSTRAINT', @level2name = N'PK_CONV_ChangementsBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les informations sur les changements de bénéficiaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un changement de bénéficiaire à une convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Changement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention faisant l''objet d''un changement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure du changement de bénéficiaire au système.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'dtDate_Changement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du nouveau bénéficiaire de la convention.  Note 2010-01-26: Il y a une petite quantité de changement de bénéficiaire pour lesquels il n''y a pas d''enregistrement dans la table "Un_Beneficiary".  Il sont par contre tous dans "Mo_Human".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la raison du changement de bénéficiaire.  La raison "INI" est utilisé pour le bénéficiaire initial lors de la création d''une nouvelle convention.  La raison "CON" a été utilisé pour la convention des données à partir du log d''UniAccès.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'tiID_Raison_Changement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la raison du changement de bénéficiaire si la raison sélectionnée est "Autre".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcAutre_Raison_Changement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si l''ancien bénéficiaire a un lien frère/soeur avec le nouveau bénéficiaire.  Ce champ sert à déterminer si le changement de bénéficiaire est non reconnu afin de rembourser les subventions.  Bien ce champ soit nullable, cette information est requise par l''IQÉÉ depuis le 1er janvier 2008 pour les conventions subventionnées en 2007.  Le champ est donc nul pour les changements de bénéficiaire avant cette date ou n''ayant pas fait l''objet d''une demande à l''IQÉÉ ou s''il s''agit du premier bénéficiaire de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'bLien_Frere_Soeur_Avec_Ancien_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur s''il y a un lien de sang entre le nouveau bénéficiaire et le souscripteur initial.  Ce champ sert à déterminer si le changement de bénéficiaire est non reconnu afin de rembourser les subventions.   Bien ce champ soit nullable, cette information est requise par l''IQÉÉ depuis le 1er janvier 2008 pour les conventions subventionnées en 2007.  Le champ est donc nul pour les changements de bénéficiaire avant cette date ou n''ayant pas fait l''objet d''une demande à l''IQÉÉ ou s''il s''agit du premier bénéficiaire de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'bLien_Sang_Avec_Souscripteur_Initial';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de relation entre le souscripteur et le nouveau bénéficiaire.  Bien ce champ soit nullable, cette information est requise par l''IQÉÉ depuis le 1er janvier 2008 pour les conventions subventionnées en 2007.  Le champ est donc nul pour les changements de bénéficiaire avant cette date ou n''ayant pas fait l''objet d''une demande à l''IQÉÉ ou s''il s''agit du premier bénéficiaire de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de relation entre le cosouscripteur et le nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''utilisateur qui a fait le changement de bénéficaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Creation';

