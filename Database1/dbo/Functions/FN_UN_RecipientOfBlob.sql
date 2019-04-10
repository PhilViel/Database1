/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_RecipientOfBlob
Description 		:	Retourne tous les objets de type UN_Recipient contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000925	IA	2006-04-10	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_RecipientOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tRecipientTable 
	TABLE (
		iRecipientID INTEGER, -- ID du destinataire, correspond au HumanID et 0 = ajout.
		FirstName VARCHAR(35), -- Prénom du destinataire
		OrigName VARCHAR(50), -- Nom à la naissance
		Initial VARCHAR(4), -- Initial (Jr, Sr, etc.)
		LastName VARCHAR(50), -- Nom
		BirthDate DATETIME, -- Date de naissance
		DeathDate DATETIME, -- Date du décès
		SexID VARCHAR(1), -- Sexe (code)
		LangID VARCHAR(3), -- Langue (code)
		CivilID VARCHAR(1), -- Statut civil (code)
		SocialNumber VARCHAR(75), -- Numéro d’assurance sociale
		ResidID VARCHAR(4), -- Pays de résidence (code)
		DriverLicenseNo VARCHAR(75), -- Numéro de permis
		WebSite VARCHAR(75), -- Site internet
		CompanyName VARCHAR(75), -- Nom de compagnie
		CourtesyTitle VARCHAR(35), -- Titre de courtoisie (Docteur, Professeur, etc.)
		UsingSocialNumber BIT, -- Droit d’utiliser le NAS.
		SharePersonalInfo BIT, -- Droit de partager les informations personnelles
		MarketingMaterial BIT, -- Veux recevoir le matériel publicitaire.
		IsCompany BIT, -- Compagny ou humain
		InForce DATETIME, -- Date d’entrée en vigueur de l’adresse.
		AdrTypeID VARCHAR(1), -- Type d’adresse (H = humain, C = Compagnie)
		SourceID INTEGER, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
		Address VARCHAR(75), -- # civique, rue et # d’appartement.
		City VARCHAR(100), -- Ville
		StateName VARCHAR(75), -- Province
		CountryID CHAR(4), -- Pays (code)
		ZipCode VARCHAR(10), -- Code postal
		Phone1 VARCHAR(27), -- Tél. résidence
		Phone2 VARCHAR(27), -- Tél. bureau
		Fax VARCHAR(15), -- Fax
		Mobile VARCHAR(15), -- Tél. cellulaire
		WattLine VARCHAR(27), -- Tél. sans frais
		OtherTel VARCHAR(27), -- Autre téléphone.
		Pager VARCHAR(15), -- Paget
		Email VARCHAR(100) ) -- Courriel
AS
BEGIN
	-- Exemple d'encodage d'objet de destinataire qui sont rechercher dans le blob.
	-- UN_Recipient;iRecipientID;FirstName;OrigName;Initial;LastName;BirthDate;DeathDate;SexID;LangID;CivilID;SocialNumber;ResidID;DriverLicenseNo;WebSite;CompanyName;CourtesyTitle;UsingSocialNumber;SharePersonalInfo;MarketingMaterial;IsCompany;InForce;AdrTypeID;SourceID;Address;City;StateName;CountryID;ZipCode;Phone1;Phone2;Fax;Mobile;WattLine;OtherTel;Pager;Email;

	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		@iRecipientID INTEGER, -- ID du destinataire, correspond au HumanID et 0 = ajout.
		@FirstName VARCHAR(35), -- Prénom du destinataire
		@OrigName VARCHAR(50), -- Nom à la naissance
		@Initial VARCHAR(4), -- Initial (Jr, Sr, etc.)
		@LastName VARCHAR(50), -- Nom
		@BirthDate DATETIME, -- Date de naissance
		@DeathDate DATETIME, -- Date du décès
		@SexID VARCHAR(1), -- Sexe (code)
		@LangID VARCHAR(3), -- Langue (code)
		@CivilID VARCHAR(1), -- Statut civil (code)
		@SocialNumber VARCHAR(75), -- Numéro d’assurance sociale
		@ResidID VARCHAR(4), -- Pays de résidence (code)
		@DriverLicenseNo VARCHAR(75), -- Numéro de permis
		@WebSite VARCHAR(75), -- Site internet
		@CompanyName VARCHAR(75), -- Nom de compagnie
		@CourtesyTitle VARCHAR(35), -- Titre de courtoisie (Docteur, Professeur, etc.)
		@UsingSocialNumber BIT, -- Droit d’utiliser le NAS.
		@SharePersonalInfo BIT, -- Droit de partager les informations personnelles
		@MarketingMaterial BIT, -- Veux recevoir le matériel publicitaire.
		@IsCompany BIT, -- Compagny ou humain
		@InForce DATETIME, -- Date d’entrée en vigueur de l’adresse.
		@AdrTypeID VARCHAR(1), -- Type d’adresse (H = humain, C = Compagnie)
		@SourceID INTEGER, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
		@Address VARCHAR(75), -- # civique, rue et # d’appartement.
		@City VARCHAR(100), -- Ville
		@StateName VARCHAR(75), -- Province
		@CountryID CHAR(4), -- Pays (code)
		@ZipCode VARCHAR(10), -- Code postal
		@Phone1 VARCHAR(27), -- Tél. résidence
		@Phone2 VARCHAR(27), -- Tél. bureau
		@Fax VARCHAR(15), -- Fax
		@Mobile VARCHAR(15), -- Tél. cellulaire
		@WattLine VARCHAR(27), -- Tél. sans frais
		@OtherTel VARCHAR(27), -- Autre téléphone.
		@Pager VARCHAR(15), -- Paget
		@Email VARCHAR(100) -- Courriel

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
		IF CHARINDEX('UN_Recipient', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est UN_UnitReduction dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1
	
			-- Va chercher le iRecipientID 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iRecipientID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le FirstName
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @FirstName = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le OrigName
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OrigName = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le Initial
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Initial = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le LastName
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @LastName = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le BirthDate
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @BirthDate = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
			SET @iPos = @iEndPos + 1

			-- Va chercher le DeathDate
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @DeathDate = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
			SET @iPos = @iEndPos + 1

			-- Va chercher le SexID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @SexID = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le LangID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @LangID = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le CivilID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @CivilID = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le SocialNumber
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @SocialNumber = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le ResidID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ResidID = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le DriverLicenseNo
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @DriverLicenseNo = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le WebSite
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @WebSite = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le CompanyName
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @CompanyName = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le CourtesyTitle
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @CourtesyTitle = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le UsingSocialNumber
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @UsingSocialNumber = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le SharePersonalInfo
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @SharePersonalInfo = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le MarketingMaterial
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @MarketingMaterial = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le IsCompany
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @IsCompany = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)
			SET @iPos = @iEndPos + 1

			-- Va chercher le InForce
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @InForce = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS DATETIME)
			SET @iPos = @iEndPos + 1

			-- Va chercher le AdrTypeID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @AdrTypeID = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le SourceID 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @SourceID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le Address
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Address = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le City
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @City = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le StateName
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @StateName = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le CountryID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @CountryID = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le @ZipCode
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ZipCode = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le @Phone1
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Phone1 = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le @Phone2
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Phone2 = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le @Fax
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Fax = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le @Mobile
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Mobile = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le @WattLine
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @WattLine = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le @OtherTel
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OtherTel = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le @Pager
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Pager = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)
			SET @iPos = @iEndPos + 1

			-- Va chercher le @Email
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @Email = SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos)

			INSERT INTO @tRecipientTable ( 
				iRecipientID,
				FirstName,
				OrigName,
				Initial,
				LastName,
				BirthDate,
				DeathDate,
				SexID,
				LangID,
				CivilID,
				SocialNumber,
				ResidID,
				DriverLicenseNo,
				WebSite,
				CompanyName,
				CourtesyTitle,
				UsingSocialNumber,
				SharePersonalInfo,
				MarketingMaterial,
				IsCompany,
				InForce,
				AdrTypeID,
				SourceID,
				Address,
				City,
				StateName,
				CountryID,
				ZipCode,
				Phone1,
				Phone2,
				Fax,
				Mobile,
				WattLine,
				OtherTel,
				Pager,
				Email )
			VALUES (
				@iRecipientID,
				@FirstName,
				@OrigName,
				@Initial,
				@LastName,
				@BirthDate,
				@DeathDate,
				@SexID,
				@LangID,
				@CivilID,
				@SocialNumber,
				@ResidID,
				@DriverLicenseNo,
				@WebSite,
				@CompanyName,
				@CourtesyTitle,
				@UsingSocialNumber,
				@SharePersonalInfo,
				@MarketingMaterial,
				@IsCompany,
				@InForce,
				@AdrTypeID,
				@SourceID,
				@Address,
				@City,
				@StateName,
				@CountryID,
				@ZipCode,
				@Phone1,
				@Phone2,
				@Fax,
				@Mobile,
				@WattLine,
				@OtherTel,
				@Pager,
				@Email )
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

