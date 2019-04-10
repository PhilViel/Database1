CREATE TABLE [dbo].[Un_OperConventionOperType] (
    [OperTypeID]           CHAR (3)             NOT NULL,
    [ConventionOperTypeID] [dbo].[MoOptionCode] NOT NULL,
    CONSTRAINT [PK_Un_OperConventionOperType] PRIMARY KEY CLUSTERED ([OperTypeID] ASC, [ConventionOperTypeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_OperConventionOperType_Un_ConventionOperType__ConventionOperTypeID] FOREIGN KEY ([ConventionOperTypeID]) REFERENCES [dbo].[Un_ConventionOperType] ([ConventionOperTypeID]),
    CONSTRAINT [FK_Un_OperConventionOperType_Un_OperType__OperTypeID] FOREIGN KEY ([OperTypeID]) REFERENCES [dbo].[Un_OperType] ([OperTypeID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table qui donne les types d''opérations sur convention (Un_ConventionOperType) qui sont disponible pour un type d''opération (Un_OperType).  C''est pour empêcher les erreurs tel que des frais disponibles sur un CPA.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperConventionOperType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaine unique de 3 caractères du type d''opération (Un_OperType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperConventionOperType', @level2type = N'COLUMN', @level2name = N'OperTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaine unique de 3 caractères du type d''opération sur convention (Un_ConventionOperType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperConventionOperType', @level2type = N'COLUMN', @level2name = N'ConventionOperTypeID';

