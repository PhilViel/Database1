CREATE TABLE [dbo].[tblOPER_RDI_StatutsDepot] (
    [tiID_RDI_Statut_Depot] TINYINT      IDENTITY (1, 1) NOT NULL,
    [vcCode_Statut]         VARCHAR (3)  NOT NULL,
    [vcDescription]         VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_OPER_RDI_StatutsDepot] PRIMARY KEY CLUSTERED ([tiID_RDI_Statut_Depot] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de référence contenant les statuts de recherche sur les dépôts informatisés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_StatutsDepot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un statut de dépôt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_StatutsDepot', @level2type = N'COLUMN', @level2name = N'tiID_RDI_Statut_Depot';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique d''un statut de dépôt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_StatutsDepot', @level2type = N'COLUMN', @level2name = N'vcCode_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut du dépôt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_RDI_StatutsDepot', @level2type = N'COLUMN', @level2name = N'vcDescription';

