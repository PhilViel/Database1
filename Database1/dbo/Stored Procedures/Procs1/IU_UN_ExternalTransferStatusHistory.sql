/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	IU_UN_ExternalTransferStatusHistory 
Description         :	Création ou modification d'un historique de status de transfert
Valeurs de retours  :	-- >0   : La sauvegarde s'est fait avec succès.  La valeur correspond au @ExternalTransferStatusHistoryID de l'enregistrement.
			-- 0    : Erreur à la sauvegarde
			-- -1   : Incapable de retrouver l'opération de transfert
Note                :						2006-09-11	Mireya Gonthier		Création										
*********************************************************************************************************************/
CREATE  PROCEDURE [dbo].[IU_UN_ExternalTransferStatusHistory] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@ExternalTransferStatusHistoryID INTEGER, -- Identificateur unique
	@iCESP400ID INTEGER, -- Sert à aller chercher l'opération (transfert in ou out)
	@ExternalTransferStatusID UnExternalTransferStatusID, -- Statut du transfert 30 jours ('30D'), 60 jours ('60D'), 90 jours('90D') ou accepté('ACC').
	@ExternalTransferStatusHistoryFileID INTEGER, -- ID unique du fichier
	@RegimeNumber VARCHAR(75), -- Régime de la convention
	@OtherContractNumber VARCHAR(75), -- Numéro de l'autre contrat
	@OtherRegimeNumber VARCHAR(75)) -- Régime de l'autre contrat
AS
BEGIN
	-- Valeur de retour :
	-- >0   : La sauvegarde s'est fait avec succès.  La valeur correspond au @ExternalTransferStatusHistoryID de l'enregistrement.
	-- 0    : Erreur à la sauvegarde
	-- -1   : Incapable de retrouver l'opération de transfert

	DECLARE
		@IResultID INTEGER,
		@OperID INTEGER

	SET @OperID = 0

	-- Recherche l'opération du transfert
	SELECT 
		@OperID = OperID
	FROM UN_CESP400
	WHERE iCESP400ID= @iCESP400ID
	IF @OperID > 0 
	BEGIN
		IF @ExternalTransferStatusHistoryID = 0
		BEGIN
			INSERT INTO Un_ExternalTransferStatusHistory (
				OperID,
				ExternalTransferStatusID,
				ExternalTransferStatusHistoryFileID,
				RegimeNumber,
				OtherContractNumber,
				OtherRegimeNumber )
			VALUES (
				@OperID,
				@ExternalTransferStatusID,
				@ExternalTransferStatusHistoryFileID,
				@RegimeNumber,
				@OtherContractNumber,
				@OtherRegimeNumber )

			IF @@ERROR = 0
				SET @ExternalTransferStatusHistoryID = IDENT_CURRENT('Un_ExternalTransferStatusHistory')
		END
		ELSE
		BEGIN
			UPDATE Un_ExternalTransferStatusHistory 
			SET
				OperID = @OperID,
				ExternalTransferStatusID = @ExternalTransferStatusID,
				ExternalTransferStatusHistoryFileID = @ExternalTransferStatusHistoryFileID,
				RegimeNumber = @RegimeNumber,
				OtherContractNumber = @OtherContractNumber,
				OtherRegimeNumber = @OtherRegimeNumber 
			WHERE ExternalTransferStatusHistoryID = @ExternalTransferStatusHistoryID

			IF @@ERROR <> 0
				SET @ExternalTransferStatusHistoryID = 0 -- Erreur à la sauvegarde
		END
	END
	ELSE 
		SET @ExternalTransferStatusHistoryID = -1 -- Incapable de retrouver l'opération de transfert

	RETURN @ExternalTransferStatusHistoryID
END



