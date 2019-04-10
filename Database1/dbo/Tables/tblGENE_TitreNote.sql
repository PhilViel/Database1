CREATE TABLE [dbo].[tblGENE_TitreNote] (
    [iID_TitreNote] INT           IDENTITY (1, 1) NOT NULL,
    [vcTitreNote]   VARCHAR (128) NOT NULL,
    [cCodeTitre]    CHAR (10)     NULL,
    CONSTRAINT [PK_GENE_TitreNote] PRIMARY KEY CLUSTERED ([iID_TitreNote] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les différents titres de note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TitreNote';

