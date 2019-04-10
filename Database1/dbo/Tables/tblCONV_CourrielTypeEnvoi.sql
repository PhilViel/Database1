CREATE TABLE [dbo].[tblCONV_CourrielTypeEnvoi] (
    [iID_CourrielTypeEnvoi]             INT           IDENTITY (1, 1) NOT NULL,
    [vcLibelleFrancais]                 VARCHAR (50)  NOT NULL,
    [vcLibelleAnglais]                  VARCHAR (50)  NOT NULL,
    [dtDateDebut]                       DATE          CONSTRAINT [DF_CONV_CourrielTypeEnvoi_dtDateDebut] DEFAULT (getdate()) NOT NULL,
    [dtDateFin]                         DATE          NULL,
    [vcDescriptionFrancais]             VARCHAR (255) NULL,
    [vcDescriptionAnglais]              VARCHAR (255) NULL,
    [vcDescriptionFrancaisBeneficiaire] VARCHAR (255) NULL,
    [vcDescriptionAnglaisBeneficiaire]  VARCHAR (255) NULL,
    CONSTRAINT [PK_CONV_CourrielTypeEnvoi] PRIMARY KEY CLUSTERED ([iID_CourrielTypeEnvoi] ASC)
);

