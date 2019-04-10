/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_CESPReceivedFile
Description         :	Destruction d'un fichier reçu du PCEE.
Valeurs de retours  :	@Return_Value :
									> 0 :	La suppression a été effectué avec succès.  La valeur correspond au 
											GovernmentSendFileID du fichier supprimé.
									<= 0:	Erreur :
										-1  : Erreur à la recherche du OperID du fichier de retour
										-2  : Erreur lors de la suppression des enregistrements d'erreurs graves (850)
										-3  : Erreur lors de la suppression des enregistrements de confirmation d'enregistrement de conventions (950)
										-4  : Erreur lors de la suppression des enregistrements de subventions (900)
										-5  : Erreur lors de la suppression de l'opération de subvention
										-6  : Erreur lors de la suppression des lien d'erreur sur les enregistrements 100
										-7  : Erreur lors de la suppression des lien d'erreur sur les enregistrements 200
										-8  : Erreur lors de la suppression des lien d'erreur sur les enregistrements 400
										-9  : Erreur lors de la suppression des lien d'erreur sur les enregistrements 511
										-10 : Erreur lors de la suppression des enregistrements d'erreurs (800)										
										-11 : Erreur lors de la suppression du lien entre le fichier de retour et le fichier d'envoi
										-12 : Erreur lors de la suppression de la liste de fichier faisant partie du retour
										-13 : Erreur lors de la suppression du fichier de retour
										-14 : Erreur lors de la suppression de l'opération
										-15 : Vous ne pouvez pas travailler dans cette période
Note                :	ADX0000811	IA	2006-04-17	Bruno Lapointe		Création
						ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
										2009-02-26  Patrick Robitaille	Suppression des erreurs associées aux enregistrements 511
										2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_CESPReceivedFile] (
	@iCESPReceiveFileID INTEGER) -- ID unique du fichier de retour à supprimer
AS
BEGIN
	-- Valeurs de retours :
	-- >0  : La suppression a été effectué avec succès.  La valeur correspond au GovernmentSendFileID du fichier supprimé.
	-- -1  : Erreur à la recherche du OperID du fichier de retour
	-- -2  : Erreur lors de la suppression des enregistrements d'erreurs graves (850)
	-- -3  : Erreur lors de la suppression des enregistrements de confirmation d'enregistrement de conventions (950)
	-- -4  : Erreur lors de la suppression des enregistrements de subventions (900)
	-- -5  : Erreur lors de la suppression de l'opération de subvention
	-- -6  : Erreur lors de la suppression des lien d'erreur sur les enregistrements 100
	-- -7  : Erreur lors de la suppression des lien d'erreur sur les enregistrements 200
	-- -8  : Erreur lors de la suppression des lien d'erreur sur les enregistrements 400
	-- -9  : Erreur lors de la suppression des lien d'erreur sur les enregistrements 511
	-- -10 : Erreur lors de la suppression des enregistrements d'erreurs (800)										
	-- -11 : Erreur lors de la suppression du lien entre le fichier de retour et le fichier d'envoi
	-- -12 : Erreur lors de la suppression de la liste de fichier faisant partie du retour
	-- -13 : Erreur lors de la suppression du fichier de retour
	-- -14 : Erreur lors de la suppression de l'opération
	-- -15 : Vous ne pouvez pas travailler dans cette période

	-- Désactive le trigger empêchant la modification des données de la table Un_CESP900
	--ALTER TABLE Un_CESP900
	--	DISABLE TRIGGER TUn_CESP900

	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	INSERT INTO #DisableTrigger VALUES('TUn_CESP900')				
	
	DECLARE
		@OperID INTEGER,
		@LockDate DATETIME,
		@Result INTEGER

	SET @Result = @iCESPReceiveFileID

	SET @OperID = 0

	-- Recherche du OperID du fichier de retour
	SELECT 
		@OperID = OperID
	FROM Un_CESPReceiveFile
	WHERE iCESPReceiveFileID = @iCESPReceiveFileID

	IF @@ERROR <> 0 OR @OperID <= 0
		SET @Result = -1 -- Erreur à la recherche du OperID du fichier de retour

	IF @Result > 0 
	BEGIN
		SELECT 
			@LockDate = LastVerifDate
		FROM Un_Def
	
		IF EXISTS (
			SELECT OperID
			FROM Un_Oper 
			WHERE OperID = @OperID
			  AND OperDate <= @LockDate)
			SET @Result = -13 -- Vous ne pouvez pas travailler dans cette période
	END

	-----------------
	BEGIN TRANSACTION 
	-----------------

	IF @Result > 0 
	BEGIN
		-- Suppression des enregistrements d'erreurs graves (850)
		DELETE 
		FROM Un_CESP850
		WHERE iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -2 -- Erreur lors de la suppression des enregistrements d'erreurs graves (850)
	END
	 
	IF @Result > 0 
	BEGIN
		-- Suppression des enregistrements de confirmation d'enregistrement de conventions (950)
		DELETE 
		FROM Un_CESP950 
		WHERE iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -3 -- Erreur lors de la suppression des enregistrements de confirmation d'enregistrement de conventions (950)
	END
	
	IF @Result > 0 
	BEGIN
		-- Suppression des enregistrements de subventions (900)
		DELETE 
		FROM Un_CESP900 
		WHERE iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -4 -- Erreur lors de la suppression des enregistrements de subventions (900)
	END
	
	IF @Result > 0 
	BEGIN
		-- Suppression de l'opération de subvention
		DELETE 
		FROM Un_CESP 
		WHERE OperID = @OperID
		
		IF @@ERROR <> 0 
			SET @Result = -5 -- Erreur lors de la suppression de l'opération de subvention
	END
	
	IF @Result > 0 
	BEGIN
		-- Suppression des lien d'erreur sur les enregistrements 100
		UPDATE Un_CESP100 
		SET 
			iCESP800ID = NULL
		FROM Un_CESP100 G1
		JOIN Un_CESP800 G8 ON G8.iCESP800ID = G1.iCESP800ID
		WHERE G8.iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -6 -- Erreur lors de la suppression des lien d'erreur sur les enregistrements 100
	END
	
	IF @Result > 0 
	BEGIN
		-- Suppression des lien d'erreur sur les enregistrements 200
		UPDATE Un_CESP200 
		SET 
			iCESP800ID = NULL
		FROM Un_CESP200 G2
		JOIN Un_CESP800 G8 ON G8.iCESP800ID = G2.iCESP800ID
		WHERE G8.iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -7 -- Erreur lors de la suppression des lien d'erreur sur les enregistrements 200
	END
	
	IF @Result > 0 
	BEGIN
		-- Suppression des lien d'erreur sur les enregistrements 400
		UPDATE Un_CESP400 
		SET 
			iCESP800ID = NULL
		FROM Un_CESP400 G4
		JOIN Un_CESP800 G8 ON G8.iCESP800ID = G4.iCESP800ID
		WHERE G8.iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -8 -- Erreur lors de la suppression des lien d'erreur sur les enregistrements 400
	END

	IF @Result > 0 
	BEGIN
		-- Suppression des lien d'erreur sur les enregistrements 511
		UPDATE Un_CESP511 
		SET 
			iCESP800ID = NULL
		FROM Un_CESP511 G5
		JOIN Un_CESP800 G8 ON G8.iCESP800ID = G5.iCESP800ID
		WHERE G8.iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -9 -- Erreur lors de la suppression des lien d'erreur sur les enregistrements 511
	END
	
	IF @Result > 0 
	BEGIN
		-- Suppression des enregistrements d'erreurs (800)
		DELETE 
		FROM Un_CESP800ToTreat
		WHERE iCESP800ID IN (
			SELECT iCESP800ID 
			FROM Un_CESP800
			WHERE iCESPReceiveFileID = @iCESPReceiveFileID
			)
		
		IF @@ERROR <> 0 
			SET @Result = -10 -- Erreur lors de la suppression des enregistrements d'erreurs (800)
	END
	
	IF @Result > 0 
	BEGIN
		-- Suppression des enregistrements d'erreurs (800)
		DELETE 
		FROM Un_CESP800 
		WHERE iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -11 -- Erreur lors de la suppression des enregistrements d'erreurs (800)
	END
	
	IF @Result > 0 
	BEGIN
		-- Suppression du lien entre le fichier de retour et le fichier d'envoi
		UPDATE Un_CESPSendFile 
		SET 
			iCESPReceiveFileID = NULL
		FROM Un_CESPSendFile
		WHERE iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -12 -- Erreur lors de la suppression du lien entre le fichier de retour et le fichier d'envoi
	END

	IF @Result > 0 
	BEGIN
		-- Suppression de la liste de fichier faisant partie du retour
		DELETE 
		FROM Un_CESPReceiveFileDtl 
		WHERE iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -13 -- Erreur lors de la suppression de la liste de fichier fesant partie du retour
	END

	IF @Result > 0 
	BEGIN
		-- Suppression du fichier de retour
		DELETE 
		FROM Un_CESPReceiveFile 
		WHERE iCESPReceiveFileID = @iCESPReceiveFileID
		
		IF @@ERROR <> 0 
			SET @Result = -14 -- Erreur lors de la suppression du fichier de retour
	END

	IF @Result > 0 
	BEGIN
		-- Suppression de l'opération
		DELETE 
		FROM Un_Oper 
		WHERE OperID = @OperID
		
		IF @@ERROR <> 0 
			SET @Result = -15 -- Erreur lors de la suppression de l'opération
	END

	IF @Result > 0 
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	-- Réactive le trigger empêchant la modification des données de la table Un_CESP900
	--ALTER TABLE Un_CESP900
	--	ENABLE TRIGGER TUn_CESP900

	Delete #DisableTrigger where vcTriggerName = 'TUn_CESP900'

	RETURN @Result
END
