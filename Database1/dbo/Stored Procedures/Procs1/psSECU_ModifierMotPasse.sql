/****************************************************************************************************
Code de service		:		psSECU_ModifierMotPasse
Nom du service		:		Modification d'un mot de passe utilisateur
But					:		Modification d'un mot de passe utilisateur
Facette				:		SECU
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@vcLoginNameID				Compte utilisateur à modifier
						@PasswordID					Nouveau mot de passe à attribuer au compte utilisateur

Exemple d'appel:
                -- EXECUTE psSECU_ModifierMotPasse 'jfgauthier','p@ssw@rd'

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-05-11					Jean-François Gauthier					Création de procédure stockée 
                        2009-06-19					Jean-François Gauthier					Commentaire
                        2016-05-26                  Steeve Picard                           Conversion du RaisError standard
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psSECU_ModifierMotPasse]
							(
							@vcLoginNameID NVARCHAR(50),
							@PasswordID MoLoginName
							)
AS
	BEGIN
		SET NOCOUNT ON
		DECLARE @vcSQL				VARCHAR(100),
				@iErrno				INT,
				@iErrSeverity		INT,
				@iErrState			INT,
				@vErrmsg			VARCHAR(1024)

		BEGIN TRY
			SET @PasswordID = dbo.fn_Mo_Encrypt(@PasswordID)		-- MOT DE PASSE DÉSIRÉ (CASE SENSITIVE) 
	
			UPDATE dbo.Mo_User 
			SET 
				PasswordID	= @PasswordID 
			WHERE 
				LoginNameID = @vcLoginNameID						-- NOM D'USAGER À MODIFIER
	
			SET @vcSQL= 'ALTER LOGIN [' + @vcLoginNameID + '] WITH PASSWORD = ' + CHAR(39) + @PasswordID + CHAR(39)
			EXECUTE (@vcSQL)
			RETURN 1
		END TRY
		BEGIN CATCH
			SELECT										-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
				@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
				@iErrState		= ERROR_STATE(),
				@iErrSeverity	= ERROR_SEVERITY(),
				@iErrno			= ERROR_NUMBER();

			SET @vErrmsg = 'ERREUR CRITIQUE : MODIFICATION IMPOSSIBLE : ' + CAST(@iErrno AS VARCHAR(6)) + ' ' + @vErrmsg
			RAISERROR (@vErrmsg, 10, 1)
			RETURN 0
		END CATCH
	END
