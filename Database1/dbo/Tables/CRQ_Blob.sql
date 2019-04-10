CREATE TABLE [dbo].[CRQ_Blob] (
    [BlobID] INT  IDENTITY (1, 1) NOT NULL,
    [Blob]   TEXT NOT NULL,
    CONSTRAINT [PK_CRQ_Blob] PRIMARY KEY CLUSTERED ([BlobID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cette table contient des blobs temporaires.  Puisque ASTA ne permet pas d''envoyer un blob directement en paramètre à une procédure, nous inséront un blob dans cette table.  Nous passons le BlobID à la précédure qui devait avoir un blob en paramètre et avec le ID nous allons chercher le blob en question.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Blob';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifiant unique du blob', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Blob', @level2type = N'COLUMN', @level2name = N'BlobID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Blob', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Blob', @level2type = N'COLUMN', @level2name = N'Blob';

