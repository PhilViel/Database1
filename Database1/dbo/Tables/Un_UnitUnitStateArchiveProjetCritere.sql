CREATE TABLE [dbo].[Un_UnitUnitStateArchiveProjetCritere] (
    [ConventionID] [dbo].[MoID]         NOT NULL,
    [UnitID]       [dbo].[MoID]         NOT NULL,
    [UnitStateID]  [dbo].[MoOptionCode] NOT NULL,
    CONSTRAINT [PK__Un_UnitU__44F5EC95843B3722] PRIMARY KEY CLUSTERED ([UnitID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient les états des groupes d''unités au moment de la mise en production du projet critère. JIRA CRIT-956', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitUnitStateArchiveProjetCritere';

