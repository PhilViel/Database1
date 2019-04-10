/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	A_LOGIN
					@LoginName nvarchar(20) - Pour le Login de SQL-SERVER  
					@Password nvarchar(20)
					@DataBase nvarchar(20)- La base de données. Par default est 'UnivBase',
					@UserForDataBase bit=0 - [0]-On ajoute Login pour SQL; 1-pour SQL et DataBase ensemble. Par default - 0									
						
Description         :	Pour ajouter Login et User (si nécessaire)
Valeurs de retours  :		
							

Note                :	2008-05-05	Vladimir Gaspariants		Création
						2008-07-03	Pierre-Luc Simard			Ne créer pas le compte s'il existe déjà 
						2009-01-09	Pierre-Luc Simard			Correction pour utiliser des tirets dans les login	  
*********************************************************************************************************************/


CREATE PROCEDURE [dbo].[A_LOGIN] (
	@LoginName nvarchar(20),  
	@Password nvarchar(20),
	@DataBase nvarchar(20)='UnivBase',
	@UserForDataBase bit=0) 
AS
BEGIN

--Pour SQL-Server
IF NOT EXISTS(SELECT name FROM sys.sql_logins WHERE name = @LoginName) 
	BEGIN
		EXEC('CREATE LOGIN [' + @LoginName + '] WITH PASSWORD=''' + @Password + ''', DEFAULT_DATABASE=' + @DataBase + '')
		EXEC('sys.sp_addsrvrolemember @loginame  =[' + @LoginName + '], @rolename = N''sysadmin''')
		EXEC('ALTER LOGIN [' + @LoginName + '] ENABLE')--DISABLE')	END--Pour UnivBaseIF @UserForDataBase=1	BEGIN		--User pour la base de données UnivBase:
		EXEC('CREATE USER [' +@LoginName + '] FOR LOGIN [' + @LoginName + ']')
		EXEC('ALTER AUTHORIZATION ON SCHEMA::[db_owner] TO [' + @LoginName + ']')
		EXEC('sys.sp_addrolemember N''db_owner'', [' + @LoginName + ']')
	END
END-- EXEC dbo.A_LOGIN 'mbreton', '253Zbja'


