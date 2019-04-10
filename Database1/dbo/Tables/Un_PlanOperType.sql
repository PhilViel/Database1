CREATE TABLE [dbo].[Un_PlanOperType] (
    [PlanOperTypeID]   [dbo].[MoOptionCode] NOT NULL,
    [PlanOperTypeDesc] [dbo].[MoDesc]       NOT NULL,
    CONSTRAINT [PK_Un_PlanOperType] PRIMARY KEY CLUSTERED ([PlanOperTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des types d''opérations sur plans.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanOperType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaine unique de 3 caractàres du type d''opération sur plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanOperType', @level2type = N'COLUMN', @level2name = N'PlanOperTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type d''opération sur plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanOperType', @level2type = N'COLUMN', @level2name = N'PlanOperTypeDesc';

