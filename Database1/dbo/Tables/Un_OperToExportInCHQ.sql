CREATE TABLE [dbo].[Un_OperToExportInCHQ] (
    [iOperToExportInCHQID] INT IDENTITY (1, 1) NOT NULL,
    [OperID]               INT NOT NULL,
    [iSPID]                INT NOT NULL,
    CONSTRAINT [PK_Un_OperToExportInCHQ] PRIMARY KEY CLUSTERED ([iOperToExportInCHQID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table temporaire pour les exportations en lot d''opération au module des chèques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperToExportInCHQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperToExportInCHQ', @level2type = N'COLUMN', @level2name = N'iOperToExportInCHQID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’opération du système de convention (Un_Oper)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperToExportInCHQ', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de de process qui a demandé cette exportation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperToExportInCHQ', @level2type = N'COLUMN', @level2name = N'iSPID';

