CREATE TABLE [dbo].[tblIQEE_SousTypeEnregistrement] (
    [iID_Sous_Type]            INT           IDENTITY (1, 1) NOT NULL,
    [tiID_Type_Enregistrement] TINYINT       NOT NULL,
    [cCode_Sous_Type]          CHAR (2)      NOT NULL,
    [vcDescription]            VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_IQEE_SousTypeEnregistrement] PRIMARY KEY CLUSTERED ([iID_Sous_Type] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_SousTypeEnregistrement_tiIDTypeEnregistrement_cCodeSousType]
    ON [dbo].[tblIQEE_SousTypeEnregistrement]([tiID_Type_Enregistrement] ASC, [cCode_Sous_Type] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le type d''enregistrement et le code de sous type d''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_SousTypeEnregistrement', @level2type = N'INDEX', @level2name = N'IX_IQEE_SousTypeEnregistrement_tiIDTypeEnregistrement_cCodeSousType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique d''un sous type d''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_SousTypeEnregistrement', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_SousTypeEnregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Sous type des types d''enregistrements de l''IQÉÉ.  Correspond aux champs "Type fiduciaire" du type d''enregistrement 04, "Type paiement" du type d''enregistrement 05 et "Raison de l''impôt spécial" du type d''enregistrement 06.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_SousTypeEnregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du sous type d''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_SousTypeEnregistrement', @level2type = N'COLUMN', @level2name = N'iID_Sous_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''enregistrement associé au sous type d''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_SousTypeEnregistrement', @level2type = N'COLUMN', @level2name = N'tiID_Type_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du sous type d''enregistrement correspondant aux NID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_SousTypeEnregistrement', @level2type = N'COLUMN', @level2name = N'cCode_Sous_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du sous type d''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_SousTypeEnregistrement', @level2type = N'COLUMN', @level2name = N'vcDescription';

