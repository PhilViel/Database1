CREATE TABLE [dbo].[Un_IrregularityType] (
    [IrregularityTypeID]        [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [IrregularityTypeName]      VARCHAR (100)        NOT NULL,
    [SearchStoredProcedure]     [dbo].[MoDesc]       NOT NULL,
    [CorrectingStoredProcedure] [dbo].[MoDescoption] NULL,
    [Active]                    [dbo].[MoBitTrue]    NOT NULL,
    CONSTRAINT [PK_Un_IrregularityType] PRIMARY KEY CLUSTERED ([IrregularityTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les types d''anomalies et leurs configurations.  Les anomalies sont un système de recherche normalisé.  Dans le passé, il nous est arrivé régulièrement de faire des listes pour sortir des erreurs précises.  Les requêtes n''était pas conservé, on ne pouvait donc pas vérifier 3 mois plus tard s''il y avait de nouveaux cas.  L''outils des anomalies à donc été developper pour conserver ces requêtes et pour permettre aux usagers de les exécuter à leurs guise.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type d''anomalies.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityType', @level2type = N'COLUMN', @level2name = N'IrregularityTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom décrivant le type d''anomalies.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityType', @level2type = N'COLUMN', @level2name = N'IrregularityTypeName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est le nom de la procédure stockée que doit utiliser l''outils des anomalies pour faire la recherche de ce type d''anomalies.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityType', @level2type = N'COLUMN', @level2name = N'SearchStoredProcedure';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est le nom de la procédure stockée que doit utiliser l''outils des anomalies pour faire la correction automatique de ce type d''anomalies.  Peut être vide si ce type d''anomalies peut être corrigé uniquement manuellement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityType', @level2type = N'COLUMN', @level2name = N'CorrectingStoredProcedure';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean disant si ce type d''anomalie est actif.  Si oui (<> 0) alors on verra le type d''anomalies dans l''outil de recherche d''anomalies.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityType', @level2type = N'COLUMN', @level2name = N'Active';

