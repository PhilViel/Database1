CREATE TABLE [dbo].[Un_ConventionOperType] (
    [ConventionOperTypeID]   [dbo].[MoOptionCode] NOT NULL,
    [ConventionOperTypeDesc] [dbo].[MoDesc]       NOT NULL,
    CONSTRAINT [PK_Un_ConventionOperType] PRIMARY KEY CLUSTERED ([ConventionOperTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des types d''opérations sur conventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionOperType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code de 3 caractères alphanumérique unique identifiant le type d''opération sur convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionOperType', @level2type = N'COLUMN', @level2name = N'ConventionOperTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom long du type d''opération sur convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionOperType', @level2type = N'COLUMN', @level2name = N'ConventionOperTypeDesc';

