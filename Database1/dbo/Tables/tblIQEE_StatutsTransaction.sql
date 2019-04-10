CREATE TABLE [dbo].[tblIQEE_StatutsTransaction] (
    [tiID_Statut_Transaction] TINYINT      IDENTITY (1, 1) NOT NULL,
    [cCode_Statut]            CHAR (1)     NOT NULL,
    [vcDescription]           VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_IQEE_StatutsTransaction] PRIMARY KEY CLUSTERED ([tiID_Statut_Transaction] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_StatutsTransaction_cCodeStatut]
    ON [dbo].[tblIQEE_StatutsTransaction]([cCode_Statut] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur le code de statut de transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsTransaction', @level2type = N'INDEX', @level2name = N'AK_IQEE_StatutsTransaction_cCodeStatut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique d''un statut de transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsTransaction', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_StatutsTransaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des statuts des transactions de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsTransaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un statut de transaction de l''IQÉÉ.  Il n''est pas utilisé dans les tables des transactions parce que cette table a été créée après la création des tables des transactions.  Le but de cette table est principalement d''avoir une description pour l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsTransaction', @level2type = N'COLUMN', @level2name = N'tiID_Statut_Transaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique du statut de transaction.  Ce code peut être codé en dur dans la programmation.  Ce champ correspond au champ "cStatut_Reponse" des tables des transactions de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsTransaction', @level2type = N'COLUMN', @level2name = N'cCode_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut de transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsTransaction', @level2type = N'COLUMN', @level2name = N'vcDescription';

