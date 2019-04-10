CREATE TABLE [dbo].[tblIQEE_Erreurs] (
    [iID_Erreur]                   INT          IDENTITY (1, 1) NOT NULL,
    [iID_Fichier_IQEE]             INT          NOT NULL,
    [tiID_Type_Enregistrement]     TINYINT      NULL,
    [iID_Enregistrement]           INT          NULL,
    [siCode_Erreur]                SMALLINT     NOT NULL,
    [vcElement_Erreur]             VARCHAR (30) NULL,
    [vcValeur_Erreur]              VARCHAR (40) NULL,
    [tiID_Statuts_Erreur]          TINYINT      NOT NULL,
    [iID_Utilisateur_Modification] INT          NULL,
    [dtDate_Modification]          DATETIME     NULL,
    [iID_Utilisateur_Traite]       INT          NULL,
    [dtDate_Traite]                DATETIME     NULL,
    [tCommentaires]                TEXT         NULL,
    CONSTRAINT [PK_IQEE_Erreurs] PRIMARY KEY CLUSTERED ([iID_Erreur] ASC),
    CONSTRAINT [FK_IQEE_Erreurs_Fichiers_iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_Erreurs_StatutsErreur_tiIDStatutsErreur] FOREIGN KEY ([tiID_Statuts_Erreur]) REFERENCES [dbo].[tblIQEE_StatutsErreur] ([tiID_Statuts_Erreur]),
    CONSTRAINT [FK_IQEE_Erreurs_TypesEnregistrement_tiIDTypeEnregistrement] FOREIGN KEY ([tiID_Type_Enregistrement]) REFERENCES [dbo].[tblIQEE_TypesEnregistrement] ([tiID_Type_Enregistrement]),
    CONSTRAINT [FK_IQEE_Erreurs_TypesErreurRQ_siCodeErreur] FOREIGN KEY ([siCode_Erreur]) REFERENCES [dbo].[tblIQEE_TypesErreurRQ] ([siCode_Erreur])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_Erreurs_Fichier_TypeEnreg_Enreg]
    ON [dbo].[tblIQEE_Erreurs]([iID_Fichier_IQEE] ASC, [tiID_Type_Enregistrement] ASC, [iID_Enregistrement] ASC, [siCode_Erreur] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Erreurs_TypeErreurRQ]
    ON [dbo].[tblIQEE_Erreurs]([siCode_Erreur] ASC);

