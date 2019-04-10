CREATE RULE [dbo].[Mo_Dep_RULE]
    AS @Dep IN ('U','H','S','A');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Dep_RULE]', @objname = N'[dbo].[Mo_Dep].[DepType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Dep_RULE]', @objname = N'[dbo].[MoDep]';

