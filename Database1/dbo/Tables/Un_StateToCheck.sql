CREATE TABLE [dbo].[Un_StateToCheck] (
    [iStateToCheck] INT IDENTITY (1, 1) NOT NULL,
    [UnitID]        INT NULL,
    [ConventionID]  INT NOT NULL,
    [iSPID]         INT NOT NULL,
    CONSTRAINT [PK_Un_StateToCheck] PRIMARY KEY CLUSTERED ([iStateToCheck] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant des lots de groupes d''unités et de conventions dont il faut réévaluer l''état.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_StateToCheck';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_StateToCheck', @level2type = N'COLUMN', @level2name = N'iStateToCheck';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_StateToCheck', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_StateToCheck', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifie le processus qui à insérer l''enregistrement dans la table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_StateToCheck', @level2type = N'COLUMN', @level2name = N'iSPID';

