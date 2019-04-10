CREATE DEFAULT [dbo].[Un_NoChequeReasonImplication_DEF]
    AS 0;


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_NoChequeReasonImplication_DEF]', @objname = N'[dbo].[Un_NoChequeReason].[NoChequeReasonImplicationID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_NoChequeReasonImplication_DEF]', @objname = N'[dbo].[UnNoChequeReasonImplication]';

