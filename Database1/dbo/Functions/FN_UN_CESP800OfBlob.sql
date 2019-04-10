/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_CESP800OfBlob
Description 		:	Fonction qui extrait les enregistrements 800 d'un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000811	IA	2006-04-17	Bruno Lapointe	Création
									2008-05-09	Pierre-Luc Simard	Correction pour indiquer que la date de naissance est invalide lorsque le PCEE retourne la valeur 2 ou 3 indiquant que le jour ou le mois n'est pas exact  
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_CESP800OfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tCESP800 
	TABLE (
		vcTransID VARCHAR(15),
		vcErrFieldName VARCHAR(30),
		siCESP800ErrorID SMALLINT,
		tyCESP800SINID SMALLINT,
		bFirstName BIT,
		bLastName BIT,
		bBirthDate BIT,
		bSex BIT)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@vcTransID VARCHAR(15),
		@vcErrFieldName VARCHAR(30),
		@siCESP800ErrorID SMALLINT,
		@tyCESP800SINID SMALLINT,
		@bFirstName BIT,
		@bLastName BIT,
		@bBirthDate BIT,
		@bSex BIT

	-- Découpe le blob en section de moins de 8000 caractères
	DECLARE crLinesOfBlob CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
		
	OPEN crLinesOfBlob
	
	-- Va chercher la première section du blob			
	FETCH NEXT FROM crLinesOfBlob
	INTO
		@vcLine
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF SUBSTRING(@vcLine, 1, 3) = '800'
		BEGIN
			-- Va chercher les valeurs dans la string
			SET @vcTransID = RTRIM(LTRIM(SUBSTRING(@vcLine, 12, 15)))
			SET @vcErrFieldName = RTRIM(LTRIM(SUBSTRING(@vcLine, 42, 30)))
			SET @siCESP800ErrorID = CAST(RTRIM(LTRIM(SUBSTRING(@vcLine, 72, 4))) AS SMALLINT)
			-- Les champs boolean sont utilisé seulement dans le cas de SIN
			IF RTRIM(LTRIM(SUBSTRING(@vcLine, 42, 30))) IN ('SIN','NAS')
			BEGIN
				SET @tyCESP800SINID  = CAST(SUBSTRING(@vcLine, 76, 1) AS SMALLINT)
				SET @bFirstName = CAST(SUBSTRING(@vcLine, 77, 1) AS BIT)
				SET @bLastName = CAST(SUBSTRING(@vcLine, 78, 1) AS BIT)
				--Correction pour indiquer que la date de naissance est invalide lorsque le PCEE retourne la valeur 2 ou 3 indiquant que le jour ou le mois n'est pas exact
				--SET @bBirthDate = CAST(SUBSTRING(@vcLine, 79, 1) AS BIT)
				SET @bBirthDate = CAST(CASE WHEN SUBSTRING(@vcLine, 79, 1) = '1' THEN '1' ELSE '0' END AS BIT)	
				SET @bSex = CAST(SUBSTRING(@vcLine, 80, 1) AS BIT)
			END
			ELSE
			BEGIN
				SET @tyCESP800SINID  = 0
				SET @bFirstName = 0
				SET @bLastName = 0
				SET @bBirthDate = 0
				SET @bSex = 0
			END
	
			INSERT INTO @tCESP800 ( 
				vcTransID,
				vcErrFieldName,
				siCESP800ErrorID,
				tyCESP800SINID ,
				bFirstName,
				bLastName,
				bBirthDate,
				bSex)
			VALUES (
				@vcTransID,
				@vcErrFieldName,
				@siCESP800ErrorID,
				@tyCESP800SINID ,
				@bFirstName,
				@bLastName,
				@bBirthDate,
				@bSex)
		END

		-- Passe à la prochaine section
		FETCH NEXT FROM crLinesOfBlob
		INTO
			@vcLine
	END

	CLOSE crLinesOfBlob
	DEALLOCATE crLinesOfBlob

	-- Fin des traitements
	RETURN
END



