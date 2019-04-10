/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_SupprimerCeduleJob
Nom du service		: Supprimer une cédule d’une job  
But 				: Supprimer une cédule d’exécution unitaire d’une job SQL.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcNom_Job					Nom de la job SQL.  Le paramètre est requis.
						iID_Cedule					Identifiant unique de la cédule à supprimer.  Le paramètre est
													requis.

Exemple d’appel		:	exec [dbo].[psGENE_SupprimerCeduleJob] 'joIQEE_CreerFichiers', 41

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					0 = La job est correctement
																						décédulée
																					-1 = Les paramètres ne sont pas
																						 valides
																					-2 = Erreur dans le traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-04-20		Éric Deshaies						Création du service							

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_SupprimerCeduleJob] 
(
	@vcNom_Job VARCHAR(128),
	@iID_Cedule INT
)
AS
BEGIN
	-- Retourner -1 s'il y a des paramètres invalides
	IF @vcNom_Job IS NULL OR @vcNom_Job = '' OR
	   @iID_Cedule IS NULL OR @iID_Cedule = 0 OR
	   NOT EXISTS(SELECT *
				  FROM [dbo].fntGENE_ObtenirCedulesJob(@vcNom_Job)
				  WHERE iID_Cedule = @iID_Cedule)
		RETURN -1

	BEGIN TRANSACTION

	BEGIN TRY
		-- Décéduler la job
		DECLARE @iCode_Retour INT

		EXECUTE @iCode_Retour = msdb.dbo.sp_delete_schedule @schedule_id=@iID_Cedule, @force_delete=1
		IF @iCode_Retour = 1
			SET @iCode_Retour = -2 

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- Retourner -2 en cas d'erreur de traitement
		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION
		RETURN -2
	END CATCH

	-- Retourner 0 en cas de réussite du traitement
	RETURN @iCode_Retour
END

