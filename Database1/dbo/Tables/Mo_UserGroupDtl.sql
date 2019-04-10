CREATE TABLE [dbo].[Mo_UserGroupDtl] (
    [UserID]      [dbo].[MoID] NOT NULL,
    [UserGroupID] [dbo].[MoID] NOT NULL,
    CONSTRAINT [PK_Mo_UserGroupDtl] PRIMARY KEY CLUSTERED ([UserID] ASC, [UserGroupID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_UserGroupDtl_Mo_User__UserID] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Mo_User] ([UserID]),
    CONSTRAINT [FK_Mo_UserGroupDtl_Mo_UserGroup__UserGroupID] FOREIGN KEY ([UserGroupID]) REFERENCES [dbo].[Mo_UserGroup] ([UserGroupID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des usagers d''un groupe.  Fait le lien qui permet de connaître les usagers qui font parti d''un groupe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserGroupDtl';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''usager (Mo_User).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserGroupDtl', @level2type = N'COLUMN', @level2name = N'UserID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''usagers (Mo_UserGroup) duquel fait parti l''usager.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserGroupDtl', @level2type = N'COLUMN', @level2name = N'UserGroupID';

