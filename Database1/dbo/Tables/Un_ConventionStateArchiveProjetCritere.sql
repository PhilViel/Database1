CREATE TABLE [dbo].[Un_ConventionStateArchiveProjetCritere] (
    [ConventionID]      [dbo].[MoID]         NOT NULL,
    [ConventionStateID] [dbo].[MoOptionCode] NOT NULL,
    CONSTRAINT [PK__Un_Conve__435789D8088DFDCD] PRIMARY KEY CLUSTERED ([ConventionID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient les états des conventions au moment de la mise en production du projet critère. JIRA CRIT-956', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionStateArchiveProjetCritere';

