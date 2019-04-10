
/****************************************************************************************************
Code de service		:		psGENE_EnregistraceTrace
Nom du service		:		psGENE_EnregistraceTrace
But					:		Insérer les données de suivi d'exécuttion dans Un_Trace
Facette				:		P171U
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description                                 Obligatoir
                        ----------                  ----------------                            --------------                       
						iConnectID					ID de connexion de l’usager
						iType						Type de trace (1 = recherche, 2 = rapport, 3 = rapport à ne pas supprimer)
						fDuration					Temps d’exécution de la procédure en millisecondes
						dtStart						Date et heure du début de l’exécution.
						dtEnd						Date et heure de la fin de l’exécution.
						vcDescription				Description de l’exécution (en texte)
						vcStoredProcedure			Nom de la procédure stockée
						vcExecutionString			Ligne d’exécution (inclus les paramètres)


Exemple d'appel:
				EXECUTE dbo.psGENE_EnregistrerTrace 2, 2, 1, '2010-05-05', '2010-05-06', 'Test JF', 'psGENE_EnregistrerTrace', 'psGENE_EnregistrerTrace'
				
Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-04-30					Jean-François Gauthier					Création de la procédure
                    	2010-05-06					Jean-François Gauthier					Ajout de la gestion des erreurs											
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_EnregistrerTrace]
	(
		@iConnectID			INT,
		@iType				INT,
		@fDuration			FLOAT,	
		@dtStart			DATETIME,
		@dtEnd				DATETIME,
		@vcDescription		VARCHAR(500),
		@vcStoredProcedure	VARCHAR(200),
		@vcExecutionString	VARCHAR(2000)
	)
AS
	BEGIN
		SET NOCOUNT ON
		SET XACT_ABORT ON
		
		BEGIN TRY
			INSERT INTO dbo.Un_Trace 
					(
					ConnectID, 
					iType, 
					fDuration,
					dtStart, 
					dtEnd, 
					vcDescription, 
					vcStoredProcedure,
					vcExecutionString 
					) 
			VALUES
					(
					@iConnectID,
					@iType,		
					@fDuration,	
					@dtStart,
					@dtEnd,	
					@vcDescription,
					@vcStoredProcedure,
					@vcExecutionString
					)
		END TRY
		BEGIN CATCH
			DECLARE		 
				@iErrSeverite	INT
				,@iErrStatut	INT
				,@vcErrMsg		NVARCHAR(1024)
				
			SELECT
				@vcErrMsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
				,@iErrStatut	= ERROR_STATE()
				,@iErrSeverite	= ERROR_SEVERITY()

			IF (XACT_STATE()) = -1 					-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
				AND @@TRANCOUNT > 0
				BEGIN
					--------------------
					ROLLBACK TRANSACTION
					--------------------
				END
				
			RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
		END CATCH
	END
