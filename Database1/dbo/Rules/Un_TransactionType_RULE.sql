CREATE RULE [dbo].[Un_TransactionType_RULE]
    AS @TransactionType IN ('AUT','CHQ','RTN','1DT','CAN','IRW','INT','FDT','FET','ADJ','WDW');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_TransactionType_RULE]', @objname = N'[dbo].[UnTransactionType]';

