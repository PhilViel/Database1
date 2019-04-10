/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	IU_UN_ExternalTransferStatusHistoryFile
Description         :	Création ou modification d'un fichier d'historique de status de transfert
Valeurs de retours  :	-- >0   : La sauvegarde s'est fait avec succès.  La valeur correspond au ExternalTransferStatusHistoryFileID de l'enregistrement.
			-- 0    : Erreur à la sauvegarde
Note                :						2006-09-11	Mireya Gonthier		Création										
*********************************************************************************************************************/
CREATE  PROCEDURE [dbo].[IU_UN_ExternalTransferStatusHistoryFile] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@ExternalTransferStatusHistoryFileID INTEGER, -- Identificateur unique du fichier (0 = Insertion)
	@ExternalTransferStatusHistoryFileName VARCHAR(75), -- Nom du fichier
	@ExternalTransferStatusHistoryFileDate DATETIME) -- Date de réception du fichier
AS
BEGIN
	-- Valeur de retour :
	-- >0   : La sauvegarde s'est fait avec succès.  La valeur correspond au ExternalTransferStatusHistoryFileID de l'enregistrement.
	-- 0    : Erreur à la sauvegarde

	-- Par défaut la date du jour si null ou plus petit ou égal à 0
	IF @ExternalTransferStatusHistoryFileDate IS NULL OR
		@ExternalTransferStatusHistoryFileDate <= 0
		SET @ExternalTransferStatusHistoryFileDate = GETDATE()

	-- Vérifie s'il s'agit d'une insertion ou d'une mise à jour
	IF @ExternalTransferStatusHistoryFileID = 0
	BEGIN
		-- Insertion
		INSERT INTO Un_ExternalTransferStatusHistoryFile (
			ExternalTransferStatusHistoryFileName,
			ExternalTransferStatusHistoryFileDate )
		VALUES (
			@ExternalTransferStatusHistoryFileName,
			@ExternalTransferStatusHistoryFileDate )

		IF @@ERROR = 0
			SET @ExternalTransferStatusHistoryFileID = IDENT_CURRENT('Un_ExternalTransferStatusHistoryFile')
	END
	ELSE
	BEGIN
		-- Mise à jour
		UPDATE Un_ExternalTransferStatusHistoryFile SET
			ExternalTransferStatusHistoryFileName = @ExternalTransferStatusHistoryFileName,
			ExternalTransferStatusHistoryFileDate = @ExternalTransferStatusHistoryFileDate
		WHERE ExternalTransferStatusHistoryFileID = @ExternalTransferStatusHistoryFileID

		IF @@ERROR <> 0
			SET @ExternalTransferStatusHistoryFileID = 0
  END

  RETURN @ExternalTransferStatusHistoryFileID 
END


