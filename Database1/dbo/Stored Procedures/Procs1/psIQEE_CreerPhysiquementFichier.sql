/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_CreerPhysiquementFichier
Nom du service		: Créer physiquement un fichier 
But 				: Créer physiquement sur un disque un fichier physique de transactions de l’IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Fichier_IQEE			Identifiant unique de l'un des fichiers logiques d'un fichier
													physique à créer physiquement sur le disque.
						vcChemin_Fichier			Chemin de destination du fichier.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_CreerPhysiquementFichier] 34, '\\gestas2\departements\IQEE\Fichiers\Transmis\'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					0 = Fichier crée
																					< 0 Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description								
		------------	----------------------------------	-----------------------------------------
		2009-02-11		Éric Deshaies						Création du service	
		2009-11-05		Éric Deshaies						Mise à niveau selon les normes de développement.
		2010-02-19		Éric Deshaies						Traiter la notion de fichier logique/physique
        2015-12-21      Steeve Picard                       Élargissement de la variable @vcLigneCommande pour les requêtes plus longues
		2016-04-08		Steeve Picard						Diversification des IDs d'erreur pour qu'ils ne soient pas juste des -1
        2018-01-23		Steeve Picard						Créer le répertoire s'il n'existe pas
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerPhysiquementFichier
(
	@iID_Fichier_IQEE INT,
	@vcChemin_Fichier VARCHAR(150)
)
AS
BEGIN
	BEGIN TRY
		-- Valider les paramètres
		DECLARE @bFichierPhysiqueCree INT = -1,
				@vcNomFichierComplet VARCHAR(200),
				@vcNom_Fichier VARCHAR(50)

		IF @iID_Fichier_IQEE IS NULL OR
		   NOT EXISTS (SELECT * FROM tblIQEE_Fichiers F WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE) OR
		   @vcChemin_Fichier IS NULL OR
		   @vcChemin_Fichier = ''
			RETURN -2
		
		-- Présumer que la création sera un échec
		SET @bFichierPhysiqueCree = -1

		-- Compléter le chemin de destination du fichier par le caractère « \ » 
		IF Right(@vcChemin_Fichier,1) <> '\'
			SET @vcChemin_Fichier = @vcChemin_Fichier + '\'

		-- Déterminer le nom complet du fichier
		SELECT @vcNomFichierComplet = @vcChemin_Fichier + F.vcNom_Fichier,
			   @vcNom_Fichier = F.vcNom_Fichier
		FROM tblIQEE_Fichiers F
		WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE

		BEGIN TRY
			------------------------------------------------------------------------
			-- Sauvegarder le fichier physiquement dans le répertoire de destination
			------------------------------------------------------------------------
			DECLARE @vcLigneCommande VARCHAR(max),  -- était 300 avant
					@iResultat INT

			-- Rechercher tous les fichiers logiques du fichier physique
			DECLARE curFichiers_Logiques CURSOR LOCAL FAST_FORWARD FOR
				SELECT F.iID_Fichier_IQEE
				FROM tblIQEE_Fichiers F
				WHERE F.vcNom_Fichier = @vcNom_Fichier

			-- Boucler les fichiers logiques
			SET @vcLigneCommande = '('
			OPEN curFichiers_Logiques
			FETCH NEXT FROM curFichiers_Logiques INTO @iID_Fichier_IQEE
			WHILE @@FETCH_STATUS = 0
				BEGIN
					-- Construire une sélection des fichiers logiques pour la requête
					-- Note: c'est fait comme ça parce que l'interface doit permettre à l'utilisateur de sélectionner n'importe quel
					--       fichier logique même si les lignes du fichier sont associées à un seul fichier logique.
					IF @vcLigneCommande = '('
						SET @vcLigneCommande = @vcLigneCommande + CAST(@iID_Fichier_IQEE AS VARCHAR)
					ELSE
						SET @vcLigneCommande = @vcLigneCommande + ','+CAST(@iID_Fichier_IQEE AS VARCHAR)

					FETCH NEXT FROM curFichiers_Logiques INTO @iID_Fichier_IQEE
				END
			CLOSE curFichiers_Logiques
			DEALLOCATE curFichiers_Logiques
			SET @vcLigneCommande = @vcLigneCommande + ')'

			SET @vcLigneCommande = 'SELECT cLigne FROM '+DB_NAME()+'.dbo.tblIQEE_LignesFichier WHERE iID_Fichier_IQEE IN ' +
								   @vcLigneCommande+' ORDER BY iSequence'

			-- Vérifier si le répertoire existe
			EXECUTE @iResultat = dbo.psGENE_FichierRepertoireExiste @vcChemin_Fichier, NULL
            IF @iResultat = 1
            BEGIN
    			-- Créer le répertoire
                DECLARE @vcCmdLine VARCHAR(1000) = 'Exec Master..xp_Cmdshell ''MkDir '+@vcChemin_Fichier+''''
                EXEC (@vcCmdLine)                 
            END 

			-- Sauvegarder le fichier
			EXECUTE dbo.psGENE_EcrireFichierTexteAPartirRequeteSQL @vcNomFichierComplet,@vcLigneCommande,@@servername,1,NULL,1,1,0

			-- S'assurer que le fichier existe
			EXECUTE @iResultat = dbo.psGENE_FichierRepertoireExiste @vcChemin_Fichier, @vcNom_Fichier
			IF @iResultat = 3
				SET @bFichierPhysiqueCree = 0
            ELSE 
				PRINT 'psGENE_FichierRepertoireExiste : ' + str(@iResultat)

		END TRY
		BEGIN CATCH
		END CATCH
	END TRY
	BEGIN CATCH
		-- Lever l'erreur
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT

		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorState = ERROR_STATE()

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

		-- Retourner -1 en cas d'erreur de traitement
		RETURN -3
	END CATCH

	-- Retourner le code de réussite ou d'échec
	RETURN @bFichierPhysiqueCree
END
