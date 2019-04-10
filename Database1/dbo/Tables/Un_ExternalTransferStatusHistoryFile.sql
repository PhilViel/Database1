CREATE TABLE [dbo].[Un_ExternalTransferStatusHistoryFile] (
    [ExternalTransferStatusHistoryFileID]   [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [ExternalTransferStatusHistoryFileName] [dbo].[MoDesc]    NOT NULL,
    [ExternalTransferStatusHistoryFileDate] [dbo].[MoGetDate] NOT NULL,
    CONSTRAINT [PK_Un_ExternalTransferStatusHistoryFile] PRIMARY KEY CLUSTERED ([ExternalTransferStatusHistoryFileID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les fichiers d''historique des statuts des transferts externes (IN et OUT).  Ils sont reçues de la SCÉÉ en format de feuilled Excel avec les autres fichiers de retours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistoryFile';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistoryFile', @level2type = N'COLUMN', @level2name = N'ExternalTransferStatusHistoryFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du fichier.  Correspond au nom du fichier Excel.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistoryFile', @level2type = N'COLUMN', @level2name = N'ExternalTransferStatusHistoryFileName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de réception du fichier Excel.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistoryFile', @level2type = N'COLUMN', @level2name = N'ExternalTransferStatusHistoryFileDate';

