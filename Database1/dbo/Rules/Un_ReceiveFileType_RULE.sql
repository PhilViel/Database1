CREATE RULE [dbo].[Un_ReceiveFileType_RULE]
    AS @ReceiveFileType IN ('ser', 'err', 'reg', 'pro');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ReceiveFileType_RULE]', @objname = N'[dbo].[UnReceiveFileType]';

