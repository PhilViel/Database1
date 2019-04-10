CREATE TABLE [dbo].[tblCONV_PretDetail] (
    [iID_PretDetail]                INT          IDENTITY (1, 1) NOT NULL,
    [iID_Pret]                      INT          NOT NULL,
    [iID_PretEncaissementCreancier] INT          NOT NULL,
    [OperID]                        INT          NOT NULL,
    [vcIdentifiant_Jira]            VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_iID_PretDetail] PRIMARY KEY CLUSTERED ([iID_PretDetail] ASC),
    CONSTRAINT [FK_tblCONV_PretDetail_tblCONV_PretEncaissementCreancier] FOREIGN KEY ([iID_PretEncaissementCreancier]) REFERENCES [dbo].[tblCONV_PretEncaissementCreancier] ([iID_PretEncaissementCreancier]),
    CONSTRAINT [FK_tblCONV_PretDetail_Un_Oper] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_tblPretEncaissementOper_tblPret] FOREIGN KEY ([iID_Pret]) REFERENCES [dbo].[tblCONV_Pret] ([iID_Pret])
);


GO
CREATE NONCLUSTERED INDEX [IX_tblCONV_PretDetail_iID_Pret]
    ON [dbo].[tblCONV_PretDetail]([iID_Pret] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_tblCONV_PretDetail_iID_PretEncaissementCreancier]
    ON [dbo].[tblCONV_PretDetail]([iID_PretEncaissementCreancier] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_tblCONV_PretDetail_OperID]
    ON [dbo].[tblCONV_PretDetail]([OperID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Détails de l''historique des encaissements associés à des prêts (master: tblCONV_Pret)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretDetail';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique auto-incrémenté d''une ligne de détail.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretDetail', @level2type = N'COLUMN', @level2name = N'iID_PretDetail';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Clé étrangère sur la table tblCONV_Pret', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretDetail', @level2type = N'COLUMN', @level2name = N'iID_Pret';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Clé étrangère sur la table tblCONV_PretEncaissementCreancier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretDetail', @level2type = N'COLUMN', @level2name = N'iID_PretEncaissementCreancier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Clé étrangère sur la table OperID', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretDetail', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro du JIRA ayant servi au transfer d''information entre le prêteur et Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretDetail', @level2type = N'COLUMN', @level2name = N'vcIdentifiant_Jira';

