
/****************************************************************************************************
Code de service		:		psGENE_ModifierTitreNote
Nom du service		:		1.7.3	Modifier un titre de note (psGENE_ModifierTitreNote)
But					:		Modifier les informations d’un titre pré établi de note
Facette				:		SGRC 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_TitreNote				Identifiant du titre de note à modifier
						@vcTitreNote				Titre de la note

Exemple d'appel:
                
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2009-04-23					D.T.									Création
						2016-05-25                  Steeve Picard                           Standardisation des vieux RaisError
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ModifierTitreNote]
                                  (	
									@iID_TitreNote	INT,
									@vcTitreNote varchar(128)
                                  )
AS
BEGIN
	DECLARE
			@iErrno INT
			,@iErrSeverity INT
			,@iErrState INT
			,@vErrmsg nvarchar(1024)
	BEGIN TRY
		IF @iID_TitreNote IS NULL OR @vcTitreNote IS NULL
			BEGIN
			   SELECT @iErrno  = 50010,
					  @vErrmsg = 'ARG_MANQUANT:iID_TitreNote ou vcTitreNote'
			   RAISERROR (@vErrmsg, 10, 1)
			END

		UPDATE dbo.tblGENE_TitreNote
		SET vcTitreNote = @vcTitreNote
		WHERE iID_TitreNote = @iID_TitreNote

		RETURN 0
	END TRY
	BEGIN CATCH

		SELECT	@vErrmsg = ERROR_MESSAGE(),
				@iErrState = ERROR_STATE(),
				@iErrSeverity = ERROR_SEVERITY(),
				@iErrno = ERROR_NUMBER();

		IF @iErrno >= 50000
			RAISERROR (@vErrmsg, 10, 2)
		ELSE
			RAISERROR (@vErrmsg, -- Message text.
					   @iErrSeverity, -- Severity.
					   @iErrState -- State.
					  );


		RETURN 1
	END CATCH
END
