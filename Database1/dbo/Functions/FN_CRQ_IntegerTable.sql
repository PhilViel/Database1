/****************************************************************************************************

	Fonction DE TRANSFORMATION D'UNE STRING D'ENTIERS EN UNE TABLE D'ENTIERS

*********************************************************************************
	12-05-2004 Dominic Létourneau
		Migration de l'ancienne fonction selon les nouveaux standards
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_IntegerTable (@StringList VARCHAR(8000)) -- Liste d'entiers séparés par des virgules
RETURNS @Table TABLE (Val INTEGER)
AS

BEGIN
	
	-- Variables de travail
	DECLARE 
		@i INTEGER,
		@Pos INTEGER,
		@Num INTEGER,
		@Str VARCHAR(8000)

	-- Initilisation des variables	
	SELECT 
		@Pos = 1,
		@i = 1

	-- Boucle tant qu'il reste des caractères dans la chaîne
	WHILE @i > 0
	BEGIN
	
		SET @i = CHARINDEX(',', @StringList, @Pos)
	
		IF @i > 0
			SET @Str = SUBSTRING(@StringList, @Pos, @i - @Pos)
		ELSE
			SET @Str = SUBSTRING(@StringList, @Pos, LEN(@StringList))
	
		SET @Str = LTRIM(RTRIM(@Str)) -- Enlève les espaces
	
		-- Vérification que la prochaine valeur est bien numérique
		IF @Str LIKE '%[0-9]%' 
			AND (@Str NOT LIKE '%[^0-9]%' OR @Str LIKE '[-+]%' AND SUBSTRING(@Str, 2, LEN(@Str)) NOT LIKE '[-+]%[^0-9]%')
		BEGIN
			SET @Num = CONVERT(INTEGER, @Str)
	
			-- Insertion de la valeur dans la table
			INSERT @Table(Val) 
			VALUES(@Num)
		END
	
		SET @Pos = @i + 1
	
	END

	-- Fin des traitements
	RETURN

END

