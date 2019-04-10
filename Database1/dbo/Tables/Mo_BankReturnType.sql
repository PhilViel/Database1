CREATE TABLE [dbo].[Mo_BankReturnType] (
    [BankReturnTypeID]     VARCHAR (4)    NOT NULL,
    [BankReturnTypeDesc]   [dbo].[MoDesc] NOT NULL,
    [BankReturnTypeDescEN] [dbo].[MoDesc] NULL,
    [EstCodeAnnulation]    BIT            CONSTRAINT [DF_Mo_BankReturnType_EstCodeAnnulation] DEFAULT ((-1)) NOT NULL,
    [EstCodeRefus]         BIT            CONSTRAINT [DF_Mo_BankReturnType_EstCodeRefus] DEFAULT ((-1)) NOT NULL,
    [CleCodeErreur]        VARCHAR (70)   NULL,
    CONSTRAINT [PK_Mo_BankReturnType] PRIMARY KEY CLUSTERED ([BankReturnTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des type d''effet retourné.  Ca donne, en fait, la raison du retour. (Ex: Compte fermé, fonds insuffisant, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type d''effet retourné.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnType', @level2type = N'COLUMN', @level2name = N'BankReturnTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type d''effet retourné.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnType', @level2type = N'COLUMN', @level2name = N'BankReturnTypeDesc';

