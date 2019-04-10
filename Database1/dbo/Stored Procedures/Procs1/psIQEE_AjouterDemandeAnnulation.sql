/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_AjouterDemandeAnnulation
Nom du service		: Ajouter une demande d'annulation
But 				: Permet d'ajouter une demande d'annulation sur une transaction de l'IQÉÉ.  Cela permet à
					  l'utilisateur de demander manuellement l'annulation d'une transaction.  Lors de la création d'un
					  fichier de transactions, elle permet également d'ajouter des demandes d'annulation pour les raisons
					  d'annulation qui sont déterminées automatiquement.
Facette				: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						tiID_Type_Enregistrement	Identifiant unique du type d'enregistrement sur lequel a lieu
													l'annulation.
						iID_Enregistrement_Demande_	Identifiant unique de l'enregistrement sur lequel a lieu la demande
							Annulation				d'annulation.
						iID_Session					Identifiant de la session à l'origine de la création du fichier qui
													est à l'origine de la demande automatique d'annulation.  S'applique
													uniquement aux annulations automatiques.
						dtDate_Creation_Fichiers	Date de la création du fichier qui est à l'origine de la demande
													automatique d'annulation.  S'applique uniquement aux annulations
													automatiques.
						vcCode_Simulation			Code de simulation de la création des fichiers qui est à l'origine
													de la demande automatique d'annulation.  S'applique uniquement aux
													annulations automatiques.
						iID_Utilisateur_Demande		Identifiant de l'utilisateur à l'origine de la création de la demande
													d'annulation.
						iID_Type_Annulation			Identifiant unique du type d'annulation.  Il fait référence à la
													table de référence "tblIQEE_TypesAnnulation".  S'il n'est pas spécifié,
													le type d'annulation "Manuelle" est considéré.
						iID_Raison_Annulation		Identifiant unique de la raison d'annulation.  Fait référence à la
													table de référence "tblIQEE_RaisonsAnnulation".
						tCommentaires				Commentaires de la demande d'annulation.  S'applique normalement
													uniquement pour les demandes d'annulation manuelles.
						dtDate_Action_Menant_		Date/heure de l'action principale ayant menée à la demande
							Annulation				d'annulation.
						iID_Utilisateur_Action_		Identifiant de l'utilisateur de l'action principale ayant menée à
							Menant_Annulation		la demande d'annulation.
						iID_Suivi_Modification		Identifiant unique du suivi de modification à l'origine de l'action
													principale ayant menée à la demande d'annulation.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_AjouterDemandeAnnulation] 1, 338446, NULL, NULL, NULL, 519626, 1, 1, 
																		 'Test d''Éric Deshaies', NULL, NULL, NULL,
																		 @vcCode_Message OUTPUT, @iID_Annulation OUTPUT

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					1 = Traitement réussi
																					0 = Traitement en erreur prévisible
																					-1 = Traitement en erreur non
																						 prévisible
						S/O							vcCode_Message					Code de message pour l'interface
						S/O							iID_Annulation					Identifiant de la nouvelle demande
																					d'annulation

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-09-15		Éric Deshaies						Création du service							
		2009-11-05		Éric Deshaies						Mise à niveau selon les normes de développement
		2010-09-10		Éric Deshaies						Renommer et réorganiser le service.  
															Séparation de la suppression d'une demande.
		2011-04-28		Éric Deshaies						Corriger un bug quand le paramètre
															"iID_Type_Annulation" était absent.

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_AjouterDemandeAnnulation] 
(
	@tiID_Type_Enregistrement TINYINT,
	@iID_Enregistrement_Demande_Annulation INT,
	@iID_Session INT,
	@dtDate_Creation_Fichiers DATETIME,
	@vcCode_Simulation VARCHAR(100),
	@iID_Utilisateur_Demande INT,
	@iID_Type_Annulation INT,
	@iID_Raison_Annulation INT,
	@tCommentaires TEXT,
	@dtDate_Action_Menant_Annulation DATETIME,
	@iID_Utilisateur_Action_Menant_Annulation INT,
	@iID_Suivi_Modification INT,
	@vcCode_Message VARCHAR(10) OUTPUT,
	@iID_Annulation INT OUTPUT
)
AS
BEGIN
	SET XACT_ABORT ON 
	
	BEGIN TRANSACTION

	BEGIN TRY
		-- Initialisation
		DECLARE @iID_Statut_Annulation INT

		SET @vcCode_Message = NULL
		SET @iID_Annulation = NULL
		
		-- Par défaut c'est une demande de type manuelle
		IF @iID_Type_Annulation IS NULL
			SELECT @iID_Type_Annulation = TA.iID_Type_Annulation
			FROM tblIQEE_TypesAnnulation TA
		    WHERE TA.vcCode_Type = 'MAN'

		-- Annuler l'ajout si la demande d'annulation existe déjà
		IF EXISTS(SELECT *
				  FROM tblIQEE_Annulations A
					   -- Demande d'annulation manuelle
					   JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
													    AND SA.vcCode_Statut = 'MAN'
				  -- 4 conditions suivantes permettent de déterminer si c'est exactement la même demande d'annulation
				  WHERE A.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
				    AND A.iID_Enregistrement_Demande_Annulation = @iID_Enregistrement_Demande_Annulation
				    AND A.iID_Type_Annulation = @iID_Type_Annulation
				    AND A.iID_Raison_Annulation = @iID_Raison_Annulation)
			BEGIN
				ROLLBACK TRANSACTION				
				SET @vcCode_Message = 'IQEEE0026'
				RETURN 0
			END

		-- Si la demande d'annulation n'existe pas déjà, créer la nouvelle demande d'annulation
		-- Déterminer le statut de la demande d'annulation
		IF EXISTS (SELECT *
				   FROM tblIQEE_TypesAnnulation TA
				   WHERE TA.iID_Type_Annulation = @iID_Type_Annulation
					 AND TA.vcCode_Type = 'MAN')
			SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
			FROM tblIQEE_StatutsAnnulation SA
			WHERE SA.vcCode_Statut = 'MAN'
		ELSE
			SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
			FROM tblIQEE_StatutsAnnulation SA
			WHERE SA.vcCode_Statut = 'ASS'

		-- Créer la nouvelle demande d'annulation
		INSERT INTO [dbo].[tblIQEE_Annulations]
				   ([tiID_Type_Enregistrement]
				   ,[iID_Enregistrement_Demande_Annulation]
				   ,[iID_Session]
				   ,[dtDate_Creation_Fichiers]
				   ,[vcCode_Simulation]
				   ,[dtDate_Demande_Annulation]
				   ,[iID_Utilisateur_Demande]
				   ,[iID_Type_Annulation]
				   ,[iID_Raison_Annulation]
				   ,[tCommentaires]
				   ,[dtDate_Action_Menant_Annulation]
				   ,[iID_Utilisateur_Action_Menant_Annulation]
				   ,[iID_Suivi_Modification]
				   ,[iID_Statut_Annulation])
			 VALUES
				   (@tiID_Type_Enregistrement
				   ,@iID_Enregistrement_Demande_Annulation
				   ,@iID_Session
				   ,@dtDate_Creation_Fichiers
				   ,@vcCode_Simulation
				   ,GETDATE()
				   ,@iID_Utilisateur_Demande
				   ,@iID_Type_Annulation
				   ,@iID_Raison_Annulation
				   ,@tCommentaires
				   ,@dtDate_Action_Menant_Annulation
				   ,@iID_Utilisateur_Action_Menant_Annulation
				   ,@iID_Suivi_Modification
				   ,@iID_Statut_Annulation)

		SET @iID_Annulation = SCOPE_IDENTITY()

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- Lever l'erreur et faire le rollback
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT

		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorState = ERROR_STATE()

		IF (XACT_STATE()) = -1 AND @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

		-- Retourner -1 en cas d'erreur non prévisible de traitement
		RETURN -1
	END CATCH

	-- Retourner 1 lors de la réussite du traitement
	RETURN 1
END




