CREATE RULE [dbo].[Un_TransType200_RULE]
    AS @TransType200 IN (3, 4, 5, 6, 7, 8);


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_TransType200_RULE]', @objname = N'[dbo].[UnTransType200]';

