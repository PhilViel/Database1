/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_ConventionOperOfBlob
Description 		:	Retourne tous les objets de type Un_ConventionOper contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_ConventionOperOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRQ_Blob
RETURNS @tConventionOperTable 
	TABLE (
		LigneTrans INTEGER,
		ConventionOperID INTEGER,
		OperID INTEGER,
		ConventionID INTEGER,
		ConventionOperTypeID VARCHAR(3),
		ConventionOperAmount MONEY)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		@LigneTrans INTEGER,
		@ConventionOperID INTEGER,
		@OperID INTEGER,
		@ConventionID INTEGER,
		@ConventionOperTypeID VARCHAR(3),
		@ConventionOperAmount MONEY

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
		IF CHARINDEX('Un_ConventionOper', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_ConventionOper dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1
	
			-- Va chercher le numéro de ligne  
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @LigneTrans = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le ConventionOperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ConventionOperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ConventionID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ConventionID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ConventionOperTypeID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ConventionOperTypeID = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ConventionOperAmount
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ConventionOperAmount = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
	
			INSERT INTO @tConventionOperTable ( 
				LigneTrans,
				ConventionOperID,
				OperID,
				ConventionID,
				ConventionOperTypeID,
				ConventionOperAmount)
			VALUES (
				@LigneTrans,
				@ConventionOperID,
				@OperID,
				@ConventionID,
				@ConventionOperTypeID,
				@ConventionOperAmount)
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

