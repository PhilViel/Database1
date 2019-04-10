CREATE TABLE [dbo].[tblOPER_RDI_Paiements_Rembourses] (
    [iID_RDI_Paiement] INT      NULL,
    [DateInserted]     DATETIME CONSTRAINT [DF_OPER_RDI_Paiements_Rembourses_DateInserted] DEFAULT (getdate()) NULL
);

