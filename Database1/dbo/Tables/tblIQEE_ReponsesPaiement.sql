CREATE TABLE [dbo].[tblIQEE_ReponsesPaiement] (
    [iID_Reponse_Paiement] INT          IDENTITY (1, 1) NOT NULL,
    [iID_Paiement_IQEE]    INT          NOT NULL,
    [iID_Fichier_IQEE]     INT          NOT NULL,
    [vcStatutTransaction]  VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_IQEE_ReponsesPaiement] PRIMARY KEY CLUSTERED ([iID_Reponse_Paiement] ASC),
    CONSTRAINT [FK_IQEE_ReponsesPaiement_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesPaiement_IQEE_Fichiers_iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesPaiement_PaiementsBeneficiaires__iIDPaiement] FOREIGN KEY ([iID_Paiement_IQEE]) REFERENCES [dbo].[tblIQEE_PaiementsBeneficiaires] ([iID_Paiement_Beneficiaire])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ReponsesPaiement_iIDPaiementIQEE]
    ON [dbo].[tblIQEE_ReponsesPaiement]([iID_Paiement_IQEE] ASC, [iID_Fichier_IQEE] ASC);

