CREATE TABLE [dbo].[DemandeRaisonRefus] (
    [ID]                  INT           NOT NULL,
    [RaisonRefus]         VARCHAR (250) NOT NULL,
    [TypeDemande]         INT           NOT NULL,
    [EstActif]            BIT           CONSTRAINT [DF_DemandeRaisonRefus_EstActif] DEFAULT ((1)) NOT NULL,
    [RaisonRefusFrancais] VARCHAR (500) NULL,
    [RaisonRefusAnglais]  VARCHAR (500) NULL,
    CONSTRAINT [PK_DemandeRaisonRefus] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

