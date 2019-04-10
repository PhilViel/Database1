CREATE TABLE [dbo].[Un_RepStatutHistorique] (
    [iRepStatutHistoriqueId]        INT      IDENTITY (1, 1) NOT NULL,
    [RepId]                         INT      NULL,
    [dRepStatutHistoriqueDateDebut] DATETIME NULL,
    [iStatutID]                     INT      NULL,
    [iRaisonID]                     INT      NULL,
    [iEtatID]                       INT      NULL,
    [dtSequence_Operation]          DATETIME CONSTRAINT [DF_Un_RepStatutHistorique_dtSequenceOperation] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_Un_RepStatutHistorique] PRIMARY KEY CLUSTERED ([iRepStatutHistoriqueId] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepStatutHistorique_REPR_RaisonsAbandon__iRaisonID] FOREIGN KEY ([iRaisonID]) REFERENCES [dbo].[tblREPR_RaisonsAbandon] ([iRaisonID]),
    CONSTRAINT [FK_Un_RepStatutHistorique_REPR_StatutsRep__iStatutID] FOREIGN KEY ([iStatutID]) REFERENCES [dbo].[tblREPR_StatutsRep] ([iStatutID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du représentant (provient de la table Un_Rep)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepStatutHistorique', @level2type = N'COLUMN', @level2name = N'RepId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de début de l''historique', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepStatutHistorique', @level2type = N'COLUMN', @level2name = N'dRepStatutHistoriqueDateDebut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'État du représentant lors du changement de statut. (1 = Candidat, 2 = Représentant)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepStatutHistorique', @level2type = N'COLUMN', @level2name = N'iEtatID';

