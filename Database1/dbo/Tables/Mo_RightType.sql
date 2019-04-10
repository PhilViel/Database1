CREATE TABLE [dbo].[Mo_RightType] (
    [RightTypeID]   [dbo].[MoID]       IDENTITY (1, 1) NOT NULL,
    [RightTypeDesc] [dbo].[MoLongDesc] NOT NULL,
    CONSTRAINT [PK_Mo_RightType] PRIMARY KEY CLUSTERED ([RightTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des types de droits.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_RightType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type de droit.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_RightType', @level2type = N'COLUMN', @level2name = N'RightTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du type de droit.  Ce champs permet le multi-langue.  C''est-à-dire qu''on peut y inscrire le nom en plusieurs langue et que selon la langue de l''usager la bon s''affichera.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_RightType', @level2type = N'COLUMN', @level2name = N'RightTypeDesc';

