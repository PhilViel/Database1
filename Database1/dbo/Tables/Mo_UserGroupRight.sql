CREATE TABLE [dbo].[Mo_UserGroupRight] (
    [UserGroupID] [dbo].[MoID] NOT NULL,
    [RightID]     [dbo].[MoID] NOT NULL,
    CONSTRAINT [PK_Mo_UserGroupRight] PRIMARY KEY CLUSTERED ([UserGroupID] ASC, [RightID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_UserGroupRight_Mo_Right__RightID] FOREIGN KEY ([RightID]) REFERENCES [dbo].[Mo_Right] ([RightID]),
    CONSTRAINT [FK_Mo_UserGroupRight_Mo_UserGroup__UserGroupID] FOREIGN KEY ([UserGroupID]) REFERENCES [dbo].[Mo_UserGroup] ([UserGroupID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des droits d''un groupe d''usagers.  Fait le lien qui permet de connaître les droits d''un groupe d''usagers.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserGroupRight';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''usagers (Mo_UserGroup).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserGroupRight', @level2type = N'COLUMN', @level2name = N'UserGroupID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du droit (Mo_Right) qu''a le groupe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserGroupRight', @level2type = N'COLUMN', @level2name = N'RightID';

