/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SP_IU_CRQ_BankReturnFile
Description         :	Sauvegarde de fichier bancaire.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au BankReturnFileID du
											fichier bancaire sauvegardé.
									<=0 :	La sauvegarde a échouée.
Note                :	ADX0000479	IA	2004-10-19	Bruno Lapointe		Migration, normalisation et documentation
								ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_CRQ_BankReturnFile] (
	@ConnectID MoID, -- ID unique de connexion de l'usager
	@BankReturnFileID MoID, -- ID unique du fichier de retour (0 = nouveau)
	@BankReturnFileName MoDesc, -- Nom du fichier 
	@BankReturnFileDate MoGetDate) -- Date du fichier
AS
BEGIN
	-- Valeur de retour
	-- >0  : le fichier est supprimé
	-- <=0 : Erreurs
	--  		0  : Erreur à la sauvegarde
	--			-1 : Le fichier existe déjà
	--			-2 : Un autre fichier porte déjà ce nom de fichier
	IF @BankReturnFileID = 0
	BEGIN
		IF NOT EXISTS ( -- Vérifie que le fichier n'existe pas déjà
				SELECT BankReturnFileName
				FROM Mo_BankReturnFile
				WHERE BankReturnFileName = @BankReturnFileName)
		BEGIN
			-- Insère le nouveau fichier
			INSERT INTO Mo_BankReturnFile (
				BankReturnFileName,
				BankReturnFileDate)
			VALUES (
				@BankReturnFileName,
				@BankReturnFileDate)

			IF @@ERROR = 0
				SET @BankReturnFileID = IDENT_CURRENT('Mo_BankReturnFile')
		END
		ELSE
			SET @BankReturnFileID = -1
	END
	ELSE
	BEGIN
		IF NOT EXISTS ( -- Vérifie que le nom du fichier n'existe pas déjà
			SELECT BankReturnFileName
			FROM Mo_BankReturnFile
			WHERE BankReturnFileName = @BankReturnFileName
			  AND BankReturnFileID <> @BankReturnFileID)
		BEGIN
			-- Met à jour le fichier
			UPDATE Mo_BankReturnFile
			SET
				BankReturnFileName = @BankReturnFileName,
				BankReturnFileDate = @BankReturnFileDate
			WHERE BankReturnFileID = @BankReturnFileID

			IF @@ERROR <> 0
				SET @BankReturnFileID = 0
		END
		ELSE
			SET @BankReturnFileID = -2
	END

	RETURN @BankReturnFileID
END
