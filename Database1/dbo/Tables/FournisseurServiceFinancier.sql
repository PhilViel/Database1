CREATE TABLE [dbo].[FournisseurServiceFinancier] (
    [ID]                                  INT          IDENTITY (1, 1) NOT NULL,
    [Nom]                                 VARCHAR (50) NULL,
    [CodeInstitution]                     VARCHAR (4)  NULL,
    [HeureTransmission]                   TIME (7)     NOT NULL,
    [ValeurDelaiVerificationTraitement]   INT          NOT NULL,
    [ValeurDelaiVerificationDecaissement] INT          NOT NULL,
    [ValeurDelaiAttenteEffetRetourne]     INT          NOT NULL,
    [HeureOuverture]                      TIME (7)     CONSTRAINT [DF_FournisseurServiceFinancier_HeureOuverture] DEFAULT ('00:00:00') NOT NULL,
    [HeureFermeture]                      TIME (7)     CONSTRAINT [DF_FournisseurServiceFinancier_HeureFermeture] DEFAULT ('00:00:00') NOT NULL,
    CONSTRAINT [PK_FournisseurServiceFinancier] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

