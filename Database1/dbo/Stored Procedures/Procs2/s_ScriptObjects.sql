Create procedure s_ScriptObjects
@SourceDB	varchar(128) ,
@SourceObject	varchar(128) ,
@SourceUID	varchar(128) ,
@SourcePWD	varchar(128) ,
@OutFilePath	varchar(128) ,
@OutFileName	varchar(128) ,
@ObjectType	varchar(50)	-- PROCS, FUNCTIONS, TABLES
as 
	set nocount on
/*
exec	s_ScriptObjects
		@SourceDB = 'mydb' ,
		@SourceObject = null ,
		@SourceUID = 'sa' ,
		@SourcePWD = 'password' ,
		@OutFilePath = 'c:\' ,
		@OutFileName = 'myfile.sql' ,
		@ObjectType = 'TABLES'
*/

declare	@SourceSVR	varchar(128) ,
	@ScriptType	int ,
	@FileName	varchar(128) ,
	@TmpFileName	varchar(128) ,
	@buffer		varchar(8000) ,
	@Collection	varchar(128)

declare	@context	varchar(255) ,
	@sql		varchar(1000) ,
	@rc		int
		
select	@SourceSVR	= '(local)'
	
select	@ScriptType	= 4 | 1 | 64 ,
	@FileName	= @OutFilePath + @OutFileName ,
	@tmpFileName	= @OutFilePath + 'ScriptTmp.txt'
	
declare	@objServer		int ,
	@objTransfer		int ,
	@strResult		varchar(255) ,
	@strCommand		varchar(255)
	
	-- get objects to script and object type
	create table #Objects (name varchar(128))
	
	if @SourceObject is not null
		insert	#Objects (name)
		select @SourceObject
	
	if @ObjectType = 'TABLES'
	begin
		if @SourceObject is null
		begin
			select @sql = 		'insert	#Objects (name) '
			select @sql = @sql + 	'select 	TABLE_NAME '
			select @sql = @sql + 	'from	' + @SourceDB + '.INFORMATION_SCHEMA.TABLES '
			select @sql = @sql + 	'where	TABLE_TYPE = ''BASE TABLE'''
			exec (@sql)
		end
		select @Collection = 'tables'
	end	
	else if @ObjectType = 'PROCS'
	begin
		if @SourceObject is null
		begin
			select @sql = 		'insert	#Objects (name) '
			select @sql = @sql + 	'select 	ROUTINE_NAME '
			select @sql = @sql + 	'from	' + @SourceDB + '.INFORMATION_SCHEMA.ROUTINES '
			select @sql = @sql + 	'where	ROUTINE_TYPE = ''PROCEDURE'''
			exec (@sql)
		end
		select @Collection = 'storedprocedures'
	end	
	else if @ObjectType = 'FUNCTIONS'
	begin
		if @SourceObject is null
		begin
			select @sql = 		'insert	#Objects (name) '
			select @sql = @sql + 	'select 	ROUTINE_NAME '
			select @sql = @sql + 	'from	' + @SourceDB + '.INFORMATION_SCHEMA.ROUTINES '
			select @sql = @sql + 	'where	ROUTINE_TYPE = ''FUNCTION'''
			exec (@sql)
		end
		select @Collection = 'userdefinedfunctions'
	end	
	else
	begin
		select 'invalid @ObjectType'
		return
	end
	
	-- create empty output file
	select	@sql = 'echo. > ' + @FileName
	exec master..xp_cmdshell @sql
	
	-- prepare scripting object
	select @context = 'anywhere'
	exec @rc = sp_OACreate 'SQLDMO.SQLServer', @objServer OUT
	if @rc <> 0 or @@error <> 0 goto ErrorHnd
	
	exec @rc = sp_OAMethod @objServer , 'Connect', NULL, @SourceSVR , @SourceUID , @SourcePWD
	if @rc <> 0 or @@error <> 0 goto ErrorHnd

	-- Script all the objects
	select @SourceObject = ''
	while exists (select * from #Objects where name > @SourceObject)
	begin
		select @SourceObject = min(name) from #Objects where name > @SourceObject
		select @sql = 'echo print ''Create = ' + @SourceObject + ''' >> ' + @FileName
		exec master..xp_cmdshell @sql
		Set @sql = 'databases("' + @SourceDB + '").' + @Collection + '("' + @SourceObject + '").script'
		exec @rc = sp_OAMethod @objServer, @sql , @buffer OUTPUT, @ScriptType , @tmpFileName
		select @sql = 'type ' + @tmpFileName + ' >> ' + @FileName
		exec master..xp_cmdshell @sql
	end
	-- delete tmp file
	select @sql = 'del ' + @tmpFileName
	exec master..xp_cmdshell @sql
	
	-- clear up dmo
	exec @rc = sp_OAMethod @objServer, 'Disconnect'
	if @rc <> 0 or @@error <> 0 goto ErrorHnd
	
	exec @rc = sp_OADestroy @objServer
	if @rc <> 0 or @@error <> 0 goto ErrorHnd
	
	-- clear up temp table
	drop table #Objects
	
return
ErrorHnd:
select 'fail', @context

