/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_FusionnerBeneficiaires
Nom du service		: Fusionner des bénéficiaires
But 				: Traiter les fusions de bénéficiaires pour l'IQÉÉ.  C'est à dire, mettre à jour les identifiants
					  dans les transactions et demander l'annulation/reprise des transactions si le NAS ou la date de 
					  naissance du bénéficiaire a changé suite à la fusion. 
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Beneficiaire_Supprime	Identifiant unique du bénéficiaire supprimé.
						iID_Beneficiaire_Conserve	Identifiant unique du bénéficiaire qui est conservé.
						iID_Utilisateur_Fusion		Identifiant unique de l'utilisateur qui fait la fusion des
													bénéficiaires.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_FusionnerBeneficiaires] 1, 2, 3

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					0 = Traitement terminé normalement
																					-1 = Erreur dans les paramètres
																					-2 = Erreur imprévue

Historique des modifications:
		Date			Programmeur							Description								
		------------	----------------------------------	-----------------------------------------
		2010-03-22		Éric Deshaies						Création du service	
		2014-09-26		Stéphane Barbeau					Activation de la mise a jour dans les tables des T03, T05 et T06.
															Désactivation de l'ajout d'annulation par raison de fusion.
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_FusionnerBeneficiaires]
(
	@iID_Beneficiaire_Supprime INT,
	@iID_Beneficiaire_Conserve INT,
	@iID_Utilisateur_Fusion INT
) 
AS
BEGIN
	-----------------
	-- Initialisation
	-----------------
	DECLARE @iID_Utilisateur_Systeme INT,
			@tiID_Type_Enregistrement TINYINT,
			@iID_Raison_Annulation INT,
			@iID_Type_Annulation INT,
			@bChangement BIT,
			@iID_Demande_IQEE INT,
			@dtDateDuJour DATETIME,
			@tiCode_Version TINYINT,
			@cStatut_Reponse CHAR(1),
			@vcCode_Message VARCHAR(10),
			@iID_Annulation INT

	-- Retourner -1 s'il y a des paramètres manquants ou invalides
	IF @iID_Beneficiaire_Supprime IS NULL OR @iID_Beneficiaire_Supprime = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM dbo.Mo_Human H
				  WHERE H.HumanID = @iID_Beneficiaire_Supprime) OR
	   @iID_Beneficiaire_Conserve IS NULL OR @iID_Beneficiaire_Conserve = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM dbo.Mo_Human H
				  WHERE H.HumanID = @iID_Beneficiaire_Conserve)
		RETURN -1

	-- Déterminer l'utilisateur système
	SELECT TOP 1 @iID_Utilisateur_Systeme = D.iID_Utilisateur_Systeme
	FROM Un_Def D

	-- Prendre l'utilisateur du système s'il est absent en paramètre
	IF @iID_Utilisateur_Fusion IS NULL OR @iID_Utilisateur_Fusion = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM Mo_User U
				  WHERE U.UserID = @iID_Utilisateur_Fusion)
		SET @iID_Utilisateur_Fusion = @iID_Utilisateur_Systeme

	SET @dtDateDuJour = GETDATE()

	SET XACT_ABORT ON

	BEGIN TRANSACTION

	BEGIN TRY
		------------------------------
		-- Déterminer si le NAS change
		------------------------------
		IF EXISTS(SELECT *
				  FROM dbo.Mo_Human H1, Mo_Human H2
				  WHERE H1.HumanID = @iID_Beneficiaire_Supprime
					AND H2.HumanID = @iID_Beneficiaire_Conserve
					AND (H1.SocialNumber <> H2.SocialNumber
						 OR H1.BirthDate <> H2.BirthDate))
			SET @bChangement = 1
		ELSE
			SET @bChangement = 0

		----------------------------------------------------------------------------------------------------------
		-- Mettre à jour les identifiants des transactions de demandes (02) et demander l'annulation si nécessaire
		----------------------------------------------------------------------------------------------------------

		-- 2014-09-26 SB: Desactivation de l'ajout d'annulation.  Laisser le travail a la stored proc psIQEE_DemanderAnnulations.
		/*
		-- Rechercher la raison d'annulation applicable
		--SELECT @iID_Type_Annulation=RA.iID_Type_Annulation,
		--	   @iID_Raison_Annulation=RA.iID_Raison_Annulation,
		--	   @tiID_Type_Enregistrement = RA.tiID_Type_Enregistrement
		--FROM [dbo].[fntIQEE_RechercherRaisonsAnnulation](NULL, NULL, 'FUSION_BENEFICIAIRE_02', NULL, NULL, NULL, NULL, NULL, NULL,
		--												 NULL) RA

		*/

		DECLARE curDemandes CURSOR LOCAL FAST_FORWARD FOR
			SELECT D.iID_Demande_IQEE  --,D.tiCode_Version,D.cStatut_Reponse
			FROM tblIQEE_Demandes D
				 JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
										AND F.bFichier_Test = 0
			WHERE D.iID_Beneficiaire_31Decembre = @iID_Beneficiaire_Supprime

		-- Boucler les demandes de l'ancien bénéficiaire
		OPEN curDemandes
		FETCH NEXT FROM curDemandes INTO @iID_Demande_IQEE  --, @tiCode_Version, @cStatut_Reponse
		WHILE @@FETCH_STATUS = 0
			BEGIN
				
				-- 2014-09-26 SB: Desactivation de l'ajout d'annulation.  Laisser le travail a la stored proc psIQEE_DemanderAnnulations.
				-- Si le NAS ou la date de naissance a changé, demander l'annulation de la demande
		--		IF @bChangement = 1 AND
		--		   @tiCode_Version IN (0,2) AND
		--		   @cStatut_Reponse IN ('A','R')
		--			EXECUTE [dbo].[psIQEE_AjouterDemandeAnnulation] @tiID_Type_Enregistrement, @iID_Demande_IQEE, NULL, NULL, NULL,
		--															@iID_Utilisateur_Systeme, @iID_Type_Annulation,
		--															@iID_Raison_Annulation, 
		--															NULL, @dtDateDuJour, @iID_Utilisateur_Fusion, NULL, @vcCode_Message OUTPUT,
		--															@iID_Annulation OUTPUT

				-- Mettre à jour l'identifiant
				UPDATE tblIQEE_Demandes
				SET iID_Beneficiaire_31Decembre = @iID_Beneficiaire_Conserve
				WHERE iID_Demande_IQEE = @iID_Demande_IQEE

				FETCH NEXT FROM curDemandes INTO @iID_Demande_IQEE  --, @tiCode_Version, @cStatut_Reponse
			END
		CLOSE curDemandes
		DEALLOCATE curDemandes

-- TODO: Faire la même chose pour les autres types de transaction
	-- Mettre a jour les T03: Declarations des Remplacements de beneficiaires

		UPDATE tblIQEE_RemplacementsBeneficiaire
		SET iID_Ancien_Beneficiaire = @iID_Beneficiaire_Conserve
		WHERE iID_Ancien_Beneficiaire = @iID_Beneficiaire_Supprime

		UPDATE tblIQEE_RemplacementsBeneficiaire
		SET iID_Nouveau_Beneficiaire = @iID_Beneficiaire_Conserve
		WHERE iID_Nouveau_Beneficiaire = @iID_Beneficiaire_Supprime

-- Annuler comme les demandes pour tout reprendre.  Les autres, juste MAJ des ID.
--		UPDATE tblIQEE_Transferts
--		SET iID_Beneficiaire = @iID_Beneficiaire_Conserve
--		WHERE iID_Beneficiaire = @iID_Beneficiaire_Supprime
--

-- Mettre a jour les T05: Declarations des PAE
		UPDATE tblIQEE_PaiementsBeneficiaires
		SET iID_Beneficiaire = @iID_Beneficiaire_Conserve
		WHERE iID_Beneficiaire = @iID_Beneficiaire_Supprime

-- Mettre a jour les T06: Declarations des Impots Speciaux
		UPDATE tblIQEE_ImpotsSpeciaux
		SET iID_Beneficiaire = @iID_Beneficiaire_Conserve
		WHERE iID_Beneficiaire = @iID_Beneficiaire_Supprime

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

	-- Retourner 0 en cas de réussite du traitement
	RETURN 0
END


