/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_OtherAccountOperOfBlob
Description 		:	Retourne tous les objets de type Un_OtherAccountOper contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_OtherAccountOperOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tOtherAccountOperTable 
	TABLE (
		LigneTrans INTEGER,
		OtherAccountOperID INTEGER,
		OperID INTEGER,
		OtherAccountOperAmount MONEY)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		@iLigneTrans INTEGER,
		@iOtherAccountOperID INTEGER,
		@iOperID INTEGER,
		@myOtherAccountOperAmount MONEY

	-- Va chercher les lignes contenus dans le blob
	DECLARE crLinesOfBlob CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
		
	OPEN crLinesOfBlob
	
	-- Va chercher la première ligne			
	FETCH NEXT FROM crLinesOfBlob
	INTO
		@vcLine
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Recherche la prochaine ligne d'opération dans les autres comptes du blob
		IF CHARINDEX('Un_OtherAccountOper', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_OtherAccountOper dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1

			-- Va chercher le numéro de ligne 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iLigneTrans = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le OtherAccountOperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iOtherAccountOperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iOperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le OtherAccountOperAmount
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @myOtherAccountOperAmount = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
	
			INSERT INTO @tOtherAccountOperTable ( 
				LigneTrans,
				OtherAccountOperID,
				OperID,
				OtherAccountOperAmount)
			VALUES (
				@iLigneTrans,
				@iOtherAccountOperID,
				@iOperID,
				@myOtherAccountOperAmount)
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

