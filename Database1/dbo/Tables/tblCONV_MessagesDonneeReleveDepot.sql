CREATE TABLE [dbo].[tblCONV_MessagesDonneeReleveDepot] (
    [id]       INT             IDENTITY (1, 1) NOT NULL,
    [dtDtTime] DATETIME        NULL,
    [vfacette] NVARCHAR (50)   NULL,
    [vmodule]  NVARCHAR (50)   NULL,
    [vmess]    NVARCHAR (4000) NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les messages créés lors de la génération des données des relevés de dépôt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_MessagesDonneeReleveDepot';

