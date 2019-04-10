CREATE TABLE [dbo].[tblOPER_EDI_Fichiers] (
    [iID_EDI_Fichier]          INT           IDENTITY (1, 1) NOT NULL,
    [tiID_EDI_Type_Fichier]    TINYINT       NOT NULL,
    [tiID_EDI_Statut_Fichier]  TINYINT       NOT NULL,
    [iID_Utilisateur_Creation] INT           NOT NULL,
    [dtDate_Creation]          DATETIME      NOT NULL,
    [vcNom_Fichier]            VARCHAR (50)  NOT NULL,
    [vcChemin_Fichier]         VARCHAR (150) NULL,
    [tCommentaires]            TEXT          NULL,
    CONSTRAINT [PK_OPER_EDI_Fichiers] PRIMARY KEY CLUSTERED ([iID_EDI_Fichier] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_EDI_Fichiers_OPER_EDI_StatutsFichier__tiIDEDIStatutFichier] FOREIGN KEY ([tiID_EDI_Statut_Fichier]) REFERENCES [dbo].[tblOPER_EDI_StatutsFichier] ([tiID_EDI_Statut_Fichier]),
    CONSTRAINT [FK_OPER_EDI_Fichiers_OPER_EDI_TypesFichier__tiIDEDITypeFichier] FOREIGN KEY ([tiID_EDI_Type_Fichier]) REFERENCES [dbo].[tblOPER_EDI_TypesFichier] ([tiID_EDI_Type_Fichier])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les informations qui définissent un fichier EDI', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Fichiers';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un fichier EDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_EDI_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de fichier associé au fichier EDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Fichiers', @level2type = N'COLUMN', @level2name = N'tiID_EDI_Type_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du statut de fichier associé au fichier EDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Fichiers', @level2type = N'COLUMN', @level2name = N'tiID_EDI_Statut_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Utilisateur qui a cré le fichier. Utilise le champ Mo_User.UserID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Fichiers', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de création du fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Fichiers', @level2type = N'COLUMN', @level2name = N'dtDate_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du fichier EDI.  Extension .txt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Fichiers', @level2type = N'COLUMN', @level2name = N'vcNom_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Répertoire où se trouve le fichier EDI lors de sa création.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Fichiers', @level2type = N'COLUMN', @level2name = N'vcChemin_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaire divers sur le fichier EDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Fichiers', @level2type = N'COLUMN', @level2name = N'tCommentaires';

