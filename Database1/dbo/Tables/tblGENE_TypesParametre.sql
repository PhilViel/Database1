CREATE TABLE [dbo].[tblGENE_TypesParametre] (
    [iID_Type_Parametre]           INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Type_Parametre]        VARCHAR (100) NOT NULL,
    [vcDescription]                VARCHAR (500) NOT NULL,
    [tiNB_Dimensions]              TINYINT       NOT NULL,
    [bConserver_Historique]        BIT           NOT NULL,
    [bPermettre_MAJ_Via_Interface] BIT           NOT NULL,
    [vcTypeDonneParametre]         VARCHAR (20)  NULL,
    [iLongueurParametre]           INT           NULL,
    [iNbreDecimale]                INT           NULL,
    [vcNomDimension1]              VARCHAR (30)  NULL,
    [vcNomDimension2]              VARCHAR (30)  NULL,
    [vcNomDimension3]              VARCHAR (30)  NULL,
    [vcNomDimension4]              VARCHAR (30)  NULL,
    [vcNomDimension5]              VARCHAR (30)  NULL,
    [bObligatoire]                 BIT           NULL,
    CONSTRAINT [PK_GENE_TypesParametre] PRIMARY KEY CLUSTERED ([iID_Type_Parametre] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_GENE_TypesParametre_vcCodeTypeParametre]
    ON [dbo].[tblGENE_TypesParametre]([vcCode_Type_Parametre] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code du type de paramètre.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypesParametre', @level2type = N'INDEX', @level2name = N'AK_GENE_TypesParametre_vcCodeTypeParametre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé unique des types de paramètre.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypesParametre', @level2type = N'CONSTRAINT', @level2name = N'PK_GENE_TypesParametre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les types de paramètres applicatifs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypesParametre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un type de paramètre applicatif.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypesParametre', @level2type = N'COLUMN', @level2name = N'iID_Type_Parametre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code interne unique du type de paramètre applicatif.  C''est le code qui est codé en dur dans le code.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypesParametre', @level2type = N'COLUMN', @level2name = N'vcCode_Type_Parametre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type de paramètre applicatif qui décrit dans quel contexte est utilisé le type de paramètre et quelles sont les différentes dimensions aux paramètres.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypesParametre', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre de dimensions du type de paramètre.  Les valeurs possibles sont de 0 à 5.  0 signifie qu''il n''y a pas de dimension.  Le paramètre est unique pour l''ensemble de l''application et ne peut pas être modulé par utilisateur ou par toute autre dimension.  De 1 à 5, cela signifie qu''il y a une ou plusieurs dimensions au paramètre.  Exemple: Une dimension par utilisateur permet d''avoir une valeur au paramètre qui diffère d''un utilisateur à un autre ou sinon d''avoir une valeur au paramètre pour tous les utilisateurs si l''utilisateur n''a pas un paramètre spécifique à celui-ci.  Autre exemple: Un paramètre à 2 dimensions (Département et utilisateur), permet d''avoir une valeur au paramètre pour les travaux d''un utilisateur dans un département, d''avoir une valeur au paramètre différent  pour le même utilisateur dans un autre département, d''avoir une valeur au paramètre pour tous les utilisateurs d''un département ou d''avoir une valeur au paramètre pour tous les utilisateurs de tous les départements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypesParametre', @level2type = N'COLUMN', @level2name = N'tiNB_Dimensions';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour savoir si un historique doit être conservé pour le type de paramètre.  S''il est à faux, la valeur du paramètre est mise à jour au lieu d''être ajoutée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypesParametre', @level2type = N'COLUMN', @level2name = N'bConserver_Historique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur qui permet à une interface utilisateur de mettre à jour les valeurs du type de paramètre.  Les paramètres d''un type de paramètre non éditable via l''interface doivent être mise à jour manuellement par l''informatique et n''ont pas d''utilité pour l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypesParametre', @level2type = N'COLUMN', @level2name = N'bPermettre_MAJ_Via_Interface';

