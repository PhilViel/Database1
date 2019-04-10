CREATE DEFAULT [dbo].[CRI_EmptyString]
    AS '';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[CRI_EmptyString]', @objname = N'[dbo].[Un_CESP800ToTreat].[vcNote]';

