CREATE TABLE [dbo].[Un_ExternalTransferStatusHistory] (
    [ExternalTransferStatusHistoryID]     [dbo].[MoID]                       IDENTITY (1, 1) NOT NULL,
    [OperID]                              [dbo].[MoID]                       NOT NULL,
    [ExternalTransferStatusID]            [dbo].[UnExternalTransferStatusID] NOT NULL,
    [ExternalTransferStatusHistoryFileID] [dbo].[MoID]                       NOT NULL,
    [RegimeNumber]                        [dbo].[MoDescoption]               NULL,
    [OtherContractNumber]                 [dbo].[MoDescoption]               NULL,
    [OtherRegimeNumber]                   [dbo].[MoDescoption]               NULL,
    CONSTRAINT [PK_Un_ExternalTransferStatusHistory] PRIMARY KEY CLUSTERED ([ExternalTransferStatusHistoryID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ExternalTransferStatusHistory_Un_ExternalTransferStatusHistoryFile__ExternalTransferStatusHistoryFileID] FOREIGN KEY ([ExternalTransferStatusHistoryFileID]) REFERENCES [dbo].[Un_ExternalTransferStatusHistoryFile] ([ExternalTransferStatusHistoryFileID]),
    CONSTRAINT [FK_Un_ExternalTransferStatusHistory_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant l''historique des statuts des transferts externes (IN et OUT).  Les statuts des transferts sont reçues de la SCÉÉ dans des fichiers Excel avec les autres fichiers de retours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistory';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement d''historique de statut de transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistory', @level2type = N'COLUMN', @level2name = N'ExternalTransferStatusHistoryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper) qui est le transfert IN ou OUT.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistory', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de 3 caractères identifiant le statut. (''30D'' = 30 jours, ''60D'' = 60 jours, ''90D'' = 90 jours, ''ACC'' = accepté)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistory', @level2type = N'COLUMN', @level2name = N'ExternalTransferStatusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du fichier d''historique de transfert (Un_ExternalTransferStatusHistoryFile).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistory', @level2type = N'COLUMN', @level2name = N'ExternalTransferStatusHistoryFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d''enregistrement gouvernemental du plan de la convention de Fondation Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistory', @level2type = N'COLUMN', @level2name = N'RegimeNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de contrat du promoteur externe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistory', @level2type = N'COLUMN', @level2name = N'OtherContractNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d''enregistrement gouvernemental du plan de la convention du promoteur externe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransferStatusHistory', @level2type = N'COLUMN', @level2name = N'OtherRegimeNumber';

