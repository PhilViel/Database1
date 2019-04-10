CREATE TABLE [dbo].[CRI_Blob] (
    [iBlobID] INT      IDENTITY (1, 1) NOT NULL,
    [dtBlob]  DATETIME CONSTRAINT [DF_CRI_Blob_dtBlob] DEFAULT (getdate()) NOT NULL,
    [txBlob]  TEXT     NULL,
    CONSTRAINT [PK_CRI_Blob] PRIMARY KEY CLUSTERED ([iBlobID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table temporaires des blobs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_Blob';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifiant unique du blob', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_Blob', @level2type = N'COLUMN', @level2name = N'iBlobID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''insertion du blob.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_Blob', @level2type = N'COLUMN', @level2name = N'dtBlob';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Blob.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_Blob', @level2type = N'COLUMN', @level2name = N'txBlob';

