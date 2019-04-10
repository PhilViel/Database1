/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_ReturnBankLinkForNOP
Description         :	Sauvegarde d'enregistrement de fichier de retour de la banque de type .NOP, qui sont des 
						changements de compte.

Valeurs de retours  :	Dataset 
Note                :	ADX0000479	IA	2004-10-19	Bruno Lapointe		Migration, normalisation et documentation
						ADX0001024	UP	2006-11-01	Bruno Lapointe		Ne plus utiliser IMo_Bank, emplacé par IU_UN_Bank
						ADX0001159	IA	2007-02-12	Alain Quirion		Modification : Att2
						ADX0001325	IA	2007-03-22	Alain Quirion		Ajout d'une trace au complt modifié
						ADX0003141	UR	2008-02-27	Bruno Lapointe		Il y avait un paramètre de trop envoyé à la SP IU_UN_Bank
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_ReturnBankLinkForNOP] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@SourceOperID INTEGER, -- ID unique de l'opération retournée
	@BankReturnFileID INTEGER, -- ID unique du fichier de retour
	@BankReturnAccount VARCHAR(75), -- Compte de l'effet retourné
	@BankReturnTypeDesc  VARCHAR(75)) -- Description du type d'effet retourné
AS
BEGIN
	DECLARE 
		@Result INTEGER,
		@BankTypeID INTEGER,
		@BankID INTEGER,
		@BankTransit  VARCHAR(75),
		@BankTypeCode  VARCHAR(75),
		@TransitNo  VARCHAR(75),
		@iOldBankID INTEGER,
		@vcOldBankTypeCode VARCHAR(75),
		@vcOldTransitNo VARCHAR(75),
		@vcOldBankTransit VARCHAR(75),
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)

	SET @cSep = CHAR(30)

	SET @Result = 1

	BEGIN TRANSACTION	

	--Va chercher les anciennes informations bancaires
	SELECT
		@iOldBankID = CA.BankID,
		@vcOldBankTransit = B.BankTransit,
		@vcOldBankTypeCode = BT.BankTypeCode,
		@vcOldTransitNo = CA.TransitNo
	FROM Un_ConventionAccount CA
	JOIN dbo.Un_Unit U ON U.ConventionID = CA.ConventionID
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Mo_Bank B ON B.BankID = CA.BankID
	JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID	
	WHERE Ct.OperID = @SourceOperID

	IF EXISTS (
			SELECT 
				BankReturnCodeID 
			FROM Mo_BankReturnLink
			WHERE BankReturnSourceCodeID = @SourceOperID
			  AND BankReturnFileID = @BankReturnFileID)
		SET @Result = -1

	-- Si le type n'existe pas il le crée
	IF @Result > 0
	BEGIN
		IF NOT EXISTS (
				SELECT 
					BankReturnTypeID 
				FROM Mo_BankReturnType 
				WHERE BankReturnTypeID = 'NOP')
			INSERT INTO Mo_BankReturnType (
				BankReturnTypeID, 
				BankReturnTypeDesc)
			VALUES (
				'NOP', 
				@BankReturnTypeDesc)
   
		IF @@ERROR <> 0
			SET @Result = -2
	END

	-- Regarde si l'institution financière existe, sinon la crée
	IF @Result > 0
	BEGIN
		-- Decode la string de compte de l'enregistrement
		SET @BankTypeCode = LTRIM(RTRIM(SUBSTRING(@BankReturnAccount,2,3)))
		SET @BankTransit = LTRIM(RTRIM(SUBSTRING(@BankReturnAccount,6,5))) 
		SET @TransitNo = LTRIM(RTRIM(SUBSTRING(@BankReturnAccount,12,11))) 

		-- Regarde si l'institution financière existe
		SELECT 
			@BankTypeID = ISNULL(MIN(BankTypeID),0)
		FROM Mo_BankType
		WHERE BankTypeCode = @BankTypeCode

		IF @BankTypeID <= 0
		BEGIN
			EXECUTE @BankTypeID = IU_Un_BankType
				@ConnectID,
				0,
				@BankTypeCode,
				'UniAcces Bank Type NOP'

			IF @BankTypeID <= 0
				SET @Result = -3
			ELSE
				SET @Result = 1
		END
	END
      
	-- Regarde si la succursale existe, sinon la crée
	IF @Result > 0
	BEGIN
		SELECT 
			@BankID = ISNULL(MIN(BankID),0)
		FROM Mo_Bank
		WHERE BankTypeID = @BankTypeID
		  AND BankTransit = @BankTransit

		IF @BankID <= 0
		BEGIN
			EXECUTE @BankID = IU_UN_Bank
				@ConnectID,
				0,
				@BankTypeID,
				@BankTransit,
				'UniAcces Bank NOP',
				'FRA',
				'',
				'',
				'',
				NULL,
				'U',
				'Unknow',
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL

			IF @BankID <= 0
				SET @Result = -4
			ELSE
				SET @Result = 1
		END
	END

	IF @Result > 0
	BEGIN
		IF (@iOldBankID <> @BankID	
			OR @vcOldTransitNo <> @TransitNo)
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
					C.ConventionID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Compte bancaire de convention : '+C.ConventionNo,
					LogText =
						CASE 
							WHEN @iOldBankID <> @BankID THEN
									'BankID'+@cSep+CAST(@iOldBankID AS VARCHAR)+@cSep+CAST(@BankID AS VARCHAR)+@cSep+
									ISNULL(@vcOldBankTypeCode+'-'+@vcOldBankTransit,'')+@cSep+
									ISNULL(@BankTypeCode+'-'+@BankTransit,'')+@cSep+
									CHAR(13)+CHAR(10)
						ELSE ''
						END+						
						CASE 
							WHEN @vcOldTransitNo <> @TransitNo THEN
								'TransitNo'+@cSep+@vcOldTransitNo+@cSep+@TransitNo+@cSep+CHAR(13)+CHAR(10)
						ELSE ''
						END
				FROM dbo.Un_Convention C
				JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
				JOIN (
					SELECT DISTINCT U.ConventionID
					FROM dbo.Un_Unit U 
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID							
					WHERE Ct.OperID = @SourceOperID
					) U ON U.ConventionID = CA.ConventionID
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
				WHERE CA.BankID <> @BankID	
					OR CA.TransitNo <> @TransitNo

			IF @@ERROR <> 0
				SET @Result = -6
		END
	END

	IF @Result > 0
	BEGIN
		--Mise à jour des nouvelles informations bancaires
		UPDATE Un_ConventionAccount
		SET
			TransitNo = @TransitNo,
			BankID = @BankID
		FROM Un_ConventionAccount
		JOIN dbo.Un_Unit U ON U.ConventionID = Un_ConventionAccount.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID		
		WHERE Ct.OperID = @SourceOperID

		IF @@ERROR <> 0
			SET @Result = -5
	END

	IF @Result > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @Result
END


