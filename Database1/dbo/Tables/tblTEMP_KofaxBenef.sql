CREATE TABLE [dbo].[tblTEMP_KofaxBenef] (
    [vcDossier] VARCHAR (100) NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table temporaire utilisée pour transférer la liste des dossiers du P: à Kofax (psGENE_MiseAJourKofaxSFTP)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_KofaxBenef';

