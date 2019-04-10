CREATE TABLE [dbo].[tblIQEE_Fichiers] (
    [iID_Fichier_IQEE]                                INT           IDENTITY (1, 1) NOT NULL,
    [tiID_Type_Fichier]                               TINYINT       NOT NULL,
    [tiID_Statut_Fichier]                             TINYINT       NOT NULL,
    [bFichier_Test]                                   BIT           NOT NULL,
    [bInd_Simulation]                                 BIT           NOT NULL,
    [vcCode_Simulation]                               VARCHAR (100) NULL,
    [iID_Utilisateur_Creation]                        INT           NOT NULL,
    [dtDate_Creation]                                 DATETIME      NOT NULL,
    [iID_Parametres_IQEE]                             INT           NULL,
    [iID_Lien_Fichier_IQEE_Demande]                   INT           NULL,
    [vcNom_Fichier]                                   VARCHAR (50)  NOT NULL,
    [vcChemin_Fichier]                                VARCHAR (150) NULL,
    [tCommentaires]                                   TEXT          NULL,
    [iID_Utilisateur_Modification]                    INT           NULL,
    [dtDate_Modification]                             DATETIME      NULL,
    [iID_Utilisateur_Approuve]                        INT           NULL,
    [dtDate_Approve]                                  DATETIME      NULL,
    [iID_Utilisateur_Transmis]                        INT           NULL,
    [dtDate_Transmis]                                 DATETIME      NULL,
    [mMontant_Total_Paiement]                         MONEY         NULL,
    [dtDate_Production_Paiement]                      DATETIME      NULL,
    [dtDate_Paiement]                                 DATETIME      NULL,
    [iNumero_Paiement]                                INT           NULL,
    [vcInstitution_Paiement]                          VARCHAR (4)   NULL,
    [vcTransit_Paiement]                              VARCHAR (5)   NULL,
    [vcCompte_Paiement]                               VARCHAR (12)  NULL,
    [vcNo_Identification_RQ]                          VARCHAR (10)  NULL,
    [mMontant_Total_A_Payer]                          MONEY         NULL,
    [mMontant_Total_Cotise]                           MONEY         NULL,
    [mMontant_Total_Recu]                             MONEY         NULL,
    [mMontant_Total_Interets]                         MONEY         NULL,
    [mSolde_Paiement_RQ]                              MONEY         NULL,
    [iID_Session]                                     INT           NULL,
    [dtDate_Creation_Fichiers]                        DATETIME      NULL,
    [dtDate_Traitement_RQ]                            DATETIME      NULL,
    [dtDate_Sommaire_Avis_Cotisation_Impots_Speciaux] DATETIME      NULL,
    CONSTRAINT [PK_IQEE_Fichiers] PRIMARY KEY CLUSTERED ([iID_Fichier_IQEE] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_Fichiers_IQEE_Fichiers__iIDLienFichierIQEEDemande] FOREIGN KEY ([iID_Lien_Fichier_IQEE_Demande]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_Fichiers_IQEE_Parametres__iIDParametresIQEE] FOREIGN KEY ([iID_Parametres_IQEE]) REFERENCES [dbo].[tblIQEE_Parametres] ([iID_Parametres_IQEE]),
    CONSTRAINT [FK_IQEE_Fichiers_IQEE_StatutsFichier__tiIDStatutFichier] FOREIGN KEY ([tiID_Statut_Fichier]) REFERENCES [dbo].[tblIQEE_StatutsFichier] ([tiID_Statut_Fichier]),
    CONSTRAINT [FK_IQEE_Fichiers_IQEE_TypesFichier__tiIDTypeFichier] FOREIGN KEY ([tiID_Type_Fichier]) REFERENCES [dbo].[tblIQEE_TypesFichier] ([tiID_Type_Fichier])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Fichiers_dtDateCreation]
    ON [dbo].[tblIQEE_Fichiers]([dtDate_Creation] DESC);


GO
CREATE NONCLUSTERED INDEX [IX_Fichiers_bFichierTest_bIndSimulation]
    ON [dbo].[tblIQEE_Fichiers]([bFichier_Test] ASC, [bInd_Simulation] ASC)
    INCLUDE([dtDate_Creation], [dtDate_Traitement_RQ], [iID_Fichier_IQEE]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Fichiers_vcNomFichier]
    ON [dbo].[tblIQEE_Fichiers]([vcNom_Fichier] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Fichiers_tiIDStatutFichier]
    ON [dbo].[tblIQEE_Fichiers]([tiID_Statut_Fichier] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Fichiers_tiIDTypeFichier]
    ON [dbo].[tblIQEE_Fichiers]([tiID_Type_Fichier] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le nom du fichier permettant d''associer un fichier de réponses à un fichier de demande.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'INDEX', @level2name = N'IX_IQEE_Fichiers_vcNomFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le statut d''un fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'INDEX', @level2name = N'IX_IQEE_Fichiers_tiIDStatutFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le type de fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'INDEX', @level2name = N'IX_IQEE_Fichiers_tiIDTypeFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire d''un fichier de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_Fichiers';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique des fichiers reliés à l''IQÉÉ.  Les fichiers de demandes, les rapports d''erreurs et de traitement y sont présent.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un fichier de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_Fichier_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de fichier.  Correspond à la table de référence "tblIQEE_TypesFichier".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'tiID_Type_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du statut du fichier.  Correspond à la table de référence "tblIQEE_StatutsFichier".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'tiID_Statut_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur de fichier test (0=Fichier de production, 1=Fichier test)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'bFichier_Test';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur que le fichier test est une simulation ou non.  Les fichiers de test qui ne sont pas des simulations, sont visibles aux utilisateurs.  Par contre, les fichiers de simulation ne sont pas visibles aux utilisateurs.  Ils sont accessibles seulement aux programmeurs. (0=Fichier normal, 1=Fichier de simulation)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'bInd_Simulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Le code de simulation est au choix du programmeur.  Il permet d’associer un code à un ou plusieurs fichiers de transactions.  Si ce champ est différent de nul, le fichier doit être considéré comme un fichier test et comme un fichier de simulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'vcCode_Simulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''utilisateur qui à crée ou importé le fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de la création du fichier.  C''est la date et l''heure de création des fichiers de transactions et c''est la date et l''heure de l''importation pour un fichier de réponses dans UniAccès.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant des paramètres IQÉÉ utilisés lors de la création du fichier des transactions ou les paramètres du fichier des transactions d''origine dans le cas des fichiers de réponses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_Parametres_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien entre les fichiers de réponses avec le fichier de transactions principal à l''origine du fichier de réponses.  Il arrive qu''un fichier de réponses répond à plus d''un fichier de transactions.  C''est le fichier de transactions le plus volumineux qui est sélectionné dans ce cas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_Lien_Fichier_IQEE_Demande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du fichier incluant l''extention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'vcNom_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Chemin de destination du fichier crée ou chemin d''origine du fichier importé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'vcChemin_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires des utilisateurs sur le fichier de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'tCommentaires';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du dernier utilisateur qui à modifier les informations du fichier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Modification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de la dernière modification des informations du fichier par un utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Modification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''utilisateur qui a approuvé le fichier de transactions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Approuve';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de l''approbation du fichier de transactions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Approve';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''utilisateur qui a marquer le fichier de transactions comme transmis.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Transmis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de marquage de la transmission du fichier de transactions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Transmis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total du paiement à GUI pour un fichier de réponses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'mMontant_Total_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de production d''un paiement à GUI pour un fichier de réponses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Production_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de paiement à GUI pour un fichier de réponses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro du paiement à GUI pour un fichier de réponses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'iNumero_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code d''institution financière du dépôt d''un paiement à GUI pour un fichier de réponses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'vcInstitution_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de transit du dépôt d''un paiement à GUI pour un fichier de réponses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'vcTransit_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de compte du dépôt d''un paiement à GUI pour un fichier de réponses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'vcCompte_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''identification permettant d''identifier le fiduciaire pour remplir le bordereau de paiement lors du paiement des impôts spéciaux.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'vcNo_Identification_RQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant que GUI doit verser à RQ en remboursement de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'mMontant_Total_A_Payer';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Somme de toutes le cotisations traitées au cours du présent exercice de cotisation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'mMontant_Total_Cotise';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Somme totale reçues à Revenu Québec.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'mMontant_Total_Recu';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant positif si des intérêts sont payables par le fiduciaire.  Montant négatif si des intérêts sont payables au fiduciaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'mMontant_Total_Interets';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Correspond à la somme du total cotisé moins la somme reçu plus le montant des intérêts.  Si le montant est positif, c''est un montant à payer à RQ.  Si le montant est négatif, c''est un paiement de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'mSolde_Paiement_RQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de la session SQL de l''utilisateur qui a commandé la création d''un groupe de fichiers logiques de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_Session';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de création d''un ensemble de fichiers logiques de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Creation_Fichiers';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de traitement par RQ qui est conservée afin de faciliter la communication avec RQ au besoin. La date et heure de traitement fait partie du nom du fichier de réponse (voir annexe 5 est NID).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Traitement_RQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date du sommaire des segments 41 des fichier COT.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Sommaire_Avis_Cotisation_Impots_Speciaux';

