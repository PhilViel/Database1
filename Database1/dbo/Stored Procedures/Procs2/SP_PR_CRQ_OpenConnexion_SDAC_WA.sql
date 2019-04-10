
/****************************************************************************************************
Code de service		:		SP_PR_CRQ_OpenConnexion_SDAC_WA
Nom du service		:		SP_PR_CRQ_OpenConnexion_SDAC_WA
But					:		Cette requête sert à l'ouverture d'une connexion.
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@LoginNameID 
						@PassWordID
						@StationName
						@IPAddress
						@bUseSQLAuth
						
Exemple d'appel:
					
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@UserID 
													@UserName
													@CodeID
													@TerminatedDate
													@LangID
													@VersionID
													@MoTimeOut
													@IsRep
													@ConnectID
                    
Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-04-23					Bruno									Point CRQ-BAS-00002
		2004-05-26					Dominic Létourneau						Correction de la validation du TerminatedDate de l'usager
		2004-11-09					Bruno Lapointe							Réinitialise à vide les paramètres OUTPUT. BR-ADX0001142
		2008-05-01					Radu T.									Modifier pour adapter à SDAC
		2009-03-27					Patrick Robitaille						Création de la SP_PR_CRQ_OpenConnexion_SDAC_WA pour l'authentification Windows
		2009-09-24					Jean-François Gauthier					Remplacement de @@Identity par Scope_Identity()

 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_PR_CRQ_OpenConnexion_SDAC_WA] (
	@LoginNameID MoLoginName,
	@PassWordID MoLoginName = '',	
	@StationName MoDescOption,
	@IPAddress MoDescOption,
	@bUseSQLAuth BIT = 1,
	@UserID MoID OUTPUT,
	@UserName MoDescOption OUTPUT,
	@CodeID MoIDOption OUTPUT,
	@TerminatedDate MoDate OUTPUT, 
	@LangID MoLang OUTPUT,
	@VersionID INTEGER OUTPUT,
	@MoTimeOut MoID OUTPUT,
	@IsRep MoBitFalse OUTPUT
	)
AS
BEGIN
	DECLARE @ConnectID MoID

	SET @ConnectID = -1
	-- Réinitialise à vide les paramètres OUTPUT.
	SET @UserID = 0
	SET @UserName = ''
	SET @CodeID = 0
	SET @TerminatedDate = 0
	SET @LangID = 0
	SET @VersionID = 0
	SET @MoTimeOut = 0
	SET @IsRep = 0

	-- Retrouve le dernier enregistrement de la table Un_Version 
	SELECT 
		@VersionID = MAX(VersionID)
	FROM CRQ_Version

	IF @bUseSQLAuth = 1
	BEGIN	
		SELECT 
			@UserID = UserID,
			@CodeID = CodeID,
			@TerminatedDate = TerminatedDate 
		FROM Mo_User
		WHERE LoginNameID = @LoginNameID
			AND dbo.fn_Mo_Decrypt(PasswordID) = @PasswordID
			AND (ISNULL(TerminatedDate,0) <= 0 OR TerminatedDate > GETDATE())
	END
	ELSE
	BEGIN
		SELECT 
			@UserID = UserID,
			@CodeID = CodeID,
			@TerminatedDate = TerminatedDate 
		FROM Mo_User
		WHERE LoginNameID = @LoginNameID
			AND (ISNULL(TerminatedDate,0) <= 0 OR TerminatedDate > GETDATE())
	END

	IF @UserID IS NOT NULL AND @UserID > 0
	BEGIN --[1]

		SELECT
			@UserName = FirstName + ' ' + LastName,
			@LangID = LangID
		FROM dbo.Mo_Human 
		WHERE HumanID = @UserID
	
	-- Vérification si l'usager est un représentant 
		IF EXISTS (SELECT RepID FROM Un_Rep WHERE RepID = @UserID)
			SET @IsRep = 1
		ELSE
			SET @IsRep = 0

		IF @LangID = 'UNK'
			SET @LangID = 'ENU'
	
		-----------------
		BEGIN TRANSACTION
		-----------------
	
		INSERT Mo_Connect (
			UserID,
			CodeID,
			StationName,
			IPAddress
			)
		VALUES (
			@UserID,
			@CodeID,
			@StationName,
			@IPAddress
			)
	
		IF (@@ERROR = 0)
		BEGIN
			SELECT @ConnectID = SCOPE_IDENTITY()
			------------------
			COMMIT TRANSACTION
			------------------
		END
		ELSE
		BEGIN
			SET @ConnectID = 0
			--------------------
			ROLLBACK TRANSACTION
			--------------------
		END

	END --[1]
	ELSE
	BEGIN
		SELECT 
			@ConnectID = 0,
			@UserID = -1,
			@CodeID = -1,
			@TerminatedDate = CONVERT(datetime, 0), 
			@UserName = '',
			@LangID = 'ENU',
			@IsRep = 0
	END

	CREATE TABLE #TempDataSet(
		ConnectID INTEGER,
		UserID INTEGER,
		CodeID INTEGER,
		TerminatedDate VARCHAR(75),
		UserName VARCHAR(75),
		LangID VARCHAR(3),
		IsRep INTEGER,
        VersionID INTEGER
	)
	
	INSERT INTO #TempDataSet
		SELECT 
			@ConnectID,
			@UserID,
			@CodeID,
			@TerminatedDate, 
			@UserName,
			@LangID,
			@IsRep,
			@VersionID
		
		SELECT 
			ConnectID,
			UserID,
			CodeID,
			TerminatedDate, 
			UserName,
			LangID,
			IsRep,
            VersionID
		FROM #TempDataSet
    
	DROP TABLE #TempDataSet
	RETURN @ConnectID
	
END


