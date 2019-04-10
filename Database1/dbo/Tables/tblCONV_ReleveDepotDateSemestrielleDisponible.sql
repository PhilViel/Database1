CREATE TABLE [dbo].[tblCONV_ReleveDepotDateSemestrielleDisponible] (
    [iDateID]                INT      IDENTITY (1, 1) NOT NULL,
    [dtDateReleveSemestriel] DATETIME NOT NULL,
    [bDateDisponible]        BIT      CONSTRAINT [DF_CONV_ReleveDepotDateSemestrielleDisponible_bDateDisponible] DEFAULT ((0)) NOT NULL,
    [bDateDebut]             BIT      CONSTRAINT [DF_CONV_ReleveDepotDateSemestrielleDisponible_bDateDebut] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CONV_ReleveDepotDateSemestrielleDisponible] PRIMARY KEY CLUSTERED ([iDateID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant la liste des dates disponibles pour la génération des relevés de dépôt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReleveDepotDateSemestrielleDisponible';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReleveDepotDateSemestrielleDisponible', @level2type = N'COLUMN', @level2name = N'iDateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date semestriel de visualisation des relevés de dépôt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReleveDepotDateSemestrielleDisponible', @level2type = N'COLUMN', @level2name = N'dtDateReleveSemestriel';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la date est disponible à l''utilisateur (afin de visualiser les relevés de dépôts de cette date)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ReleveDepotDateSemestrielleDisponible', @level2type = N'COLUMN', @level2name = N'bDateDisponible';

