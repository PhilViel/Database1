/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc
Nom                 :	dbo.FN_Un_OtherAccountOperInBlob
Description         :	Fonction qui extrait les opérations dans les autres comptes d'un blob de sauvegarde ou de 
								validation de la gestion des opérations
Valeurs de retours  :	Table des opérations dans les autres comptes
Note                :	ADX0000623	IA	2005-01-04	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_OtherAccountOperInBlob (
	@BlobID INTEGER) -- ID Unique du blob de la table CRQ_Blob
RETURNS @OtherAccountOperTable 
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
	DECLARE LinesOfBlob CURSOR FOR
		SELECT Val
		FROM dbo.FN_CRQ_LinesOfBlob(@BlobID)
		
	OPEN LinesOfBlob
	
	-- Va chercher la première ligne			
	FETCH NEXT FROM LinesOfBlob
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
	
			INSERT INTO @OtherAccountOperTable ( 
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
		FETCH NEXT FROM LinesOfBlob
		INTO
			@vcLine
	END

	CLOSE LinesOfBlob
	DEALLOCATE LinesOfBlob

	-- Fin des traitements
	RETURN
END

