CREATE TABLE [dbo].[tblCONV_PretEncaissementCreancier] (
    [iID_PretEncaissementCreancier] INT          IDENTITY (1, 1) NOT NULL,
    [mMontant_Encaissement]         MONEY        NOT NULL,
    [dDate_Encaissement]            DATE         NOT NULL,
    [vcUtilisateur_Saisie]          VARCHAR (50) NULL,
    CONSTRAINT [PK_iID_PretEncaissementCreancier] PRIMARY KEY CLUSTERED ([iID_PretEncaissementCreancier] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_tblCONV_PretEncaissementCreancier_dDate_Encaissement]
    ON [dbo].[tblCONV_PretEncaissementCreancier]([dDate_Encaissement] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les encaissments de paiements (généralement journalier) provenenant d''un prêteur (ex: La Capitale) pouvant couvrir plusieurs conventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretEncaissementCreancier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un encaissement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretEncaissementCreancier', @level2type = N'COLUMN', @level2name = N'iID_PretEncaissementCreancier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de l''encaissement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretEncaissementCreancier', @level2type = N'COLUMN', @level2name = N'mMontant_Encaissement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date à laquelle l''encaissement a lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretEncaissementCreancier', @level2type = N'COLUMN', @level2name = N'dDate_Encaissement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Utilisateur aillant saisi les données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_PretEncaissementCreancier', @level2type = N'COLUMN', @level2name = N'vcUtilisateur_Saisie';

