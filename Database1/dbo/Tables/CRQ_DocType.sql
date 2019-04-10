CREATE TABLE [dbo].[CRQ_DocType] (
    [DocTypeID]   INT           IDENTITY (1, 1) NOT NULL,
    [DocTypeCode] VARCHAR (20)  NOT NULL,
    [DocTypeDesc] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_CRQ_DocType] PRIMARY KEY CLUSTERED ([DocTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Elle contient tous les types de documents codés dans l''application.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type de document', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocType', @level2type = N'COLUMN', @level2name = N'DocTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code unique identifiant un type de document qui est utilisé dans les scripts pour retrouver une type de document', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocType', @level2type = N'COLUMN', @level2name = N'DocTypeCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description du type de document. (Ex : Relevé de dépôt)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocType', @level2type = N'COLUMN', @level2name = N'DocTypeDesc';

