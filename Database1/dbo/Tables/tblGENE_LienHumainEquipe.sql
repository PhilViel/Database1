CREATE TABLE [dbo].[tblGENE_LienHumainEquipe] (
    [iID_LienHumainEquipe] INT IDENTITY (1, 1) NOT NULL,
    [iID_Equipe]           INT NOT NULL,
    [iID_Humain]           INT NULL,
    CONSTRAINT [PK_GENE_LienHumainEquipe] PRIMARY KEY CLUSTERED ([iID_LienHumainEquipe] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_LienHumainEquipe_GENE_EquipeTravail__iIDEquipe] FOREIGN KEY ([iID_Equipe]) REFERENCES [dbo].[tblGENE_EquipeTravail] ([iID_Equipe]),
    CONSTRAINT [FK_GENE_LienHumainEquipe_Mo_Human__iIDHumain] FOREIGN KEY ([iID_Humain]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de liaison entre les humains et les équipes de travail', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_LienHumainEquipe';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'iID_LienHumaineEquipe identifie tblGENE_LienHumainEquipe', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_LienHumainEquipe', @level2type = N'COLUMN', @level2name = N'iID_LienHumainEquipe';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'iID_Equipe identifie tblGENE_LienHumainEquipe', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_LienHumainEquipe', @level2type = N'COLUMN', @level2name = N'iID_Equipe';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'HumanID appartient à tblGENE_LienHumainEquipe', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_LienHumainEquipe', @level2type = N'COLUMN', @level2name = N'iID_Humain';

