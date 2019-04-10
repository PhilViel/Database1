CREATE TABLE [dbo].[tblIQEE_CasSpeciaux] (
    [iID_CasSpecial_IQEE]     INT            IDENTITY (1, 1) NOT NULL,
    [iID_Convention]          INT            NOT NULL,
    [vcNo_Convention]         VARCHAR (15)   NOT NULL,
    [tiID_TypeEnregistrement] TINYINT        NULL,
    [iID_SousType]            INT            NULL,
    [bCasRegle]               BIT            CONSTRAINT [DF_CasSpeciaux_bCasRegle] DEFAULT ((0)) NOT NULL,
    [vcMotif]                 VARCHAR (256)  NULL,
    [vcCommentaires]          VARCHAR (1024) NULL,
    CONSTRAINT [PK_IQEE_CasSpeciaux] PRIMARY KEY CLUSTERED ([iID_CasSpecial_IQEE] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire des cas spéciaux de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_CasSpeciaux';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des conventions ayant des cas spéciaux avec Revenu Québec au sujet de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un cas spécial l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_CasSpecial_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux', @level2type = N'COLUMN', @level2name = N'vcNo_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiants du type de transaction touché par ce cas spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux', @level2type = N'COLUMN', @level2name = N'tiID_TypeEnregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiants du sous-type de transaction touché par ce cas spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_SousType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Booléen pour indiquer que le cas est résolu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux', @level2type = N'COLUMN', @level2name = N'bCasRegle';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Motif expliquant la création de ce cas spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux', @level2type = N'COLUMN', @level2name = N'vcMotif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires des utilisateurs sur le cas spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CasSpeciaux', @level2type = N'COLUMN', @level2name = N'vcCommentaires';

