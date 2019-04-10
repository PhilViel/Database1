/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_OperOfBlob
Description 		:	Retourne tous les objets de type Un_Oper contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_OperOfBlob (
	@iBlobID INTEGER) -- ID du blob contenant l'information qu'il faut aller chercher
RETURNS @tOperTable 
	TABLE (
		LigneTrans INTEGER,
		OperID INTEGER,
		ConnectID INTEGER,
		OperTypeID CHAR(3),
		OperDate DATETIME)
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
		@ConnectID INTEGER,
		@OperTypeID CHAR(3),
		@OperDate DATETIME

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
		IF CHARINDEX('Un_Oper', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_Oper dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1
	
			-- Va chercher le numéro de ligne 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @LigneTrans = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le ConnectID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ConnectID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le OperTypeID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperTypeID = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le OperDate
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperDate = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
	
			INSERT INTO @tOperTable ( 
				LigneTrans,
				OperID,
				ConnectID,
				OperTypeID,
				OperDate)
			VALUES (
				@LigneTrans,
				@OperID,
				@ConnectID,
				@OperTypeID,
				@OperDate)
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

