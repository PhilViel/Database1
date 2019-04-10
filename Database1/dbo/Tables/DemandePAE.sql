﻿CREATE TABLE [dbo].[DemandePAE] (
    [Id]                                    INT           NOT NULL,
    [IdPlan]                                INT           NOT NULL,
    [IdProgramme]                           INT           NULL,
    [IdConvention]                          INT           NOT NULL,
    [IdBeneficiaire]                        INT           NULL,
    [IdSouscripteur]                        INT           NULL,
    [IdOperationFinanciere]                 INT           NULL,
    [IdOperationFinanciereRgc]              INT           NULL,
    [IdRaisonRefus]                         INT           NULL,
    [EstQualifiee]                          BIT           NOT NULL,
    [PreuveDinscriptionRecue]               BIT           NOT NULL,
    [ReleveNotesRecu]                       BIT           NOT NULL,
    [TreizeSemainesEtudesCompletees]        BIT           NOT NULL,
    [BeneficiaireEstResidentDeFaitAuCanada] BIT           NOT NULL,
    [BeneficiaireEtudieATempsPlein]         BIT           NOT NULL,
    [BeneficiaireEtudieATempsPartiel]       BIT           NOT NULL,
    [BeneficiaireEstResidentDeFaitAuQuebec] BIT           NOT NULL,
    [BeneficiaireDevancement]               BIT           CONSTRAINT [DF_DemandePAE_BeneficiaireDevancement] DEFAULT ((0)) NOT NULL,
    [MontantPaeDemande]                     MONEY         NULL,
    [PourcentageProportionPaeDemande]       MONEY         NULL,
    [OrdreVersement]                        SMALLINT      NOT NULL,
    [RaisonRefusAutre]                      VARCHAR (MAX) NULL,
    [SoldesConfondus]                       MONEY         NULL,
    [SoldeDisponible]                       MONEY         NULL,
    [LimiteSolde]                           MONEY         NULL,
    [SoldeRistourneAssurance]               MONEY         NULL,
    [DateExecutionPae]                      DATETIME      NULL,
    [EtatConvention]                        VARCHAR (75)  NULL,
    [NumeroConvention]                      VARCHAR (15)  NOT NULL,
    [ProgrammeEtudeIdEtablissement]         INT           NULL,
    [ProgrammeEtudeNumeroAnneeCourante]     INT           NULL,
    [ProgrammeEtudeDureeProgrammeEnAnnees]  INT           NULL,
    [ProgrammeEtudeDateDebutAnneeScolaire]  DATETIME      NULL,
    [ReussiteAcademiqueMesure]              VARCHAR (25)  NULL,
    [ReussiteAcademiqueValeur]              SMALLINT      NULL,
    [InformationBancaireTransitInstitution] VARCHAR (75)  NULL,
    [InformationBancaireNumeroSuccursale]   VARCHAR (75)  NULL,
    [InformationBancaireNumeroCompte]       VARCHAR (75)  NULL,
    [EstAbandonnee]                         BIT           CONSTRAINT [DF_DemandePAE_EstAbandonnee] DEFAULT ((0)) NOT NULL,
    [RaisonAbandon]                         VARCHAR (500) NULL,
    [bDestinataireEstSouscripteur]          BIT           CONSTRAINT [DF_DemandePAE_bDestinataireEstSouscripteur] DEFAULT ((0)) NULL,
    [IdTypePreuveEtude]                     TINYINT       NULL,
    CONSTRAINT [PK_DemandePAE] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_DemandePAE_Demande__Id] FOREIGN KEY ([Id]) REFERENCES [dbo].[Demande] ([Id]),
    CONSTRAINT [FK_DemandePAE_TypePreuveEtude] FOREIGN KEY ([IdTypePreuveEtude]) REFERENCES [dbo].[tblCONV_TypePreuveEtude] ([tiID_TypePreuveEtude]),
    CONSTRAINT [FK_DemandePAE_Un_Beneficiary__IdBeneficiaire] FOREIGN KEY ([IdBeneficiaire]) REFERENCES [dbo].[Un_Beneficiary] ([BeneficiaryID]),
    CONSTRAINT [FK_DemandePAE_Un_Convention__IdConvention] FOREIGN KEY ([IdConvention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_DemandePAE_Un_Subscriber__IdSouscripteur] FOREIGN KEY ([IdSouscripteur]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Si vrai, indique que le compte de destination est celui du souscripteur. Si faux, le compte est celui du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandePAE', @level2type = N'COLUMN', @level2name = N'bDestinataireEstSouscripteur';

