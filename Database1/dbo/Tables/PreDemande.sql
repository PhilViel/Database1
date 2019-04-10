CREATE TABLE [dbo].[PreDemande] (
    [Id]                     INT           IDENTITY (1, 1) NOT NULL,
    [IdBeneficiaire]         INT           NULL,
    [IdSouscripteur]         INT           NULL,
    [NumerosConventions]     VARCHAR (MAX) NOT NULL,
    [DateCreation]           DATETIME      NULL,
    [TypeDemande]            INT           NOT NULL,
    [Type]                   INT           NOT NULL,
    [bDemandeurSouscripteur] BIT           NULL,
    CONSTRAINT [PK_PreDemande] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_PreDemande_Un_Beneficiary__IdBeneficiaire] FOREIGN KEY ([IdBeneficiaire]) REFERENCES [dbo].[Un_Beneficiary] ([BeneficiaryID]) ON DELETE CASCADE,
    CONSTRAINT [FK_PreDemande_Un_Subscriber__IdSouscripteur] FOREIGN KEY ([IdSouscripteur]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID])
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[PreDemande] TO [svc-elk]
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de demande (0 = PAE, 1 = RIN, 2 = ARI, 3 = DND, 4 = DDD, 5 = PRA, 6 = Ajout de cotisation Portail)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'PreDemande', @level2type = N'COLUMN', @level2name = N'TypeDemande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de pré-demande (0 et/ou 2 = Kofax, 1 = Portail, 3 = Proacces)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'PreDemande', @level2type = N'COLUMN', @level2name = N'Type';

