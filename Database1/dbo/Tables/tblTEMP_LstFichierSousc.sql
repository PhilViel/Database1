CREATE TABLE [dbo].[tblTEMP_LstFichierSousc] (
    [id]   INT             IDENTITY (1, 1) NOT NULL,
    [line] NVARCHAR (1000) NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table temporaire utilisée pour lister les fichiers d''un souscripteur sur le P: (psGENE_ObtenirListeFichierSouscripteur)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_LstFichierSousc';

