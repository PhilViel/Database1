/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	SL_UN_BeneficiarySuggest
Description 		:	Retourne une liste de suggestions de bénéficiaires si 3 des 5 critères de bases correspondent.
Valeurs de retour	:	Dataset :
							BeneficiaryID	INTEGER			Identifiant unique du bénéficiaire
							FirstName		VARCHAR(50)		Prénom du bénéficiaire	
							bSameFirstName	BIT				Indique si le prénom est identique (1=Oui)
							LastName		VARCHAR(50)		Nom du bénéficiaire
							bSameLastName	BIT				Indique si le nom est identique (1=Oui)
							ZipCode			VARCHAR(10)		Code postal
							bSameZipCode	BIT				Indique si le code postal est identique (1=Oui)
							BirthDate		DATE			Date de naissance
							bSameBirthDate	BIT				Indique si l date de naissance est identique (1=Oui)
							Phone1			VARCHAR(50)		Numéro de téléphone du bénéficiaire
							bSamePhone1 	BIT				Indique si le numéro de téléphone résidentiel est identique (1=Oui)
							SocialNumber	VARCHAR(9)		NAS du bénéficiaire
							Address			VARCHAR(100)	Adresse du bénéficiaire
							City			VARCHAR(100)	Ville du bénéficiaire

Note			:	ADX0001234	IA	2007-02-15	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_BeneficiarySuggest] (
	@FirstName VARCHAR(35),		--	Prénom du bénéficiaire	
	@LastName VARCHAR(50),		--	Nom du bénéficiaire
	@ZipCode VARCHAR(10),		--	Code Postal
	@Phone1	VARCHAR(27),		--	Numéro de téléphone résidentiel
	@BirthDate DATETIME,		--	Date de naissance
	@SocialNumber VARCHAR(75))	--	NAS : Numéro d’assurance sociale
AS
BEGIN	
	IF @SocialNumber = ''
	BEGIN
		CREATE TABLE #tBeneficiaryIDs(
			BeneficiaryID INTEGER PRIMARY KEY)

		INSERT INTO #tBeneficiaryIDs
			SELECT B.BeneficiaryID
			FROM dbo.Un_Beneficiary B
			JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
			WHERE H.FirstName = @FirstName
					OR H.LastName = @LastName
					OR H.BirthDate = @BirthDate

		SELECT
			B.BeneficiaryID,							--Identifiant unique du bénéficiaire
			H.FirstName,								--Prénom du bénéficiaire	
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
			A.Phone1,									--Numéro de téléphone résidentiel du bénéficiaire
			bSamePhone1 = CAST((CASE 
										WHEN A.Phone1 = @Phone1 THEN 1
										ELSE 0
									END) AS BIT),		--Indique si le numéro de téléphone résidentiel est identique (1=Oui)
			H.SocialNumber,								--NAS du bénéficiaire
			A.Address,									--Adresse du bénéficiaire
			A.City										--Ville du bénéficiaire	
		FROM #tBeneficiaryIDs B			
		JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
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

		DROP TABLE #tBeneficiaryIDs
	END
	ELSE -- L'usager a saisie un NAS
	BEGIN
		SELECT
			B.BeneficiaryID,								--Identifiant unique du bénéficiaire
			H.FirstName,								--Prénom du bénéficiaire	
			bSameFirstName = CAST((CASE 
										WHEN H.FirstName = @FirstName THEN 1
										ELSE 0
									END) AS BIT),		--Indique si le prénom est identique (1=Oui)
			H.LastName,									--Nom du bénéficiaire
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
			A.Phone1,									--Numéro de téléphone résidentiel du bénéficiaire
			bSamePhone1 = CAST((CASE 
										WHEN A.Phone1 = @Phone1 THEN 1
										ELSE 0
									END) AS BIT),		--Indique si le numéro de téléphone résidentiel est identique (1=Oui)
			H.SocialNumber,								--NAS du bénéficiaire
			A.Address,									--Adresse du bénéficiaire
			A.City										--Ville du bénéficiaire	
		FROM dbo.Un_Beneficiary B
		JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
		JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		WHERE H.SocialNumber = @SocialNumber				
	END	
END


