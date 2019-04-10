CREATE TABLE [dbo].[tblIQEE_TypesEnregistrement] (
    [tiID_Type_Enregistrement]  TINYINT       IDENTITY (1, 1) NOT NULL,
    [cCode_Type_Enregistrement] CHAR (2)      NOT NULL,
    [vcDescription]             VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_IQEE_TypesEnregistrement] PRIMARY KEY CLUSTERED ([tiID_Type_Enregistrement] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_TypesEnregistrement_cCodeTypeEnregistrement]
    ON [dbo].[tblIQEE_TypesEnregistrement]([cCode_Type_Enregistrement] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur le code de type d''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesEnregistrement', @level2type = N'INDEX', @level2name = N'AK_IQEE_TypesEnregistrement_cCodeTypeEnregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé primaire des types d''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesEnregistrement', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_TypesEnregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Types d''enregistrement selon les NID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesEnregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un type d''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesEnregistrement', @level2type = N'COLUMN', @level2name = N'tiID_Type_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique du type d''enregistrement correspondant au code utilisé dans les NID de RQ.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesEnregistrement', @level2type = N'COLUMN', @level2name = N'cCode_Type_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type d''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesEnregistrement', @level2type = N'COLUMN', @level2name = N'vcDescription';

