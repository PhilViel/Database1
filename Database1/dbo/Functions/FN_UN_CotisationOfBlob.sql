/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_CotisationOfBlob
Description 		:	Retourne tous les objets de type Un_Cotisation contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_CotisationOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRQ_Blob
RETURNS @tCotisationTable 
	TABLE (
		LigneTrans INTEGER,
		CotisationID INTEGER,
		OperID INTEGER,
		UnitID INTEGER,
		EffectDate DATETIME,
		Cotisation MONEY,
		Fee MONEY,
		BenefInsur MONEY,
		SubscInsur MONEY,
		TaxOnInsur MONEY)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		@LigneTrans INTEGER,
		@CotisationID INTEGER,
		@OperID INTEGER,
		@UnitID INTEGER,
		@EffectDate DATETIME,
		@Cotisation MONEY,
		@Fee MONEY,
		@BenefInsur MONEY,
		@SubscInsur MONEY,
		@TaxOnInsur MONEY

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
		IF CHARINDEX('Un_Cotisation', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_Cotisation dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1
	
			-- Va chercher le numéro de ligne 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @LigneTrans = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le CotisationID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @CotisationID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le UnitID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @UnitID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le EffectDate
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @EffectDate = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
			SET @iPos = @iEndPos + 1

			-- Va chercher le Cotisation
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Cotisation = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le Fee
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Fee = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le BenefInsur
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @BenefInsur = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le SubscInsur
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @SubscInsur = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
			SET @iPos = @iEndPos + 1

			-- Va chercher le TaxOnInsur
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @TaxOnInsur = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS MONEY)
	
			INSERT INTO @tCotisationTable ( 
				LigneTrans,
				CotisationID,
				OperID,
				UnitID,
				EffectDate,
				Cotisation,
				Fee,
				BenefInsur,
				SubscInsur,
				TaxOnInsur)
			VALUES (
				@LigneTrans,
				@CotisationID,
				@OperID,
				@UnitID,
				@EffectDate,
				@Cotisation,
				@Fee,
				@BenefInsur,
				@SubscInsur,
				@TaxOnInsur)
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

