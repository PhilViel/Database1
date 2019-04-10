CREATE TABLE [dbo].[tblOPER_EDI_StatutsFichier] (
    [tiID_EDI_Statut_Fichier] TINYINT      IDENTITY (1, 1) NOT NULL,
    [vcCode_Statut]           VARCHAR (3)  NOT NULL,
    [vcDescription]           VARCHAR (35) NOT NULL,
    CONSTRAINT [PK_OPER_EDI_StatutsFichier] PRIMARY KEY CLUSTERED ([tiID_EDI_Statut_Fichier] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de référence contenant les statuts qui définissent un fichier EDI', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_StatutsFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un statut de fichier EDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_StatutsFichier', @level2type = N'COLUMN', @level2name = N'tiID_EDI_Statut_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique d''un statut de fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_StatutsFichier', @level2type = N'COLUMN', @level2name = N'vcCode_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut de fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_StatutsFichier', @level2type = N'COLUMN', @level2name = N'vcDescription';

