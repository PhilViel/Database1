CREATE TABLE [dbo].[tblCONV_StatutBourse] (
    [iID_Statut]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Statut] VARCHAR (3)   NOT NULL,
    [vcDescription] VARCHAR (100) NULL,
    CONSTRAINT [PK_CONV_StatutBourse] PRIMARY KEY CLUSTERED ([iID_Statut] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du statut de bourse', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_StatutBourse', @level2type = N'COLUMN', @level2name = N'iID_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du statut de bourse', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_StatutBourse', @level2type = N'COLUMN', @level2name = N'vcCode_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut de bourse', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_StatutBourse', @level2type = N'COLUMN', @level2name = N'vcDescription';

