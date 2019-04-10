/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_PlanOperOfBlob
Description 		:	Retourne tous les objets de type Un_PlanOper contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_PlanOperOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRQ_Blob
RETURNS @tPlanOperTable 
	TABLE (
		LigneTrans INTEGER,
		PlanOperID INTEGER,
		OperID INTEGER,
		PlanID INTEGER,
		PlanOperTypeID CHAR(3),
		PlanOperAmount MONEY)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		------------------
		@iLigneTrans INTEGER,
		@iPlanOperID INTEGER,
		@iOperID INTEGER,
		@iPlanID INTEGER,
		@cPlanOperTypeID CHAR(3),
		@myPlanOperAmount MONEY

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
		-- Recherche la prochaine ligne d'opération sur plan du blob
		IF CHARINDEX('Un_PlanOper', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_PlanOper dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1

			-- Va chercher le numéro de ligne 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iLigneTrans = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le PlanOperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iPlanOperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iOperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le PlanID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iPlanID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le PlanOperTypeID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @cPlanOperTypeID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS CHAR(3))
			SET @iPos = @iEndPos + 1

			-- Va chercher le PlanOperAmount
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @myPlanOperAmount = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
	
			INSERT INTO @tPlanOperTable ( 
				LigneTrans,
				PlanOperID,
				OperID,
				PlanID,
				PlanOperTypeID,
				PlanOperAmount)
			VALUES (
				@iLigneTrans,
				@iPlanOperID,
				@iOperID,
				@iPlanID,
				@cPlanOperTypeID,
				@myPlanOperAmount)
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

