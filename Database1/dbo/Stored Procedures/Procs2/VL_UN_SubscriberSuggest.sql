/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	VL_UN_SubscriberSuggest
Description 		:	Valide les entrées pour les suggestions de souscripteurs
Valeurs de retour	:	Dataset :
							vcErrorCode		CHAR(3)			Code d’erreur
							vcErrorText		VARCHAR(1000)	Texte de l’erreur
						Code d’erreur		Erreur
						SS1					Le NAS saisi appartient à un souscripteur existant, mais les informations saisies ne concordent pas.
						SS2					« Le NAS saisi appartient à un souscripteur existant, mais certaines informations saisies ne concordent pas avec ce dernier.

Note			:	ADX0001235	IA	2007-02-13	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_SubscriberSuggest] (
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
	DECLARE @tSuggestions TABLE(		
		SubscriberID INTEGER,
		bSameFirstName INTEGER,
		bSameLastName INTEGER,
		bSameZipCode INTEGER,
		bSameBirthDate INTEGER,
		bSamePhone1 INTEGER,
		bSamePhone2 INTEGER)

	DECLARE @Sum INTEGER
	SET @Sum = 0

	IF @IsCompany = 0 
	BEGIN
		INSERT INTO @tSuggestions
		SELECT		
			S.SubscriberID,	
			bSameFirstName = CASE 
									WHEN H.FirstName = @FirstName THEN 1
									ELSE 0
								END,					--Indique si le prénom est identique (1=Oui)
			bSameLastName = CASE 
									WHEN H.LastName = @LastName THEN 1
									ELSE 0
								END,					--Indique si le nom est identique (1=Oui)			
			bSameZipCode = CASE 
									WHEN A.ZipCode = @ZipCode THEN 1
									ELSE 0
								END,					--Indique si le code postal est identique (1=Oui)			
			bSameBirthDate = CASE 
									WHEN H.BirthDate = @BirthDate THEN 1
									ELSE 0
								END,					--Indique si la date de naissance est identique (1=Oui)			
			bSamePhone1 = CASE 
									WHEN A.Phone1 = @Phone1 THEN 1
									ELSE 0
								END,				--Indique si le numéro de téléphone résidentiel est identique (1=Oui)			
			0
		FROM dbo.Un_Subscriber S
		JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
		JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		WHERE H.SocialNumber = @SocialNumber
				AND H.IsCompany = 0	
	END
	ELSE -- Entreprise			
	BEGIN
		INSERT INTO @tSuggestions
		SELECT	
			S.SubscriberID,			
			0,
			bSameLastName = CASE 
								WHEN H.LastName = @LastName THEN 1
								ELSE 0
							END,						--Indique si le nom est identique (1=Oui)			
			bSameZipCode = CASE 
								WHEN A.ZipCode = @ZipCode THEN 1
								ELSE 0
							END,						--Indique si le code postal est identique (1=Oui)
			0,
			0,
			bSamePhone2 = CASE 
								WHEN A.Phone2 = @Phone2 THEN 1
								ELSE 0
							END							--Indique si le numéro de téléphone au bureau est identique (1=Oui) 			
		FROM dbo.Un_Subscriber S
		JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
		JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		WHERE H.SocialNumber = @SocialNumber
				AND H.IsCompany = 1
	END	

	SELECT TOP 1
			@Sum = ISNULL(bSameFirstName,0) + ISNULL(bSameLastName,0) + ISNULL(bSameZipCode,0) + ISNULL(bSameBirthDate,0) + ISNULL(bSamePhone1,0) + ISNULL(bSamePhone2,0)
	FROM @tSuggestions

	IF @IsCompany = 0 
		SELECT 
				vcErrorCode = CASE
									WHEN @Sum < 3 THEN 'SS1'
									WHEN @Sum < 5 THEN 'SS2'
									ELSE 'SS3'
								END,
				vcErrorText = CASE
									WHEN @Sum < 3 THEN 'Le NAS saisi appartient à un souscripteur existant, mais les informations saisies ne concordent pas.'
									ELSE CAST(SubscriberID AS VARCHAR(10))
								END	
		FROM @tSuggestions	
	ELSE
		SELECT 
				vcErrorCode = CASE
									WHEN @Sum < 2 THEN 'SS1'
									WHEN @Sum < 3 THEN 'SS2'
									ELSE 'SS3'
								END,
				vcErrorText = CASE
									WHEN @Sum < 2 THEN 'Le NE saisi appartient à un souscripteur existant, mais les informations saisies ne concordent pas.'
									ELSE CAST(SubscriberID AS VARCHAR(10))
								END	
		FROM @tSuggestions	
END


