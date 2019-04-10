CREATE TABLE [dbo].[tblIQEE_Validations] (
    [iID_Validation]                   INT           IDENTITY (1, 1) NOT NULL,
    [tiID_Type_Enregistrement]         TINYINT       NOT NULL,
    [iID_Sous_Type]                    INT           NULL,
    [iCode_Validation]                 INT           NOT NULL,
    [vcDescription]                    VARCHAR (300) NOT NULL,
    [vcDescription_Parametrable]       VARCHAR (300) NOT NULL,
    [bActif]                           BIT           NOT NULL,
    [bValidation_Speciale]             BIT           NOT NULL,
    [cType]                            CHAR (1)      NOT NULL,
    [bCorrection_Possible]             BIT           NOT NULL,
    [iOrdre_Presentation]              INT           NOT NULL,
    [vcDescription_Valeur_Reference]   VARCHAR (100) NULL,
    [vcDescription_Valeur_Erreur]      VARCHAR (100) NULL,
    [vcDescription_Lien_Vers_Erreur_1] VARCHAR (100) NULL,
    [vcDescription_Lien_Vers_Erreur_2] VARCHAR (100) NULL,
    [vcDescription_Lien_Vers_Erreur_3] VARCHAR (100) NULL,
    [tiID_Categorie_Element]           TINYINT       NOT NULL,
    [tiID_Categorie_Erreur]            TINYINT       NOT NULL,
    [bInformation_Manquante]           BIT           NOT NULL,
    CONSTRAINT [PK_IQEE_Validations] PRIMARY KEY CLUSTERED ([iID_Validation] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_Validations_IQEE_CategoriesElements__tiIDCategorieElement] FOREIGN KEY ([tiID_Categorie_Element]) REFERENCES [dbo].[tblIQEE_CategoriesElements] ([tiID_Categorie_Element]),
    CONSTRAINT [FK_IQEE_Validations_IQEE_CategoriesErreur__tiIDCategorieErreur] FOREIGN KEY ([tiID_Categorie_Erreur]) REFERENCES [dbo].[tblIQEE_CategoriesErreur] ([tiID_Categorie_Erreur]),
    CONSTRAINT [FK_IQEE_Validations_IQEE_SousTypeEnregistrement__iIDSousType] FOREIGN KEY ([iID_Sous_Type]) REFERENCES [dbo].[tblIQEE_SousTypeEnregistrement] ([iID_Sous_Type]),
    CONSTRAINT [FK_IQEE_Validations_IQEE_TypesEnregistrement__tiIDTypeEnregistrement] FOREIGN KEY ([tiID_Type_Enregistrement]) REFERENCES [dbo].[tblIQEE_TypesEnregistrement] ([tiID_Type_Enregistrement])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_Validations_IDTypeEnregistrement_iIDSousType_iCodeValidation]
    ON [dbo].[tblIQEE_Validations]([tiID_Type_Enregistrement] ASC, [iID_Sous_Type] ASC, [iCode_Validation] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Validations_iOrdrePresentation]
    ON [dbo].[tblIQEE_Validations]([iOrdre_Presentation] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Validations_tiIDTypeEnregistrement_bValidationSpeciale_bActif]
    ON [dbo].[tblIQEE_Validations]([tiID_Type_Enregistrement] ASC, [bValidation_Speciale] ASC, [bActif] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Validations_tiIDTypeEnregistrement_cType_bActif_bCorrectionPossible_iCodeValidation_iIDValidation]
    ON [dbo].[tblIQEE_Validations]([tiID_Type_Enregistrement] ASC, [cType] ASC, [bActif] ASC, [bCorrection_Possible] ASC, [iCode_Validation] ASC, [iID_Validation] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Validations_cType_iIDValidation_tiIDTypeEnregistrement]
    ON [dbo].[tblIQEE_Validations]([cType] ASC, [iID_Validation] ASC, [tiID_Type_Enregistrement] ASC) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [stat_tblIQEE_Validations_1]
    ON [dbo].[tblIQEE_Validations]([bActif], [iID_Validation], [tiID_Type_Enregistrement]);


GO
CREATE STATISTICS [stat_tblIQEE_Validations_2]
    ON [dbo].[tblIQEE_Validations]([iCode_Validation], [iID_Validation], [tiID_Type_Enregistrement], [bCorrection_Possible]);


GO
CREATE STATISTICS [stat_tblIQEE_Validations_3]
    ON [dbo].[tblIQEE_Validations]([tiID_Type_Enregistrement], [bCorrection_Possible], [bActif], [iCode_Validation]);


GO
CREATE STATISTICS [stat_tblIQEE_Validations_4]
    ON [dbo].[tblIQEE_Validations]([cType], [iID_Validation], [tiID_Type_Enregistrement], [bCorrection_Possible]);


GO
CREATE STATISTICS [stat_tblIQEE_Validations_5]
    ON [dbo].[tblIQEE_Validations]([bCorrection_Possible], [iID_Validation], [tiID_Type_Enregistrement], [bActif], [iCode_Validation]);


GO
CREATE STATISTICS [stat_tblIQEE_Validations_6]
    ON [dbo].[tblIQEE_Validations]([iID_Validation], [tiID_Type_Enregistrement], [cType], [bActif], [bCorrection_Possible], [iCode_Validation]);


GO
CREATE STATISTICS [stat_tblIQEE_Validations_7]
    ON [dbo].[tblIQEE_Validations]([tiID_Categorie_Element], [iID_Validation]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index du numéro d''ordre de présentation des validations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'INDEX', @level2name = N'IX_IQEE_Validations_iOrdrePresentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index des validations par lot.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'INDEX', @level2name = N'IX_IQEE_Validations_tiIDTypeEnregistrement_bValidationSpeciale_bActif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé unique des validations de l''admissibilité aux types d''enregistrement de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_Validations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des validations applicables à l''admissibilité des différents types d''enregistrement de l''IQÉÉ.  Lorsqu''une convention/transaction ne passe pas une validation, cela mène à un rejet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une validation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'iID_Validation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''enregistrement sur lequel s''applique la validation.  Par exemple, si une validation concernant le nom du bénéficiaire s''applique sur 2 types de transactions, la validation est doublée pour chaque type de transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'tiID_Type_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du sous-type d''enregistrement lorsqu''applicable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'iID_Sous_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique interne à UniAccès qui identifie une validation.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'iCode_Validation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description pour l''utilisateur de la validation.  C''est la même description que la description paramétrable sauf qu''elle n''a pas de paramètres.  Elle est donc utilisé pour l''utilisateur dans les interfaces ou dans les rapports.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description interne de la validation.  Elle sert dans la programmation.  Le nom des paramètres apparait dans la description entre 2 caractères poucentage.  Exemple: "%siAnnee_Fiscale%" qui sera remplacé par "2007".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'vcDescription_Parametrable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur qui spécifie si la validation est active ou non.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'bActif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur de validation spéciale.  Les validations spéciales sont traitées d''une façon particulière dans le code SQL par opposition à une validation régulière qui fait partie d''un lot de validations.  Les validations régulières sont traitée une à une dans les services "psIQEE_CreerTransactions...".  Les validations spéciales n''entre pas dans cette catégorie et doivent être traitées séparément.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'bValidation_Speciale';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Catégorie de la validation.  E=Erreur, A=Avertissement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'cType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour savoir s''il est théoriquement possible d''apporter une correction aux données afin de pouvoir rendre valide la transaction rejetée.  C’est ce qui détermine si le message de rejet est traitable ou non traitable par GUI dans le processus de gestion des rejets.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'bCorrection_Possible';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de séquence de présentation des messages de validation afin de conserver un ordre logique avec l''importance du message.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du contenu du champ "vcValeur_Reference" de la table des rejets.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'vcDescription_Valeur_Reference';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du contenu du champ "vcValeur_Erreur" de la table des rejets.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'vcDescription_Valeur_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du contenu du champ "iID_Lien_Vers_Erreur_1" de la table des rejets.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'vcDescription_Lien_Vers_Erreur_1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du contenu du champ "iID_Lien_Vers_Erreur_2" de la table des rejets.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'vcDescription_Lien_Vers_Erreur_2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du contenu du champ "iID_Lien_Vers_Erreur_3" de la table des rejets.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'vcDescription_Lien_Vers_Erreur_3';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la catégorie d''élément que fait partie la validation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'tiID_Categorie_Element';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la catégorie de rejet de la validation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'tiID_Categorie_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'L''indicateur d''information manquante vient compléter la notion de "rejet traitable" dans certaines circonstances.  Lorsque tous les messages de rejet d''un événement ont le champ "bCorrection_Possible" à 1, cela signifie que l''événement rejeté est traitable et que GUI interviendra pour traiter ces rejets.  Il arrive parfois comme dans le rapport de l''estimation de l''IQÉÉ à recevoir que l''on désire considérer les rejets pour cause d''informations manquantes comme des rejets traitables parce que l''on présume que les données manquantes seront potentiellement remplis d''ici la prochaine création de fichiers de transactions de l''IQÉÉ.  C''est le cas lorsqu''il manque le NAS du bénéficiaire.  GUI n''intervient pas directement pour aller chercher l''information parce qu''il est en attente du souscripteur pour obtenir l''information.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Validations', @level2type = N'COLUMN', @level2name = N'bInformation_Manquante';

