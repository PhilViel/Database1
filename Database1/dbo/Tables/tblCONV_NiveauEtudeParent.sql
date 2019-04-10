CREATE TABLE [dbo].[tblCONV_NiveauEtudeParent] (
    [iIDNiveauEtudeParent]    INT          IDENTITY (1, 1) NOT NULL,
    [vcDescNiveauEtudeParent] VARCHAR (75) NOT NULL,
    CONSTRAINT [PK_CONV_NiveauEtudeParent] PRIMARY KEY CLUSTERED ([iIDNiveauEtudeParent] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les niveaux d`étude des parents', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_NiveauEtudeParent';

