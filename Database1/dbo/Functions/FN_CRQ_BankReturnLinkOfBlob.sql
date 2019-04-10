/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRQ_BankReturnLinkOfBlob
Description 		:	Retourne tous les objets de type CRQ_BankRetunrLink contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
											2014-06-18	Maxime Martel		BankReturnTypeID varchar(3) -> varchar(4)
*******************************************************************************************************************/
CREATE FUNCTION [dbo].[FN_CRQ_BankReturnLinkOfBlob] (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRQ_Blob
RETURNS @BankReturnLinkTable 
	TABLE (
		BankReturnCodeID INTEGER,
		BankReturnFileID INTEGER,
		BankReturnSourceCodeID INTEGER,
		BankReturnTypeID VARCHAR(4))
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		@BankReturnCodeID INTEGER,
		@BankReturnFileID INTEGER,
		@BankReturnSourceCodeID INTEGER,
		@BankReturnTypeID VARCHAR(4)

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
		IF CHARINDEX('CRQ_BankReturnLink', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est CRQ_BankReturnLink dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1
	
			-- Va chercher le BankReturnCodeID 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @BankReturnCodeID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le BankReturnFileID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @BankReturnFileID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le BankReturnSourceCodeID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @BankReturnSourceCodeID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1
	
			-- Va chercher le BankReturnTypeID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @BankReturnTypeID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS VARCHAR(4))
	
			INSERT INTO @BankReturnLinkTable ( 
				BankReturnCodeID,
				BankReturnFileID,
				BankReturnSourceCodeID,
				BankReturnTypeID)
			VALUES (
				@BankReturnCodeID,
				@BankReturnFileID,
				@BankReturnSourceCodeID,
				@BankReturnTypeID)
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
