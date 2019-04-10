CREATE TABLE [dbo].[CRQ_DocTypeDataFormat] (
    [DocTypeDataFormatID] INT           IDENTITY (1, 1) NOT NULL,
    [DocTypeID]           INT           NOT NULL,
    [DocTypeTime]         DATETIME      CONSTRAINT [DF_CRQ_DocTypeDataFormat_DocTypeTime] DEFAULT (getdate()) NOT NULL,
    [DocTypeDataFormat]   TEXT          NOT NULL,
    [StoredProcedureName] VARCHAR (100) NULL,
    CONSTRAINT [PK_CRQ_DocTypeDataFormat] PRIMARY KEY CLUSTERED ([DocTypeDataFormatID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CRQ_DocTypeDataFormat_CRQ_DocType__DocTypeID] FOREIGN KEY ([DocTypeID]) REFERENCES [dbo].[CRQ_DocType] ([DocTypeID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Elle contient des blobs qui permet de connaître le formatage des documents pour chacun des types de document.  C''est avec ces blobs qu''on peut savoir comment sont structurés les documents d''une type précis.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTypeDataFormat';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du formatage des données des types de document', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTypeDataFormat', @level2type = N'COLUMN', @level2name = N'DocTypeDataFormatID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type de document (CRQ_DocType) auquel appartient ce formatage', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTypeDataFormat', @level2type = N'COLUMN', @level2name = N'DocTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure d''entrée vigueur du format de données', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTypeDataFormat', @level2type = N'COLUMN', @level2name = N'DocTypeTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Blob contenant le format de données', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTypeDataFormat', @level2type = N'COLUMN', @level2name = N'DocTypeDataFormat';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la procédure stockée qui utilise ce format de données', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocTypeDataFormat', @level2type = N'COLUMN', @level2name = N'StoredProcedureName';

