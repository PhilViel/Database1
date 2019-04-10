CREATE TABLE [dbo].[Un_RepRole] (
    [RepRoleID]   [dbo].[MoOptionCode] NOT NULL,
    [RepRoleDesc] [dbo].[MoDesc]       NOT NULL,
    CONSTRAINT [PK_Un_RepRole] PRIMARY KEY CLUSTERED ([RepRoleID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des rôles des représentants.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepRole';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de trois caractères identifiant le rôle.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepRole', @level2type = N'COLUMN', @level2name = N'RepRoleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Le rôle.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepRole', @level2type = N'COLUMN', @level2name = N'RepRoleDesc';

