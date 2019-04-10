CREATE TABLE [dbo].[tblGENE_TypeNote] (
    [iId_TypeNote]  INT          IDENTITY (1, 1) NOT NULL,
    [tNoteTypeDesc] TEXT         NOT NULL,
    [cCodeTypeNote] VARCHAR (75) NULL,
    [bActif]        BIT          CONSTRAINT [DF_GENE_TypeNote_bActif] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_GENE_TypeNote] PRIMARY KEY CLUSTERED ([iId_TypeNote] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_GENE_TypeNote_cCodeTypeNote]
    ON [dbo].[tblGENE_TypeNote]([cCodeTypeNote] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les codes des types de note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeNote';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du type d''objet', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeNote', @level2type = N'COLUMN', @level2name = N'iId_TypeNote';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type de note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeNote', @level2type = N'COLUMN', @level2name = N'tNoteTypeDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code identifiant le type de note', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeNote', @level2type = N'COLUMN', @level2name = N'cCodeTypeNote';

