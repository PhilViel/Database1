CREATE TABLE [dbo].[tblGENE_Erreurs] (
    [iID_ErreurLog]      INT             IDENTITY (1, 1) NOT NULL,
    [dtDate_Erreur]      DATETIME        CONSTRAINT [DF_GENE_Erreurs_dtDateErreur] DEFAULT (getdate()) NULL,
    [iLigne_Erreur]      INT             NULL,
    [vcMessage_Erreur]   NVARCHAR (4000) NULL,
    [iNumero_Erreur]     INT             NULL,
    [vcNom_Objet]        NVARCHAR (126)  NULL,
    [iSeverite_Erreur]   INT             NULL,
    [iEtat_Erreur]       INT             NULL,
    [vcNom_BaseDeDonnee] NVARCHAR (255)  NULL,
    CONSTRAINT [PK_GENE_Erreurs] PRIMARY KEY CLUSTERED ([iID_ErreurLog] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table qui contient les erreurs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''erreur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs', @level2type = N'COLUMN', @level2name = N'iID_ErreurLog';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de l''erreur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs', @level2type = N'COLUMN', @level2name = N'dtDate_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur de la variable système ERROR_LINE()', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs', @level2type = N'COLUMN', @level2name = N'iLigne_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur de la variable système ERROR_MESSAGE()', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs', @level2type = N'COLUMN', @level2name = N'vcMessage_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur de la variable système ERROR_NUMBER()', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs', @level2type = N'COLUMN', @level2name = N'iNumero_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur de la variable système ERROR_PROCEDURE()', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs', @level2type = N'COLUMN', @level2name = N'vcNom_Objet';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur de la variable système ERROR_SEVERITY()', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs', @level2type = N'COLUMN', @level2name = N'iSeverite_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur de la variable système ERROR_STATE()', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs', @level2type = N'COLUMN', @level2name = N'iEtat_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur de la variable système DB_NAME()', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Erreurs', @level2type = N'COLUMN', @level2name = N'vcNom_BaseDeDonnee';

