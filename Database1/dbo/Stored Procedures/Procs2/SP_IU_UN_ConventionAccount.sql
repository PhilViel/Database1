/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : SP_IU_UN_ConventionAccount
Description         : Sauvegarde d'ajouts/modifications de compte bancaire de conventions
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
								-1	: Erreur lors de la sauvegarde de l'ajout
								-2	: Erreur lors de la création du log lors de l'insertion
								-3	: Erreur lors de la sauvegarde des modifications
								-4	: Erreur lors de la création du log lors de la mise à jour
Note                :						2004-06-07	Bruno Lapointe			Création
								ADX0000594	IA	2004-11-24	Bruno Lapointe			Gestion du log
												2008-05-13	Pierre-Luc Simard		Nom de compte en majuscule et sans accent		
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_UN_ConventionAccount] (
	@ConnectID INTEGER,
	@ConventionID INTEGER,
	@BankID INTEGER,
	@AccountName VARCHAR(75),
	@TransitNo VARCHAR(75)
)
AS
BEGIN
	DECLARE
		@iConventionNo3Last INTEGER,
		@iOldBankID INTEGER,
		@vcOldAccountName VARCHAR(75),
		@vcOldTransitNo VARCHAR(75),
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)

	SET @cSep = CHAR(30)

	-- Inscrit le nom en majuscule et sans accent et Enlever les espaces inutiles. conserver seulement celui après la virgule
	SET @AccountName =  UPPER(dbo.fn_Mo_FormatStringWithoutAccent(@AccountName))

	-----------------
	BEGIN TRANSACTION
	-----------------

	SELECT
		@iOldBankID = BankID,
		@vcOldAccountName = AccountName,
		@vcOldTransitNo = TransitNo
	FROM Un_ConventionAccount
	WHERE ConventionID = @ConventionID

	IF NOT EXISTS(
			SELECT 
				ConventionID
			FROM Un_ConventionAccount
			WHERE @ConventionID = ConventionID)
	BEGIN
		INSERT INTO Un_ConventionAccount (
			ConventionID,
			BankID,
			TransitNo,
			AccountName)
		VALUES (
			@ConventionID,
			@BankID,
			@TransitNo,
			@AccountName)

		IF @@ERROR <> 0
			SET @ConventionID = -1

		IF @ConventionID > 0
		BEGIN
			-- Insère un log de l'objet inséré.
			INSERT INTO CRQ_Log (
				ConnectID,
				LogTableName,
				LogCodeID,
				LogTime,
				LogActionID,
				LogDesc,
				LogText)
				SELECT
					@ConnectID,
					'Un_Convention',
					@ConventionID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Compte bancaire de convention : '+C.ConventionNo,
					LogText =
						'BankID'+@cSep+CAST(AC.BankID AS VARCHAR)+@cSep+ISNULL(BT.BankTypeCode+'-'+B.BankTransit,'')+@cSep+CHAR(13)+CHAR(10)+
						'AccountName'+@cSep+AC.AccountName+@cSep+CHAR(13)+CHAR(10)+
						'TransitNo'+@cSep+AC.TransitNo+@cSep+CHAR(13)+CHAR(10)
					FROM dbo.Un_Convention C
					JOIN Un_ConventionAccount AC ON AC.ConventionID = C.ConventionID
					JOIN Mo_Bank B ON B.BankID = AC.BankID
					JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'I'
					WHERE C.ConventionID = @ConventionID

			IF @@ERROR <> 0
				SET @ConventionID = -2
		END
	END
	ELSE
	BEGIN
		UPDATE Un_ConventionAccount 
		SET
			BankID = @BankID,
			AccountName = @AccountName,
			TransitNo = @TransitNo
		WHERE ConventionID = @ConventionID

		IF @@ERROR <> 0
			SET @ConventionID = -3

		IF EXISTS	(
				SELECT 
					ConventionID
				FROM Un_ConventionAccount
				WHERE ConventionID = @ConventionID
					AND	(	@iOldBankID <> BankID
							OR	@vcOldAccountName <> AccountName
							OR	@vcOldTransitNo <> TransitNo
							)
						)
		AND	(	@ConventionID > 0	
				)
		BEGIN
			-- Insère un log de l'objet modifié.
			INSERT INTO CRQ_Log (
				ConnectID,
				LogTableName,
				LogCodeID,
				LogTime,
				LogActionID,
				LogDesc,
				LogText)
				SELECT
					@ConnectID,
					'Un_Convention',
					@ConventionID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Compte bancaire de convention : '+C.ConventionNo,
					LogText =
						CASE 
							WHEN @iOldBankID <> AC.BankID THEN
								'BankID'+@cSep+CAST(@iOldBankID AS VARCHAR)+@cSep+CAST(AC.BankID AS VARCHAR)+@cSep+
								ISNULL(OBT.BankTypeCode+'-'+OB.BankTransit,'')+@cSep+
								ISNULL(BT.BankTypeCode+'-'+B.BankTransit,'')+@cSep+
								CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN @vcOldAccountName <> AC.AccountName THEN
								'AccountName'+@cSep+@vcOldAccountName+@cSep+AC.AccountName+@cSep+CHAR(13)+CHAR(10)
						ELSE ''
						END+
						CASE 
							WHEN @vcOldTransitNo <> AC.TransitNo THEN
								'TransitNo'+@cSep+@vcOldTransitNo+@cSep+AC.TransitNo+@cSep+CHAR(13)+CHAR(10)
						ELSE ''
						END
					FROM dbo.Un_Convention C
					JOIN Un_ConventionAccount AC ON AC.ConventionID = C.ConventionID
					JOIN Mo_Bank B ON B.BankID = AC.BankID
					JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
					JOIN Mo_Bank OB ON OB.BankID = @iOldBankID
					JOIN Mo_BankType OBT ON OBT.BankTypeID = OB.BankTypeID
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
					WHERE C.ConventionID = @ConventionID

			IF @@ERROR <> 0
				SET @ConventionID = -4
		END
	END

	IF @ConventionID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @ConventionID
END


