CREATE TABLE [dbo].[tblGENE_EquipeTravail] (
    [iID_Equipe]            INT           IDENTITY (1, 1) NOT NULL,
    [vcNomEquipe]           VARCHAR (50)  NULL,
    [vcDesciption]          VARCHAR (100) NULL,
    [iID_HumainResponsable] INT           NULL,
    [iID_EquipeResponsable] INT           NULL,
    CONSTRAINT [PK_GENE_EquipeTravail] PRIMARY KEY CLUSTERED ([iID_Equipe] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_EquipeTravail_Mo_Human__iIDHumainResponsable] FOREIGN KEY ([iID_HumainResponsable]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant la liste des équipes de travail', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_EquipeTravail';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'iID_Equipe identifie tblGENE_EquipeTravail', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_EquipeTravail', @level2type = N'COLUMN', @level2name = N'iID_Equipe';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'vcNomEquipe appartient à tblGENE_EquipeTravail', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_EquipeTravail', @level2type = N'COLUMN', @level2name = N'vcNomEquipe';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'vcDesciption appartient à tblGENE_EquipeTravail', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_EquipeTravail', @level2type = N'COLUMN', @level2name = N'vcDesciption';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du reponsable appartient à tblGENE_EquipeTravail', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_EquipeTravail', @level2type = N'COLUMN', @level2name = N'iID_HumainResponsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'iID_EquipeResponsable appartient à tblGENE_EquipeTravail', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_EquipeTravail', @level2type = N'COLUMN', @level2name = N'iID_EquipeResponsable';

