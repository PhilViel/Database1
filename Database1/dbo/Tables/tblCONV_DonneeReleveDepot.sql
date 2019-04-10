﻿CREATE TABLE [dbo].[tblCONV_DonneeReleveDepot] (
    [iIDConvention]                     INT              NULL,
    [iIDSouscripteur]                   INT              NULL,
    [iIDBeneficiaire]                   INT              NULL,
    [vcNumeroConvention]                VARCHAR (20)     NULL,
    [mQuantiteUnite]                    MONEY            NULL,
    [vcTypeOperation]                   VARCHAR (3)      NULL,
    [mFraisCotisation]                  MONEY            NULL,
    [mFrais]                            MONEY            NULL,
    [mSCEE]                             MONEY            NULL,
    [mIntSCEE]                          MONEY            NULL,
    [mSCEESup]                          MONEY            NULL,
    [mIntSCEESup]                       MONEY            NULL,
    [mIQEE]                             MONEY            NULL,
    [mIntIQEE]                          MONEY            NULL,
    [mBec]                              MONEY            NULL,
    [mIntBEC]                           MONEY            NULL,
    [mPAE]                              MONEY            NULL,
    [mIntPAE]                           MONEY            NULL,
    [mAutreRev]                         MONEY            NULL,
    [mIntAutreRev]                      MONEY            NULL,
    [vcAnneeQualif]                     INT              NULL,
    [mBourse]                           MONEY            NULL,
    [mMntSouscrit]                      MONEY            NULL,
    [mMntTheoMens]                      MONEY            NULL,
    [dtEntreeVigueur]                   DATETIME         NULL,
    [dtRembEstime]                      DATETIME         NULL,
    [dtFinCotisation]                   DATETIME         NULL,
    [dtFinRegime]                       DATETIME         NULL,
    [vcPrenomRep]                       VARCHAR (100)    NULL,
    [vcNomRep]                          VARCHAR (100)    NULL,
    [vcTelRep]                          VARCHAR (20)     NULL,
    [vcPrenomDir]                       VARCHAR (100)    NULL,
    [vcNomDir]                          VARCHAR (100)    NULL,
    [vcTelDir]                          VARCHAR (20)     NULL,
    [mCoutEtude]                        MONEY            NULL,
    [vcPrenomSouscripteur]              VARCHAR (100)    NULL,
    [vcNomSouscripteur]                 VARCHAR (100)    NULL,
    [vcAdresseSouscripteur]             VARCHAR (200)    NULL,
    [vcVilleSouscripteur]               VARCHAR (100)    NULL,
    [vcProvinceSouscripteur]            VARCHAR (100)    NULL,
    [vcPaysSouscripteur]                VARCHAR (100)    NULL,
    [vcCodePostSouscripteur]            VARCHAR (50)     NULL,
    [bPrincipalResponsableErreur]       BIT              NULL,
    [bPrincipalResponsableManquant]     BIT              NULL,
    [vcLangue]                          VARCHAR (50)     NULL,
    [vcPrenomBenef]                     VARCHAR (100)    NULL,
    [vcNomBenef]                        VARCHAR (100)    NULL,
    [vcNASBenef]                        VARCHAR (75)     NULL,
    [dtDateOperation]                   DATETIME         NULL,
    [vcCompagnie]                       VARCHAR (200)    NULL,
    [vcRegime]                          VARCHAR (50)     NULL,
    [vcTypeDonnee]                      CHAR (1)         NULL,
    [vcTexteDiplome]                    VARCHAR (150)    NULL,
    [iIDRegime]                         VARCHAR (3)      NULL,
    [vcDerniereAnnee]                   VARCHAR (4)      NULL,
    [vcAvantDernAnnee]                  VARCHAR (50)     NULL,
    [vcCourrielSouscripteur]            VARCHAR (100)    NULL,
    [vcTypeContact]                     VARCHAR (3)      NULL,
    [cSexeSouscripteur]                 CHAR (1)         NULL,
    [iPayementParAnnee]                 INT              NULL,
    [iNombrePayement]                   INT              NULL,
    [dtDateCalcul]                      DATETIME         NULL,
    [dtDateFin]                         DATETIME         NULL,
    [bSouscripteur_Desire_Releve_Elect] BIT              NULL,
    [mIQEEMaj]                          MONEY            NULL,
    [iNbGroupeUnite]                    INT              NULL,
    [bEntreeVigueurIQEE]                BIT              NULL,
    [bEntreeVigueurSCEE]                BIT              NULL,
    [nDiffAnneeIQEE]                    NUMERIC (18, 10) NULL,
    [nDiffAnneeSCEE]                    NUMERIC (18, 10) NULL,
    [dtEcheance]                        DATETIME         NULL,
    [dtDateFinGeneration]               DATETIME         NULL,
    [mIntAutreRevTINDiffere]            MONEY            NULL,
    [mIntIQEETIN]                       MONEY            NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_DonneeReleveDepot_iIDConvention_iIDSouscripteur_iIDBeneficiaire_vcRegime_vcTypeDonnee]
    ON [dbo].[tblCONV_DonneeReleveDepot]([iIDConvention] ASC, [iIDSouscripteur] ASC, [iIDBeneficiaire] ASC, [vcRegime] ASC, [vcTypeDonnee] DESC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_DonneeReleveDepot_iIDConvention]
    ON [dbo].[tblCONV_DonneeReleveDepot]([iIDConvention] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CONV_DonneeReleveDepot_iIDSouscripteur]
    ON [dbo].[tblCONV_DonneeReleveDepot]([iIDSouscripteur] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des données servant à la génération des relevés de dépôt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_DonneeReleveDepot';

