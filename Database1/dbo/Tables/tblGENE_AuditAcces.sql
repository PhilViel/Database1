CREATE TABLE [dbo].[tblGENE_AuditAcces] (
    [iID_AuditAcces]   INT           IDENTITY (1, 1) NOT NULL,
    [dtDate_Acces]     DATETIME      NOT NULL,
    [vcUtilisateur]    VARCHAR (75)  NOT NULL,
    [vcNom_Server]     VARCHAR (20)  NOT NULL,
    [vcNom_BD]         VARCHAR (20)  NOT NULL,
    [vcContexte]       VARCHAR (500) NOT NULL,
    [bAcces_Courriel]  BIT           CONSTRAINT [DF_tblGENE_AuditAcces_bAcces_Courriel] DEFAULT ((0)) NOT NULL,
    [bAcces_Telephone] BIT           CONSTRAINT [DF_tblGENE_AuditAcces_bAcces_Telephone] DEFAULT ((0)) NOT NULL,
    [bAcces_Adresse]   BIT           CONSTRAINT [DF_tblGENE_AuditAcces_bAcces_Adresse] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_tblGENE_AuditAcces] PRIMARY KEY CLUSTERED ([iID_AuditAcces] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le courriel du l''humain a été consulté', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AuditAcces', @level2type = N'COLUMN', @level2name = N'bAcces_Courriel';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si les téléphones de l''humain ont été consultés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AuditAcces', @level2type = N'COLUMN', @level2name = N'bAcces_Telephone';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''adresse de l''humain a été consultée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AuditAcces', @level2type = N'COLUMN', @level2name = N'bAcces_Adresse';

