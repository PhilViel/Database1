CREATE TABLE [dbo].[PreDemandePortail] (
    [Id]                                    INT           NOT NULL,
    [EstQualifiee]                          BIT           NOT NULL,
    [EstResidentQuebec]                     BIT           NOT NULL,
    [EstResidentCanada]                     BIT           NOT NULL,
    [EstRevenusImposables]                  BIT           NOT NULL,
    [EstDocumentsOriginaux]                 BIT           NOT NULL,
    [Commentaires]                          VARCHAR (MAX) NULL,
    [InformationBancaireTransitInstitution] VARCHAR (75)  NULL,
    [InformationBancaireNumeroSuccursale]   VARCHAR (75)  NULL,
    [InformationBancaireNumeroCompte]       VARCHAR (75)  NULL,
    [IdProgramme]                           INT           NULL,
    [IdEtablissement]                       INT           NULL,
    [TreizeSemainesDetudesCompletees]       BIT           NULL,
    [AnneeProgramme]                        INT           NULL,
    [DureeProgramme]                        INT           NULL,
    [IdTypePreuveEtude]                     TINYINT       NULL,
    CONSTRAINT [PK_PreDemandePortail] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_PreDemandePortail_TypePreuveEtude] FOREIGN KEY ([IdTypePreuveEtude]) REFERENCES [dbo].[tblCONV_TypePreuveEtude] ([tiID_TypePreuveEtude])
);

