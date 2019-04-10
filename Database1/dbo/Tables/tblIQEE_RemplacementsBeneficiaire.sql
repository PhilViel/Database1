CREATE TABLE [dbo].[tblIQEE_RemplacementsBeneficiaire] (
    [iID_Remplacement_Beneficiaire]                        INT          IDENTITY (1, 1) NOT NULL,
    [iID_Fichier_IQEE]                                     INT          NOT NULL,
    [tiCode_Version]                                       TINYINT      NOT NULL,
    [cStatut_Reponse]                                      CHAR (1)     NOT NULL,
    [iID_Convention]                                       INT          NOT NULL,
    [vcNo_Convention]                                      VARCHAR (15) NOT NULL,
    [iID_Changement_Beneficiaire]                          INT          NOT NULL,
    [dtDate_Remplacement]                                  DATETIME     NOT NULL,
    [bInd_Remplacement_Reconnu]                            BIT          NOT NULL,
    [bLien_Frere_Soeur]                                    BIT          NOT NULL,
    [iID_Ancien_Beneficiaire]                              INT          NOT NULL,
    [vcNAS_Ancien_Beneficiaire]                            VARCHAR (9)  NOT NULL,
    [vcNom_Ancien_Beneficiaire]                            VARCHAR (20) NOT NULL,
    [vcPrenom_Ancien_Beneficiaire]                         VARCHAR (20) NOT NULL,
    [dtDate_Naissance_Ancien_Beneficiaire]                 DATETIME     NOT NULL,
    [tiSexe_Ancien_Beneficiaire]                           TINYINT      NOT NULL,
    [iID_Nouveau_Beneficiaire]                             INT          NOT NULL,
    [vcNAS_Nouveau_Beneficiaire]                           VARCHAR (9)  NOT NULL,
    [vcNom_Nouveau_Beneficiaire]                           VARCHAR (20) NOT NULL,
    [vcPrenom_Nouveau_Beneficiaire]                        VARCHAR (20) NOT NULL,
    [dtDate_Naissance_Nouveau_Beneficiaire]                DATETIME     NOT NULL,
    [tiSexe_Nouveau_Beneficiaire]                          TINYINT      NOT NULL,
    [tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire] TINYINT      NOT NULL,
    [bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial] BIT          NOT NULL,
    [iID_Adresse_Beneficiaire_Date_Remplacement]           INT          NOT NULL,
    [vcAppartement_Beneficiaire]                           VARCHAR (6)  NULL,
    [vcNo_Civique_Beneficiaire]                            VARCHAR (10) NOT NULL,
    [vcRue_Beneficiaire]                                   VARCHAR (50) NOT NULL,
    [vcLigneAdresse2_Beneficiaire]                         VARCHAR (14) NULL,
    [vcLigneAdresse3_Beneficiaire]                         VARCHAR (40) NULL,
    [vcVille_Beneficiaire]                                 VARCHAR (30) NOT NULL,
    [vcProvince_Beneficiaire]                              VARCHAR (2)  NULL,
    [vcPays_Beneficiaire]                                  VARCHAR (3)  NOT NULL,
    [vcCodePostal_Beneficiaire]                            VARCHAR (10) NOT NULL,
    [bResidence_Quebec]                                    BIT          NULL,
    [iID_Ligne_Fichier]                                    INT          NULL,
    [siAnnee_Fiscale]                                      INT          NOT NULL,
    CONSTRAINT [PK_IQEE_RemplacementsBeneficiaire] PRIMARY KEY CLUSTERED ([iID_Remplacement_Beneficiaire] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_RemplacementsBeneficiaire_Convention__iIDConvention] FOREIGN KEY ([iID_Convention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_IQEE_RemplacementsBeneficiaire_IQEE_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_RemplacementsBeneficiaires_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_RemplacementsBeneficiaire]([iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Remplacement_Beneficiaire] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_RemplacementsBeneficiaires_vcNoConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_RemplacementsBeneficiaire]([vcNo_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Remplacement_Beneficiaire] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_RemplacementsBeneficiaires_siAnnee_Fiscale]
    ON [dbo].[tblIQEE_RemplacementsBeneficiaire]([siAnnee_Fiscale] ASC, [iID_Fichier_IQEE] ASC, [iID_Remplacement_Beneficiaire] ASC)
    INCLUDE([iID_Changement_Beneficiaire], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_RemplacementsBeneficiaires_iIDNouveauBeneficiaire_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_RemplacementsBeneficiaire]([iID_Nouveau_Beneficiaire] ASC, [iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Remplacement_Beneficiaire] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse], [iID_Ancien_Beneficiaire]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_RemplacementsBeneficiaires_iIDChangementBeneficiaire_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_RemplacementsBeneficiaire]([iID_Changement_Beneficiaire] ASC, [iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Remplacement_Beneficiaire] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse], [iID_Ancien_Beneficiaire]);


GO
CREATE NONCLUSTERED INDEX [ixIQEE_RemplacementsBeneficiaire__iIDFichier_siAnneeFiscale]
    ON [dbo].[tblIQEE_RemplacementsBeneficiaire]([iID_Fichier_IQEE] ASC, [siAnnee_Fiscale] ASC)
    INCLUDE([iID_Remplacement_Beneficiaire], [tiCode_Version], [cStatut_Reponse]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de l''identifiant unique d''une transaction de type 03 - Remplacement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_RemplacementsBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique des transactions de type 03 - Remplacement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une transaction de type 03 - Remplacement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Remplacement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du fichier de transactions de l''IQÉÉ associé à la transaction de type 03.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Fichier_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de version de la transaction.  Il fait référence à la table "tblIQEE_VersionsTransaction".  0=Originale, 1=Annulation, 2=Reprise', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'tiCode_Version';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statut de la transaction.  Il correspond à la table de référence "tblIQEE_StatutsTransaction"   A=En attente d''une réponse, E=En erreur, R=Réponse reçue (positive ou négative), D=Annulation en attente d''une réponse, T=Transaction annulée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'cStatut_Reponse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention fesant l''objet d''un changement de bénédiciaire.  La convention doit être connue de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de la convention fesant l''objet d''un changement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcNo_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un changement de bénéficiaire à une convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Changement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date du remplacement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'dtDate_Remplacement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si le remplacement est reconnu ou non pour RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'bInd_Remplacement_Reconnu';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si l''ancien bénéficiaire a un lien frère/soeur avec le nouveau bénéficiaire.  Ce champ sert à déterminer si le changement de bénéficiaire est non reconnu afin de rembourser les subventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'bLien_Frere_Soeur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''ancien bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Ancien_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS de l''ancien bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcNAS_Ancien_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de l''ancien bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcNom_Ancien_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom de l''ancien bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcPrenom_Ancien_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de naissance de l''ancien bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'dtDate_Naissance_Ancien_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Sexe de l''ancien bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'tiSexe_Ancien_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcNAS_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcNom_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcPrenom_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de naissance du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'dtDate_Naissance_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Sexe du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'tiSexe_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de relation entre le souscripteur et le nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur s''il y a un lien de sang entre le nouveau bénéficiaire et le souscripteur initial.  Ce champ sert à déterminer si le changement de bénéficiaire est non reconnu afin de rembourser les subventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''adresse  du nouveau bénéficiaire en date du remplacement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Adresse_Beneficiaire_Date_Remplacement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''appartement du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcAppartement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro civique du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcNo_Civique_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Rue du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcRue_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 2 du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse2_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 3 du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse3_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ville du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcVille_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de province du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcProvince_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Pays du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcPays_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code postal du nouveau bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'vcCodePostal_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si le nouveau bénéficiaire est résident du Québec ou non au moment du remplacement de bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'bResidence_Quebec';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la ligne correspondante à la transaction du fichier physique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_RemplacementsBeneficiaire', @level2type = N'COLUMN', @level2name = N'iID_Ligne_Fichier';

