CREATE TABLE [dbo].[Un_CESPReceiveFile] (
    [iCESPReceiveFileID] INT          IDENTITY (1, 1) NOT NULL,
    [OperID]             INT          NOT NULL,
    [dtRead]             DATETIME     NOT NULL,
    [dtPeriodStart]      DATETIME     NULL,
    [dtPeriodEnd]        DATETIME     NULL,
    [fSumary]            MONEY        NOT NULL,
    [fPayment]           MONEY        NOT NULL,
    [vcPaymentReqID]     VARCHAR (10) NULL,
    CONSTRAINT [PK_Un_CESPReceiveFile] PRIMARY KEY CLUSTERED ([iCESPReceiveFileID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESPReceiveFile_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESPReceiveFile_OperID]
    ON [dbo].[Un_CESPReceiveFile]([OperID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des fichiers PCEE reçus', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFile';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier reçu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFile', @level2type = N'COLUMN', @level2name = N'iCESPReceiveFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFile', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à laquelle le fichier a été lu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFile', @level2type = N'COLUMN', @level2name = N'dtRead';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de début de la période couverte', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFile', @level2type = N'COLUMN', @level2name = N'dtPeriodStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de la période couverte', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFile', @level2type = N'COLUMN', @level2name = N'dtPeriodEnd';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant inscrit dans le sommaire du fichier .pro', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFile', @level2type = N'COLUMN', @level2name = N'fSumary';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFile', @level2type = N'COLUMN', @level2name = N'fPayment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de réquisition pour le paiement, bref numéro de la SCÉÉ identifiant ce paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESPReceiveFile', @level2type = N'COLUMN', @level2name = N'vcPaymentReqID';

