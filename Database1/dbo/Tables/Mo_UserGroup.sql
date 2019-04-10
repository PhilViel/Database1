CREATE TABLE [dbo].[Mo_UserGroup] (
    [UserGroupID]   [dbo].[MoID]   IDENTITY (1, 1) NOT NULL,
    [UserGroupDesc] [dbo].[MoDesc] NOT NULL,
    CONSTRAINT [PK_Mo_UserGroup] PRIMARY KEY CLUSTERED ([UserGroupID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des groupes d''usagers.  Un groupe d''usagers et un regroupement d''usager auxquelles on donne des droits communs.  (Ex: Représentant, Service à la clientèle, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserGroup';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''usagers.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserGroup', @level2type = N'COLUMN', @level2name = N'UserGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du groupe d''usagers.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserGroup', @level2type = N'COLUMN', @level2name = N'UserGroupDesc';

