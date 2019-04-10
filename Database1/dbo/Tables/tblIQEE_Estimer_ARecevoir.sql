﻿CREATE TABLE [dbo].[tblIQEE_Estimer_ARecevoir] (
    [iID_Estimer_ARecevoir]    INT            IDENTITY (1, 1) NOT NULL,
    [iID_Plan]                 INT            NOT NULL,
    [siAnnee_Cohorte]          SMALLINT       NULL,
    [iID_Beneficiaire]         INT            NOT NULL,
    [siAnnee_Fiscale]          SMALLINT       NULL,
    [tiID_TypeEnregistrement]  TINYINT        NOT NULL,
    [iId_SousType]             INT            NULL,
    [iID_Evenement]            INT            NULL,
    [dtEvenement]              DATE           NULL,
    [iID_Convention]           INT            NOT NULL,
    [vcNo_Convention]          VARCHAR (15)   NOT NULL,
    [mMontant_Subventionnable] MONEY          NOT NULL,
    [mMontant_Admissible]      MONEY          NOT NULL,
    [mMontant_Majorable]       MONEY          NOT NULL,
    [fPourcentMajoration]      DECIMAL (5, 4) NOT NULL,
    [mCreditBase_Estime]       MONEY          NOT NULL,
    [mMajoration_Estime]       MONEY          NOT NULL,
    [mTotal_Estime]            MONEY          NOT NULL,
    [fCreditBase_Partage]      DECIMAL (8, 6) NULL,
    [fMajoration_Partage]      DECIMAL (8, 6) NULL,
    [dtFin_ARecevoir]          DATE           NOT NULL,
    [dtCreation]               DATETIME       NOT NULL,
    CONSTRAINT [PK_tblIQEE_Estimer_ARecevoir] PRIMARY KEY CLUSTERED ([iID_Estimer_ARecevoir] ASC),
    CONSTRAINT [FK_IQEE_EstimerARecevoir_Convention__iIDConvention] FOREIGN KEY ([iID_Convention]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);

