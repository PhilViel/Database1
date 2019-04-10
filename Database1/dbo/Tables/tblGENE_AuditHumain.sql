CREATE TABLE [dbo].[tblGENE_AuditHumain] (
    [iID_AuditHumain] INT IDENTITY (1, 1) NOT NULL,
    [iID_AuditAcces]  INT NOT NULL,
    [iID_Humain]      INT NOT NULL,
    CONSTRAINT [PK_tblGENE_AuditHumain] PRIMARY KEY CLUSTERED ([iID_AuditHumain] ASC),
    CONSTRAINT [FK_tblGENE_AuditHumain_tblGENE_AuditAcces] FOREIGN KEY ([iID_AuditAcces]) REFERENCES [dbo].[tblGENE_AuditAcces] ([iID_AuditAcces])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table dans laquelle on historise les accès aux données des clients.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AuditHumain';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AuditHumain', @level2type = N'COLUMN', @level2name = N'iID_AuditHumain';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''humain auquel des infos ont été consultées', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AuditHumain', @level2type = N'COLUMN', @level2name = N'iID_Humain';

