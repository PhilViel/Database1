CREATE TABLE [dbo].[DecaissementDepotDirect] (
    [Id]                                    INT             IDENTITY (1, 1) NOT NULL,
    [IdDecaissementDepotDirectInitial]      INT             NULL,
    [IdDemande]                             INT             NOT NULL,
    [IdOperationFinanciere]                 INT             NOT NULL,
    [IdPlan]                                INT             NOT NULL,
    [IdDemandeur]                           INT             NOT NULL,
    [IdDestinataire]                        INT             NOT NULL,
    [TypeDestinataire]                      INT             NOT NULL,
    [NumeroConvention]                      VARCHAR (15)    NOT NULL,
    [Montant]                               DECIMAL (18, 2) NOT NULL,
    [InformationBancaireTransitInstitution] VARCHAR (75)    NULL,
    [InformationBancaireNumeroSuccursale]   VARCHAR (75)    NULL,
    [InformationBancaireNumeroCompte]       VARCHAR (75)    NULL,
    [CodeEchec]                             VARCHAR (MAX)   NULL,
    [DateCreation]                          DATETIME        NULL,
    [DateTransmission]                      DATETIME        NULL,
    [DateConfirmation]                      DATETIME        NULL,
    [DateDecaissement]                      DATETIME        NULL,
    [DateFinalise]                          DATETIME        NULL,
    [DateAnnule]                            DATETIME        NULL,
    [DateEffetRetourne]                     DATETIME        NULL,
    [DateRejete]                            DATETIME        NULL,
    [IdRaisonAnnulation]                    INT             NULL,
    [RaisonAnnulation]                      VARCHAR (150)   NULL,
    [IdRaisonEffetRetourne]                 VARCHAR (4)     NULL,
    [IdConvention]                          INT             NULL,
    [EtatConvention]                        VARCHAR (15)    NULL,
    [TypeDemande]                           INT             NULL,
    [InfoDemandeParent]                     VARCHAR (15)    NULL,
    [NonDecaissePar]                        VARCHAR (50)    NULL,
    CONSTRAINT [PK_DecaissementDepotDirect] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_DecaissementDepotDirect_DecaissementDepotDirectRaisonAnnulation__IdRaisonAnnulation] FOREIGN KEY ([IdRaisonAnnulation]) REFERENCES [dbo].[DecaissementDepotDirectRaisonAnnulation] ([IDRaisonAnnulation]),
    CONSTRAINT [FK_DecaissementDepotDirect_Mo_BankReturnType__IdRaisonEffetRetourne] FOREIGN KEY ([IdRaisonEffetRetourne]) REFERENCES [dbo].[Mo_BankReturnType] ([BankReturnTypeID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DecaissementDepotDirect', @level2type = N'COLUMN', @level2name = N'IdConvention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'État de la convention au moment de du décaissement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DecaissementDepotDirect', @level2type = N'COLUMN', @level2name = N'EtatConvention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de la demande (PAE, RIN) en lien avec le décaissement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DecaissementDepotDirect', @level2type = N'COLUMN', @level2name = N'TypeDemande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Information sur la demande parent.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DecaissementDepotDirect', @level2type = N'COLUMN', @level2name = N'InfoDemandeParent';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identité de l’usager (ou banque) qui annule, rejette ou refuse un décaissement par dépôt direct.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DecaissementDepotDirect', @level2type = N'COLUMN', @level2name = N'NonDecaissePar';

