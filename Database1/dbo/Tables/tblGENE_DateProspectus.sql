CREATE TABLE [dbo].[tblGENE_DateProspectus] (
    [iIDDateProspectus] INT      IDENTITY (1, 1) NOT NULL,
    [dtDateProspectus]  DATETIME NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les dates de prospectus', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_DateProspectus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique interne de la date de prospectus', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_DateProspectus', @level2type = N'COLUMN', @level2name = N'iIDDateProspectus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur de la date de prospectus', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_DateProspectus', @level2type = N'COLUMN', @level2name = N'dtDateProspectus';

