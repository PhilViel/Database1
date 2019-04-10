CREATE TABLE [dbo].[DocumentImpression] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [DateCreation]     DATETIME     CONSTRAINT [DF_DocumentImpression_DateCreation] DEFAULT (getdate()) NOT NULL,
    [CodeTypeDocument] VARCHAR (25) NOT NULL,
    [TypeObjetLie]     INT          NOT NULL,
    [IdObjetLie]       INT          NOT NULL,
    [EstEmis]          BIT          CONSTRAINT [DF_DocumentImpression_EstEmis] DEFAULT ((0)) NOT NULL,
    [LoginName]        VARCHAR (50) NULL,
    [IdDestinataire]   INT          NULL,
    CONSTRAINT [PK_DocumentImpression] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''objet relié à l''impression du document. (0=Convention, 1=Groupe d''unités, 2=Humain, 3=Demande) ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DocumentImpression', @level2type = N'COLUMN', @level2name = N'TypeObjetLie';

