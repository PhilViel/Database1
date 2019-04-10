CREATE TABLE [dbo].[tblCONV_NbPsPrep] (
    [iNbPsPrep] INT NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de travail servant à la génération des relevés de dépôt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_NbPsPrep';

