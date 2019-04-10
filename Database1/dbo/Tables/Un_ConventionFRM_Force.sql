CREATE TABLE [dbo].[Un_ConventionFRM_Force] (
    [ConventionID]    [dbo].[MoID]         NOT NULL,
    [RaisonFermeture] [dbo].[MoOptionCode] NULL,
    [Commentaire]     VARCHAR (MAX)        NULL,
    CONSTRAINT [PK__Un_Conve__435789D89FF6BD6B] PRIMARY KEY CLUSTERED ([ConventionID] ASC),
    CONSTRAINT [FK_Un_ConventionFRM_Force_Un_Convention_ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient la liste des conventions qui doivent être maintenu à FRM de force dû aux changements de gestions des groupes d''unités lors de l''implémentation du projet critère. JIRA CRIT-956', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionFRM_Force';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient l''état du dernier Un_Scholarship associé à la convention lors de la mise en production du projet CRITERE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionFRM_Force', @level2type = N'COLUMN', @level2name = N'RaisonFermeture';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient l''ancien état de groupe d''unités qui permettait de fermer cette convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionFRM_Force', @level2type = N'COLUMN', @level2name = N'Commentaire';

