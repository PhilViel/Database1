CREATE TABLE [dbo].[tblIQEE_LignesFichier] (
    [iID_Ligne_Fichier] INT         IDENTITY (1, 1) NOT NULL,
    [iID_Fichier_IQEE]  INT         NOT NULL,
    [iSequence]         INT         NOT NULL,
    [cLigne]            CHAR (1000) NULL,
    CONSTRAINT [PK_IQEE_LignesFichier] PRIMARY KEY CLUSTERED ([iID_Ligne_Fichier] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_LignesFichier_IQEE_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_IQEE_LignesFichier_iIDFichierIQEE_iSequence]
    ON [dbo].[tblIQEE_LignesFichier]([iID_Fichier_IQEE] ASC, [iSequence] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_LignesFichier_iIDFichierIQEE]
    ON [dbo].[tblIQEE_LignesFichier]([iID_Fichier_IQEE] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index permettant d''accéder aux lignes d''un fichier dans le bon ordre.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_LignesFichier', @level2type = N'INDEX', @level2name = N'IX_IQEE_LignesFichier_iIDFichierIQEE_iSequence';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire d''une ligne d''un fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_LignesFichier', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_LignesFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lignes d''un fichier physique de l''IQÉÉ.  Les fichiers de transactions crées par GUI sont créer dans cette table avant d''être créer physiquement sur le disque.  Les fichiers de réponses sont importés dans cette table avant d''être traités par l''importation des fichiers de réponses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_LignesFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une ligne de fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_LignesFichier', @level2type = N'COLUMN', @level2name = N'iID_Ligne_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du fichier de l''IQÉÉ auquel appartient la ligne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_LignesFichier', @level2type = N'COLUMN', @level2name = N'iID_Fichier_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de séquence à l''intérieur d''un fichier pour l''intégrité du fichier.  Ce champ est une reproduction du champ "iID_Ligne_Fichier".  Le champ est non requis uniquement afin de permettre l''insertion des lignes.  Le champ est mis à jour après chaque insertion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_LignesFichier', @level2type = N'COLUMN', @level2name = N'iSequence';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contenu d''une ligne du fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_LignesFichier', @level2type = N'COLUMN', @level2name = N'cLigne';

