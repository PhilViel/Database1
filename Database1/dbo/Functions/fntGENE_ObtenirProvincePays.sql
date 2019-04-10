/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntGENE_ObtenirProvincePays
Nom du service		: Obtenir la province et le pays d’une adresse
But 				: Obtenir la province et le pays d’une adresse à partir du nom de la province ou du nom de la ville.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcNom_Province				Nom de la province de l’adresse
						vcNom_Ville					Nom de la ville de l’adresse
						cCode_Pays					Code du pays de l'adresse

Exemple d’appel		:	SELECT * FROM [dbo].[fntGENE_ObtenirProvincePays]('Québec', 'Trois-Rivières','CAN','G1S2P4')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							vcCode_Province					Code de la province.
						S/O							vcNom_Province					Nom de la province.
						S/O							cCode_Pays						Code du pays.
						S/O							vcNom_Pays						Nom du pays.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-05-29		Éric Deshaies						Création du service							
		2009-02-05		Éric Deshaies						Transformer la fonction scalar en fonction
															table.
		2009-03-18		Éric Deshaies						Utiliser le code postal canadien pour
															déterminer la province et le pays
		2011-03-25		Éric Deshaies						Ajouter des conditions supplémentaires
															pour utiliser le code postal pour déterminer
															la province canadienne.

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_ObtenirProvincePays]
(
	@vcNom_Province VARCHAR(75),
	@vcNom_Ville VARCHAR(100),
	@cCode_Pays CHAR(4),
	@vcCode_Postal VARCHAR(10)
)
RETURNS @tblGENE_ProvincePays TABLE
(
	vcCode_Province VARCHAR(75) NULL,
	vcNom_Province VARCHAR(75) NULL,
	cCode_Pays CHAR(4) NULL,
	vcNom_Pays VARCHAR(75) NULL
)
AS
BEGIN
	-- Si les champs sont nul, retourner les champs vides
	IF @vcNom_Province IS NULL AND @vcNom_Ville IS NULL AND @cCode_Pays IS NULL AND @vcCode_Postal IS NULL
		BEGIN
			INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
					VALUES (NULL,NULL,NULL,NULL)
			RETURN
		END

	DECLARE
		@vcCode_Province_TMP VARCHAR(75),
		@vcNom_Province_TMP VARCHAR(75),
		@cCode_Pays_TMP CHAR(4),
		@vcNom_Pays_TMP VARCHAR(75)
	
	-- Rechercher une correspondance avec une province
	SELECT  @vcCode_Province_TMP = S.StateCode,
			@vcNom_Province_TMP = S.StateName,
			@cCode_Pays_TMP = S.CountryID,
			@vcNom_Pays_TMP = P.CountryName
	FROM Mo_State S
		 JOIN Mo_Country P ON P.CountryID = S.CountryID
	WHERE UPPER(LTRIM(RTRIM(S.StateName))) = UPPER(LTRIM(RTRIM(@vcNom_Province)))
	
	IF @vcNom_Province_TMP IS NOT NULL AND @vcNom_Province_TMP <> ''
		BEGIN
			INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
					VALUES (@vcCode_Province_TMP,@vcNom_Province_TMP,@cCode_Pays_TMP,@vcNom_Pays_TMP)
			RETURN
		END
	
	-- Utiliser le code postal canadien pour déterminer la province et le pays
	SET @vcCode_Postal = LTRIM(RTRIM(REPLACE(ISNULL(@vcCode_Postal,''),' ','')))
	IF LEN(@vcCode_Postal) = 6 AND
	   (@cCode_Pays = 'CAN' OR (UPPER(SUBSTRING(@vcCode_Postal,1,1)) >= 'A' AND UPPER(SUBSTRING(@vcCode_Postal,1,1)) <= 'Z' AND
								UPPER(SUBSTRING(@vcCode_Postal,2,1)) >= '0' AND UPPER(SUBSTRING(@vcCode_Postal,2,1)) <= '9' AND
								UPPER(SUBSTRING(@vcCode_Postal,3,1)) >= 'A' AND UPPER(SUBSTRING(@vcCode_Postal,3,1)) <= 'Z' AND
								UPPER(SUBSTRING(@vcCode_Postal,4,1)) >= '0' AND UPPER(SUBSTRING(@vcCode_Postal,4,1)) <= '9' AND
								UPPER(SUBSTRING(@vcCode_Postal,5,1)) >= 'A' AND UPPER(SUBSTRING(@vcCode_Postal,5,1)) <= 'Z' AND
								UPPER(SUBSTRING(@vcCode_Postal,6,1)) >= '0' AND UPPER(SUBSTRING(@vcCode_Postal,6,1)) <= '9'))
		BEGIN
			SET @vcCode_Postal = UPPER(SUBSTRING(@vcCode_Postal,1,1))
			SELECT @vcCode_Province_TMP = CASE
												WHEN @vcCode_Postal IN ('J','G','H') THEN 'QC'
												WHEN @vcCode_Postal = 'E' THEN 'NB'
												WHEN @vcCode_Postal IN ('K','L','M','N','P') THEN 'ON' 
												WHEN @vcCode_Postal = 'A' THEN 'NL'
												WHEN @vcCode_Postal = 'B' THEN 'NS'
												WHEN @vcCode_Postal = 'C' THEN 'PE'
												WHEN @vcCode_Postal = 'R' THEN 'MB'
												WHEN @vcCode_Postal = 'S' THEN 'SK'
												WHEN @vcCode_Postal = 'T' THEN 'AB'
												WHEN @vcCode_Postal = 'V' THEN 'BC'
												WHEN @vcCode_Postal = 'Y' THEN 'YT'
												WHEN @vcCode_Postal = 'X' THEN 'NT'
												ELSE NULL
										  END

			IF @vcCode_Province_TMP IS NOT NULL
				BEGIN
					SELECT  @vcNom_Province_TMP = S.StateName,
							@cCode_Pays_TMP = S.CountryID,
							@vcNom_Pays_TMP = P.CountryName
					FROM Mo_State S
						 JOIN Mo_Country P ON P.CountryID = S.CountryID
					WHERE S.StateCode = @vcCode_Province_TMP

					INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
							VALUES (@vcCode_Province_TMP,@vcNom_Province_TMP,@cCode_Pays_TMP,@vcNom_Pays_TMP)
					RETURN
				END
		END

	-- Rechercher une correspondance avec une ville
	SELECT  @vcCode_Province_TMP = S.StateCode,
			@vcNom_Province_TMP = S.StateName,
			@cCode_Pays_TMP = S.CountryID,
			@vcNom_Pays_TMP = P.CountryName
	FROM Mo_City V
		 JOIN Mo_State S ON S.StateID = V.StateID 
		 JOIN Mo_Country P ON P.CountryID = S.CountryID
	WHERE UPPER(LTRIM(RTRIM(V.CityName))) = UPPER(LTRIM(RTRIM(@vcNom_Ville)))
	  AND ISNULL(V.CountryID,'') = ISNULL(@cCode_Pays,'')
	
	IF @vcNom_Province_TMP IS NOT NULL AND @vcNom_Province_TMP <> ''
		BEGIN
			INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
					VALUES (@vcCode_Province_TMP,@vcNom_Province_TMP,@cCode_Pays_TMP,@vcNom_Pays_TMP)
			RETURN
		END

	-- Rechercher une correspondance avec une province d'une fusion de ville
	SELECT  @vcCode_Province_TMP = S.StateCode,
			@vcNom_Province_TMP = S.StateName,
			@cCode_Pays_TMP = S.CountryID,
			@vcNom_Pays_TMP = P.CountryName
	FROM Mo_CityFusion F
		 JOIN Mo_State S ON S.StateID = F.StateID 
		 JOIN Mo_Country P ON P.CountryID = S.CountryID
	WHERE UPPER(LTRIM(RTRIM(F.OldCityName))) = UPPER(LTRIM(RTRIM(@vcNom_Ville)))
	
	IF @vcNom_Province_TMP IS NOT NULL AND @vcNom_Province_TMP <> ''
		BEGIN
			INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
					VALUES (@vcCode_Province_TMP,@vcNom_Province_TMP,@cCode_Pays_TMP,@vcNom_Pays_TMP)
			RETURN
		END

	-- Rechercher une correspondance avec une province d'une ville d'une fusion de ville
	SELECT  @vcCode_Province_TMP = S.StateCode,
			@vcNom_Province_TMP = S.StateName,
			@cCode_Pays_TMP = S.CountryID,
			@vcNom_Pays_TMP = P.CountryName
	FROM Mo_CityFusion F
		 JOIN Mo_City V ON V.CityID = F.CityID
		 JOIN Mo_State S ON S.StateID = V.StateID 
		 JOIN Mo_Country P ON P.CountryID = S.CountryID
	WHERE UPPER(LTRIM(RTRIM(F.OldCityName))) = UPPER(LTRIM(RTRIM(@vcNom_Ville)))
	
	IF @vcNom_Province_TMP IS NOT NULL AND @vcNom_Province_TMP <> ''
		BEGIN
			INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
					VALUES (@vcCode_Province_TMP,@vcNom_Province_TMP,@cCode_Pays_TMP,@vcNom_Pays_TMP)
			RETURN
		END

	-- Rechercher le pays avec une correspondance avec une ville
	SELECT  @vcCode_Province_TMP = '',
			@vcNom_Province_TMP = '',
			@cCode_Pays_TMP = P.CountryID,
			@vcNom_Pays_TMP = P.CountryName
	FROM Mo_City V
		 JOIN Mo_Country P ON P.CountryID = V.CountryID
	WHERE UPPER(LTRIM(RTRIM(V.CityName))) = UPPER(LTRIM(RTRIM(@vcNom_Ville)))
	
	IF @vcNom_Pays_TMP IS NOT NULL AND @vcNom_Pays_TMP <> ''
		BEGIN
			INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
					VALUES (@vcCode_Province_TMP,@vcNom_Province_TMP,@cCode_Pays_TMP,@vcNom_Pays_TMP)
			RETURN
		END

	-- Rechercher le pays avec une correspondance avec une fusion de ville
	SELECT  @vcCode_Province_TMP = '',
			@vcNom_Province_TMP = '',
			@cCode_Pays_TMP = P.CountryID,
			@vcNom_Pays_TMP = P.CountryName
	FROM Mo_CityFusion F
		 JOIN Mo_City V ON V.CityID = F.CityID
		 JOIN Mo_Country P ON P.CountryID = V.CountryID
	WHERE UPPER(LTRIM(RTRIM(F.OldCityName))) = UPPER(LTRIM(RTRIM(@vcNom_Ville)))
	
	IF @vcNom_Pays_TMP IS NOT NULL AND @vcNom_Pays_TMP <> ''
		BEGIN
			INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
					VALUES (@vcCode_Province_TMP,@vcNom_Province_TMP,@cCode_Pays_TMP,@vcNom_Pays_TMP)
			RETURN
		END

	IF @cCode_Pays IS NOT NULL
		BEGIN
			SELECT  @vcCode_Province_TMP = '',
					@vcNom_Province_TMP = '',
					@cCode_Pays_TMP = P.CountryID,
					@vcNom_Pays_TMP = P.CountryName
			FROM Mo_Country P
			WHERE P.CountryID = @cCode_Pays

			IF @vcNom_Pays_TMP IS NOT NULL AND @vcNom_Pays_TMP <> ''
				BEGIN
					INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
							VALUES (@vcCode_Province_TMP,@vcNom_Province_TMP,@cCode_Pays_TMP,@vcNom_Pays_TMP)
					RETURN
				END
		END

	INSERT INTO @tblGENE_ProvincePays (vcCode_Province,vcNom_Province,cCode_Pays,vcNom_Pays)
		VALUES (NULL,NULL,NULL,NULL)
	RETURN
END
