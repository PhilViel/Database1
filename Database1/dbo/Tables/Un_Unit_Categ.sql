CREATE TABLE [dbo].[Un_Unit_Categ] (
    [iCateg_ID]         INT           IDENTITY (1, 1) NOT NULL,
    [vcCateg]           VARCHAR (250) NOT NULL,
    [vcCode_Importance] VARCHAR (5)   NOT NULL,
    [iPlan_Com]         INT           NOT NULL,
    CONSTRAINT [PK_Un_Unit_Categ] PRIMARY KEY CLUSTERED ([iCateg_ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Unit_Categ_Un_Plan_Com__iPlanCom] FOREIGN KEY ([iPlan_Com]) REFERENCES [dbo].[Un_Plan_Com] ([iPlan_Com_ID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les codes de catégorie d`unité', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Categ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID Unique de la catégorie du groupe d''unités', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Categ', @level2type = N'COLUMN', @level2name = N'iCateg_ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Catégorie-description', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Categ', @level2type = N'COLUMN', @level2name = N'vcCateg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de tri pour la catégorie (Ex.: 100-200-300)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Categ', @level2type = N'COLUMN', @level2name = N'vcCode_Importance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du plan de commission relié à la catégorie', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit_Categ', @level2type = N'COLUMN', @level2name = N'iPlan_Com';

