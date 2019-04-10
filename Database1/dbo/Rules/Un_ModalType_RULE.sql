CREATE RULE [dbo].[Un_ModalType_RULE]
    AS @ModalType BETWEEN 0 AND 12;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ModalType_RULE]', @objname = N'[dbo].[Un_MinDepositCfg].[ModalTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ModalType_RULE]', @objname = N'[dbo].[UnModalType]';

