/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_Rep
Description         :	Sauvegarde d'ajouts/modifications de représentant
Valeurs de retours  :	>0  :	Tout à fonctionné
                     	<=0 :	Erreur SQL
Note :					
						ADX0000697	IA	2005-05-05	Bruno Lapointe		Création
						ADX0000848	IA	2006-03-24	Bruno Lapointe		Adaptation des FCB pour PCEE 4.3 
						ADX0001278	IA	2007-03-19	Alain Quirion			Vérification de la province en plus du pays pour la fusion des villes
										2010-02-22	Jean-François Gauthier	Ajout de la sauvegarde du champ iNumeroBDNI
										2014-03-06	Pierre-Luc Simard			Retrait du log des téléphone Pager et Wattline
****************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Rep] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@RepID INTEGER, -- ID du représentant, correspond au HumanID et 0 = ajouR.
	@RepCode VARCHAR(75), -- Numéro d’employé
	@RepLicenseNo VARCHAR(75), -- Numéro de permis
	@BusinessStart MoGetDate, -- Date de début d’affaire
	@BusinessEnd DATETIME, -- Date de fin d’affaire
	@FirstName VARCHAR(35), -- Prénom du tuteur
	@OrigName VARCHAR(50), -- Nom à la naissance
	@Initial VARCHAR(4), -- Initial (Jr, Sr, etc.)
	@LastName VARCHAR(50), -- Nom
	@BirthDate DATETIME, -- Date de naissance
	@DeathDate DATETIME, -- Date du décès
	@SexID MoSex, -- Sexe (code)
	@LangID MoLang, -- Langue (code)
	@CivilID MoCivil, -- Statut civil (code)
	@SocialNumber VARCHAR(75), -- Numéro d’assurance sociale
	@ResidID CHAR(3), -- Pays de résidence (code)
	@DriverLicenseNo VARCHAR(75), -- Numéro de permis
	@WebSite VARCHAR(75), -- Site internet
	@CompanyName VARCHAR(75), -- Nom de compagnie
	@CourtesyTitle VARCHAR(35), -- Titre de courtoisie (Docteur, Professeur, etc.)
	@UsingSocialNumber BIT = 1, -- Droit d’utiliser le NAS.
	@SharePersonalInfo BIT = 1, -- Droit de partager les informations personnelles
	@MarketingMaterial BIT = 1, -- Veux recevoir le matériel publicitaire.
	@IsCompany BIT = 0, -- Compagny ou humain
	@InForce DATETIME, -- Date d’entrée en vigueur de l’adresse.
	@AdrTypeID MoAdrType, -- Type d’adresse (H = humain, C = Compagnie)
	@SourceID INTEGER, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
	@Address VARCHAR(75), -- # civique, rue et # d’appartemenR.
	@City VARCHAR(100), -- Ville
	@StateName VARCHAR(75), -- Province
	@CountryID CHAR(3), -- Pays (code)
	@ZipCode VARCHAR(10), -- Code postal
	@Phone1 VARCHAR(27), -- Tél. résidence
	@Phone2 VARCHAR(27), -- Tél. bureau
	@Fax VARCHAR(15), -- Fax
	@Mobile VARCHAR(15), -- Tél. cellulaire
	@WattLine VARCHAR(27), -- Tél. sans frais
	@OtherTel VARCHAR(27), -- Autre téléphone.
	@Pager VARCHAR(15), -- Paget
	@EMail VARCHAR(100),
	@iNumeroBDNI	INT	= NULL -- Numéro BDNI	
	) -- Courriel
AS
BEGIN
	-- Variables de travail
	DECLARE
		@vcStateCode VARCHAR(75),
		@iErrorID INTEGER,
		-- Variables contenant les anciennes valeurs pour le log
		@iOldRepID INTEGER,
		@vcOldFirstName VARCHAR(35),
		@vcOldOrigName VARCHAR(75),
		@vcOldInitial VARCHAR(4),
		@vcOldLastName VARCHAR(50),
		@dtOldBirthDate DATETIME,
		@dtOldDeathDate DATETIME,
		@cOldSexID MoSex,
		@cOldLangID MoLang,
		@cOldCivilID MoCivil,
		@vcOldSocialNumber VARCHAR(75),
		@cOldResidID CHAR(3),
		@vcOldDriverLicenseNo VARCHAR(75),
		@vcOldWebSite VARCHAR(75),
		@vcOldCompanyName VARCHAR(75),
		@vcOldCourtesyTitle VARCHAR(35),
		@bOldUsingSocialNumber BIT,
		@bOldSharePersonalInfo BIT,
		@bOldMarketingMaterial BIT,
		@bOldIsCompany BIT,
		@dtOldInForce DATETIME,
		@vcOldAddress VARCHAR(75),
		@vcOldCity VARCHAR(100),
		@vcOldStateName VARCHAR(75),
		@cOldCountryID CHAR(3),
		@vcOldZipCode VARCHAR(10),
		@vcOldPhone1 VARCHAR(27),
		@vcOldPhone2 VARCHAR(27),
		@vcOldFax VARCHAR(15),
		@vcOldMobile VARCHAR(15),
		@vcOldWattLine VARCHAR(27),
		@vcOldOtherTel VARCHAR(27),
		@vcOldPager VARCHAR(15),
		@vcOldEMail VARCHAR(100),
		@vcOldRepCode VARCHAR(75),
		@vcOldRepLicenseNo VARCHAR(75),
		@dtOldBusinessStart DATETIME,
		@dtOldBusinessEnd DATETIME,
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1),
		@iOldNumeroBDNI	INT

	SET @cSep = CHAR(30)

	IF @BusinessStart <= 0
		SET @BusinessStart = NULL
	IF @BusinessEnd <= 0
		SET @BusinessEnd = NULL

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			print 'TRIGGER IGNORE : ' + isnull(OBJECT_NAME(@@PROCID),'<N/A>')
			RETURN
		END
	END

	-- Empêche le trigger de exécuter à nouveau
	INSERT INTO #DisableTrigger VALUES('TMo_Human_Log')		

	-----------------	
	BEGIN TRANSACTION
	-----------------

	-- Va chercher les anciennes valeurs s'il y en a
	SELECT
		@iOldRepID = R.RepID,
		@vcOldFirstName = H.FirstName,
		@vcOldOrigName = H.OrigName,
		@vcOldInitial = H.Initial,
		@vcOldLastName = H.LastName,
		@dtOldBirthDate = H.BirthDate,
		@dtOldDeathDate = H.DeathDate,
		@cOldSexID = H.SexID,
		@cOldLangID = H.LangID,
		@cOldCivilID = H.CivilID,
		@vcOldSocialNumber = H.SocialNumber,
		@cOldResidID = H.ResidID,
		@vcOldDriverLicenseNo = H.DriverLicenseNo,
		@vcOldWebSite = H.WebSite,
		@vcOldCompanyName = H.CompanyName,
		@vcOldCourtesyTitle = H.CourtesyTitle,
		@bOldUsingSocialNumber = H.UsingSocialNumber,
		@bOldSharePersonalInfo = H.SharePersonalInfo,
		@bOldMarketingMaterial = H.MarketingMaterial,
		@bOldIsCompany = H.IsCompany,
		@dtOldInForce = A.InForce,
		@vcOldAddress = A.Address,
		@vcOldCity = A.City,
		@vcOldStateName = A.StateName,
		@cOldCountryID = A.CountryID,
		@vcOldZipCode = A.ZipCode,
		@vcOldPhone1 = A.Phone1,
		@vcOldPhone2 = A.Phone2,
		@vcOldFax = A.Fax,
		@vcOldMobile = A.Mobile,
		@vcOldWattLine = A.WattLine,
		@vcOldOtherTel = A.OtherTel,
		@vcOldPager = A.Pager,
		@vcOldEMail = A.EMail,
		@vcOldRepCode = R.RepCode,
		@vcOldRepLicenseNo = R.RepLicenseNo,
		@dtOldBusinessStart = R.BusinessStart,
		@dtOldBusinessEnd = R.BusinessEnd,
		@iOldNumeroBDNI	= R.iNumeroBDNI
	FROM Un_Rep R
	JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	WHERE R.RepID = @RepID
	  AND (	@RepID > 0 
			)
  
	-- Recherche d'une fusion existante pour le nom de ville en paramètre
	IF EXISTS (
			SELECT *
			FROM Mo_CityFusion F
			LEFT JOIN Mo_State S ON S.StateID = F.StateID
			JOIN Mo_City C ON C.CityID = F.CityID
			WHERE F.OldCityName = @City
			  AND C.CountryID = @CountryID			 
			  AND ISNULL(S.StateName,'') = ISNULL(@StateName,''))
	BEGIN
		SELECT 
			@City = C.CityName
		FROM Mo_CityFusion F
		LEFT JOIN Mo_State S ON S.StateID = F.StateID
		JOIN Mo_City C ON C.CityID = F.CityID		
		WHERE F.OldCityName = @City
			AND C.CountryID = @CountryID	
			AND ISNULL(S.StateName,'') = ISNULL(@StateName,'')
	END

	-- Création des dossiers dans Mo_Human et Mo_Adresse
	EXECUTE @RepID = SP_IU_CRQ_Human
		@ConnectID,
		@RepID,
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
		@EMail
		
	IF @RepID > 0
	BEGIN
		IF NOT EXISTS 
				(
				SELECT RepID
				FROM Un_Rep
				WHERE RepID = @RepID
				)
		BEGIN
			INSERT Un_Rep (
				RepID,
				RepCode,
				RepLicenseNo,
				BusinessStart,
				BusinessEnd,
				iNumeroBDNI)
			VALUES (
				@RepID,
				@RepCode,
				@RepLicenseNo,
				@BusinessStart,
				@BusinessEnd,
				@iNumeroBDNI)

			-- Insère un log de l'objet inséré.
			INSERT INTO CRQ_Log (
				ConnectID,
				LogTableName,
				LogCodeID,
				LogTime,
				LogActionID,
				LogDesc,
				LogText)
				SELECT
					@ConnectID,
					'Un_Rep',
					@RepID,
					GETDATE(),
					LA.LogActionID,
					LogDesc = 'Représentant : '+H.LastName+', '+H.FirstName,
					LogText =
						CASE 
							WHEN ISNULL(H.FirstName,'') = '' THEN ''
						ELSE 'FirstName'+@cSep+H.FirstName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.LastName,'') = '' THEN ''
						ELSE 'LastName'+@cSep+H.LastName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.OrigName,'') = '' THEN ''
						ELSE 'OrigName'+@cSep+H.OrigName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.Initial,'') = '' THEN ''
						ELSE 'Initial'+@cSep+H.Initial+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.BirthDate,0) <= 0 THEN ''
						ELSE 'BirthDate'+@cSep+CONVERT(CHAR(10), H.BirthDate, 20)+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.DeathDate,0) <= 0 THEN ''
						ELSE 'DeathDate'+@cSep+CONVERT(CHAR(10), H.DeathDate, 20)+@cSep+CHAR(13)+CHAR(10)
						END+
						'LangID'+@cSep+H.LangID+@cSep+L.LangName+@cSep+CHAR(13)+CHAR(10)+
						'SexID'+@cSep+H.SexID+@cSep+S.SexName+@cSep+CHAR(13)+CHAR(10)+
						'CivilID'+@cSep+H.CivilID+@cSep+CS.CivilStatusName+@cSep+CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(H.SocialNumber,'') = '' THEN ''
						ELSE 'SocialNumber'+@cSep+H.SocialNumber+@cSep+CHAR(13)+CHAR(10)
						END+
						'ResidID'+@cSep+H.ResidID+@cSep+Re.CountryName+@cSep+CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(H.DriverLicenseNo,'') = '' THEN ''
						ELSE 'DriverLicenseNo'+@cSep+H.DriverLicenseNo+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.WebSite,'') = '' THEN ''
						ELSE 'WebSite'+@cSep+H.WebSite+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.CompanyName,'') = '' THEN ''
						ELSE 'CompanyName'+@cSep+H.CompanyName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(H.CourtesyTitle,'') = '' THEN ''
						ELSE 'CourtesyTitle'+@cSep+H.CourtesyTitle+@cSep+CHAR(13)+CHAR(10)
						END+
						'UsingSocialNumber'+@cSep+CAST(ISNULL(H.UsingSocialNumber,1) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(H.UsingSocialNumber,1) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'SharePersonalInfo'+@cSep+CAST(ISNULL(H.SharePersonalInfo,1) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(H.SharePersonalInfo,1) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'MarketingMaterial'+@cSep+CAST(ISNULL(H.MarketingMaterial,1) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(H.MarketingMaterial,1) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						'IsCompany'+@cSep+CAST(ISNULL(H.IsCompany,0) AS CHAR(1))+@cSep+
						CASE 
							WHEN ISNULL(H.IsCompany,0) = 1 THEN 'Oui'
						ELSE 'Non'
						END+@cSep+
						CHAR(13)+CHAR(10)+
						CASE 
							WHEN ISNULL(A.Address,'') = '' THEN ''
						ELSE 'Address'+@cSep+A.Address+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.City,'') = '' THEN ''
						ELSE 'City'+@cSep+A.City+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.StateName,'') = '' THEN ''
						ELSE 'StateName'+@cSep+A.StateName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.CountryID,'') = '' THEN ''
						ELSE 'CountryID'+@cSep+A.CountryID+@cSep+C.CountryName+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.ZipCode,'') = '' THEN ''
						ELSE 'ZipCode'+@cSep+A.ZipCode+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.Phone1,'') = '' THEN ''
						ELSE 'Phone1'+@cSep+A.Phone1+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.Phone2,'') = '' THEN ''
						ELSE 'Phone2'+@cSep+A.Phone2+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.Fax,'') = '' THEN ''
						ELSE 'Fax'+@cSep+A.Fax+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(A.Mobile,'') = '' THEN ''
						ELSE 'Mobile'+@cSep+A.Mobile+@cSep+CHAR(13)+CHAR(10)
						END+/*
						CASE 
							WHEN ISNULL(A.WattLine,'') = '' THEN ''
						ELSE 'WattLine'+@cSep+A.WattLine+@cSep+CHAR(13)+CHAR(10)
						END+*/
						CASE 
							WHEN ISNULL(A.OtherTel,'') = '' THEN ''
						ELSE 'OtherTel'+@cSep+A.OtherTel+@cSep+CHAR(13)+CHAR(10)
						END+/*
						CASE 
							WHEN ISNULL(A.Pager,'') = '' THEN ''
						ELSE 'Pager'+@cSep+A.Pager+@cSep+CHAR(13)+CHAR(10)
						END+*/
						CASE 
							WHEN ISNULL(A.EMail,'') = '' THEN ''
						ELSE 'EMail'+@cSep+A.EMail+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(R.RepCode,'') = '' THEN ''
						ELSE 'RepCode'+@cSep+R.RepCode+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(R.RepLicenseNo,'') = '' THEN ''
						ELSE 'RepLicenseNo'+@cSep+R.RepLicenseNo+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(R.BusinessStart,0) <= 0 THEN ''
						ELSE 'BusinessStart'+@cSep+CONVERT(CHAR(10), R.BusinessStart, 20)+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(R.BusinessEnd,0) <= 0 THEN ''
						ELSE 'BusinessEnd'+@cSep+CONVERT(CHAR(10), R.BusinessEnd, 20)+@cSep+CHAR(13)+CHAR(10)
						END+
						CASE 
							WHEN ISNULL(R.iNumeroBDNI,0) <= 0 THEN ''
							ELSE 'iNumeroBDNI'+@cSep+CAST(iNumeroBDNI AS VARCHAR(8))+@cSep+CHAR(13)+CHAR(10)
						END
					FROM Un_Rep R
					JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
					JOIN Mo_Lang L ON L.LangID = H.LangID
					JOIN Mo_Sex S ON S.LangID = 'FRA' AND S.SexID = H.SexID
					JOIN Mo_CivilStatus CS ON CS.LangID = 'FRA' AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
					JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'I'
					JOIN Mo_Country Re ON Re.CountryID = H.ResidID
					LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
					LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
					WHERE R.RepID = @RepID
		END
		ELSE
		BEGIN
			UPDATE Un_Rep 
			SET
				RepCode = @RepCode,
				RepLicenseNo = @RepLicenseNo,
				BusinessStart = @BusinessStart,
				BusinessEnd = @BusinessEnd,
				iNumeroBDNI = @iNumeroBDNI
			WHERE RepID = @RepID

			IF EXISTS	(
					SELECT RepID
					FROM Un_Rep R
					JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
					WHERE R.RepID = @RepID
						AND	(	@vcOldFirstName <> H.FirstName
								OR	@vcOldOrigName <> H.OrigName
								OR	@vcOldInitial <> H.Initial
								OR @vcOldLastName <> H.LastName
								OR @cOldLangID <> H.LangID
								OR @cOldSexID <> H.SexID
								OR @cOldCivilID <> H.CivilID
								OR @dtOldBirthDate <> H.BirthDate
								OR @dtOldDeathDate <> H.DeathDate
								OR @vcOldRepCode <> R.RepCode
								OR @vcOldRepLicenseNo <> R.RepLicenseNo
								OR @dtOldBusinessStart <> R.BusinessStart
								OR @dtOldBusinessEnd <> R.BusinessEnd
								OR @iOldNumeroBDNI <> R.iNumeroBDNI
								)
							)
			BEGIN
				-- Insère un log de l'objet modifié.
				INSERT INTO CRQ_Log (
					ConnectID,
					LogTableName,
					LogCodeID,
					LogTime,
					LogActionID,
					LogDesc,
					LogText)
					SELECT
						@ConnectID,
						'Un_Rep',
						@RepID,
						GETDATE(),
						LA.LogActionID,
						LogDesc = 'Représentant : '+H.LastName+', '+H.FirstName,
						LogText =
							CASE 
								WHEN ISNULL(@vcOldFirstName,'') <> ISNULL(H.FirstName,'') THEN
									'FirstName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldFirstName,'') = '' THEN ''
									ELSE @vcOldFirstName
									END+@cSep+
									CASE 
										WHEN ISNULL(H.FirstName,'') = '' THEN ''
									ELSE H.FirstName
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldLastName,'') <> ISNULL(H.LastName,'') THEN
									'LastName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldLastName,'') = '' THEN ''
									ELSE @vcOldLastName
									END+@cSep+
									CASE 
										WHEN ISNULL(H.LastName,'') = '' THEN ''
									ELSE H.LastName
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldOrigName,'') <> ISNULL(H.OrigName,'') THEN
									'OrigName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldOrigName,'') = '' THEN ''
									ELSE @vcOldOrigName
									END+@cSep+
									CASE 
										WHEN ISNULL(H.OrigName,'') = '' THEN ''
									ELSE H.OrigName
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldInitial,'') <> ISNULL(H.Initial,'') THEN
									'Initial'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldInitial,'') = '' THEN ''
									ELSE @vcOldInitial
									END+@cSep+
									CASE 
										WHEN ISNULL(H.Initial,'') = '' THEN ''
									ELSE H.Initial
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @cOldLangID <> H.LangID THEN
									'LangID'+@cSep+@cOldLangID+@cSep+H.LangID+@cSep+OL.LangName+@cSep+L.LangName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @cOldSexID <> H.SexID THEN
									'SexID'+@cSep+@cOldSexID+@cSep+H.SexID+@cSep+OS.SexName+@cSep+S.SexName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @cOldCivilID <> H.CivilID THEN
									'CivilID'+@cSep+@cOldCivilID+@cSep+H.CivilID+@cSep+OCS.CivilStatusName+@cSep+CS.CivilStatusName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@dtOldBirthDate,0) <> ISNULL(H.BirthDate,0) THEN
									'BirthDate'+@cSep+
									CASE 
										WHEN ISNULL(@dtOldBirthDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), @dtOldBirthDate, 20)
									END+@cSep+
									CASE 
										WHEN ISNULL(H.BirthDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), H.BirthDate, 20)
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@dtOldDeathDate,0) <> ISNULL(H.DeathDate,0) THEN
									'DeathDate'+@cSep+
									CASE 
										WHEN ISNULL(@dtOldDeathDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), @dtOldDeathDate, 20)
									END+@cSep+
									CASE 
										WHEN ISNULL(H.DeathDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), H.DeathDate, 20)
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldRepCode,'') <> ISNULL(R.RepCode,'') THEN
									'RepCode'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldRepCode,'') = '' THEN ''
									ELSE @vcOldRepCode
									END+@cSep+
									CASE 
										WHEN ISNULL(R.RepCode,'') = '' THEN ''
									ELSE R.RepCode
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldRepLicenseNo,'') <> ISNULL(R.RepLicenseNo,'') THEN
									'RepLicenseNo'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldRepLicenseNo,'') = '' THEN ''
									ELSE @vcOldRepLicenseNo
									END+@cSep+
									CASE 
										WHEN ISNULL(R.RepLicenseNo,'') = '' THEN ''
									ELSE R.RepLicenseNo
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@dtOldBusinessStart,0) <> ISNULL(R.BusinessStart,0) THEN
									'BusinessStart'+@cSep+
									CASE 
										WHEN ISNULL(@dtOldBusinessStart,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), @dtOldBusinessStart, 20)
									END+@cSep+
									CASE 
										WHEN ISNULL(R.BusinessStart,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), R.BusinessStart, 20)
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@dtOldBusinessEnd,0) <> ISNULL(R.BusinessEnd,0) THEN
									'BusinessEnd'+@cSep+
									CASE 
										WHEN ISNULL(@dtOldBusinessEnd,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), @dtOldBusinessEnd, 20)
									END+@cSep+
									CASE 
										WHEN ISNULL(R.BusinessEnd,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), R.BusinessEnd, 20)
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@iOldNumeroBDNI,0) <> ISNULL(R.iNumeroBDNI,0) THEN
									'iNumeroBDNI'+@cSep+
									CASE 
										WHEN ISNULL(@iOldNumeroBDNI,0) <= 0 THEN ''
										ELSE CAST(@iOldNumeroBDNI AS VARCHAR(8))
									END+@cSep+
									CASE 
										WHEN ISNULL(R.iNumeroBDNI,0) <= 0 THEN ''
										ELSE CAST(R.iNumeroBDNI AS VARCHAR(8))
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END
						FROM Un_Rep R
						JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
						JOIN Mo_Lang L ON L.LangID = H.LangID
						JOIN Mo_Lang OL ON OL.LangID = @cOldLangID
						JOIN Mo_Sex S ON S.SexID = H.SexID AND S.LangID = 'FRA'
						JOIN Mo_Sex OS ON OS.SexID = @cOldSexID AND OS.LangID = 'FRA'
						JOIN Mo_CivilStatus CS ON CS.LangID = 'FRA' AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
						JOIN Mo_CivilStatus OCS ON OCS.LangID = 'FRA' AND OCS.SexID = @cOldSexID AND OCS.CivilStatusID = @cOldCivilID
						JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
						WHERE R.RepID = @RepID
			END
		END
	END
	ELSE
		SET @RepID = -1
	
	IF @RepID > 0
		-- Gestion de l'historique des NAS
		EXECUTE TT_UN_HumanSocialNumber @ConnectID, @RepID, @SocialNumber

	-- Fin des traitements
	IF @RepID > 0
	BEGIN
		IF @@ERROR = 0
			------------------
			COMMIT TRANSACTION
			------------------
		ELSE
		BEGIN
			---------------------
			ROLLBACK TRANSACTION
			---------------------	
			SET @RepID = -2
		END
	END

	DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TMo_Human_Log'
	
	RETURN @RepID
END


