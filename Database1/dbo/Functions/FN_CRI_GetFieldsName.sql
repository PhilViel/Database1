/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRI_GetFieldsName
Description 		:	Retourne une table avec tout les noms de champs contenu dans le champ texte passé en paramètre.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000714	IA	2005-09-13	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRI_GetFieldsName (
	@cFieldDelimiter VARCHAR(5), -- Caractère qui sépare les noms de champs
	@txInputString VARCHAR(8000) ) -- La chaîne de caractères qui contient les noms de champs
RETURNS @tFieldName TABLE (
		iFieldNameNumber INTEGER,
		vcFieldName VARCHAR(255)
		)
AS
BEGIN
	DECLARE
		@iDataLength INTEGER,
		@iStartPos INTEGER,
		@iEndPos INTEGER,
		@iFieldNameNumber INTEGER,
		@vcFieldName VARCHAR(255)

	-- Nombre de caractère dans le blob
	SET @iDataLength = DATALENGTH(@txInputString)

	-- Recherche le premier délimiteur de nom de champ
	SET @iStartPos = CHARINDEX(@cFieldDelimiter, @txInputString, 1)
	-- Recherche le deuxième délimiteur de nom de champ.  Celui qui marque la fin du nom du champ
	SET @iEndPos = CHARINDEX(@cFieldDelimiter, @txInputString, @iStartPos+1)
	-- Initialise le compteur de nom de champ
	SET @iFieldNameNumber = 1

	WHILE @iStartPos <> 0
	BEGIN
		IF @iEndPos = 0
			-- Si il n'a pas trouver de délimiteur de fin du nom de champ(dernier nom de champ) il prend la longueur du blob.
			SET @vcFieldName = SUBSTRING(@txInputString, @iStartPos + 1, @iDataLength - @iStartPos)
		ELSE
			-- Lit le nom du champ
			SET @vcFieldName = SUBSTRING(@txInputString, @iStartPos + 1, @iEndPos - @iStartPos - 1)

		-- Insère le nom de champ dans la table.
		INSERT INTO @tFieldName (
			iFieldNameNumber,
			vcFieldName	)
		VALUES (
			@iFieldNameNumber,
			@vcFieldName )

		-- Met la valeur du délimiteur de la fin du nom de champ comme celle de début, car le délimiteur de fin d'un nom de champ est
		-- aussi celui du début du prochain.
		SET @iStartPos = @iEndPos
		-- Va chercher la position du délimiteur de fin du nom de champ du prochain nom de champ
		SET @iEndPos = CHARINDEX(@cFieldDelimiter, @txInputString, @iStartPos+1)
		-- Incrément le numéro du nom de champ.
		SET @iFieldNameNumber = @iFieldNameNumber + 1
	END

	RETURN
END
