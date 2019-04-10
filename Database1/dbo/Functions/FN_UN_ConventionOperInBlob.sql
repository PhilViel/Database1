/****************************************************************************************************
	Fonction qui extrait les opérations sur conventions d'un blob de sauvegarde ou 
	de validation de la gestion d'opérations
*********************************************************************************
	2004-07-02 Bruno Lapointe
		Création
	2004-11-15 Bruno Lapointe
		Ajout du OperID
		IA-ADX0000510
	2008-12-19	Pierre-Luc Simard	Modification pour utiliser la table CRI_Blob au lieu de CRQ_Blob
*********************************************************************************/
CREATE FUNCTION [dbo].[FN_UN_ConventionOperInBlob] (
	@BlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @ConventionOperTable 
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
		@Pos INTEGER,
		@PosOper INTEGER,
		@EndPos INTEGER,
		@StrOper VARCHAR(8000),
		@LigneTrans INTEGER,
		@ConventionOperID INTEGER,
		@OperID INTEGER,
		@ConventionID INTEGER,
		@ConventionOperTypeID VARCHAR(3),
		@ConventionOperAmount MONEY,
		@BlobPos INTEGER,
		@BlobPart VARCHAR(8000),
		@BlobLength INTEGER

	SET @BlobPos = 1

	SELECT 
		@BlobPart = 
			CASE 
				WHEN DATALENGTH (txBlob) < 8000 THEN SUBSTRING(txBlob, @BlobPos, DATALENGTH (txBlob))
			ELSE SUBSTRING(txBlob, @BlobPos, 8000)
			END,
		@BlobLength = DATALENGTH (txBlob)
	FROM CRI_Blob
	WHERE iBlobID = @BlobID


	WHILE @BlobPos < @BlobLength 
	BEGIN
		-- Initilisation des variables	
		SET @PosOper = 1

		-- Boucle tant qu'il reste des caractères dans la chaîne
		WHILE @PosOper > 0
		BEGIN
			-- Recherche la prochaine ligne d'opération du blob
			IF CHARINDEX('Un_ConventionOper', @BlobPart, @PosOper) = 0
				SET @PosOper = 0
			ELSE
			BEGIN
				SET @PosOper = CHARINDEX('Un_ConventionOper', @BlobPart, @PosOper)
	
				SET @EndPos = CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper)
	
				IF @EndPos > 0
				BEGIN
					-- Va chercher la ligne contenant l'opération
					SET @StrOper = SUBSTRING(@BlobPart, @PosOper, @EndPos - @PosOper)
	
					-- Saute la ligne au niveau du blob avant de traité l'opération
					SET @PosOper = @EndPos + 2
	
					-- Début du traitement de l'opération
	
					-- Saute par dessus le nom de la table qui est Un_Oper dans tout les cas
					SET @Pos = CHARINDEX(';', @StrOper, 1) + 1
	
					-- Va chercher le numéro de ligne 
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @LigneTrans = CAST(SUBSTRING(@StrOper, @Pos, @EndPos - @Pos) AS INTEGER)
					SET @Pos = @EndPos + 1
	
					-- Va chercher le ConventionOperID
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @ConventionOperID = CAST(SUBSTRING(@StrOper, @Pos, @EndPos - @Pos) AS INTEGER)
					SET @Pos = @EndPos + 1
	
					-- Va chercher le OperID
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @OperID = CAST(SUBSTRING(@StrOper, @Pos, @EndPos - @Pos) AS INTEGER)
					SET @Pos = @EndPos + 1

					-- Va chercher le ConventionID
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @ConventionID = CAST(SUBSTRING(@StrOper, @Pos, @EndPos - @Pos) AS INTEGER)
					SET @Pos = @EndPos + 1
	
					-- Va chercher le ConventionOperTypeID
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @ConventionOperTypeID = SUBSTRING(@StrOper, @Pos, @EndPos - @Pos)
					SET @Pos = @EndPos + 1

					-- Va chercher le ConventionOperAmount
					SET @EndPos = CHARINDEX(';', @StrOper, @Pos)
					SET @ConventionOperAmount = CAST(SUBSTRING(@StrOper, @Pos, @EndPos - @Pos) AS MONEY)
	
					INSERT INTO @ConventionOperTable ( 
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
					-- Fin du traitement de l'opération
				END	
				ELSE 
					SET @PosOper = 0 -- Il n'y a pas de caractère de fin de ligne, le format du blob est donc incorrect alors il quitte la fonction 
			END
		END
		-- Va chercher la position du dernier retour de chariot
		SET @PosOper = 1
		WHILE CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper) > 0
			SET @PosOper = CHARINDEX(CHAR(13)+CHAR(10), @BlobPart, @PosOper) + 2
		SET @BlobPos = @BlobPos - 2 + @PosOper 

		IF @BlobPos < @BlobLength
			-- Passe à la prochaine section
			SELECT 
				@BlobPart = 
					CASE 
						WHEN @BlobLength < (@BlobPos + 8000) THEN SUBSTRING(txBlob, @BlobPos, @BlobLength - @BlobPos + 1)
					ELSE SUBSTRING(txBlob, @BlobPos, 8000)
					END
			FROM CRI_Blob
			WHERE iBlobID = @BlobID
	END

	-- Fin des traitements
	RETURN
END


