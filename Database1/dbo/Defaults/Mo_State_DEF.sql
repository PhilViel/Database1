CREATE DEFAULT [dbo].[Mo_State_DEF]
    AS 'QC';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_State_DEF]', @objname = N'[dbo].[MoState]';

