/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_CedulerJob
Nom du service		: Céduler une job 
But 				: Céduler la prochaine exécution unitaire d’une job SQL.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcNom_Job					Nom de la job SQL.  Le paramètre est requis.
						vcNom_Cedule				Nom de la nouvelle cédule de la job.  Le paramètre est requis.
						dtDate_Prochaine_Execution	Date et heure de la prochaine exécution de la job.  Le paramètre
													est requis et il doit être plus grand que la date/heure courante.

Exemple d’appel		:	exec [dbo].[psGENE_CedulerJob] 'joIQEE_CreerFichiers',
													   'Production, 2007-2009, U-20080101001, Éric Deshaies',
													   '2009-04-20 13:20:00.000'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					0 = La job est correctement cédulée
																					-1 = Les paramètres ne sont pas
																						 valides
																					-2 = Erreur dans le traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-04-20		Éric Deshaies						Création du service							

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_CedulerJob] 
(
	@vcNom_Job VARCHAR(128),
	@vcNom_Cedule VARCHAR(128),
	@dtDate_Prochaine_Execution DATETIME
)
AS
BEGIN
	-- Retourner -1 s'il y a des paramètres invalides
	IF @vcNom_Job IS NULL OR
	   NOT EXISTS(SELECT *
				  FROM msdb.dbo.sysjobs_view V
				  WHERE V.Name = @vcNom_Job) OR
	   @vcNom_Cedule IS NULL OR @vcNom_Cedule = '' OR 
	   @dtDate_Prochaine_Execution IS NULL OR
	   @dtDate_Prochaine_Execution < GETDATE()
		RETURN -1

	BEGIN TRANSACTION

	BEGIN TRY
		-- Céduler la job
		DECLARE @bnID_Job BINARY(16),
				@iCode_Retour INT,
				@iDate INT,
				@iHeure INT,
				@vcTMP VARCHAR(20)

		SELECT @bnID_Job = Job_ID
		FROM msdb.dbo.sysjobs_view V
		WHERE V.Name = @vcNom_Job

		SET @vcTMP = CONVERT(VARCHAR(20),@dtDate_Prochaine_Execution,120)
		SET @iDate = CAST(REPLACE(SUBSTRING(@vcTMP,1,10),'-','') AS INT)
		SET @iHeure = CAST(REPLACE(SUBSTRING(@vcTMP,12,8),':','') AS INT)

		EXEC @iCode_Retour = msdb.dbo.sp_add_jobschedule @job_id=@bnID_Job, @name=@vcNom_Cedule, 
				@enabled=1, 
				@freq_type=1, 
				@freq_interval=0, 
				@freq_subday_type=0, 
				@freq_subday_interval=0, 
				@freq_relative_interval=0, 
				@freq_recurrence_factor=0, 
				@active_start_date=@iDate, 
				@active_end_date=99991231, 
				@active_start_time=@iHeure, 
				@active_end_time=235959

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- Retourner -2 en cas d'erreur de traitement
		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION
		RETURN -2
	END CATCH

	-- Retourner 0 en cas de réussite du traitement
	RETURN 0
END

