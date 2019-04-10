CREATE TABLE [dbo].[CRQ_FeatureReleaseVersion] (
    [Feature]          VARCHAR (20) NOT NULL,
    [ReleaseVersionID] INT          NULL,
    CONSTRAINT [PK_CRQ_FeatureReleaseVersion] PRIMARY KEY CLUSTERED ([Feature] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cette table nous permet de connaître à partir de qu''elle version un Feature doit être disponible.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_FeatureReleaseVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de caractères identifiant le feature', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_FeatureReleaseVersion', @level2type = N'COLUMN', @level2name = N'Feature';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique de version (CRQ_Version) à partir de laquel le feature sera disponible', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_FeatureReleaseVersion', @level2type = N'COLUMN', @level2name = N'ReleaseVersionID';

