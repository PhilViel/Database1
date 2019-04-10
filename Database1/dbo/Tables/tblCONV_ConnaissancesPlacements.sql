CREATE TABLE [dbo].[tblCONV_ConnaissancesPlacements] (
    [iID_Connaissance_Placements]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Connaissance_Placements] VARCHAR (100) NOT NULL,
    [vcDescription]                  VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_CONV_ConnaissancesPlacements] PRIMARY KEY CLUSTERED ([iID_Connaissance_Placements] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les niveaux de connaissance sur les placements', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ConnaissancesPlacements';

