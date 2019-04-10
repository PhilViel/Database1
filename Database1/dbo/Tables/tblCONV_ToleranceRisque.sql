CREATE TABLE [dbo].[tblCONV_ToleranceRisque] (
    [iID_Tolerance_Risque]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Tolerance_Risque] VARCHAR (100) NOT NULL,
    [vcDescription]           VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_CONV_ToleranceRisque] PRIMARY KEY CLUSTERED ([iID_Tolerance_Risque] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les niveaux de tolérance au risque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ToleranceRisque';

