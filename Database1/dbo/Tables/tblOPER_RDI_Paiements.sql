CREATE TABLE [dbo].[tblOPER_RDI_Paiements] (
    [iID_RDI_Paiement]         INT           IDENTITY (1, 1) NOT NULL,
    [iID_RDI_Depot]            INT           NOT NULL,
    [vcNom_Deposant]           VARCHAR (35)  NULL,
    [mMontant_Paiement]        MONEY         NULL,
    [mMontant_Reduction]       MONEY         NULL,
    [mMontant_Paiement_Final]  MONEY         NULL,
    [vcNo_Document]            VARCHAR (30)  NULL,
    [vcDesc_Document]          VARCHAR (100) NULL,
    [vcNo_Oper]                VARCHAR (50)  NULL,
    [vcDesc_Oper]              VARCHAR (50)  NULL,
    [vcAutreTexte]             VARCHAR (500) NULL,
    [tiID_RDI_Raison_Paiement] TINYINT       NULL,
    [vcDescription_Raison]     VARCHAR (100) NULL,
    CONSTRAINT [PK_OPER_RDI_Paiements] PRIMARY KEY CLUSTERED ([iID_RDI_Paiement] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_RDI_Paiements_OPER_RDI_Depots__iIDRDIDepot] FOREIGN KEY ([iID_RDI_Depot]) REFERENCES [dbo].[tblOPER_RDI_Depots] ([iID_RDI_Depot]),
    CONSTRAINT [FK_OPER_RDI_Paiements_OPER_RDI_RaisonPaiement__tiIDRDIRaisonPaiement] FOREIGN KEY ([tiID_RDI_Raison_Paiement]) REFERENCES [dbo].[tblOPER_RDI_RaisonPaiement] ([tiID_RDI_Raison_Paiement])
);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_RDI_Paiements_iIDRDIDepot]
    ON [dbo].[tblOPER_RDI_Paiements]([iID_RDI_Depot] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les paiements informatisés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une transaction de paiement - EDI - Réception dépôts informatisé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'iID_RDI_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du dépôt associé à la transaction de paiement EDI-RDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'iID_RDI_Depot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du déposant. Il peut s''agir du souscripteur ou d''une autre personne n''ayant pas de lien avec GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'vcNom_Deposant';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant reçu pour le paiement.  Établi par la banque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'mMontant_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de réduction à appliquer au paiement. Établi par la banque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'mMontant_Reduction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant du paiement moins le montant de la réduction.  Établi par la banque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'mMontant_Paiement_Final';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de document entré par le déposant.  Il s''agit d''une zone de texte libre.  Habituellement il s''agit du numéro de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'vcNo_Document';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Texte qui décrit ce que représente le numéro du document.  Ex : No de référence du client.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'vcDesc_Document';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de l''opération du paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'vcNo_Oper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Texte qui décrit ce que représente le numéro de l''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'vcDesc_Oper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Autre texte fournit par la banque mais non affiché dans UN', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Paiements', @level2type = N'COLUMN', @level2name = N'vcAutreTexte';

