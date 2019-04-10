/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_WithdrawalReasonOfBlob
Description 		:	Retourne tous les objets de type Un_WithdrawalReason contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note			:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
				ADX0001123	IA	2006-10-06	Alain Quirion		Modification : Ajout de	tiCESP400WithdrawReasonID
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_WithdrawalReasonOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRQ_Blob
RETURNS @tWithdrawalReasonTable 
	TABLE (
		LigneTrans INTEGER,
		OperID INTEGER,
		WithdrawalReasonID INTEGER,
		tiCESP400WithdrawReasonID TINYINT)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		-----------------
		@LigneTrans INTEGER,
		@OperID INTEGER,
		@WithdrawalReasonID INTEGER,
		@tiCESP400WithdrawReasonID TINYINT

	-- Va chercher les lignes contenus dans le blob
	DECLARE crLinesOfBlob CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
		
	OPEN crLinesOfBlob
	
	-- Va chercher la première ligne			
	FETCH NEXT FROM crLinesOfBlob
	INTO
		@vcLine
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		-- Recherche la prochaine ligne d'opération du blob
		IF CHARINDEX('Un_WithdrawalReason', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_WithdrawalReason dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1
	
			-- Va chercher le numéro de ligne 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @LigneTrans = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le WithdrawalReasonID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @WithdrawalReasonID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le tiCESP400WithdrawReasonID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @tiCESP400WithdrawReasonID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
	
			INSERT INTO @tWithdrawalReasonTable ( 
				LigneTrans,
				OperID,
				WithdrawalReasonID,
				tiCESP400WithdrawReasonID)
			VALUES (
				@LigneTrans,
				@OperID,
				@WithdrawalReasonID,
				@tiCESP400WithdrawReasonID)
		END

		-- Passe à la prochaine ligne
		FETCH NEXT FROM crLinesOfBlob
		INTO
			@vcLine
	END

	CLOSE crLinesOfBlob
	DEALLOCATE crLinesOfBlob

	-- Fin des traitements
	RETURN
END


