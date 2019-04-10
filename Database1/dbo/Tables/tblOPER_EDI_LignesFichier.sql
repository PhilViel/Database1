CREATE TABLE [dbo].[tblOPER_EDI_LignesFichier] (
    [iID_EDI_Ligne_Fichier] INT         IDENTITY (1, 1) NOT NULL,
    [iID_EDI_Fichier]       INT         NOT NULL,
    [iSequence]             INT         NULL,
    [cLigne]                CHAR (1000) NULL,
    CONSTRAINT [PK_OPER_EDI_LignesFichier] PRIMARY KEY CLUSTERED ([iID_EDI_Ligne_Fichier] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_EDI_LignesFichier_OPER_EDI_Fichiers__iIDEDIFichier] FOREIGN KEY ([iID_EDI_Fichier]) REFERENCES [dbo].[tblOPER_EDI_Fichiers] ([iID_EDI_Fichier])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les lignes des fichiers EDI', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_LignesFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une ligne de fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_LignesFichier', @level2type = N'COLUMN', @level2name = N'iID_EDI_Ligne_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du fichier associé à la ligne du fichier EDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_LignesFichier', @level2type = N'COLUMN', @level2name = N'iID_EDI_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Séquence utilisé pour les ORDER BY des requêtes SQL.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_LignesFichier', @level2type = N'COLUMN', @level2name = N'iSequence';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contenu complet d''une ligne de fichier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_LignesFichier', @level2type = N'COLUMN', @level2name = N'cLigne';

