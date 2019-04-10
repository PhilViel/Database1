CREATE TABLE [dbo].[tblGENE_Traductions] (
    [iID_Traduction]      INT            IDENTITY (1, 1) NOT NULL,
    [vcNom_Table]         VARCHAR (150)  NOT NULL,
    [vcNom_Champ]         VARCHAR (150)  NOT NULL,
    [iID_Enregistrement]  INT            NULL,
    [vcID_Enregistrement] VARCHAR (15)   NULL,
    [vcID_Langue]         VARCHAR (3)    NOT NULL,
    [vcTraduction]        VARCHAR (8000) NULL,
    CONSTRAINT [PK_GENE_Traductions] PRIMARY KEY CLUSTERED ([iID_Traduction] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_GENE_Traductions_vcNomTable_vcNomChamp_iIDEnregistrement_vcIDEnregistrement_vcIDLangue]
    ON [dbo].[tblGENE_Traductions]([vcNom_Table] ASC, [vcNom_Champ] ASC, [iID_Enregistrement] ASC, [vcID_Enregistrement] ASC, [vcID_Langue] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par l''identification unique d''un texte à traduire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions', @level2type = N'INDEX', @level2name = N'AK_GENE_Traductions_vcNomTable_vcNomChamp_iIDEnregistrement_vcIDEnregistrement_vcIDLangue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de l''identifiant unique de traduction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions', @level2type = N'CONSTRAINT', @level2name = N'PK_GENE_Traductions';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table permettant aux services SQL de traduire les champs de texte des tables de références d''UniAccès pour les interfaces Web d''UniAccès.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un enregistrement de traduction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions', @level2type = N'COLUMN', @level2name = N'iID_Traduction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la table de références contenant le champ à traduire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions', @level2type = N'COLUMN', @level2name = N'vcNom_Table';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du champ de la table de référence qui doit être traduit.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions', @level2type = N'COLUMN', @level2name = N'vcNom_Champ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique numérique de l''enregistrement contenant le champ à traduire.  Les nouvelles tables utilisent nécessairement un identifiant unique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions', @level2type = N'COLUMN', @level2name = N'iID_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique en format alpha numérique de l''enregistrement contenant le champ à traduire.  Ce champ est utilisé pour traduire les descriptions des anciennes tables où l''identifiant unique n''est pas numérique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions', @level2type = N'COLUMN', @level2name = N'vcID_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la langue de traduction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions', @level2type = N'COLUMN', @level2name = N'vcID_Langue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Texte de la traduction selon la langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Traductions', @level2type = N'COLUMN', @level2name = N'vcTraduction';

