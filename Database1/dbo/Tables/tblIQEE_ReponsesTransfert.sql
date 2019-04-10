CREATE TABLE [dbo].[tblIQEE_ReponsesTransfert] (
    [iID_Reponse_Transfert] INT          IDENTITY (1, 1) NOT NULL,
    [iID_Transfert_IQEE]    INT          NOT NULL,
    [iID_Fichier_IQEE]      INT          NOT NULL,
    [vcStatutTransaction]   VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_IQEE_ReponsesTransfert] PRIMARY KEY CLUSTERED ([iID_Reponse_Transfert] ASC),
    CONSTRAINT [FK_IQEE_ReponsesTransfert_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesTransfert_IQEE_Fichiers_iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesTransfert_IQEE_Transferts_iIDTransfertIQEE] FOREIGN KEY ([iID_Transfert_IQEE]) REFERENCES [dbo].[tblIQEE_Transferts] ([iID_Transfert])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ReponsesTransfert_iIDTransfertIQEE]
    ON [dbo].[tblIQEE_ReponsesTransfert]([iID_Transfert_IQEE] ASC, [iID_Fichier_IQEE] ASC);

