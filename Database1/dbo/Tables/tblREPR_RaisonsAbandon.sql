CREATE TABLE [dbo].[tblREPR_RaisonsAbandon] (
    [iRaisonID]    INT           IDENTITY (1, 1) NOT NULL,
    [dtDate_Debut] DATETIME      NOT NULL,
    [dtDate_Fin]   DATETIME      NULL,
    [vcRaison]     VARCHAR (100) NOT NULL,
    [iCode_Raison] INT           NULL,
    CONSTRAINT [PK_REPR_RaisonsAbandon] PRIMARY KEY CLUSTERED ([iRaisonID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la raison', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_RaisonsAbandon', @level2type = N'COLUMN', @level2name = N'iRaisonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de début d''utilisation', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_RaisonsAbandon', @level2type = N'COLUMN', @level2name = N'dtDate_Debut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de fin d''utilisation', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_RaisonsAbandon', @level2type = N'COLUMN', @level2name = N'dtDate_Fin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la raison d''abandon du représentant', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_RaisonsAbandon', @level2type = N'COLUMN', @level2name = N'vcRaison';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de la raison', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_RaisonsAbandon', @level2type = N'COLUMN', @level2name = N'iCode_Raison';

