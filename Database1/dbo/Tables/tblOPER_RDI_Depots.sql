CREATE TABLE [dbo].[tblOPER_RDI_Depots] (
    [iID_RDI_Depot]         INT          IDENTITY (1, 1) NOT NULL,
    [iID_EDI_Fichier]       INT          NOT NULL,
    [tiID_RDI_Statut_Depot] TINYINT      NOT NULL,
    [dtDate_Depot]          DATETIME     NOT NULL,
    [mMontant_Depot]        MONEY        NULL,
    [cDevise]               CHAR (3)     NULL,
    [tiID_EDI_Banque]       TINYINT      NOT NULL,
    [vcNo_Cheque]           VARCHAR (30) NULL,
    [vcNo_Trace]            VARCHAR (30) NULL,
    [vcNom_Beneficiaire]    VARCHAR (35) NULL,
    [cTest]                 CHAR (1)     NULL,
    CONSTRAINT [PK_OPER_RDI_Depots] PRIMARY KEY CLUSTERED ([iID_RDI_Depot] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_RDI_Depots_OPER_EDI_Banques__tiIDEDIBanque] FOREIGN KEY ([tiID_EDI_Banque]) REFERENCES [dbo].[tblOPER_EDI_Banques] ([tiID_EDI_Banque]),
    CONSTRAINT [FK_OPER_RDI_Depots_OPER_EDI_Fichiers__iIDEDIFichier] FOREIGN KEY ([iID_EDI_Fichier]) REFERENCES [dbo].[tblOPER_EDI_Fichiers] ([iID_EDI_Fichier]),
    CONSTRAINT [FK_OPER_RDI_Depots_OPER_RDI_StatutsDepot__tiIDRDIStatutDepot] FOREIGN KEY ([tiID_RDI_Statut_Depot]) REFERENCES [dbo].[tblOPER_RDI_StatutsDepot] ([tiID_RDI_Statut_Depot])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les dépôts informatisés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un dépôt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'iID_RDI_Depot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du fichier EDI associé au dépôt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'iID_EDI_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du statut associé au dépôt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'tiID_RDI_Statut_Depot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date du dépôt des sommes dans le compte de GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'dtDate_Depot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant du dépôt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'mMontant_Depot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Devise du paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'cDevise';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la banque associé au déposant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'tiID_EDI_Banque';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de trace de la banque du déposant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'vcNo_Cheque';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de trace du fournisseur de services RBC.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'vcNo_Trace';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'GUI', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'vcNom_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Permet d''identifier si le dépôts est un test.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Depots', @level2type = N'COLUMN', @level2name = N'cTest';

