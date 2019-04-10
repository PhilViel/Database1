CREATE TABLE [dbo].[tbl_TEMP_OVNTRencontreProspect] (
    [id]             INT            NULL,
    [tel_maison]     NVARCHAR (255) NULL,
    [tel_travail]    NVARCHAR (255) NULL,
    [tel_cellulaire] NVARCHAR (255) NULL,
    [prenom]         NVARCHAR (255) NOT NULL,
    [nom]            NVARCHAR (255) NOT NULL,
    [ville]          NVARCHAR (100) NOT NULL,
    [date_rencontre] DATE           NOT NULL,
    [date_confirme]  NVARCHAR (25)  NOT NULL,
    [RepCode]        INT            NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_TEMP_OVNTRencontreProspect_TelMaison_TelTravail_TelCellulaire]
    ON [dbo].[tbl_TEMP_OVNTRencontreProspect]([tel_maison] ASC, [tel_travail] ASC, [tel_cellulaire] ASC);

