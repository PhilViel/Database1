CREATE DEFAULT [dbo].[Un_RepExceptionTypeType_DEF]
    AS 'COM';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_RepExceptionTypeType_DEF]', @objname = N'[dbo].[Un_RepExceptionType].[RepExceptionTypeTypeID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_RepExceptionTypeType_DEF]', @objname = N'[dbo].[UnRepExceptionTypeType]';

