/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	VL_UN_BeneficiarySuggest
Description 		:	Valide les entrées pour les suggestions de bénéficiaires
Valeurs de retour	:	Dataset :
							vcErrorCode		CHAR(3)			Code d’erreur
							vcErrorText		VARCHAR(1000)	Texte de l’erreur
						Code d’erreur		Erreur						
						BS1					Le NAS saisi appartient à un bénéficiaire existant, mais les informations saisies ne concordent pas.
						BS2					Le NAS saisi appartient à un bénéficiaire existant, mais certaines informations saisies ne concordent pas avec ce dernier.

Note			:	ADX0001234	IA	2007-02-15	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_BeneficiarySuggest] (
	@FirstName VARCHAR(35),		--Prénom du bénéficiaire	
	@LastName VARCHAR(50),		--Nom du bénéficiaire
	@ZipCode VARCHAR(10),		--Code Postal
	@Phone1	VARCHAR(27),		--Numéro de téléphone résidentiel	
	@BirthDate DATETIME,		--Date de naissance
	@SocialNumber VARCHAR(75))	--NAS : Numéro d’assurance sociale 
AS
BEGIN
	DECLARE @tSuggestions TABLE(
		BeneficiaryID INTEGER,
		bSameFirstName INTEGER,
		bSameLastName INTEGER,
		bSameZipCode INTEGER,
		bSameBirthDate INTEGER,
		bSamePhone1 INTEGER)

	DECLARE @Sum INTEGER
	SET @Sum = 0

	INSERT INTO @tSuggestions
		SELECT	
			B.BeneficiaryID,	
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
									WHEN ISNULL(A.Phone1,'') = ISNULL(@Phone1,'') THEN 1
									ELSE 0
								END						--Indique si le numéro de téléphone résidentiel est identique (1=Oui)					
		FROM dbo.Un_Beneficiary B
		JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
		JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		WHERE H.SocialNumber = @SocialNumber				

	SELECT TOP 1
			@Sum = ISNULL(bSameFirstName,0) + ISNULL(bSameLastName,0) + ISNULL(bSameZipCode,0) + ISNULL(bSameBirthDate,0) + ISNULL(bSamePhone1,0)
	FROM @tSuggestions

	SELECT 
			vcErrorCode = CASE
								WHEN @Sum < 3 THEN 'BS1'
								WHEN @Sum < 5 THEN 'BS2'
								ELSE 'BS3'
							END,
			vcErrorText = CASE
								WHEN @Sum < 3 THEN 'Le NAS saisi appartient à un bénéficiaire existant, mais les informations saisies ne concordent pas.'
								ELSE CAST(BeneficiaryID AS VARCHAR(10))
							END		
	FROM @tSuggestions
END


