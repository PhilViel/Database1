/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_ScholarshipPmtOfBlob
Description 		:	Retourne tous les objets de type UN_ScholarshipPmt contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
											2010-01-18	Jean-F. Gauthier	Ajout du champ EligibilityConditionID 
*******************************************************************************************************************/
CREATE FUNCTION [dbo].[FN_UN_ScholarshipPmtOfBlob] (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRQ_Blob
RETURNS @tScholarshipPmtTable 
	TABLE (
		ScholarshipPmtID INTEGER,
		OperID INTEGER,
		ScholarshipID INTEGER,
		CollegeID INTEGER,
		ProgramID INTEGER,
		StudyStart DATETIME,
		ProgramLength INTEGER,
		ProgramYear INTEGER,
		RegistrationProof BIT,
		SchoolReport BIT,
		EligibilityQty INTEGER,
		CaseOfJanuary BIT,
		EligibilityConditionID CHAR(3))		-- 2010-01-19 : JFG : Ajout
AS
BEGIN
	-- Exemple d'encodage d'objet de paiement de bourse qui sont rechercher dans le blob.
	-- UN_ScholarshipPmt;ScholarshipPmtID;OperID;ScholarshipID;CollegeID;ProgramID;StudyStart;ProgramLength;ProgramYear;RegistrationProof;SchoolReport;EligibilityQty;CaseOfJanuary;

	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		-----------------
		@ScholarshipPmtID INTEGER,
		@OperID INTEGER,
		@ScholarshipID INTEGER,
		@CollegeID INTEGER,
		@ProgramID INTEGER,
		@StudyStart DATETIME,
		@ProgramLength INTEGER,
		@ProgramYear INTEGER,
		@RegistrationProof BIT,
		@SchoolReport BIT,
		@EligibilityQty INTEGER,
		@CaseOfJanuary BIT,
		@EligibilityConditionID	CHAR(3)	-- 2010-01-19 : JFG : ajout

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
		IF CHARINDEX('UN_ScholarshipPmt', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est UN_UnitReduction dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1
	
			-- Va chercher le ScholarshipPmtID 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ScholarshipPmtID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le ScholarshipID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ScholarshipID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le CollegeID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @CollegeID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ProgramID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ProgramID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le StudyStart
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @StudyStart = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ProgramLength
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ProgramLength = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ProgramYear
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ProgramYear = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le RegistrationProof
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @RegistrationProof = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le SchoolReport
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @SchoolReport = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le EligibilityQty
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @EligibilityQty = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le CaseOfJanuary
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @CaseOfJanuary = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1	

			-- 2010-01-19 : JFG : obtention du EligibilityConditionID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @EligibilityConditionID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS CHAR(3))
			
			INSERT INTO @tScholarshipPmtTable ( 
				ScholarshipPmtID,
				OperID,
				ScholarshipID,
				CollegeID,
				ProgramID,
				StudyStart,
				ProgramLength,
				ProgramYear,
				RegistrationProof,
				SchoolReport,
				EligibilityQty,
				CaseOfJanuary,
				EligibilityConditionID)		-- 2010-01-19 : JFG : ajout
			VALUES (
				@ScholarshipPmtID,
				@OperID,
				@ScholarshipID,
				@CollegeID,
				@ProgramID,
				@StudyStart,
				@ProgramLength,
				@ProgramYear,
				@RegistrationProof,
				@SchoolReport,
				@EligibilityQty,
				@CaseOfJanuary,
				@EligibilityConditionID)	-- 2010-01-19 : JFG : ajout
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
