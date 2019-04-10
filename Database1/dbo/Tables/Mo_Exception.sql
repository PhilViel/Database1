CREATE TABLE [dbo].[Mo_Exception] (
    [ExceptionID]    [dbo].[MoID]             IDENTITY (1, 1) NOT NULL,
    [ClassName]      [dbo].[MoDescoption]     NULL,
    [SenderName]     [dbo].[MoDescoption]     NULL,
    [ExcepClassName] [dbo].[MoDescoption]     NULL,
    [MsgException]   [dbo].[MoNoteDescoption] NULL,
    [ConnectID]      [dbo].[MoID]             NOT NULL,
    [ExceptionDate]  [dbo].[MoGetDate]        NULL,
    CONSTRAINT [PK_Mo_Exception] PRIMARY KEY CLUSTERED ([ExceptionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Exception_Mo_Connect__ConnectID] FOREIGN KEY ([ConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des exceptions de l''application.  Lorsqu''un usager à un message d''erreur on l''inscrit dans cette table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Exception';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Exception', @level2type = N'COLUMN', @level2name = N'ExceptionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Classe de l''objet dans lequel a eu lieu l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Exception', @level2type = N'COLUMN', @level2name = N'ClassName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de l''objet dans lequel a eu lieu l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Exception', @level2type = N'COLUMN', @level2name = N'SenderName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Classe de l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Exception', @level2type = N'COLUMN', @level2name = N'ExcepClassName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Message de l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Exception', @level2type = N'COLUMN', @level2name = N'MsgException';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect) de l''usager qui a eu l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Exception', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure à laquel l''exception à eu lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Exception', @level2type = N'COLUMN', @level2name = N'ExceptionDate';

