/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_AjouterChangementBeneficiaire
Nom du service		: Ajouter un changement de bénéficiaire
But 				: Ajouter un changement de bénéficiaire à l’historique des changements de bénéficiaire.
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Convention				Identifiant de la convention qui fait l’objet d’un changement de
													bénéficiaire.
						iID_Nouveau_Beneficiaire	Identifiant du nouveau bénéficiaire.
						vcCode_Raison				Code de la raison du changement de bénéficiaire.
						vcAutre_Raison_Changement_	Description de la raison du changement de bénéficiaire si la raison
							Beneficiaire			est autre.
						bLien_Frere_Soeur_Avec_Anc	Indicateur de lien frère/sœur entre l’ancien et le nouveau
							ien_Beneficiaire		bénéficiaire.
						bLien_Sang_Avec_Souscripte	Indicateur de lien de sang entre le nouveau bénéficiaire et le
							ur_Initial				souscripteur initial.
						tiID_Type_Relation_Souscri	Identifiant de la relation entre le souscripteur et le nouveau
							pteur_Nouveau_Benefici	bénéficiaire.
							aire
						tiID_Type_Relation_CoSousc	Identifiant de la relation entre le co-souscripteur et le nouveau
							ripteur_Nouveau_Benefi	bénéficiaire.
							ciaire
						iID_Utilisateur_Creation	Identifiant de l’utilisateur qui réalise le changement de bénéficiaire.
													S’il n’est pas spécifié, le service considère l’utilisateur système.

Exemple d’appel		:	exec [dbo].[psCONV_AjouterChangementBeneficiaire] 159756, 296133, 'INV', 'Accident le 25 janvier', 1, 1,
																		  1, 1, 2

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					> 0 = Identifiant du nouveau
																						  changement de bénéficiaire en
																						  cas de réussite du traitement
																						  (tblCONV_ChangementsBeneficiaire.
																						  iID_Changement_Beneficiaire)
																					-1 = Erreur dans les paramètres
																					-2 = Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-12-18		Éric Deshaies						Création du service							
		2010-03-02		Éric Deshaies						Correction erreur dans les validations des
															paramètres.

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_AjouterChangementBeneficiaire] 
(
	@iID_Convention INT,
	@iID_Nouveau_Beneficiaire INT,
	@vcCode_Raison VARCHAR(3),
	@vcAutre_Raison_Changement_Beneficiaire VARCHAR(150),
	@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire BIT,
	@bLien_Sang_Avec_Souscripteur_Initial BIT,
	@tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire TINYINT,
	@tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire TINYINT,
	@iID_Utilisateur_Creation INT
)
AS
BEGIN
	-- Rechercher la raison du changement de bénéficiaire
	DECLARE @tiID_Raison_Changement_Beneficiaire TINYINT,
			@bRequiere_Complement_Information BIT,
			@bSelectionnable_Utilisateur BIT

	SELECT @tiID_Raison_Changement_Beneficiaire = tiID_Raison_Changement_Beneficiaire,
		   @bRequiere_Complement_Information = bRequiere_Complement_Information,
		   @bSelectionnable_Utilisateur = bSelectionnable_Utilisateur
	FROM tblCONV_RaisonsChangementBeneficiaire
	WHERE vcCode_Raison = @vcCode_Raison

	-- Valider les paramètres
	IF @iID_Convention IS NULL OR
	   NOT EXISTS(SELECT * 
				  FROM dbo.Un_Convention 
				  WHERE ConventionID = @iID_Convention) OR
	   @iID_Nouveau_Beneficiaire IS NULL OR
	   NOT EXISTS(SELECT * 
				  FROM dbo.Un_Beneficiary 
				  WHERE BeneficiaryID = @iID_Nouveau_Beneficiaire) OR
	   @vcCode_Raison IS NULL OR
	   @tiID_Raison_Changement_Beneficiaire IS NULL OR
	   (@vcAutre_Raison_Changement_Beneficiaire IS NULL AND @bRequiere_Complement_Information = 1) OR
	   (@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire IS NULL AND @bSelectionnable_Utilisateur = 1) OR
	   (@bLien_Sang_Avec_Souscripteur_Initial IS NULL AND @bSelectionnable_Utilisateur = 1) OR
	   (@tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire IS NULL AND @bSelectionnable_Utilisateur = 1) OR
	   (@tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire IS NULL AND @bSelectionnable_Utilisateur = 1 AND
		EXISTS (SELECT *
				FROM dbo.Un_Convention 
				WHERE ConventionID = @iID_Convention
				  AND CoSubscriberID IS NOT NULL
				  AND CoSubscriberID > 0)) OR
		(@tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire IS NOT NULL AND
		NOT EXISTS(SELECT * 
				  FROM Un_RelationshipType
				  WHERE tiRelationshipTypeID  = @tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire)) OR
		(@tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire IS NOT NULL AND
		NOT EXISTS(SELECT * 
				  FROM Un_RelationshipType
				  WHERE tiRelationshipTypeID  = @tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire))
		RETURN -1

	-- Prendre l'utilisateur du système s'il est absent en paramètre
	IF @iID_Utilisateur_Creation IS NULL OR
		NOT EXISTS(SELECT * 
				  FROM Mo_User
				  WHERE UserID  = @iID_Utilisateur_Creation)
		SELECT TOP 1 @iID_Utilisateur_Creation = iID_Utilisateur_Systeme
		FROM Un_Def

	-- Considérer le changement à la date du jour ou à 1900-01-01 s'il s'agit du bénéficiaire initial
	DECLARE @iID_Changement_Beneficiaire INT,
			@dtDate_Changement_Beneficiaire DATETIME

	IF @vcCode_Raison = 'INI'
		SET @dtDate_Changement_Beneficiaire = 0
	ELSE
		SET @dtDate_Changement_Beneficiaire = GETDATE()
		
	SET XACT_ABORT ON 

	BEGIN TRANSACTION

	BEGIN TRY
		-- Créer le changement de bénéficiaire à l'historique
		INSERT INTO tblCONV_ChangementsBeneficiaire
				   ([iID_Convention]
				   ,[dtDate_Changement_Beneficiaire]
				   ,[iID_Nouveau_Beneficiaire]
				   ,[tiID_Raison_Changement_Beneficiaire]
				   ,[vcAutre_Raison_Changement_Beneficiaire]
				   ,[bLien_Frere_Soeur_Avec_Ancien_Beneficiaire]
				   ,[bLien_Sang_Avec_Souscripteur_Initial]
				   ,[tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire]
				   ,[tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire]
				   ,[iID_Utilisateur_Creation])
			 VALUES
				   (@iID_Convention
				   ,@dtDate_Changement_Beneficiaire
				   ,@iID_Nouveau_Beneficiaire
				   ,@tiID_Raison_Changement_Beneficiaire
				   ,@vcAutre_Raison_Changement_Beneficiaire
				   ,@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire
				   ,@bLien_Sang_Avec_Souscripteur_Initial
				   ,@tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire
				   ,@tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire
				   ,@iID_Utilisateur_Creation)

		SET @iID_Changement_Beneficiaire = SCOPE_IDENTITY()

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

		-- Retourner -2 en cas d'erreur de traitement
		RETURN -2
	END CATCH

	-- Retourner l'identifiant de la nouvelle série de paramètres
	RETURN @iID_Changement_Beneficiaire
END


