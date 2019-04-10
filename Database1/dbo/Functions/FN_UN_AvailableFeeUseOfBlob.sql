/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 			:	FN_UN_AvailableFeeUseOfBlob
Description 		:	Retourne tous les objets de type Un_Cotisation contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note			:	ADX0000861	IA	2006-11-02	Alain Quirion		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_AvailableFeeUseOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRQ_Blob
RETURNS @tAvailableFeeUseTable 
	TABLE (
		iAvailableFeeUseID INTEGER,
		UnitReductionID INTEGER,
		OperID INTEGER,
		fUnitQtyUse MONEY)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		@LigneTrans INTEGER,
		@iAvailableFeeUseID INTEGER,
		@UnitReductionID INTEGER,
		@OperID INTEGER,
		@fUnitQtyUse MONEY

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
		IF CHARINDEX('Un_AvailableFeeUse', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_Cotisation dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1
	
			-- Va chercher le iAvailableFeeUseID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iAvailableFeeUseID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ReductionUnitID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @UnitReductionID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le fUnitQtyUse
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @fUnitQtyUse = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)			
	
			INSERT INTO @tAvailableFeeUseTable ( 
				iAvailableFeeUseID,
				UnitReductionID,
				OperID,				
				fUnitQtyUse)
			VALUES (
				@iAvailableFeeUseID,
				@UnitReductionID,
				@OperID,				
				@fUnitQtyUse)
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


