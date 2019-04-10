CREATE TABLE [dbo].[tblOPER_RDI_RaisonPaiement] (
    [tiID_RDI_Raison_Paiement] TINYINT      IDENTITY (1, 1) NOT NULL,
    [vcCode_Raison]            VARCHAR (20) NOT NULL,
    [vcDescription]            VARCHAR (50) NULL,
    CONSTRAINT [PK_OPER_RDI_RaisonPaiement] PRIMARY KEY CLUSTERED ([tiID_RDI_Raison_Paiement] ASC) WITH (FILLFACTOR = 90)
);

