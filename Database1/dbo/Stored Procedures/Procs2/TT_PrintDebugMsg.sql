CREATE PROCEDURE [dbo].[TT_PrintDebugMsg](
	@ProcID int,
	@Msg varchar(100)
) AS
BEGIN
	DECLARE @ObjName varchar(100) = OBJECT_NAME(@PROCID),
	        @NbSpace int = 0,
             @Datetime varchar(20) = CONVERT(varchar, GetDate(), 120)

	If dbo.FN_IsDebug() = 0
		RETURN

	IF OBJECT_ID('tempdb..#TB_PrintDebugMsg') IS NULL
	BEGIN
		CREATE TABLE #TB_PrintDebugMsg (RowNo int identity(0,1), objName varchar(100) NOT NULL, Msg varchar(100) NULL)
		PRINT 'CREATE TABLE #TB_PrintDebugMsg'
	END

	IF CharIndex('Begin', @Msg, 1) > 0 Or CharIndex('Start', @Msg, 1) > 0
	BEGIN
		SELECT @NbSpace = Count(*) From #TB_PrintDebugMsg

		INSERT INTO #TB_PrintDebugMsg (objName, Msg) VALUES (@ObjName, @Msg)
	END
	ELSE
	BEGIN
		IF CharIndex('End', @Msg, 1) > 0 Or CharIndex('Terminate', @Msg, 1) > 0 Or CharIndex('TRIGGER IGNORE', @Msg, 1) > 0
		BEGIN
			IF EXISTS(Select Top 1 * From #TB_PrintDebugMsg Where objName = @ObjName)
			BEGIN
				DECLARE @MaxRow int = -1
				SELECT @MaxRow = Max(IsNull(RowNo, 0)) From #TB_PrintDebugMsg Where objName = @ObjName

				DELETE FROM #TB_PrintDebugMsg WHERE RowNo >= @MaxRow
			END
		END

		SELECT @NbSpace = Count(*) From #TB_PrintDebugMsg
	END

	PRINT @Datetime + ': ' + Space(IsNull(@NbSpace, 0) * 3) +  @ObjName + ' - ' + @Msg
END