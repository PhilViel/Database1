CREATE TABLE [dbo].[tblIQEE_TypesErreurRQ] (
    [siCode_Erreur]                        SMALLINT      NOT NULL,
    [vcDescription]                        VARCHAR (500) NOT NULL,
    [tiID_Categorie_Erreur]                TINYINT       NOT NULL,
    [bInd_Erreur_Grave]                    BIT           NOT NULL,
    [bConsiderer_Traite_Creation_Fichiers] BIT           CONSTRAINT [dfIQEE_TypesErreurRQ_bConsidererTraiteCreationFichier] DEFAULT ((0)) NOT NULL,
    [bResoumettre_En_Totalite]             BIT           CONSTRAINT [dfIQEE_TypesErreurRQ_bResoumettreEnTotalite] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_IQEE_TypesErreurRQ] PRIMARY KEY CLUSTERED ([siCode_Erreur] ASC),
    CONSTRAINT [FK_IQEE_TypesErreurRQ_IQEE_CategoriesErreur__tiIDCategorieErreur] FOREIGN KEY ([tiID_Categorie_Erreur]) REFERENCES [dbo].[tblIQEE_CategoriesErreur] ([tiID_Categorie_Erreur])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_TypesErreurRQ_siCodeErreur]
    ON [dbo].[tblIQEE_TypesErreurRQ]([siCode_Erreur] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code d''erreur de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesErreurRQ', @level2type = N'INDEX', @level2name = N'AK_IQEE_TypesErreurRQ_siCodeErreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Types d''erreur de RQ.  Correspond à l''annexe 2 des NID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesErreurRQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du type d''erreur de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesErreurRQ', @level2type = N'COLUMN', @level2name = N'siCode_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type d''erreur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesErreurRQ', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de la catégorie d''erreur du type d''erreur de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesErreurRQ', @level2type = N'COLUMN', @level2name = N'tiID_Categorie_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur d''erreur grave.  Correspond aux erreurs de la section "Recevabilité du fichier" d''un rapport d''erreur.  0=Erreur de recevabilité d''une demande, 1=Erreur de recevabilité du fichier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesErreurRQ', @level2type = N'COLUMN', @level2name = N'bInd_Erreur_Grave';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si les erreurs RQ de ce type et qui ne sont pas encore traitée par GUI devront ou non être considérées comme traitée pour la création de fichiers de transactions parce que GUI désire s''assurer que tout les efforts ont été fait pour obtenir le maximum d''IQÉÉ lorsque le souscripteur doit contacter RQ pour mettre à jour ses informations ou qu''une correction pourrait être fait non intentionnellement par un employé de GUI et qui corrigerait l''erreur.  Les types d''erreur RQ dans les catégories d''erreurs destinées aux TI sont automatiquement considérés comme traités pour la création des fichiers de transactions.  Les types d''erreur RQ dans les catégories d''erreurs destinées aux opérations tiennent compte de cet indicateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesErreurRQ', @level2type = N'COLUMN', @level2name = N'bConsiderer_Traite_Creation_Fichiers';

