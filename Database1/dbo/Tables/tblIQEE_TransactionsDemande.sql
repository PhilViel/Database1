CREATE TABLE [dbo].[tblIQEE_TransactionsDemande] (
    [iID_Transaction_Demande] INT IDENTITY (1, 1) NOT NULL,
    [iID_Demande_IQEE]        INT NOT NULL,
    [iID_Transaction]         INT NOT NULL,
    CONSTRAINT [PK_IQEE_TransactionsDemande] PRIMARY KEY CLUSTERED ([iID_Transaction_Demande] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_TransactionsDemande_IQEE_Demandes__iIDDemandeIQEE] FOREIGN KEY ([iID_Demande_IQEE]) REFERENCES [dbo].[tblIQEE_Demandes] ([iID_Demande_IQEE])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_TransactionsDemande_iIDDemandeIQEE]
    ON [dbo].[tblIQEE_TransactionsDemande]([iID_Demande_IQEE] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_TransactionsDemande_iIDTransaction]
    ON [dbo].[tblIQEE_TransactionsDemande]([iID_Transaction] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_TransactionsDemande_iIDTransaction_iIDTransactionDemande_iIDDemandeIQEE]
    ON [dbo].[tblIQEE_TransactionsDemande]([iID_Transaction] ASC, [iID_Transaction_Demande] ASC, [iID_Demande_IQEE] ASC) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [stat_tblIQEE_TransactionsDemande_1]
    ON [dbo].[tblIQEE_TransactionsDemande]([iID_Transaction_Demande], [iID_Demande_IQEE]);


GO
CREATE STATISTICS [stat_tblIQEE_TransactionsDemande_2]
    ON [dbo].[tblIQEE_TransactionsDemande]([iID_Demande_IQEE], [iID_Transaction]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par identifiant unique de la demande d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TransactionsDemande', @level2type = N'INDEX', @level2name = N'IX_IQEE_TransactionsDemande_iIDDemandeIQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par l''identifiant unique de la transaction de cotisation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TransactionsDemande', @level2type = N'INDEX', @level2name = N'IX_IQEE_TransactionsDemande_iIDTransaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire d''une transaction de cotisation d''une demande d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TransactionsDemande', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_TransactionsDemande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des transactions de cotisations qui ont servies à déterminer le montant de cotisation annuelle.  Cela permet de savoir si une transaction de demande doit être reprise lorsqu''une transaction de cotisation est supprimée, modifiée ou ajoutée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TransactionsDemande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une transaction de cotisation associée à une demande d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TransactionsDemande', @level2type = N'COLUMN', @level2name = N'iID_Transaction_Demande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une demande d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TransactionsDemande', @level2type = N'COLUMN', @level2name = N'iID_Demande_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la transaction de cotisation (Un_Cotisation) associée à la demande d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TransactionsDemande', @level2type = N'COLUMN', @level2name = N'iID_Transaction';

