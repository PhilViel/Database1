/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_AjouterLigneFichier
Nom du service		: Ajouter une ligne à un fichier
But 				: Ajouter une ligne à un fichier physique de l'IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Fichier_IQEE			Identifiant unique du fichier physique auquel appartient la ligne
													à ajouter.
						cLigne						Ligne à ajouter.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_AjouterLigneFichier] 1, 'Test d''insertion d''une ligne à un fichier IQÉÉ'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblIQEE_LignesFichier		iID_Ligne_Fichier				>0 = Traitement réussi - Identifiant
																						 de la nouvelle ligne de fichier
																					-1 = Fichier IQEE inexistant
																					-2 = Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-06-02		Éric Deshaies						Création du service							
		2009-07-21		Éric Deshaies						Correction ROLLBACK
		2009-11-05		Éric Deshaies						Mise à niveau selon les normes de développement.
		2010-09-01		Éric Deshaies						Retourner l'ID de la nouvelle ligne de fichier.		
        2016-02-15      Steeve Picard                       Ajout de la séquence en paramètre au lieu de mettre une copie du ID de la table
                                                            Ainsi la séquence correspondera au # de ligne dans le fichier
		2016-02-17      Steeve Picard                       Ajout du champ Identificateur unique pour toute les lignes de T02 à T06
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_AjouterLigneFichier]
(
	@iID_Fichier_IQEE INT,
	@iSequence INT,
	@cLigne VARCHAR(1000)
)
AS
BEGIN
    SET NOCOUNT ON

	-- Retourner -1 si le fichier IQÉÉ n'existe pas.
	IF @iID_Fichier_IQEE IS NULL OR @iID_Fichier_IQEE = 0 OR
		NOT EXISTS(SELECT *
					FROM tblIQEE_Fichiers
					WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE)
		RETURN -1

	DECLARE
		@iID_Ligne_Fichier INT,
		@vcType_Enregistrement VARCHAR(2) = LEFT(@cLigne, 2),
		@vcTransactionID varchar(15)

	SET XACT_ABORT ON 
		
	BEGIN TRANSACTION

	BEGIN TRY
		-- Insérer la ligne de fichier
		INSERT INTO dbo.tblIQEE_LignesFichier
			(iID_Fichier_IQEE, iSequence, cLigne)
		VALUES
			(@iID_Fichier_IQEE, @iSequence, @cLigne)

		SET @iID_Ligne_Fichier = SCOPE_IDENTITY()
		
		IF @vcType_Enregistrement in ('02','03','04','05','06')
		BEGIN
		    SET @vcTransactionID = dbo.fnIQEE_FormaterChamp(LTrim(Str(@iID_Ligne_Fichier)),'X',15,0)
		    UPDATE dbo.tblIQEE_LignesFichier
		       SET cLigne = @cLigne + @vcTransactionID
		     WHERE iID_Ligne_Fichier = @iID_Ligne_Fichier
		END

        -- N'est plus nécessaire car la valeur est passé maintenant en paramètre
		----  Mettre à jour le numéro de séquence
		--UPDATE tblIQEE_LignesFichier
		--SET iSequence = @iID_Ligne_Fichier
		--WHERE iID_Ligne_Fichier = @iID_Ligne_Fichier
		
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
		SET @iID_Ligne_Fichier = -2
	END CATCH

	-- Retourner 0 si le traitement est réussi
	RETURN @iID_Ligne_Fichier
END

