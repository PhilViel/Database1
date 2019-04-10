/****************************************************************************************************
Code de service		:		fn_Mo_FormatStringWithoutAccent
Nom du service		:		Ce service est utilisé pour remplacer les caractères accentués
But					:		Remplacer les caractères accentués par leur équivalent
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@FString					Chaîne de caractère

Exemple d'appel:
                SELECT dbo.fn_Mo_FormatStringWithoutAccent('À,Á,Â,Ã,Ä,Å-È,É,Ê,Ë-Ì,Í,Î,Ï-Ò,Ó,Ô,Õ,Ö-Ù,Ù,Ú,Û,Ü-Ý-Ñ-Ç')

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
						N/A							@NewString									Chaîne de caractère sans accent
													
Historique des modifications :
			
						Date			Programmeur					Description							Référence
						----------		-------------------------	----------------------------		---------------
						2015-10-08		Stéphane Barbeau			Création du service
						2015-10-22		Steeve Picard				Différentie les majuscules & minuscules
						2015-06-01          Steeve Picard                 Légère optimisation des boucles WHILE
*****************************************************************************************************/
CREATE FUNCTION [dbo].[fn_Mo_FormatStringWithoutAccent] (
	@FString	varchar(max)
)
RETURNS MoDesc AS
BEGIN
	DECLARE	@i		int,
			@FChar 	varchar,
			@ListeChar varchar(20),
			@SearchChar varchar(1),
			@ReplaceChar varchar(1),
			@NewString  varchar(max)

	IF LTrim(IsNull(@FString, '')) = ''
		RETURN('')

	SET @NewString = @FString;

	SET @ListeChar = Replace('Å,À,Á,Â,Ã,Ä', ',', '')
	WHILE 1 = 1
	BEGIN
        SET @i = PatIndex('%[' + Lower(@ListeChar) + @ListeChar + ']%', @NewString)
        IF @i = 0
            BREAK
	   SET @ReplaceChar = 'A'
	   SET @SearchChar = Substring(@NewString, @i, 1)
	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Upper(@SearchChar), Upper(@ReplaceChar))
	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Lower(@SearchChar), Lower(@ReplaceChar))
	END

	SET @ListeChar = Replace('È,É,Ê,Ë', ',', '')
	WHILE 1 = 1
	BEGIN
        SET @i = PatIndex('%[' + @ListeChar + ']%', @NewString)
        IF @i = 0
            BREAK
	   SET @ReplaceChar = 'E'
	   SET @SearchChar = Substring(@NewString, @i, 1)
	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Upper(@SearchChar), Upper(@ReplaceChar))
	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Lower(@SearchChar), Lower(@ReplaceChar))
	END

	SET @ListeChar = Replace('Ì,Í,Î,Ï', ',', '')
	WHILE 1 = 1
	BEGIN
        SET @i = PatIndex('%[' + @ListeChar + ']%', @NewString)
        IF @i = 0
            BREAK
	   SET @ReplaceChar = 'I'
	   SET @SearchChar = Substring(@NewString, @i, 1)
	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Upper(@SearchChar), Upper(@ReplaceChar))
	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Lower(@SearchChar), Lower(@ReplaceChar))
	END

	SET @ListeChar = Replace('Ò,Ó,Ô,Õ,Ö', ',', '')
	WHILE 1 = 1
	BEGIN
        SET @i = PatIndex('%[' + @ListeChar + ']%', @NewString)
        IF @i = 0
            BREAK
	   SET @ReplaceChar = 'O'
	   SET @SearchChar = Substring(@NewString, @i, 1)
	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Upper(@SearchChar), Upper(@ReplaceChar))
	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Lower(@SearchChar), Lower(@ReplaceChar))
	END

	SELECT	@ListeChar = Replace('Ù,Ú,Û,Ü', ',', '')
	WHILE 1 = 1
	BEGIN
        SET @i = PatIndex('%[' + @ListeChar + ']%', @NewString)
        IF @i = 0
            BREAK
	   SET @ReplaceChar = 'U'
	   SET @SearchChar = Substring(@NewString, @i, 1)

	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Upper(@SearchChar), Upper(@ReplaceChar))
	   SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Lower(@SearchChar), Lower(@ReplaceChar))
	END

	SET @SearchChar = 'Ý'
     SET @i = PatIndex('%[' + @SearchChar + ']%', @NewString)
	IF @i > 0
	BEGIN
		SET @ReplaceChar = 'Y'
		SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Upper(@SearchChar), Upper(@ReplaceChar))
		SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Lower(@SearchChar), Lower(@ReplaceChar))
	END

	SET @SearchChar = 'Ñ'
     SET @i = PatIndex('%[' + @SearchChar + ']%', @NewString)
	IF @i > 0
	BEGIN
		SET @ReplaceChar = 'N'
		SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Upper(@SearchChar), Upper(@ReplaceChar))
		SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Lower(@SearchChar), Lower(@ReplaceChar))
	END

	SET @SearchChar = 'Ç'
     SET @i = PatIndex('%[' + @SearchChar + ']%', @NewString)
	IF @i > 0
	BEGIN
		SET @ReplaceChar = 'C'
		SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Upper(@SearchChar), Upper(@ReplaceChar))
		SET @NewString = Replace(@NewString COLLATE Latin1_General_CS_AS, Lower(@SearchChar), Lower(@ReplaceChar))
	END

	RETURN(@NewString)
END
