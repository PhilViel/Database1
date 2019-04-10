CREATE TABLE [dbo].[Un_MoneyType] (
    [iMoneyTypeID] INT           IDENTITY (1, 1) NOT NULL,
    [OperTypeID]   CHAR (3)      NOT NULL,
    [vcTableName]  VARCHAR (100) NOT NULL,
    [vcFieldName]  VARCHAR (100) NOT NULL,
    [vcValueType]  VARCHAR (3)   NULL,
    [vcMoneyType]  VARCHAR (75)  NOT NULL,
    CONSTRAINT [PK_Un_MoneyType] PRIMARY KEY CLUSTERED ([iMoneyTypeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_MoneyType_Un_OperType__OperTypeID] FOREIGN KEY ([OperTypeID]) REFERENCES [dbo].[Un_OperType] ([OperTypeID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des types d''argent', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MoneyType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type d’argent', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MoneyType', @level2type = N'COLUMN', @level2name = N'iMoneyTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type d’opération affecté', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MoneyType', @level2type = N'COLUMN', @level2name = N'OperTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table qui contient ce type d’argent', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MoneyType', @level2type = N'COLUMN', @level2name = N'vcTableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champ qui contient ce type d’argent', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MoneyType', @level2type = N'COLUMN', @level2name = N'vcFieldName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champ supplémentaire servant à lié le type d''argent à une valeur d''une table (Ex: ConventionOperTypeID).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MoneyType', @level2type = N'COLUMN', @level2name = N'vcValueType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type d’argent (Description)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_MoneyType', @level2type = N'COLUMN', @level2name = N'vcMoneyType';

