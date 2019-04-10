CREATE TABLE [dbo].[CHQ_CheckStatus] (
    [iCheckStatusID]        INT          IDENTITY (1, 1) NOT NULL,
    [vcStatusDescription]   VARCHAR (50) NOT NULL,
    [bStatusAvailable]      BIT          NOT NULL,
    [vcStatusDescriptionEN] VARCHAR (50) CONSTRAINT [DF_CHQ_CheckStatus_vcStatusDescriptionEN] DEFAULT ('None') NOT NULL,
    CONSTRAINT [PK_CHQ_CheckStatus] PRIMARY KEY CLUSTERED ([iCheckStatusID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table de statuts disponibles pour chèques', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckStatus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique du statut de chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckStatus', @level2type = N'COLUMN', @level2name = N'iCheckStatusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut de chèque en francais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckStatus', @level2type = N'COLUMN', @level2name = N'vcStatusDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Disponibilité de statut de chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckStatus', @level2type = N'COLUMN', @level2name = N'bStatusAvailable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut de chèque en anglais', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckStatus', @level2type = N'COLUMN', @level2name = N'vcStatusDescriptionEN';

