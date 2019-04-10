CREATE RULE [dbo].[Un_TransType400_RULE]
    AS @TransType400 IN (11,12,13,14,15,16,19,21,22,23);


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_TransType400_RULE]', @objname = N'[dbo].[UnTransType400]';

