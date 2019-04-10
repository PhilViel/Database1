CREATE TABLE [dbo].[tblCONV_RevenuFamilial] (
    [iID_Revenu_Familial]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Revenu_Familial] VARCHAR (100) NOT NULL,
    [vcDescription]          VARCHAR (150) NOT NULL,
    [vcDescription_ENU]      VARCHAR (150) NULL,
    [RevenuMinimum]          MONEY         NULL,
    [RevenuMaximum]          MONEY         NULL,
    [CapaciteMaximale]       MONEY         NULL,
    [DateDebut]              DATE          NULL,
    [DateFin]                DATE          NULL,
    CONSTRAINT [PK_CONV_RevenuFamilial] PRIMARY KEY CLUSTERED ([iID_Revenu_Familial] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les codes de revenu familial', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenuFamilial';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date à laquelle cette tranche de revenu peut être utilisée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenuFamilial', @level2type = N'COLUMN', @level2name = N'DateDebut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date à laquelle cette tranche de revenu ne peut plus être utilisée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_RevenuFamilial', @level2type = N'COLUMN', @level2name = N'DateFin';

