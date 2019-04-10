/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_IntReimbOfBlob
Description 		:	Retourne tous les objets de type Un_IntReimb contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
											2008-10-16	Patrick Robitaille	Ajout du FeeRefund dans la table Un_IntReimb
*******************************************************************************************************************/
CREATE FUNCTION [dbo].[FN_UN_IntReimbOfBlob] (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tIntReimbTable 
	TABLE (
		IntReimbID INTEGER,
		UnitID INTEGER,
		CollegeID INTEGER,
		ProgramID INTEGER,
		IntReimbDate DATETIME,
		StudyStart DATETIME,
		ProgramYear INTEGER,
		ProgramLength INTEGER,
		CESGRenonciation BIT,
		FullRIN BIT,
		FeeRefund BIT)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		-----------------
		@iIntReimbID INTEGER,
		@iUnitID INTEGER,
		@iCollegeID INTEGER,
		@iProgramID INTEGER,
		@dtIntReimbDate DATETIME,
		@dtStudyStart DATETIME,
		@iProgramYear INTEGER,
		@iProgramLength INTEGER,
		@bCESGRenonciation BIT,
		@bFullRIN BIT,
		@bFeeRefund BIT

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
		-- Recherche la prochaine ligne de remboursement intégral du blob
		IF CHARINDEX('Un_IntReimb', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_IntReimb dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1

			-- Va chercher le IntReimbID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iIntReimbID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le UnitID 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iUnitID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le CollegeID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iCollegeID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ProgramID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iProgramID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le IntReimbDate
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @dtIntReimbDate = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
			SET @iPos = @iEndPos + 1

			-- Va chercher le StudyStart
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @dtStudyStart = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ProgramYear
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iProgramYear = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ProgramLength
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iProgramLength = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le CESGRenonciation
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @bCESGRenonciation = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le FullRIN
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @bFullRIN = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le FeeRefund
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @bFeeRefund = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
	
			INSERT INTO @tIntReimbTable ( 
				IntReimbID,
				UnitID,
				CollegeID,
				ProgramID,
				IntReimbDate,
				StudyStart,
				ProgramYear,
				ProgramLength,
				CESGRenonciation,
				FullRIN,
				FeeRefund)
			VALUES (
				@iIntReimbID,
				@iUnitID,
				@iCollegeID,
				@iProgramID,
				@dtIntReimbDate,
				@dtStudyStart,
				@iProgramYear,
				@iProgramLength,
				@bCESGRenonciation,
				@bFullRIN,
				@bFeeRefund)
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

