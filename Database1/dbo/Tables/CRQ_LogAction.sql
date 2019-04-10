CREATE TABLE [dbo].[CRQ_LogAction] (
    [LogActionID]        INT          IDENTITY (1, 1) NOT NULL,
    [LogActionShortName] CHAR (1)     NOT NULL,
    [LogActionLongName]  VARCHAR (75) NOT NULL,
    CONSTRAINT [PK_CRQ_LogAction] PRIMARY KEY CLUSTERED ([LogActionID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des actions possibles dans un log', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_LogAction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''action', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_LogAction', @level2type = N'COLUMN', @level2name = N'LogActionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom court de l''action', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_LogAction', @level2type = N'COLUMN', @level2name = N'LogActionShortName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom long de l''action', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_LogAction', @level2type = N'COLUMN', @level2name = N'LogActionLongName';

