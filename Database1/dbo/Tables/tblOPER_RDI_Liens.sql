CREATE TABLE [dbo].[tblOPER_RDI_Liens] (
    [iID_RDI_Lien]     INT IDENTITY (1, 1) NOT NULL,
    [iID_RDI_Paiement] INT NOT NULL,
    [OperID]           INT NOT NULL,
    CONSTRAINT [PK_OPER_RDI_Liens] PRIMARY KEY CLUSTERED ([iID_RDI_Lien] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_RDI_Liens_OPER_RDI_Paiements__iIDRDIPaiement] FOREIGN KEY ([iID_RDI_Paiement]) REFERENCES [dbo].[tblOPER_RDI_Paiements] ([iID_RDI_Paiement])
);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_RDI_Liens_OperID]
    ON [dbo].[tblOPER_RDI_Liens]([OperID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_RDI_Liens_iIDRDIPaiement]
    ON [dbo].[tblOPER_RDI_Liens]([iID_RDI_Paiement] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les informations sur les liens entre les paiements informatisés et les opérations', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Liens';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un lien RDI-OPER.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Liens', @level2type = N'COLUMN', @level2name = N'iID_RDI_Lien';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du paiement RDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Liens', @level2type = N'COLUMN', @level2name = N'iID_RDI_Paiement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''opération associé au paiement RDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_Liens', @level2type = N'COLUMN', @level2name = N'OperID';

