CREATE TABLE [dbo].[tblIQEE_PaiementsBeneficiaires] (
    [iID_Paiement_Beneficiaire]     INT           IDENTITY (1, 1) NOT NULL,
    [iID_Fichier_IQEE]              INT           NOT NULL,
    [tiCode_Version]                TINYINT       NOT NULL,
    [cStatut_Reponse]               CHAR (1)      NOT NULL,
    [iID_Convention]                INT           NOT NULL,
    [vcNo_Convention]               VARCHAR (15)  NOT NULL,
    [iID_Sous_Type]                 INT           NOT NULL,
    [iID_Bourse]                    INT           NULL,
    [iID_Paiement_Bourse]           INT           NULL,
    [iID_Operation]                 INT           NULL,
    [dtDate_Paiement]               DATETIME      NOT NULL,
    [bRevenus_Accumules]            BIT           NULL,
    [mCotisations_Retirees]         MONEY         NULL,
    [mIQEE_CreditBase]              MONEY         NOT NULL,
    [mIQEE_Majoration]              MONEY         NOT NULL,
    [mPAE_Verse]                    MONEY         NOT NULL,
    [mSolde_IQEE]                   MONEY         NULL,
    [mJuste_Valeur_Marchande]       MONEY         NULL,
    [mCotisations_Versees]          MONEY         NULL,
    [mBEC_Autres_Beneficiaires]     MONEY         NULL,
    [mBEC_Beneficiaire]             MONEY         NULL,
    [mSolde_SCEE]                   MONEY         NULL,
    [mProgrammes_Autres_Provinces]  MONEY         NULL,
    [iID_Beneficiaire]              INT           NOT NULL,
    [vcNAS_Beneficiaire]            VARCHAR (9)   NOT NULL,
    [vcNom_Beneficiaire]            VARCHAR (20)  NOT NULL,
    [vcPrenom_Beneficiaire]         VARCHAR (20)  NOT NULL,
    [dtDate_Naissance_Beneficiaire] DATETIME      NOT NULL,
    [tiSexe_Beneficiaire]           TINYINT       NOT NULL,
    [bResidence_Quebec]             BIT           NULL,
    [tiType_Etudes]                 TINYINT       NOT NULL,
    [tiDuree_Programme]             TINYINT       NOT NULL,
    [tiAnnee_Programme]             TINYINT       NOT NULL,
    [dtDate_Debut_Annee_Scolaire]   DATETIME      NOT NULL,
    [tiDuree_Annee_Scolaire]        TINYINT       NOT NULL,
    [vcCode_Postal_Etablissement]   VARCHAR (10)  NOT NULL,
    [vcNom_Etablissement]           VARCHAR (150) NULL,
    [iID_Ligne_Fichier]             INT           NULL,
    [siAnnee_Fiscale]               INT           NOT NULL,
    CONSTRAINT [PK_IQEE_PaiementsBeneficiaires] PRIMARY KEY CLUSTERED ([iID_Paiement_Beneficiaire] ASC),
    CONSTRAINT [FK_IQEE_PaiementsBeneficiaires_Convention__iIDConvention] FOREIGN KEY ([iID_Convention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_IQEE_PaiementsBeneficiaires_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_PaiementsBeneficiaires_SousTypeEnregistrement__iIDSousType] FOREIGN KEY ([iID_Sous_Type]) REFERENCES [dbo].[tblIQEE_SousTypeEnregistrement] ([iID_Sous_Type])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_PaiementsBeneficiaires_iIDBeneficiaire_iIDConvention_siAnneeFiscale_dtDatePaiement]
    ON [dbo].[tblIQEE_PaiementsBeneficiaires]([iID_Beneficiaire] ASC, [iID_Convention] ASC, [siAnnee_Fiscale] ASC, [dtDate_Paiement] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_PaiementsBeneficiaires_iIDConvention_siAnneeFiscale_dtDatePaiement]
    ON [dbo].[tblIQEE_PaiementsBeneficiaires]([iID_Convention] ASC, [siAnnee_Fiscale] ASC, [dtDate_Paiement] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_PaiementsBeneficiaires_siAnneeFiscale_dtDatePaiement]
    ON [dbo].[tblIQEE_PaiementsBeneficiaires]([siAnnee_Fiscale] ASC, [dtDate_Paiement] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_PaiementsBeneficiaires_vcNoConvention_siAnneeFiscale_dtDatePaiement]
    ON [dbo].[tblIQEE_PaiementsBeneficiaires]([vcNo_Convention] ASC, [siAnnee_Fiscale] ASC, [dtDate_Paiement] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [ixIQEE_PaiementsBeneficiaires__iIDFichier_siAnneeFiscale]
    ON [dbo].[tblIQEE_PaiementsBeneficiaires]([iID_Fichier_IQEE] ASC, [siAnnee_Fiscale] ASC)
    INCLUDE([iID_Paiement_Beneficiaire], [tiCode_Version], [cStatut_Reponse]);

