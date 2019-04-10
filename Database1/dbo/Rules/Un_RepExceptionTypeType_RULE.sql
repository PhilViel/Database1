CREATE RULE [dbo].[Un_RepExceptionTypeType_RULE]
    AS @RepExceptionTypeType IN ('COM','ADV','CAD','ISB','IB5','IB1','IB2');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_RepExceptionTypeType_RULE]', @objname = N'[dbo].[Un_RepExceptionType].[RepExceptionTypeTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_RepExceptionTypeType_RULE]', @objname = N'[dbo].[UnRepExceptionTypeType]';

