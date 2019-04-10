CREATE TABLE [dbo].[DemandePRA] (
    [Id]                                            INT            NOT NULL,
    [IdConvention]                                  INT            NOT NULL,
    [IdBeneficiaire]                                INT            NOT NULL,
    [IdSouscripteur]                                INT            NOT NULL,
    [IdCoSouscripteur]                              INT            NULL,
    [ConventionStateName]                           VARCHAR (75)   NULL,
    [TypeDestination]                               INT            NOT NULL,
    [PreuveDeficienceRecue]                         BIT            CONSTRAINT [DF_DemandePRA_PreuveDeficienceRecue] DEFAULT ((0)) NOT NULL,
    [CotisationsInutilisees]                        MONEY          NULL,
    [IdSouscripteurOriginal]                        INT            NULL,
    [IdLienEntreSouscripteurEtSouscripteurOriginal] TINYINT        NULL,
    [RaisonChangementSouscripteurId]                TINYINT        NULL,
    [RentierNom]                                    VARCHAR (50)   NULL,
    [RentierPrenom]                                 VARCHAR (50)   NULL,
    [RentierNAS]                                    VARCHAR (10)   NULL,
    [RentierTypeID]                                 TINYINT        NULL,
    [InstitutionFinanciereNom]                      VARCHAR (100)  NULL,
    [InstitutionFinanciereNoCompte]                 VARCHAR (20)   NULL,
    [InstitutionFinanciereAdresse]                  VARCHAR (250)  NULL,
    [EstQualifiee]                                  BIT            CONSTRAINT [DF_DemandePRA_EstQualifiee] DEFAULT ((0)) NOT NULL,
    [EstAbandonnee]                                 BIT            CONSTRAINT [DF_DemandePRA_EstAbandonnee] DEFAULT ((0)) NOT NULL,
    [RaisonAbandon]                                 VARCHAR (500)  NULL,
    [RaisonRefusListeIds]                           VARCHAR (100)  NULL,
    [RaisonRefusAutre]                              VARCHAR (500)  NULL,
    [ModePaiement]                                  INT            NULL,
    [PourcentageDemande]                            DECIMAL (5, 4) CONSTRAINT [DF_DemandePRA_PourcentageDemande] DEFAULT ((1)) NULL,
    [SoldeRevenuAccumule]                           MONEY          NULL,
    [IdOper]                                        INT            NULL,
    [LoginName]                                     VARCHAR (75)   CONSTRAINT [DF_DemandePRA_LoginName] DEFAULT ([dbo].[GetUserContext]()) NOT NULL,
    [DateCreation]                                  DATETIME       CONSTRAINT [DF_DemandePRA_DateCreation] DEFAULT (getdate()) NOT NULL,
    [DateModification]                              DATETIME       NULL,
    [IdRaisonRefus]                                 INT            NULL,
    CONSTRAINT [PK_DemandePRA] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_DemandePRA_Demande__Id] FOREIGN KEY ([Id]) REFERENCES [dbo].[Demande] ([Id]),
    CONSTRAINT [FK_DemandePRA_Un_Beneficiary__IdBeneficiaire] FOREIGN KEY ([IdBeneficiaire]) REFERENCES [dbo].[Un_Beneficiary] ([BeneficiaryID]),
    CONSTRAINT [FK_DemandePRA_Un_Convention__IdConvention] FOREIGN KEY ([IdConvention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_DemandePRA_Un_Subscriber__IdSouscripteur] FOREIGN KEY ([IdSouscripteur]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID])
);


GO
CREATE TRIGGER [dbo].[TRG_DemandePRA] ON [dbo].[DemandePRA] FOR INSERT
AS BEGIN
	UPDATE [dbo].[DemandePRA] SET IdSouscripteurOriginal = IdSouscripteur
	WHERE IdSouscripteurOriginal IS NULL
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Raison du dernier changement de Souscripteur pour la Convention. (0 = Divorce/Séparation, 1 = Décès)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandePRA', @level2type = N'COLUMN', @level2name = N'RaisonChangementSouscripteurId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type identifiant à qui le REER ou REEI (0 = Souscripteur, 1 = Conjoint)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandePRA', @level2type = N'COLUMN', @level2name = N'RentierTypeID';

