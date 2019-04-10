CREATE TABLE [dbo].[DemandeCOT] (
    [Id]                                    INT             NOT NULL,
    [IdConvention]                          INT             NOT NULL,
    [IdBeneficiaire]                        INT             NOT NULL,
    [IdSouscripteur]                        INT             NOT NULL,
    [EstQualifiee]                          BIT             NOT NULL,
    [IdRaisonRefus]                         INT             NULL,
    [RaisonRefusAutre]                      VARCHAR (MAX)   NULL,
    [InformationBancaireTransitInstitution] VARCHAR (75)    NULL,
    [InformationBancaireNumeroSuccursale]   VARCHAR (75)    NULL,
    [InformationBancaireNumeroCompte]       VARCHAR (75)    NULL,
    [EstAbandonnee]                         BIT             CONSTRAINT [DF_DemandeCOT_EstAbandonnee] DEFAULT ((0)) NOT NULL,
    [RaisonAbandon]                         VARCHAR (500)   NULL,
    [Montant]                               MONEY           NULL,
    [Frais]                                 MONEY           NULL,
    [NombreUnite]                           [dbo].[MoMoney] NULL,
    CONSTRAINT [PK_DemandeCOT] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_DemandeCOT_Demande__Id] FOREIGN KEY ([Id]) REFERENCES [dbo].[Demande] ([Id]),
    CONSTRAINT [FK_DemandeCOT_Un_Beneficiary__IdBeneficiaire] FOREIGN KEY ([IdBeneficiaire]) REFERENCES [dbo].[Un_Beneficiary] ([BeneficiaryID]),
    CONSTRAINT [FK_DemandeCOT_Un_Convention__IdConvention] FOREIGN KEY ([IdConvention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_DemandeCOT_Un_Subscriber__IdSouscripteur] FOREIGN KEY ([IdSouscripteur]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant la liste des demande traité ou abandonné d''ajout de cotisation du gestionnaire de demande de ProAcces.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la demande du gestionnaire de demande de ProAcces.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'Id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'IdConvention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'IdBeneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'IdSouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour les cas de demande qualifiée ou non-qualifiée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'EstQualifiee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la raison de refus de la demande.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'IdRaisonRefus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Texte pour la raison de refus de la demande.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'RaisonRefusAutre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numero d''institution ou transit bancaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'InformationBancaireTransitInstitution';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de succursale bancaire,', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'InformationBancaireNumeroSuccursale';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de compte bancaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'InformationBancaireNumeroCompte';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour les cas de demande abandonné.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'EstAbandonnee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Texte pour la raison d''abandon de la demande.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'RaisonAbandon';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant demandé pour l''ajout de cotisation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'Montant';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre de frais calculé pour l''ajout de cotisation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'Frais';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre d''unité calculé pour l''ajout de cotisation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeCOT', @level2type = N'COLUMN', @level2name = N'NombreUnite';

