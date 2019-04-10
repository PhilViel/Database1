CREATE TABLE [dbo].[tblCONV_ReleveDepotPrincipalResponsableErreur] (
    [iIDSouscripteur] [dbo].[MoID] NOT NULL,
    [iIDBeneficiaire] [dbo].[MoID] NOT NULL,
    [dtdatereleve]    DATETIME     NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant la liste des souscripteurs / bénéficiaires dont le responsable est en erreur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReleveDepotPrincipalResponsableErreur';

