CREATE TABLE [dbo].[Mo_UserRight] (
    [UserID]  [dbo].[MoID]      NOT NULL,
    [RightID] [dbo].[MoID]      NOT NULL,
    [Granted] [dbo].[MoBitTrue] NOT NULL,
    CONSTRAINT [PK_Mo_UserRight] PRIMARY KEY CLUSTERED ([UserID] ASC, [RightID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_UserRight_Mo_Right__RightID] FOREIGN KEY ([RightID]) REFERENCES [dbo].[Mo_Right] ([RightID]),
    CONSTRAINT [FK_Mo_UserRight_Mo_User__UserID] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Mo_User] ([UserID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des droits d''un usager.  Fait le lien qui permet de connaître les droits d''un usager.  On peut ce servir de cette table pour donner un droit à un usager particulier ou encore pour lui enlever un droit qu''il hérite d''un groupe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserRight';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''usager (Mo_User).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserRight', @level2type = N'COLUMN', @level2name = N'UserID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du droit (Mo_Right) qu''a ou n''a pas l''usager.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserRight', @level2type = N'COLUMN', @level2name = N'RightID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si on veut donner ou enlever le droit à l''usager. (=0:Enlever, <>0:Donner)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_UserRight', @level2type = N'COLUMN', @level2name = N'Granted';

