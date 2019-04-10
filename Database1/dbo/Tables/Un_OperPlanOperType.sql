CREATE TABLE [dbo].[Un_OperPlanOperType] (
    [OperTypeID]     CHAR (3)             NOT NULL,
    [PlanOperTypeID] [dbo].[MoOptionCode] NOT NULL,
    CONSTRAINT [PK_Un_OperPlanOperType] PRIMARY KEY CLUSTERED ([OperTypeID] ASC, [PlanOperTypeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_OperPlanOperType_Un_OperType__OperTypeID] FOREIGN KEY ([OperTypeID]) REFERENCES [dbo].[Un_OperType] ([OperTypeID]),
    CONSTRAINT [FK_Un_OperPlanOperType_Un_PlanOperType__PlanOperTypeID] FOREIGN KEY ([PlanOperTypeID]) REFERENCES [dbo].[Un_PlanOperType] ([PlanOperTypeID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table qui donne les types d''opérations sur plan (Un_PlanOperType) qui sont disponible pour un type d''opération (Un_OperType).  C''est pour empêcher les erreurs tel que des intérêts collectif sur un CPA.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperPlanOperType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaine unique de 3 caractères du type d''opération (Un_OperType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperPlanOperType', @level2type = N'COLUMN', @level2name = N'OperTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaine unique de 3 caractères du type d''opération sur plan (Un_PlanOperType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperPlanOperType', @level2type = N'COLUMN', @level2name = N'PlanOperTypeID';

