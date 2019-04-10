/*----------------------------------------------------------------------------------------------------------
Version 1: Manohar Punna 3/1/2011
Desc: Send Disk space alert with free space details in each drive
------------------------------------------------------------------------------------------------------------
input: @mailto - recepients list
         @mailProfile - DBMail Profile.
         @threshold - Threshold Free space in MB below which you need the alert to be sent.
         @logfile - Log file to hold the file size details and send it as attachment.
output: Send Mail

Warnings: None.
------------------------------------------------------------------------------------------------------------
Example: EXEC [psGENE_VerifierEspaceDisque]
							@mailto = 'pierre-luc.simard@universitas.qc.ca',
							@threshold = 10240 -- 10 Go
------------------------------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[psGENE_VerifierEspaceDisque]
	@mailto nvarchar(4000),
	@threshold INT
AS
BEGIN
	declare @count int;
	declare @tempfspace int;
	declare @tempdrive char(1);
	declare @mailbody nvarchar(4000);
	declare @altflag bit;
	declare @sub nvarchar(4000);
	SET @count = 0;
	SET @mailbody = '';
	SET NOCOUNT ON
	
	-- Création de la table contenant les infos sur les disques
	IF object_id('tempdb..#driveinfo') is not null 
		drop table #driveinfo
	create table #driveinfo(id int identity(1,1),drive char(1), fspace int)
	insert into #driveinfo EXEC master..xp_fixeddrives
	--SELECT * FROM #driveinfo
	
	--Vérifier si l'espace disponible est en dessous de la limite permise
	while (select count(*) from #driveinfo) >= @count
	begin
		set @tempfspace = (select fspace from #driveinfo where id = @count)
		set @tempdrive = (select drive from #driveinfo where id = @count)
		if @tempfspace < @threshold
		BEGIN
			SET @altflag = 1;
			SET @mailbody = @mailbody + '<p>Le disque ' + CAST(@tempdrive AS NVARCHAR(10)) + ' a seulement ' + CAST(@tempfspace AS NVARCHAR(10)) + ' Mo de libre.</br>'
		END
		set @count = @count + 1
	end
	
	--Un courriel est envoyé si un des disques est en dessous de la limite
	IF (@altflag = 1)
	BEGIN
		SET @sub = 'Espace disque manquant sur ' + CAST(@@SERVERNAME AS NVARCHAR(30))
		EXEC msdb.dbo.sp_send_dbmail
			@recipients= @mailto,
			@subject = @sub,
			@body = @mailbody,
			@body_format = 'HTML'
	END
	
	drop table #driveinfo
	set nocount off
END
