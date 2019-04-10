/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_UnitReductionOfBlob
Description 		:	Retourne tous les objets de type UN_UnitReduction contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2006-04-10	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_UnitReductionOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tUnitReductionTable 
	TABLE (
		UnitReductionID INTEGER,
		UnitID INTEGER,
		ReductionConnectID INTEGER,
		ReductionDate DATETIME,
		UnitQty MONEY,
		FeeSumByUnit MONEY,
		SubscInsurSumByUnit MONEY,
		UnitReductionReasonID INTEGER,
		NoChequeReasonID INTEGER)
AS
BEGIN
	-- Exemple d'encodage d'objet de réduction d'unités qui sont rechercher dans le blob.
	-- UN_UnitReduction;UnitReductionID;UnitID;ReductionConnectID;ReductionDate;UnitQty;FeeSumByUnit;SubscInsurSumByUnit;UnitReductionReasonID;NoChequeReasonID;

	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		@UnitReductionID INTEGER,
		@UnitID INTEGER,
		@ReductionConnectID INTEGER,
		@ReductionDate DATETIME,
		@UnitQty MONEY,
		@FeeSumByUnit MONEY,
		@SubscInsurSumByUnit MONEY,
		@UnitReductionReasonID INTEGER,
		@NoChequeReasonID INTEGER

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
		IF CHARINDEX('UN_UnitReduction', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est UN_UnitReduction dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1
	
			-- Va chercher le UnitReductionID 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @UnitReductionID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le UnitID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @UnitID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le ReductionConnectID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ReductionConnectID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le ReductionDate
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ReductionDate = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
			SET @iPos = @iEndPos + 1

			-- Va chercher le UnitQty
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @UnitQty = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le FeeSumByUnit
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @FeeSumByUnit = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le SubscInsurSumByUnit
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @SubscInsurSumByUnit = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le UnitReductionReasonID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @UnitReductionReasonID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le NoChequeReasonID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @NoChequeReasonID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)

			INSERT INTO @tUnitReductionTable ( 
				UnitReductionID,
				UnitID,
				ReductionConnectID,
				ReductionDate,
				UnitQty,
				FeeSumByUnit,
				SubscInsurSumByUnit,
				UnitReductionReasonID,
				NoChequeReasonID)
			VALUES (
				@UnitReductionID,
				@UnitID,
				@ReductionConnectID,
				@ReductionDate,
				@UnitQty,
				@FeeSumByUnit,
				@SubscInsurSumByUnit,
				@UnitReductionReasonID,
				@NoChequeReasonID)
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

