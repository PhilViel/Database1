CREATE TABLE [dbo].[tblCONV_PretRemboursement] (
    [iID_PretRemboursement]  INT          IDENTITY (1, 1) NOT NULL,
    [iID_Pret]               INT          NOT NULL,
    [ConventionID]           INT          NOT NULL,
    [mMontant_Remboursement] MONEY        NOT NULL,
    [dDate_Remboursement]    DATETIME     NULL,
    [vcIdentifiant_Jira]     VARCHAR (50) NOT NULL,
    [iID_PretAnnulation]     INT          NULL,
    CONSTRAINT [PK_iID_PretRemboursement] PRIMARY KEY CLUSTERED ([iID_PretRemboursement] ASC),
    CONSTRAINT [FK_tblCONV_PretRemboursement_ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_tblCONV_PretRemboursement_iID_Pret] FOREIGN KEY ([iID_Pret]) REFERENCES [dbo].[tblCONV_Pret] ([iID_Pret]),
    CONSTRAINT [FK_tblconv_pretRemboursement_iID_PretAnnulation] FOREIGN KEY ([iID_PretAnnulation]) REFERENCES [dbo].[tblCONV_PretRemboursement] ([iID_PretRemboursement])
);


GO
CREATE NONCLUSTERED INDEX [IX_tblCONV_PretRemboursement_ConventionID]
    ON [dbo].[tblCONV_PretRemboursement]([ConventionID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_tblCONV_PretRemboursement_iID_Pret]
    ON [dbo].[tblCONV_PretRemboursement]([iID_Pret] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Détails de l''historique des remboursements associés à des prêts (master: tblCONV_Pret).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretRemboursement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique auto-incrémenté d''une ligne de remboursement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretRemboursement', @level2type = N'COLUMN', @level2name = N'iID_PretRemboursement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Clé étrangère sur la table tblCONV_Pret.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretRemboursement', @level2type = N'COLUMN', @level2name = N'iID_Pret';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Clé étrangère sur la table UN_Convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretRemboursement', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant du remboursement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretRemboursement', @level2type = N'COLUMN', @level2name = N'mMontant_Remboursement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date du remboursement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretRemboursement', @level2type = N'COLUMN', @level2name = N'dDate_Remboursement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro du JIRA ayant servi au transfer d''information entre le prêteur et Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretRemboursement', @level2type = N'COLUMN', @level2name = N'vcIdentifiant_Jira';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant d''une ligne de remboursement qui a été annulée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretRemboursement', @level2type = N'COLUMN', @level2name = N'iID_PretAnnulation';

