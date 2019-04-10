CREATE TABLE [dbo].[tblIQEE_TypesAnnulation] (
    [iID_Type_Annulation] INT          IDENTITY (1, 1) NOT NULL,
    [vcCode_Type]         VARCHAR (3)  NOT NULL,
    [vcDescription]       VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_IQEE_TypesAnnulation] PRIMARY KEY CLUSTERED ([iID_Type_Annulation] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_TypesAnnulation_vcCodeType]
    ON [dbo].[tblIQEE_TypesAnnulation]([vcCode_Type] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur le code de type d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesAnnulation', @level2type = N'INDEX', @level2name = N'AK_IQEE_TypesAnnulation_vcCodeType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé primaire soit l''identifiant du type d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesAnnulation', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_TypesAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Types d''annulation.  Cette table sert principalement à afficher une description pour l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesAnnulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un type d''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesAnnulation', @level2type = N'COLUMN', @level2name = N'iID_Type_Annulation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique du type d''annulation.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesAnnulation', @level2type = N'COLUMN', @level2name = N'vcCode_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type d''annulation.  Cette description s''affiche dans les interfaces utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesAnnulation', @level2type = N'COLUMN', @level2name = N'vcDescription';

