CREATE DEFAULT [dbo].[Mo_RegularSign_DEF]
    AS 'DT';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_RegularSign_DEF]', @objname = N'[dbo].[MoRegularSign]';

