CREATE TABLE [dbo].[tblCONV_ReclamationAssurance] (
    [IdSouscripteur]  INT          NOT NULL,
    [DateEvenement]   DATE         NOT NULL,
    [DateReclamation] DATE         NOT NULL,
    [TypeGarantie]    VARCHAR (3)  NOT NULL,
    [MontantReclame]  MONEY        NOT NULL,
    [Statut]          VARCHAR (3)  NULL,
    [LoginName]       VARCHAR (75) CONSTRAINT [DF_ReclamationAssurance_Login] DEFAULT ([dbo].[GetUserContext]()) NULL,
    [DateCreation]    DATETIME     CONSTRAINT [DF_ReclamationAssurance_Creation] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_CONV_ReclamationAssurance] PRIMARY KEY CLUSTERED ([IdSouscripteur] ASC),
    CONSTRAINT [FK_CONV_ReclamationAssurance_Subcriber] FOREIGN KEY ([IdSouscripteur]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Demande des réclamations d''assurance-vie ou invalidité', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReclamationAssurance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifiant du souscripteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReclamationAssurance', @level2type = N'COLUMN', @level2name = N'IdSouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de l''évènement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReclamationAssurance', @level2type = N'COLUMN', @level2name = N'DateEvenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la réclamation', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReclamationAssurance', @level2type = N'COLUMN', @level2name = N'DateReclamation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de garantie: (VIE) ou (INV)alidité ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReclamationAssurance', @level2type = N'COLUMN', @level2name = N'TypeGarantie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de la réclamation', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReclamationAssurance', @level2type = N'COLUMN', @level2name = N'MontantReclame';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Statut de la réclamation: (ACC)eptée, (REF)usée ou (IND)erminée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReclamationAssurance', @level2type = N'COLUMN', @level2name = N'Statut';

