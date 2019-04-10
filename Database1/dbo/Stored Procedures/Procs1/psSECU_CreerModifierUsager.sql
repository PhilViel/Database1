
/****************************************************************************************************
Code de service		:		psSECU_CreerModifierUsager
Nom du service		:		psSECU_CreerModifierUsager
But					:		Création d'un nouvel utilisateur
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@UserID						--Mo_User
						@FirstName					--Mo_Human
						@LastName					--Mo_Human
						@LangID						--Mo_Human
						@TerminatedDate				--Mo_User
						@PasswordEndDate			--Mo_User
						@LoginNameID				--Mo_User
						@PassWordID					--Mo_User
						
Exemple d'appel:
               EXECUTE dbo.psSECU_CreerModifierUsager NULL, 'prenom', 'nom', 'FRA', '2012-12-31', '2012-12-31', 'login', 'p@$$word'

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
					   Mo_Human / Mo_User			HumanId	/ UserId							Identifiant de l'utilisateur
					   S/O							-1  										Si une erreur s'est produite

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-06-17					Jean-François Gauthier					Création de la procédure
                        2009-09-24					Jean-François Gauthier					Remplacement de @@Identity par Scope_Identity()
 ****************************************************************************************************/


CREATE PROCEDURE [dbo].[psSECU_CreerModifierUsager]
	  @UserID               MoID,						--Mo_User
	  @FirstName            MoFirstName,				--Mo_Human
	  @LastName             MoLastName,					--Mo_Human
	  @LangID               MoLang,						--Mo_Human
	  @TerminatedDate       MoDateOption,				--Mo_User
	  @PasswordEndDate      MoDateOption,				--Mo_User
	  @LoginNameID          MoLoginName,				--Mo_User
	  @PassWordID           MoLoginName					--Mo_User
AS
	BEGIN
		SET NOCOUNT ON
		
		DECLARE @dPasswordDate	DATETIME

		SET @dPasswordDate =GETDATE()

		BEGIN TRY
			IF @UserID IS NULL		-- CRÉATION
				BEGIN
					-- INSERTION DANS LA TABLE Mo_Human
					INSERT INTO dbo.Mo_Human
						(
							FirstName,
							LastName, 
							[LangID]  
						)
					VALUES
						(
							@FirstName,
							@LastName,
							@LangID
						)
					SELECT @UserID = SCOPE_IDENTITY()

					-- INSERTION DANS LA TABLE Mo_User
					INSERT INTO dbo.Mo_User 
						(
							UserID,		
							LoginNameID,
							PassWordID,
							PassWordDate,
							PassWordEndDate,
							TerminatedDate
						)
					VALUES 
						(
							@UserID,					-- Le UserId et le HumanId sont les mêmes
							@LoginNameID,
							dbo.fn_Mo_Encrypt(@PassWordID),
							@dPasswordDate,
							@PassWordEndDate,
							@TerminatedDate
						)				
				END
			ELSE					-- MISE À JOUR
				BEGIN
					-- MISE À JOUR DE LA TABLE Mo_Human
					UPDATE dbo.Mo_Human 
					SET
						FirstName			= @FirstName,
						LastName			= @LastName,
						[LangID]			= @LangID
					WHERE 
						HumanID = @UserID

					-- MISE À JOUR DE LA TABLE Mo_User
					UPDATE dbo.Mo_User 
					SET
						LoginNameID		= @LoginNameID,
						PassWordID		= dbo.fn_Mo_Encrypt(@PassWordID),
						PassWordDate	= @dPasswordDate,
						PassWordEndDate	= @PassWordEndDate,
						TerminatedDate	= @TerminatedDate
					WHERE 
						UserID = @UserID
				END	
			RETURN @UserID
		END TRY
		BEGIN CATCH
			DECLARE	 @iErrno				INT,
					 @iErrSeverity			INT,
					 @iErrState				INT,
					 @vErrmsg				VARCHAR(1024)
			
			-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
			SELECT	
				@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
				@iErrState		= ERROR_STATE(),
				@iErrSeverity	= ERROR_SEVERITY(),
				@iErrno			= ERROR_NUMBER()
			
			-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
			SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg		

			-- SOULÈVE L'ERREUR
			RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState)

			RETURN -1
		END CATCH
	END
