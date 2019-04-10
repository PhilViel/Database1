CREATE TABLE [dbo].[tblIQEE_ReponsesRemplacement] (
    [iID_Reponse_Remplacement] INT          IDENTITY (1, 1) NOT NULL,
    [iID_Remplacement_IQEE]    INT          NOT NULL,
    [iID_Fichier_IQEE]         INT          NOT NULL,
    [vcStatutTransaction]      VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_IQEE_ReponsesRemplacement] PRIMARY KEY CLUSTERED ([iID_Reponse_Remplacement] ASC),
    CONSTRAINT [FK_IQEE_ReponsesRemplacement_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesRemplacement_IQEE_Fichiers_iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesRemplacement_IQEE_Remplacements_iIDRemplacementIQEE] FOREIGN KEY ([iID_Remplacement_IQEE]) REFERENCES [dbo].[tblIQEE_RemplacementsBeneficiaire] ([iID_Remplacement_Beneficiaire])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ReponsesRemplacement_iIDRemplacementIQEE]
    ON [dbo].[tblIQEE_ReponsesRemplacement]([iID_Remplacement_IQEE] ASC, [iID_Fichier_IQEE] ASC);

