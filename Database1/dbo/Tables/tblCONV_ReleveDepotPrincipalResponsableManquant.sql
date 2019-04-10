CREATE TABLE [dbo].[tblCONV_ReleveDepotPrincipalResponsableManquant] (
    [iIDConvention] [dbo].[MoID] NOT NULL,
    [dtDateReleve]  DATETIME     NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant la liste des conventions dont le responsable est manquant', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReleveDepotPrincipalResponsableManquant';

