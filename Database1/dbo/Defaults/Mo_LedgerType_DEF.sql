CREATE DEFAULT [dbo].[Mo_LedgerType_DEF]
    AS 'UNK';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_LedgerType_DEF]', @objname = N'[dbo].[MoLedgerType]';

