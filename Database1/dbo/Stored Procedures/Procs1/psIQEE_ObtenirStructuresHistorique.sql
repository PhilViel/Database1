/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirStructuresHistorique
Nom du service		: Obtenir les structures de l'historique
But 				: Obtenir les structures de l'historique IQÉÉ selon le droit et la langue de l’utilisateur.
Facette				: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						iID_Utilisateur				Identifiant unique de l'utilisateur qui utilise l'historique de
													l'IQÉÉ.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirStructuresHistorique] 'FRA', 519626

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_HistoStructures ».  Les structures de l'historique sont
						triés en ordre de type et d'ordre de présentation.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-10-06		Éric Deshaies						Création du service	

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirStructuresHistorique] 
(
	@cID_Langue CHAR(3),
	@iID_Utilisateur INT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	BEGIN TRY
		-- Considérer le français comme la langue par défaut
		IF @cID_Langue IS NULL
			SET @cID_Langue = 'FRA'

		-- Retourner les structures d'historique
		SELECT S.iID_Structure_Historique,
			   S.cType_Structure,
			   S.vcCode_Structure,
			   ISNULL(T1.vcTraduction,S.vcDescription) AS vcDescription,
			   S.vcCode_Droit
		FROM tblIQEE_HistoStructures S
			 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_HistoStructures'
											 AND T1.vcNom_Champ = 'vcDescription'
											 AND T1.iID_Enregistrement = S.iID_Structure_Historique
											 AND T1.vcID_Langue = @cID_Langue
		WHERE S.vcCode_Droit IS NULL
		   OR [dbo].[fnSECU_ObtenirAccessibiliteDroitUtilisateur](CAST(ISNULL(@iID_Utilisateur,0) AS VARCHAR(255)),S.vcCode_Droit) = 1
		ORDER BY S.cType_Structure,S.iOrdre_Presentation
	END TRY
	BEGIN CATCH
		-- Lever l'erreur et faire le rollback
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT

		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorState = ERROR_STATE()

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

		-- Retourner -1 en cas d'erreur de traitement
		RETURN -1
	END CATCH

	-- Retourner 1 en cas de réussite du traitement
	RETURN 1
END

