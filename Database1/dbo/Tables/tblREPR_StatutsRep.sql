CREATE TABLE [dbo].[tblREPR_StatutsRep] (
    [iStatutID]    INT           NOT NULL,
    [dtDate_Debut] DATETIME      NOT NULL,
    [dtDate_Fin]   DATETIME      NULL,
    [vcStatut]     VARCHAR (100) NOT NULL,
    [iCode_Statut] INT           NULL,
    CONSTRAINT [PK_REPR_StatutsRep] PRIMARY KEY CLUSTERED ([iStatutID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du statut', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_StatutsRep', @level2type = N'COLUMN', @level2name = N'iStatutID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de début d''utilisation', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_StatutsRep', @level2type = N'COLUMN', @level2name = N'dtDate_Debut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de fin d''utilisation', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_StatutsRep', @level2type = N'COLUMN', @level2name = N'dtDate_Fin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut du représentant', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_StatutsRep', @level2type = N'COLUMN', @level2name = N'vcStatut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du statut', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblREPR_StatutsRep', @level2type = N'COLUMN', @level2name = N'iCode_Statut';

