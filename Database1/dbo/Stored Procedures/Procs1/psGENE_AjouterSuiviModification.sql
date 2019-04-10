/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_AjouterSuiviModification
Nom du service		: Ajouter un suivi de modifications
But 				: Ajouter un suivi de modifications suite à l'exécution d'un déclencheur de modification d'un
					  enregistrement
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iCode_Table					Code arbitraire et unique de la table qui fait l'objet de la
													modification d'un enregistrement. Ce code peut être codé en dur
													dans la programmation.  1-Un_Oper, 2-Un_Cotisation, 
													3-Un_ConventionOper, 4-Un_TIN, 5-Un_OUT, 6-Un_CESP, 7-Mo_Human,
													8-Un_ExternalPromo
						iID_Nouveau_Enregistrement	Identifiant unique du nouvel enregistrement ou de l'enregistrement
													modifié.  Indique l'enregistrement inséré ou modifié.
						iID_Ancien_Enregistrement	Identifiant unique de l'ancien enregistrement ou l'enregistrement
													modifié.  S'il est présent, c'est une modification d'un
													enregistrement et s'il est absent, c'est une insertion d'un
													enregistrement.

Exemple d’appel		:	EXECUTE [dbo].[psGENE_AjouterSuiviModification] 1, 18455724

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					> 0 = Identifiant du nouveau suivi

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-09-04		Éric Deshaies						Création du service							

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_AjouterSuiviModification] 
(
	@iCode_Table INT,
	@iID_Nouveau_Enregistrement INT,
	@iID_Ancien_Enregistrement INT
)
AS
BEGIN
	DECLARE
		@iID_Suivi_Modification INT,
		@iID_Utilisateur_Modification INT,
		@vcNom_Utilisateur VARCHAR(85),
		@iID_Action INT

	BEGIN TRANSACTION

	BEGIN TRY
		-- Déterminer l'utilisateur qui a fait la modification.  S'il n'est pas possible de l'identifié, on utilise
		-- l'utilisateur du système UniAccès
		SET @vcNom_Utilisateur = SUSER_SNAME()
		SET @vcNom_Utilisateur = SUBSTRING(@vcNom_Utilisateur,CHARINDEX('\',@vcNom_Utilisateur)+1,85)

		SELECT @iID_Utilisateur_Modification = U.UserID
		FROM dbo.Mo_User U
		WHERE U.LoginNameID = @vcNom_Utilisateur

		IF @iID_Utilisateur_Modification IS NULL
			SELECT @iID_Utilisateur_Modification = P.iID_Utilisateur_Systeme
			FROM dbo.Un_Def P

		-- Déternimer l'identifiant de l'action
		IF @iID_Ancien_Enregistrement IS NULL
			SELECT @iID_Action = LA.LogActionID
			FROM CRQ_LogAction LA
			WHERE LA.LogActionShortName = 'I'
		ELSE
			SELECT @iID_Action = LA.LogActionID
			FROM CRQ_LogAction LA
			WHERE LA.LogActionShortName = 'U'

		-- Insérer la modification dans le suivi des modifications
		INSERT INTO [dbo].[tblGENE_SuiviModifications]
				   ([iCode_Table]
				   ,[iID_Enregistrement]
				   ,[iID_Action]
				   ,[dtDate_Modification]
				   ,[iID_Utilisateur_Modification])
			 VALUES
				   (@iCode_Table
				   ,@iID_Nouveau_Enregistrement
				   ,@iID_Action
				   ,GETDATE()
				   ,@iID_Utilisateur_Modification)

		SET @iID_Suivi_Modification = SCOPE_IDENTITY()

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT

		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorState = ERROR_STATE()

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	END CATCH

	-- Retourner l'identifiant du nouveau suivi de modifications
	RETURN @iID_Suivi_Modification
END




