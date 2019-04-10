CREATE RULE [dbo].[Mo_Civil_RULE]
    AS @Civil IN ('U','S','M','J','D','P','W');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Civil_RULE]', @objname = N'[dbo].[Mo_Human].[CivilID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Civil_RULE]', @objname = N'[dbo].[MoCivil]';

