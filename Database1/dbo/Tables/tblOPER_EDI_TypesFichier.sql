CREATE TABLE [dbo].[tblOPER_EDI_TypesFichier] (
    [tiID_EDI_Type_Fichier] TINYINT       IDENTITY (1, 1) NOT NULL,
    [vcCode_Type_Fichier]   VARCHAR (3)   NOT NULL,
    [vcDescription]         VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_OPER_EDI_TypesFichier] PRIMARY KEY CLUSTERED ([tiID_EDI_Type_Fichier] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de référence contenant les types qui définissent un fichier EDI', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_TypesFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un type de fichier EDI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_TypesFichier', @level2type = N'COLUMN', @level2name = N'tiID_EDI_Type_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique d''un type de fichier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_TypesFichier', @level2type = N'COLUMN', @level2name = N'vcCode_Type_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type de fichier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_TypesFichier', @level2type = N'COLUMN', @level2name = N'vcDescription';

