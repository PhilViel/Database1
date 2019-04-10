/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_AjouterParametres
Nom du service		: Ajouter des paramètres
But 				: Ajouter une nouvelle série de paramètres de l’IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				siAnnee_Fiscale				L’année fiscale de la nouvelle série de paramètres.  Le paramètre
													est obligatoire.
						iID_Utilisateur_Creation	Identifiant de l’utilisateur qui demande la création de la
													nouvelle série de paramètres.  S’il n’est pas spécifié, le service
													considère l’utilisateur système.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_AjouterParametres] 2008, 546658

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					> 0 = Identifiant de la nouvelle
																						  série de paramètres
																					-1 = Absence du paramètre
																						 « siAnnee_Fiscale »
																					-2 = Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-05-30		Éric Deshaies						Création du service							
		2009-03-24		Éric Deshaies						Utiliser "fntIQEE_RechercherParametres"
															au lieu de "fnIQEE_RechercherParametres"
		2009-07-21		Éric Deshaies						Correction ROLLBACK
		2009-08-05		Jean-François Gauthier				Modification car dans le cas où aucun paramètre 
															n'est en vigueur, la procédure n'était pas en mesure
															d'en ajouter. Maintenant, elle fera un ajout en fonction
															du paramètre non en vigueur le plus récent.
															N.B.
															Cette procédure ne fonctionnera pas dans le cas
															où la table tblIQEE_Parametre sera entièrement vide
		2009-11-05		Éric Deshaies						Mise à niveau selon les normes de développement.
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_AjouterParametres] 
(
	@siAnnee_Fiscale SMALLINT,
	@iID_Utilisateur_Creation INT
)
AS
BEGIN
	-- Retourner -1 si l'année fiscale est absente
	IF @siAnnee_Fiscale IS NULL OR @siAnnee_Fiscale = 0
		RETURN -1

	-- Prendre l'utilisateur du système s'il est absent en paramètre
	IF @iID_Utilisateur_Creation IS NULL OR @iID_Utilisateur_Creation = 0 OR
		NOT EXISTS (SELECT *
					FROM Mo_User U
					WHERE U.UserID = @iID_Utilisateur_Creation)
		SELECT TOP 1 @iID_Utilisateur_Creation = iID_Utilisateur_Systeme
		FROM dbo.Un_Def

	DECLARE
		@iID_Parametres_IQEE INT,
		@dtDateHeureCourante DATETIME

	SET XACT_ABORT ON 

	BEGIN TRANSACTION

	BEGIN TRY
		-- Rechercher les paramètres en vigueur à la même année fiscale qu'en paramètre
		SELECT @iID_Parametres_IQEE = iID_Parametres_IQEE
		FROM [dbo].[fntIQEE_RechercherParametres](@siAnnee_Fiscale, 1)

		SET @dtDateHeureCourante = GETDATE()

		-- S'il y a des paramètres en vigueur pour la même année fiscale qu'en paramètre
		IF @iID_Parametres_IQEE IS NOT NULL AND @iID_Parametres_IQEE <> 0
			BEGIN
				-- Mettre à jour la date de fin de la série précédente
				UPDATE dbo.tblIQEE_Parametres
				SET dtDate_Fin_Application = @dtDateHeureCourante
				WHERE iID_Parametres_IQEE = @iID_Parametres_IQEE

				-- Déterminer la date de début de la nouvelle série
				SET @dtDateHeureCourante = DATEADD(millisecond,2,@dtDateHeureCourante)

				-- Créer la nouvelle série de paramètres
				INSERT INTO dbo.tblIQEE_Parametres
					(
					siAnnee_Fiscale,
					dtDate_Debut_Application,
					dtDate_Debut_Cotisation,
					dtDate_Fin_Cotisation,
					siNb_Jour_Limite_Demande,
					tiNb_Maximum_Annee_Fiscale_Anterieur,
					iID_Utilisateur_Creation		
					)
				SELECT P.siAnnee_Fiscale,
					   @dtDateHeureCourante,
					   P.dtDate_Debut_Cotisation,
					   P.dtDate_Fin_Cotisation,
					   P.siNb_Jour_Limite_Demande,
					   P.tiNb_Maximum_Annee_Fiscale_Anterieur,
					   @iID_Utilisateur_Creation
				FROM 
					dbo.tblIQEE_Parametres P
				WHERE 
					P.iID_Parametres_IQEE = @iID_Parametres_IQEE
			END
		ELSE
		-- S'il n'y a pas des paramètres en vigueur pour la même année fiscale qu'en paramètre
			BEGIN
				-- Rechercher les derniers paramètres en vigueur
				SELECT TOP 1 @iID_Parametres_IQEE = iID_Parametres_IQEE
				FROM [dbo].[fntIQEE_RechercherParametres](NULL, 1)

				-- Rechercher les derniers paramètres non en vigueur s'il n'y en pas en vigueur
				IF @iID_Parametres_IQEE IS NULL 
					BEGIN
						SELECT TOP 1 @iID_Parametres_IQEE = iID_Parametres_IQEE
						FROM [dbo].[fntIQEE_RechercherParametres](NULL, 0)
						ORDER BY iID_Parametres_IQEE DESC
					END

				-- Créer la nouvelle série de paramètres
				INSERT INTO dbo.tblIQEE_Parametres
					(
					siAnnee_Fiscale,
					dtDate_Debut_Application,
					dtDate_Debut_Cotisation,
					dtDate_Fin_Cotisation,
					siNb_Jour_Limite_Demande,
					tiNb_Maximum_Annee_Fiscale_Anterieur,
					iID_Utilisateur_Creation		
					)
				SELECT @siAnnee_Fiscale,
					   @dtDateHeureCourante,
					   DATEADD(YEAR, @siAnnee_Fiscale-YEAR(P.dtDate_Debut_Cotisation), P.dtDate_Debut_Cotisation),
					   DATEADD(YEAR, @siAnnee_Fiscale-YEAR(P.dtDate_Fin_Cotisation), P.dtDate_Fin_Cotisation),
					   P.siNb_Jour_Limite_Demande,
					   P.tiNb_Maximum_Annee_Fiscale_Anterieur,
					   @iID_Utilisateur_Creation
				FROM 
					dbo.tblIQEE_Parametres P
				WHERE 
					P.iID_Parametres_IQEE = @iID_Parametres_IQEE
			END

		SET @iID_Parametres_IQEE = SCOPE_IDENTITY()

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
	RETURN @iID_Parametres_IQEE
END
