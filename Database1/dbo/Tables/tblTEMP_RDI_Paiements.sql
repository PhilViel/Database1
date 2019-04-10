CREATE TABLE [dbo].[tblTEMP_RDI_Paiements] (
    [iID_TEMP_RDI_Paiement] INT          IDENTITY (1, 1) NOT NULL,
    [iID_RDI_Paiement]      INT          NOT NULL,
    [iID_RDI_Depot]         INT          NOT NULL,
    [mMontantAjout]         MONEY        NOT NULL,
    [vcNo_Document]         VARCHAR (30) NULL,
    [iID_Utilisateur]       INT          NOT NULL,
    CONSTRAINT [PK_TEMP_RDI_Paiements] PRIMARY KEY CLUSTERED ([iID_TEMP_RDI_Paiement] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table qui contient temporairement les paiements informatisés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_RDI_Paiements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une transaction temporaire de paiement - EDI - Réception dépôts informatisé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'iID_TEMP_RDI_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une transaction de paiement - EDI - Réception dépôts informatisé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'iID_RDI_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du dépôt associé à la transaction de paiement EDI-RDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'iID_RDI_Depot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant calculé maximum pour un ajout.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'mMontantAjout';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de document entré par le déposant.  Il s''agit d''une zone de texte libre.  Habituellement il s''agit du numéro de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'vcNo_Document';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''utilisateur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur';

