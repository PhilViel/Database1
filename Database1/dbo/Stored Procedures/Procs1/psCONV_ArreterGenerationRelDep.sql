
/****************************************************************************************************
Code de service		:		psCONV_ObtenirEvolutionRelDep
Nom du service		:		psCONV_ObtenirEvolutionRelDep
But					:		Permet d'arrêter la génération des données de relevé de dépôt
Facette				:		CONV 
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        N/A
						

Exemple d'appel:
				DECLARE @i INT
                EXECUTE @i = dbo.psCONV_ArreterGenerationRelDep 
				SELECT @i

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       N/A							@iStatut									= 1 si procédure exécutée avec succès
																								= -1 si erreur technique lors de l'exécution de la procédure						
																								= 0 exécution réussie, mais la job SQL n'était pas en fonction
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-04-26					Jean-Francois Gauthier					Création du service
						2010-04-27					Jean-François Gauthier					Ajout d'une vérification si 
																							la job SQL est bien en cours
																							de traitement
						2010-04-30					Jean-François Gauthier					Ajout de la suppression de la table tblCONV_TMPRelDep
						2010-05-25					Jean-François Gauthier					Ajout du paramètre signifiant si on vide la table temporaire ou non
 ****************************************************************************************************/
CREATE PROCEDURE dbo.psCONV_ArreterGenerationRelDep
								(
									@bVideTable BIT = 0		-- 2010-05-25 : JFG : Ajout
								)
AS
	BEGIN
		BEGIN TRY
			DECLARE 
					@iStatut	INT
					,@iJobID	UNIQUEIDENTIFIER
					
			DECLARE	@tJob	TABLE
								(
								iJobId                 UNIQUEIDENTIFIER NOT NULL,
	                            iLast_run_date         INT              NOT NULL,
	                            iLast_run_time         INT              NOT NULL,
	                            iNext_run_date         INT              NOT NULL,
	                            iNext_run_time         INT              NOT NULL,
	                            iNext_run_schedule_id  INT              NOT NULL,
	                            iRequested_to_run      INT              NOT NULL, 
	                            iRequest_source        INT              NOT NULL,
	                            sRequest_source_id     sysname          COLLATE database_default NULL,
	                            iRunning               INT              NOT NULL, 
	                            iCurrent_step          INT              NOT NULL,
	                            iCurrent_retry_attempt INT              NOT NULL,
	                            iJobStatut             INT              NOT NULL
	                            )
	                            
			SELECT 
				@iJobID = job_id 
			FROM 
				msdb..sysjobs_view 
			WHERE 
				[name] = 'runDTSXcalculRelevDepot' 
				
			INSERT INTO @tJob
		    EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, 'dbo', @iJobID

			IF EXISTS(SELECT 1 FROM @tJob t WHERE t.iJobStatut = 1)
				BEGIN 
					EXECUTE msdb.dbo.sp_stop_job @job_name =N'runDTSXcalculRelevDepot'
					SET @iStatut = 1
				END
			ELSE
				BEGIN
					SET @iStatut = 0
				END
			--2010-04-30 : JFG : On vide la table
			IF @bVideTable = 1		--2010-05-25 : JFG : Ajout
				BEGIN
					DELETE FROM dbo.tblCONV_TMPRelDep
				END
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
				,@iStatut		= -1
				
			RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
		END CATCH
		
		RETURN @iStatut
	END
