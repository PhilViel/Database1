/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SP_TT_CRQ_FormatTextOfLog
Description         :	Format le texte contenu dans un log pour qu'il soit compréhensible pour un usager.
Valeurs de retours  :	@ReturnValue :
									>0  : ID du blob et tout à fonctionné
	                     	<=0 : Erreur SQL 
Note                :	ADX0000591	IA	2004-11-22	Bruno Lapointe		Création
						ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
										2008-11-24	Josée Parent		Modification pour tenir compte du LOG des fusions
										2008-12-10  Patrick Robitaille	Changer la longueur de la description du champ 
																		de 30 à 35  caractères pour accomoder certains 
																		champs plus longs du profil souscripteur
										2011-04-14	Corentin Menthonnex	2011-12 : Il restait une variable de 30 caractères ce qui 
																		faisait un bug pour les variables de plus de 30.
										2012-09-11	Donald Huppé		Il arrive que @vcLine contient seulement char(30) (séparateur).
																		Dans ce cas, on passe à la ligne suivante
										2015-06-30  Steve Picard		Renomme les variable New & Old car étaient inversées
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_TT_CRQ_FormatTextOfLog] (
	@LogID INTEGER, -- ID Unique du log
	@LogActionShortName CHAR(1), -- Type de log
	@LogTableName VARCHAR(75), -- Table sur laquelle le log est liée
	@LangID CHAR(3)) -- Langue désirée pour les descriptions
AS
BEGIN
	DECLARE 
		@iBlobID INTEGER,
		@bnBlob BINARY(16),
		@vcLine VARCHAR(8000),
		@vcNewLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		@iBlobLength INTEGER,
		@vcColumnName VARCHAR(75),
		@vcColumnDesc VARCHAR(75),
		@vcHeaderNewValue VARCHAR(75),
		@vcHeaderOldValue VARCHAR(75),
		@vcNewValues VARCHAR(100),
		@vcOldValues VARCHAR(100)

	INSERT INTO CRQ_Blob (
		Blob)
		SELECT
			LogText
		FROM CRQ_Log
		WHERE LogID = @LogID AND LogText IS NOT NULL

	IF @@ERROR = 0 AND @@ROWCOUNT > 0
	BEGIN
		SET @iBlobID = SCOPE_IDENTITY()

		-- Va chercher les lignes contenus dans le blob
		DECLARE crLinesOfBlob CURSOR FOR
			SELECT Val
			FROM dbo.FN_CRQ_LinesOfBlob(@iBlobID)
			WHERE ISNULL(Val, '') <> ''
			
		OPEN crLinesOfBlob
		
		-- Vide le blob temporaire après avoir mis son contenu dans le curseur
		UPDATE CRQ_Blob
		SET Blob = ''
		WHERE BlobID = @iBlobID
	
		-- Crée un pointeur sur le blob.
		SELECT @bnBlob = TEXTPTR(Blob)
		FROM CRQ_Blob
		WHERE BlobID = @iBlobID

		SET @vcHeaderNewValue = ''
		SELECT -- Regarde s'il y a une description usager de la variable générale.
			@vcHeaderNewValue = ColumnDesc
		FROM CRQ_ColumnDesc
		WHERE TableName = 'GENERAL'
			AND ColumnName = 'NewValue'
			AND LangID = @LangID
	
		SET @vcHeaderOldValue = ''
		SELECT -- Regarde s'il y a une description usager de la variable générale.
			@vcHeaderOldValue = ColumnDesc
		FROM CRQ_ColumnDesc
		WHERE TableName = 'GENERAL'
			AND ColumnName = 'OldValue'
			AND LangID = @LangID
	
		-- Fait la ligne d'entête de colonne
		IF @LogActionShortName = 'I' AND
			@vcHeaderNewValue <> ''
			SET @vcNewLine = CAST(' ' AS CHAR(37))+CAST(@vcHeaderNewValue AS CHAR(35))+CHAR(13)+CHAR(10)
	
		IF @LogActionShortName = 'U' AND
			@vcHeaderNewValue <> '' AND
			@vcHeaderOldValue <> ''
			SET @vcNewLine = CAST(' ' AS CHAR(37))+CAST(@vcHeaderOldValue AS CHAR(37))+CAST(@vcHeaderNewValue AS CHAR(35))+CHAR(13)+CHAR(10)

		IF @LogActionShortName = 'F' AND
			@vcHeaderNewValue <> '' AND
			@vcHeaderOldValue <> ''
			SET @vcNewLine = CAST(' ' AS CHAR(37))+CAST(@vcHeaderOldValue AS CHAR(37))+CAST(@vcHeaderNewValue AS CHAR(35))+CHAR(13)+CHAR(10)
	
		IF @LogActionShortName = 'D' AND
			@vcHeaderOldValue <> ''
			SET @vcNewLine = CAST(' ' AS CHAR(37))+CAST(@vcHeaderOldValue AS CHAR(35))+CHAR(13)+CHAR(10)
	
		-- Va chercher la grandeur actuelle du blob
		SELECT @iBlobLength = DATALENGTH(Blob)
		FROM CRQ_Blob
		WHERE BlobID = @iBlobID

		-- Inscrit la ligne d'entête dans le blob
		UPDATETEXT CRQ_Blob.Blob @bnBlob @iBlobLength 0 @vcNewLine 

		-- Va chercher la première ligne			
		FETCH NEXT FROM crLinesOfBlob
		INTO
			@vcLine
		
		WHILE @@FETCH_STATUS = 0
				-- La ligne ne doit pas commencer par un séparateur char(30), sinon c'est illogique. 
				-- Alors on passe au prochain enregistrement
				/*2012-09-11*/ and ascii(@vcLine) <> 30 /*2012-09-11*/
		
		
		BEGIN
			SET @vcNewLine = ''
	
			-- Positionne sur le premier caractère
			SET @iPos = 1
	
			-- Va chercher le nom du champs
			SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
			SET @vcColumnDesc = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS VARCHAR(35)) -- 2011-12 : +/- CM
			SET @vcColumnName = @vcColumnDesc
			SELECT -- Regarde s'il y a une description usager du nom de colonne.
				@vcColumnDesc = ColumnDesc
			FROM CRQ_ColumnDesc
			WHERE TableName = @LogTableName
				AND ColumnName = @vcColumnName
				AND LangID = @LangID
			SET @vcNewLine = @vcNewLine + CAST(@vcColumnDesc AS CHAR(35))
			SET @iPos = @iEndPos + 1
	
			IF @LogActionShortName = 'I'
			BEGIN
				-- Va chercher la nouvelle valeur 
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				SET @vcNewValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
				SET @iPos = @iEndPos + 1

				-- Regarde s'il y a des valeurs remplacentes.  Une valeur remplacentes est une valeur plus compréhensible pour l'usager (Ex: Au lieu de 'FRA' on met 'Français')
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				IF @iEndPos	> 0
					SET @vcNewValues = SUBSTRING(@vcLine, @iPos, Case when @iEndPos - @iPos < 0 then 0 else @iEndPos - @iPos end)

				-- Ajoute la valeur à la ligne
				IF @vcColumnName = 'PasswordID'
					SET @vcNewLine = @vcNewLine+'  '+CAST('********' AS CHAR(35))+CHAR(13)+CHAR(10)
				ELSE
					SET @vcNewLine = @vcNewLine+'  '+CAST(@vcNewValues AS CHAR(35))+CHAR(13)+CHAR(10)
			END
			IF @LogActionShortName = 'U'
			BEGIN
				-- Va chercher l'ancienne valeur
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				SET @vcOldValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
				SET @iPos = @iEndPos + 1

				-- Va chercher la nouvelle valeur 
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				SET @vcNewValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
				SET @iPos = @iEndPos + 1

				-- Regarde s'il y a des valeurs remplacentes.  Une valeur remplacentes est une valeur plus compréhensible pour l'usager (Ex: Au lieu de 'FRA' on met 'Français')
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				IF @iEndPos	> 0
				BEGIN
					SET @vcOldValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
					SET @iPos = @iEndPos + 1

					-- Regarde s'il y a des valeurs remplacentes.  Une valeur remplacentes est une valeur plus compréhensible pour l'usager (Ex: Au lieu de 'FRA' on met 'Français')
					SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
					IF @iEndPos	> 0
						SET @vcNewValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
				END

				-- Ajoute les valeurs à la ligne
				IF @vcColumnName = 'PasswordID'
					SET @vcNewLine = @vcNewLine+'  '+CAST('********' AS CHAR(35))+'  '+CAST('********' AS CHAR(35))+CHAR(13)+CHAR(10)
				ELSE
					SET @vcNewLine = @vcNewLine+'  '+CAST(@vcOldValues AS CHAR(35))+'  '+CAST(@vcNewValues AS CHAR(35))+CHAR(13)+CHAR(10)
			END
			IF @LogActionShortName = 'F'
			BEGIN
				-- Va chercher l'ancienne valeur
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				SET @vcOldValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
				SET @iPos = @iEndPos + 1

				-- Va chercher la nouvelle valeur 
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				SET @vcNewValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
				SET @iPos = @iEndPos + 1

				-- Regarde s'il y a des valeurs remplacentes.  Une valeur remplacentes est une valeur plus compréhensible pour l'usager (Ex: Au lieu de 'FRA' on met 'Français')
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				IF @iEndPos	> 0
				BEGIN
					SET @vcOldValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
					SET @iPos = @iEndPos + 1

					-- Regarde s'il y a des valeurs remplacentes.  Une valeur remplacentes est une valeur plus compréhensible pour l'usager (Ex: Au lieu de 'FRA' on met 'Français')
					SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
					IF @iEndPos	> 0
						SET @vcNewValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
				END

				-- Ajoute les valeurs à la ligne
				IF @vcColumnName = 'PasswordID'
					SET @vcNewLine = @vcNewLine+'  '+CAST('********' AS CHAR(35))+'  '+CAST('********' AS CHAR(35))+CHAR(13)+CHAR(10)
				ELSE
					SET @vcNewLine = @vcNewLine+'  '+CAST(@vcOldValues AS CHAR(35))+'  '+CAST(@vcNewValues AS CHAR(35))+CHAR(13)+CHAR(10)
			END
			IF @LogActionShortName = 'D'
			BEGIN
				-- Va chercher l'ancienne valeur 
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				SET @vcOldValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
				SET @iPos = @iEndPos + 1

				-- Regarde s'il y a des valeurs remplacentes.  Une valeur remplacentes est une valeur plus compréhensible pour l'usager (Ex: Au lieu de 'FRA' on met 'Français')
				SET @iEndPos = CHARINDEX(CHAR(30), @vcLine, @iPos)
				IF @iEndPos	> 0
					SET @vcOldValues = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)

				-- Ajoute la valeur à la ligne
				IF @vcColumnName = 'PasswordID'
					SET @vcNewLine = @vcNewLine+'  '+CAST('********' AS CHAR(35))+CHAR(13)+CHAR(10)
				ELSE
					SET @vcNewLine = @vcNewLine+'  '+CAST(@vcOldValues AS CHAR(35))+CHAR(13)+CHAR(10)
			END
	
			-- Va chercher la grandeur actuelle du blob
			SELECT @iBlobLength = DATALENGTH(Blob)
			FROM CRQ_Blob
			WHERE BlobID = @iBlobID
	
			UPDATETEXT CRQ_Blob.Blob @bnBlob @iBlobLength 0 @vcNewLine 
	
			-- Passe à la prochaine ligne
			FETCH NEXT FROM crLinesOfBlob
			INTO
				@vcLine
		END
	
		CLOSE crLinesOfBlob
		DEALLOCATE crLinesOfBlob
	END
	ELSE
		SET @iBlobID = -1

	-- Fin des traitements
	RETURN @iBlobID
END
