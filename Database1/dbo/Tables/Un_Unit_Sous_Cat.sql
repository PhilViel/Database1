CREATE TABLE [dbo].[Un_Unit_Sous_Cat] (
    [iSous_Cat_ID]       INT           IDENTITY (1, 1) NOT NULL,
    [vcSous_Cat_Code]    VARCHAR (5)   NOT NULL,
    [vcSous_Cat_Desc]    VARCHAR (250) NOT NULL,
    [bCommission]        BIT           NOT NULL,
    [iOrganisation_ID]   INT           NOT NULL,
    [iOrg_Contact_ID]    INT           NOT NULL,
    [bGene_Liste_Pres]   BIT           NOT NULL,
    [vcNom_Fichier_Pres] VARCHAR (250) NULL,
    [vcNom_Fichier_Ded]  VARCHAR (250) NULL,
    [iCateg_ID]          INT           NOT NULL,
    CONSTRAINT [PK_Un_Unit_Sous_Cat] PRIMARY KEY CLUSTERED ([iSous_Cat_ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Unit_Sous_Cat_Un_Unit_Categ__iCategID] FOREIGN KEY ([iCateg_ID]) REFERENCES [dbo].[Un_Unit_Categ] ([iCateg_ID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les codes de sous-catégorie d`unité', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Id unique de la sous-catégorie', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'iSous_Cat_ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de sous-catégorie', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'vcSous_Cat_Code';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Sous-catégorie description', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'vcSous_Cat_Desc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commission calculés sur cette sous-catégorie (Oui / Non)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'bCommission';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de l''organisation relié à la sous-catégorie (Mo_Human)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'iOrganisation_ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du contact dans l''organisation (Mo_Human)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'iOrg_Contact_ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Flag génération d''une liste de prescription pour la sous-catégorie', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'bGene_Liste_Pres';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du fichier des prescriptions générées pour cette sous-catégorie', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'vcNom_Fichier_Pres';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du fichier des déductions à importer pour cette sous-catégorie', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'vcNom_Fichier_Ded';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Id Unique de la catégorie du groupe d’unités. (Un_Unit_Categ)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Sous_Cat', @level2type = N'COLUMN', @level2name = N'iCateg_ID';

