﻿CREATE TABLE [dbo].[DemandeRin] (
    [Id]                                    INT           NOT NULL,
    [IdConvention]                          INT           NULL,
    [IdPlan]                                INT           NOT NULL,
    [DateEcheance]                          DATETIME      NULL,
    [IdSouscripteur]                        INT           NULL,
    [IdBeneficiaire]                        INT           NULL,
    [InformationBancaireTransitInstitution] VARCHAR (75)  NULL,
    [InformationBancaireNumeroSuccursale]   VARCHAR (75)  NULL,
    [InformationBancaireNumeroCompte]       VARCHAR (75)  NULL,
    [ModePaiement]                          INT           NOT NULL,
    [EstQualifiee]                          BIT           NOT NULL,
    [RaisonRefusAutre]                      VARCHAR (MAX) NULL,
    [IdRaisonRefus]                         INT           NULL,
    [DateExecutionRin]                      DATETIME      NULL,
    [AvecPreuve]                            BIT           NOT NULL,
    [EtablissementId]                       INT           NULL,
    [ProgrammeId]                           INT           NULL,
    [PourcentagePartRIN]                    MONEY         NOT NULL,
    [TypeDestinataire]                      INT           NOT NULL,
    [IdOperationRin]                        INT           NULL,
    [IdDestinataire]                        INT           NULL,
    [EstAbandonnee]                         BIT           NULL,
    [RaisonAbandon]                         VARCHAR (500) NULL,
    [NumeroConvention]                      VARCHAR (15)  CONSTRAINT [DF_DemandeRin_NumeroConvention] DEFAULT ('') NOT NULL,
    [NumeroAnneeCourante]                   INT           NULL,
    [DureeProgrammeEnAnnees]                INT           NULL,
    [DateDebutAnneeScolaire]                DATETIME      NULL,
    [IdTypePreuveEtude]                     TINYINT       NULL,
    CONSTRAINT [PK_DemandeRin] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_DemandeRin_Demande__Id] FOREIGN KEY ([Id]) REFERENCES [dbo].[Demande] ([Id]),
    CONSTRAINT [FK_DemandeRIN_TypePreuveEtude] FOREIGN KEY ([IdTypePreuveEtude]) REFERENCES [dbo].[tblCONV_TypePreuveEtude] ([tiID_TypePreuveEtude]),
    CONSTRAINT [FK_DemandeRin_Un_Beneficiary__IdBeneficiaire] FOREIGN KEY ([IdBeneficiaire]) REFERENCES [dbo].[Un_Beneficiary] ([BeneficiaryID]),
    CONSTRAINT [FK_DemandeRin_Un_Convention__IdConvention] FOREIGN KEY ([IdConvention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_DemandeRin_Un_Subscriber__IdSouscripteur] FOREIGN KEY ([IdSouscripteur]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID])
);

