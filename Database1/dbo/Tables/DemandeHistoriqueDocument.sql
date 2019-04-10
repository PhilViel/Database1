CREATE TABLE [dbo].[DemandeHistoriqueDocument] (
    [ID]                 INT          IDENTITY (1, 1) NOT NULL,
    [IDDemande]          INT          NOT NULL,
    [DateCreation]       DATETIME     CONSTRAINT [DF_DemandeHistoriqueDocument_DateCreation] DEFAULT (getdate()) NOT NULL,
    [EstEmis]            BIT          CONSTRAINT [DF_DemandeHistoriqueDocument_EstEmis] DEFAULT ((0)) NOT NULL,
    [CodeTypeDocument]   VARCHAR (25) NOT NULL,
    [LoginName]          VARCHAR (50) NULL,
    [iHumanDestLettreID] INT          NULL,
    CONSTRAINT [PK_DemandeHistoriqueDocument] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_DemandeHistoriqueDocument_Demande__IDDemande] FOREIGN KEY ([IDDemande]) REFERENCES [dbo].[Demande] ([Id]),
    CONSTRAINT [FK_DemandeHistoriqueDocument_TypeDocument__CodeTypeDocument] FOREIGN KEY ([CodeTypeDocument]) REFERENCES [dbo].[TypeDocument] ([Code])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'HumanID de la personne à qui la lettre est destiné (souscripteur ou bénéficiaire)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeHistoriqueDocument', @level2type = N'COLUMN', @level2name = N'iHumanDestLettreID';

