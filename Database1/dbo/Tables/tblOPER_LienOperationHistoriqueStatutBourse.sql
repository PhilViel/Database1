CREATE TABLE [dbo].[tblOPER_LienOperationHistoriqueStatutBourse] (
    [iID_Lien]              INT IDENTITY (1, 1) NOT NULL,
    [iID_Historique_Statut] INT NOT NULL,
    [iID_Operation]         INT NOT NULL,
    CONSTRAINT [PK_OPER_LienOperationHistoriqueStatutBourse] PRIMARY KEY CLUSTERED ([iID_Lien] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_LienOperationHistoriqueStatutBourse_CONV_HistoriqueStatutBourse__iIDHistoriqueStatut] FOREIGN KEY ([iID_Historique_Statut]) REFERENCES [dbo].[tblCONV_HistoriqueStatutBourse] ([iID_Historique_Statut])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du lien', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_LienOperationHistoriqueStatutBourse', @level2type = N'COLUMN', @level2name = N'iID_Lien';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''historique de statut de bourse', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_LienOperationHistoriqueStatutBourse', @level2type = N'COLUMN', @level2name = N'iID_Historique_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_LienOperationHistoriqueStatutBourse', @level2type = N'COLUMN', @level2name = N'iID_Operation';

