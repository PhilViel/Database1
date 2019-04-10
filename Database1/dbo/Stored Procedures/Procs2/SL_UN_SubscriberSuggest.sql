/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	SL_UN_SubsciberSuggest
Description 		:	Retourne une liste de suggestions de souscripteurs si 3 des 5 critères de bases correspondent.
Valeurs de retour	:	Dataset :
							SubscriberID	INTEGER			Identifiant unique du souscripteur
							FirstName		VARCHAR(50)		Prénom du souscripteur	
							bSameFirstName	BIT				Indique si le prénom est identique (1=Oui)
							LastName		VARCHAR(50)		Nom du souscripteur
							bSameLastName	BIT				Indique si le nom est identique (1=Oui)
							ZipCode			VARCHAR(10)		Code postal
							bSameZipCode	BIT				Indique si le code postal est identique (1=Oui)
							BirthDate		DATE			Date de naissance
							bSameBirthDate	BIT				Indique si la date de naissance est identique (1=Oui)
							Phone1			VARCHAR(50)		Numéro de téléphone résidentiel du souscripteur
							Phone2			VARCHAR(50)		Numéro de téléphone au bureau du souscripteur
							bSamePhone1  	BIT				Indique si le numéro de téléphone résidentiel est identique (1=Oui)
							bSamePhone2  	BIT				Indique si le numéro de téléphone au bureau est identique (1=Oui)
							SocialNumber	VARCHAR(9)		NAS du souscripteur
							Address			VARCHAR(100)	Adresse du souscripteur
							City			VARCHAR(100)	Ville du souscripteur

Note			:	ADX0001235	IA	2007-02-13	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SubscriberSuggest] (
	@FirstName VARCHAR(35),		--Prénom du souscripteur	
	@LastName VARCHAR(50),		--Nom du souscripteur
	@ZipCode VARCHAR(10),		--Code Postal
	@Phone1	VARCHAR(27),		--Numéro de téléphone résidentiel
	@Phone2	VARCHAR(27),		--Numéro de téléphone au bureau
	@BirthDate DATETIME,		--Date de naissance
	@SocialNumber VARCHAR(75),	--NAS/NE : Numéro d’assurance sociale 
	@IsCompany BIT)				--Indique s'il s'git d'une compagnie
AS
BEGIN
	IF @IsCompany = 0 
	BEGIN
		IF @SocialNumber = ''
		BEGIN
			CREATE TABLE #tSubscruberIDs(
				SubscriberID INTEGER PRIMARY KEY)

			INSERT INTO #tSubscruberIDs
				SELECT S.SubscriberID
				FROM dbo.Un_Subscriber S
				JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
				WHERE H.FirstName = @FirstName
						OR H.LastName = @LastName
						OR H.BirthDate = @BirthDate

			SELECT
				S.SubscriberID,								--Identifiant unique du souscripteur
				H.FirstName,								--Prénom du souscripteur	
				bSameFirstName = CAST((CASE 
											WHEN H.FirstName = @FirstName THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le prénom est identique (1=Oui)
				H.LastName,									--Nom du souscripteur
				bSameLastName = CAST((CASE 
											WHEN H.LastName = @LastName THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le nom est identique (1=Oui)
				A.ZipCode,									--Code postal
				bSameZipCode = CAST((CASE 
											WHEN A.ZipCode = @ZipCode THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le code postal est identique (1=Oui)
				H.BirthDate,								--Date de naissance
				bSameBirthDate = CAST((CASE 
											WHEN H.BirthDate = @BirthDate THEN 1
											ELSE 0
										END) AS BIT),		--Indique si la date de naissance est identique (1=Oui)
				A.Phone1,									--Numéro de téléphone résidentiel du souscripteur
				A.Phone2,									--Numéro de téléphone au bureau du souscripteur
				bSamePhone1 = CAST((CASE 
											WHEN A.Phone1 = @Phone1 THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le numéro de téléphone résidentiel est identique (1=Oui)
				bSamePhone2 = CAST(0 AS BIT),							--Indique si le numéro de téléphone au bureau est identique (1=Oui) (0 pour les humains)
				H.SocialNumber,								--NAS du souscripteur
				A.Address,									--Adresse du souscripteur
				A.City										--Ville du souscripteur	
			FROM #tSubscruberIDs S			
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			WHERE (H.FirstName = @FirstName
					AND H.LastName = @LastName
					AND A.ZipCode = @ZipCode)			-- CAS 1 (prénom, nom, zipcode)
				OR (H.FirstName = @FirstName
					AND H.LastName = @LastName
					AND A.Phone1 = @Phone1)				-- CAS 2 (prénom, nom, phone1)
				OR (H.FirstName = @FirstName
					AND H.LastName = @LastName
					AND H.BirthDate = @BirthDate)		-- CAS 3 (prénom, nom, birthdate)
				OR (H.FirstName = @FirstName				
					AND A.ZipCode = @ZipCode		
					AND A.Phone1 = @Phone1)				-- CAS 4 (prénom, zipcode, phone1)
				OR (H.FirstName = @FirstName				
						AND A.ZipCode = @ZipCode		
						AND H.BirthDate = @BirthDate)	-- CAS 5 (prénom, zipcode, birthdate)
				OR (H.FirstName = @FirstName				
						AND A.Phone1 = @Phone1		
						AND H.BirthDate = @BirthDate)	-- CAS 6 (prénom, phone1, birthdate)
				OR (H.LastName = @LastName				
						AND A.ZipCode = @ZipCode			
						AND A.Phone1 = @Phone1)			-- CAS 7 (nom, zipcode, phone1)
				OR (H.LastName = @LastName				
						AND A.ZipCode = @ZipCode			
						AND H.BirthDate = @BirthDate)	-- CAS 8 (nom, zipcode, birthdate)
				OR (H.LastName = @LastName					
						AND A.Phone1 = @Phone1		
						AND H.BirthDate = @BirthDate)	-- CAS 9 (nom, phone1, birthdate)
				OR (A.ZipCode = @ZipCode					
						AND A.Phone1 = @Phone1		
						AND H.BirthDate = @BirthDate)	-- CAS 10 (zipcode, phone1, birthdate)
				AND H.IsCompany = 0

			DROP TABLE #tSubscruberIDs
		END
		ELSE -- L'usager a saisie un NAS
		BEGIN
			SELECT
				S.SubscriberID,								--Identifiant unique du souscripteur
				H.FirstName,								--Prénom du souscripteur	
				bSameFirstName = CAST((CASE 
											WHEN H.FirstName = @FirstName THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le prénom est identique (1=Oui)
				H.LastName,									--Nom du souscripteur
				bSameLastName = CAST((CASE 
											WHEN H.LastName = @LastName THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le nom est identique (1=Oui)
				A.ZipCode,									--Code postal
				bSameZipCode = CAST((CASE 
											WHEN A.ZipCode = @ZipCode THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le code postal est identique (1=Oui)
				H.BirthDate,								--Date de naissance
				bSameBirthDate = CAST((CASE 
											WHEN H.BirthDate = @BirthDate THEN 1
											ELSE 0
										END) AS BIT),		--Indique si la date de naissance est identique (1=Oui)
				A.Phone1,									--Numéro de téléphone résidentiel du souscripteur
				A.Phone2,									--Numéro de téléphone au bureau du souscripteur
				bSamePhone1 = CAST((CASE 
											WHEN A.Phone1 = @Phone1 THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le numéro de téléphone résidentiel est identique (1=Oui)
				bSamePhone2 = CAST(0 AS BIT),				--Indique si le numéro de téléphone au bureau est identique (1=Oui) (0 pour les humains)
				H.SocialNumber,								--NAS du souscripteur
				A.Address,									--Adresse du souscripteur
				A.City										--Ville du souscripteur	
			FROM dbo.Un_Subscriber S
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			WHERE H.SocialNumber = @SocialNumber
					AND H.IsCompany = 0
		END
	END
	ELSE -- Entreprise
	BEGIN
		IF @SocialNumber = ''
		BEGIN		
			SELECT
				S.SubscriberID,								--Identifiant unique du souscripteur
				H.FirstName,								--Prénom du souscripteur	
				bSameFirstName = CAST(0 AS BIT),			--Indique si le prénom est identique (1=Oui) (0 pour les humains)
				H.LastName,									--Nom du souscripteur
				bSameLastName = CAST((CASE 
											WHEN H.LastName = @LastName THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le nom est identique (1=Oui)
				A.ZipCode,									--Code postal
				bSameZipCode = CAST((CASE 
											WHEN A.ZipCode = @ZipCode THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le code postal est identique (1=Oui)
				H.BirthDate,								--Date de naissance
				bSameBirthDate = CAST(0 AS BIT),			--Indique si la date de naissance est identique (1=Oui) (0 pour les humains)
				A.Phone1,									--Numéro de téléphone résidentiel du souscripteur
				A.Phone2,									--Numéro de téléphone au bureau du souscripteur
				bSamePhone1 = CAST(0 AS BIT),				--Indique si le numéro de téléphone résidentiel est identique (1=Oui) (0 pour les humains)
				bSamePhone2 = CAST((CASE 
											WHEN A.Phone2 = @Phone2 THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le numéro de téléphone au bureau est identique (1=Oui) 
				H.SocialNumber,								--NAS du souscripteur
				A.Address,									--Adresse du souscripteur
				A.City										--Ville du souscripteur	
			FROM dbo.Un_Subscriber S
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			WHERE (H.LastName = @LastName					
					OR A.Phone2 = @Phone2		
					OR A.ZipCode = @ZipCode)
				AND H.IsCompany = 1
		END
		ELSE -- L'usager a saisie un NE
		BEGIN
			SELECT
				S.SubscriberID,								--Identifiant unique du souscripteur
				H.FirstName,								--Prénom du souscripteur	
				bSameFirstName = CAST(0 AS BIT),			--Indique si le prénom est identique (1=Oui) (0 pour les humains)
				H.LastName,									--Nom du souscripteur
				bSameLastName = CAST((CASE 
											WHEN H.LastName = @LastName THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le nom est identique (1=Oui)
				A.ZipCode,									--Code postal
				bSameZipCode = CAST((CASE 
											WHEN A.ZipCode = @ZipCode THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le code postal est identique (1=Oui)
				H.BirthDate,								--Date de naissance
				bSameBirthDate = CAST(0 AS BIT),			--Indique si la date de naissance est identique (1=Oui) (0 pour les humains)
				A.Phone1,									--Numéro de téléphone résidentiel du souscripteur
				A.Phone2,									--Numéro de téléphone au bureau du souscripteur
				bSamePhone1 = CAST(0 AS BIT),				--Indique si le numéro de téléphone résidentiel est identique (1=Oui) (0 pour les humains)
				bSamePhone2 = CAST((CASE 
											WHEN A.Phone2 = @Phone2 THEN 1
											ELSE 0
										END) AS BIT),		--Indique si le numéro de téléphone au bureau est identique (1=Oui) 
				H.SocialNumber,								--NAS du souscripteur
				A.Address,									--Adresse du souscripteur
				A.City										--Ville du souscripteur	
			FROM dbo.Un_Subscriber S
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			WHERE H.SocialNumber = @SocialNumber
					AND H.IsCompany = 1
		END
	END
END


