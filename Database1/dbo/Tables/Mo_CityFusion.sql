CREATE TABLE [dbo].[Mo_CityFusion] (
    [OldCityName] [dbo].[MoCity] NOT NULL,
    [CityID]      [dbo].[MoID]   NOT NULL,
    [ConnectID]   [dbo].[MoID]   NOT NULL,
    [StateID]     INT            NULL,
    CONSTRAINT [PK_Mo_CityFusion] PRIMARY KEY CLUSTERED ([OldCityName] ASC, [CityID] ASC),
    CONSTRAINT [FK_Mo_CityFusion_Mo_City__CityID] FOREIGN KEY ([CityID]) REFERENCES [dbo].[Mo_City] ([CityID]),
    CONSTRAINT [FK_Mo_CityFusion_Mo_State__StateID] FOREIGN KEY ([StateID]) REFERENCES [dbo].[Mo_State] ([StateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_CityFusion_CityID]
    ON [dbo].[Mo_CityFusion]([CityID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_CityFusion_StateID]
    ON [dbo].[Mo_CityFusion]([StateID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de fusion de villes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_CityFusion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de ville qu''il faut fusionner.  Quand un usager tappera ce nom de ville, automatique il sera remplacé par le nom (Mo_City.CityName) correspondant au CityID de cette enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_CityFusion', @level2type = N'COLUMN', @level2name = N'OldCityName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la ville (Mo_City).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_CityFusion', @level2type = N'COLUMN', @level2name = N'CityID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect) de l''usager qui a fait cette fusion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_CityFusion', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifiant de l''état ou de la province', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_CityFusion', @level2type = N'COLUMN', @level2name = N'StateID';

