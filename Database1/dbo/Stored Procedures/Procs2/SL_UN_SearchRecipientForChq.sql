/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchRecipientForChq
Description         :	Procédure de recherche de destinataire pour cheque, ce peut être autant des souscripteurs, 
								des bénéficiaires ou encore des destinataires.
Valeurs de retours  :	Dataset :
									HumanID				INTEGER			ID de l’humain (souscripteur, bénéficiaire ou destinataire).
									Tablename			VARCHAR(75)		Nom de la table qui permet de définir le type de destinataire dont
																				il s’agit (Un_Subscriber = souscripteur, Un_Beneficiary = 
																				bénéficiaire, Un_Recipient = destinataire)
									FirstName			VARCHAR(35)		Prénom du destinataire
									OrigName				VARCHAR(50)		Nom à la naissance
									Initial				VARCHAR(4)		Initial (Jr, Sr, etc.)
									LastName				VARCHAR(50)		Nom
									BirthDate			DATETIME			Date de naissance
									DeathDate			DATETIME			Date du décès
									SexID					CHAR(1)			Sexe (code)
									LangID				CHAR(3)			Langue (code)
									CivilID				CHAR(1)			Statut civil (code)
									SocialNumber		VARCHAR(75)		Numéro d’assurance sociale
									ResidID				CHAR(3)			Pays de résidence (code)
									ResidName			VARCHAR(75)		Pays de résidence
									DriverLicenseNo	VARCHAR(75)		Numéro de permis
									WebSite				VARCHAR(75)		Site internet
									CompanyName			VARCHAR(75)		Nom de compagnie
									CourtesyTitle		VARCHAR(35)		Titre de courtoisie (Docteur, Professeur, etc.)
									UsingSocialNumber	BIT				Droit d’utiliser le NAS.
									SharePersonalInfo	BIT				Droit de partager les informations personnelles
									MarketingMaterial	BIT				Veux recevoir le matériel publicitaire.
									IsCompany			BIT				Compagny ou humain
									InForce				DATETIME			Date d’entrée en vigueur de l’adresse.
									AdrTypeID			CHAR(1)			Type d’adresse (H = humain, C = Compagnie)
									SourceID	 			INTEGER			ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
									Address				VARCHAR(75)		# civique, rue et # d’appartement.
									City					VARCHAR(100)	Ville
									StateName			VARCHAR(75)		Province
									CountryID			CHAR(3)			Pays (code)
									CountryName			VARCHAR(75)		Pays
									ZipCode				VARCHAR(10)		Code postal
									Phone1				VARCHAR(27)		Tél. résidence
									Phone2				VARCHAR(27)		Tél. bureau
									Fax					VARCHAR(15)		Fax
									Mobile				VARCHAR(15)		Tél. cellulaire
									WattLine				VARCHAR(27)		Tél. sans frais
									OtherTel				VARCHAR(27)		Autre téléphone.
									Pager					VARCHAR(15)		Paget
									Email					VARCHAR(100)	Courriel
Note						:	ADX0000826	IA	2006-03-20	Bruno Lapointe			Géré le prénom NULL des souscripteurs-compagnies
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchRecipientForChq] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@vcSearchType VARCHAR(3),	-- Type de recherche : FNa = Prénom, nom, LNa = Nom, prénom, Adr = Adresse, 
										-- Zip = Code postal, Pho = Numéro de téléphone résidentiel
	@vcSearch VARCHAR(100) ) -- Valeur recherché selon le @vcSearchType.
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()

	DECLARE @tSearchRecipient TABLE (
		HumanID INTEGER PRIMARY KEY)

	-- Nom, prénom
	IF @vcSearchType = 'LNa'
		INSERT INTO @tSearchRecipient
			SELECT HumanID
			FROM dbo.Mo_Human
			WHERE ISNULL(LastName,'') + ', ' + ISNULL(FirstName,'') LIKE @vcSearch
	-- Prénom, nom
	ELSE IF @vcSearchType = 'FNa'
		INSERT INTO @tSearchRecipient
			SELECT HumanID
			FROM dbo.Mo_Human
			WHERE ISNULL(FirstName,'') + ', ' + ISNULL(LastName,'') LIKE @vcSearch
				OR (ISNULL(LastName,'') LIKE @vcSearch
					AND IsCompany = 1
					)	-- Adresse
	ELSE IF @vcSearchType = 'Adr'
		INSERT INTO @tSearchRecipient
			SELECT H.HumanID
			FROM dbo.Mo_Adr A
			JOIN dbo.Mo_Human H ON A.AdrID = H.AdrID
			WHERE ISNULL(A.Address,'') LIKE @vcSearch
	-- Téléphone
	ELSE IF @vcSearchType = 'Pho'
		INSERT INTO @tSearchRecipient
			SELECT H.HumanID
			FROM dbo.Mo_Adr A
			JOIN dbo.Mo_Human H ON A.AdrID = H.AdrID
			WHERE ISNULL(A.Phone1,'') LIKE @vcSearch
	-- Code postal
	ELSE IF @vcSearchType = 'Zip'
		INSERT INTO @tSearchRecipient
			SELECT H.HumanID
			FROM dbo.Mo_Adr A
			JOIN dbo.Mo_Human H ON A.AdrID = H.AdrID
			WHERE ISNULL(A.ZipCode,'') LIKE @vcSearch

	SELECT
		H.HumanID, -- ID de l’humain (souscripteur, bénéficiaire ou destinataire).
		Tablename =  -- Nom de la table qui permet de définir le type de destinataire dont il s’agit (Un_Subscriber = souscripteur, Un_Beneficiary = bénéficiaire, Un_Recipient = destinataire)
			CASE
				WHEN S.SubscriberID IS NOT NULL THEN 'Un_Subscriber'
				WHEN B.BeneficiaryID IS NOT NULL THEN 'Un_Beneficiary'
			ELSE 'Un_Recipient'
			END,
		H.FirstName, -- Prénom du destinataire
		H.OrigName, -- Nom à la naissance
		H.Initial, -- Initial (Jr, Sr, etc.)
		H.LastName, -- Nom
		H.BirthDate, -- Date de naissance
		H.DeathDate, -- Date du décès
		H.SexID, -- Sexe (code)
		H.LangID, -- Langue (code)
		H.CivilID, -- Statut civil (code)
		H.SocialNumber, -- Numéro d’assurance sociale
		H.ResidID, -- Pays de résidence (code)
		ResidName = R.CountryName, -- Pays de résidence
		H.DriverLicenseNo, -- Numéro de permis
		H.WebSite, -- Site internet
		H.CompanyName, -- Nom de compagnie
		H.CourtesyTitle, -- Titre de courtoisie (Docteur, Professeur, etc.)
		H.UsingSocialNumber, -- Droit d’utiliser le NAS.
		H.SharePersonalInfo, -- Droit de partager les informations personnelles
		H.MarketingMaterial, -- Veux recevoir le matériel publicitaire.
		H.IsCompany, -- Compagny ou humain
		A.InForce, -- Date d’entrée en vigueur de l’adresse.
		A.AdrTypeID, -- Type d’adresse (H = humain, C = Compagnie)
		A.SourceID, -- ID de l’objet auquel appartient l’adresse (HumanID ou CompanyID)
		A.Address, -- # civique, rue et # d’appartement.
		A.City, -- Ville
		A.StateName, -- Province
		A.CountryID, -- Pays (code)
		C.CountryName, -- Pays
		A.ZipCode, -- Code postal
		A.Phone1, -- Tél. résidence
		A.Phone2, -- Tél. bureau
		A.Fax, -- Fax
		A.Mobile, -- Tél. cellulaire
		A.WattLine, -- Tél. sans frais
		A.OtherTel, -- Autre téléphone.
		A.Pager, -- Paget
		A.Email -- Courriel
	FROM @tSearchRecipient tR
	JOIN dbo.Mo_Human H ON H.HumanID = tR.HumanID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Mo_Country R ON R.CountryID = H.ResidID
	LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
	LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
	LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
	LEFT JOIN Un_Recipient Rp ON Rp.iRecipientID = H.HumanID
	WHERE	( S.SubscriberID IS NOT NULL
			OR B.BeneficiaryID IS NOT NULL
			OR Rp.iRecipientID IS NOT NULL
			)
	ORDER BY
		CASE @vcSearchType
			WHEN 'LNa' THEN ISNULL(H.LastName,'') + ', ' + ISNULL(H.FirstName,'')
			WHEN 'FNa' THEN ISNULL(H.FirstName,'') + ', ' + ISNULL(H.LastName,'')
			WHEN 'Adr' THEN ISNULL(A.Address,'')
			WHEN 'Zip' THEN ISNULL(A.ZipCode,'')
			WHEN 'Pho' THEN ISNULL(A.Phone1,'')
		END,
		CASE @vcSearchType
			WHEN 'LNa' THEN ISNULL(H.FirstName,'')
			ELSE ISNULL(H.LastName,'') 
		END,
		CASE 
			WHEN @vcSearchType IN ('LNa', 'FNa') THEN ISNULL(A.Address,'')
			ELSE ISNULL(H.FirstName,'')
		END, 
		ISNULL(A.Address,'')

	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceSearch.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				1,
				DATEDIFF(SECOND, @dtBegin, @dtEnd), -- Temps en seconde
				@dtBegin,
				@dtEnd,
				LogDesc = 
				'Recherche de destinataire par '+
					CASE @vcSearchType
						WHEN 'LNa' THEN 'nom, prénom : ' 
						WHEN 'Pho' THEN 'téléphone : ' 
						WHEN 'Adr' THEN 'adresse : '
						WHEN 'FNa' THEN 'prénom, nom : ' 
						WHEN 'Zip' THEN 'code postal : '
					END + @vcSearch,
				'SL_UN_SearchRecipientForChq',
				'EXECUTE SL_UN_SearchRecipientForChq @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @vcSearchType = '+@vcSearchType+
					', @vcSearch = '+@vcSearch
END


