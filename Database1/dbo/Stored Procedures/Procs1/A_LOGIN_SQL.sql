/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	A_LOGIN_SQL
Description         :	Cette procédure créer un compte sur le serveur SQL pour tous les utilisateurs actifs d'Uniacces
						ou pour celui passé en paramètre s'il y en a un. 
Valeurs de retours  :	
Note                :	2008-07-03	Pierre-Luc Simard		Création						
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[A_LOGIN_SQL] (
	@LoginName nvarchar(20) = NULL )  
AS
BEGIN
	DECLARE 
		@Login varchar(50), 
		@Password varchar(50)
	
	DECLARE user_cursor CURSOR FOR
	SELECT 
		U.LoginNameID,
		dbo.fn_Mo_Decrypt(PasswordID) As 'Password'
	FROM Mo_User U
	WHERE U.TerminatedDate IS NULL
		AND LoginNameID = COALESCE(@LoginName, LoginNameID)
	ORDER BY U.LoginNameID

	IF @LoginName = ''	
		SET @LoginName = NULL

	OPEN user_cursor

	FETCH NEXT FROM user_cursor
	INTO @Login, @Password

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF LEN(@Password) = 7
		BEGIN	
			SET @Password = LEFT(@Password, 3) + SUBSTRING(@Password, 4, 1) + LOWER(SUBSTRING(@Password, 5, LEN(@Password) - 4))
		END
		-- Création du compte dans SQL s'il n'existe pas	
		EXEC dbo.A_LOGIN @Login, @Password	   
		FETCH NEXT FROM user_cursor
		INTO @Login, @Password
	END

	CLOSE user_cursor
	DEALLOCATE user_cursor
END

-- Peut être exécuté avec un login en paramètre:

-- EXEC dbo.A_LOGIN_SQL 'pgirard'

-- ou sans login pour créer tous les comptes actifs qui ne sont pas encore créés dans SQL:

-- EXEC dbo.A_LOGIN_SQL
