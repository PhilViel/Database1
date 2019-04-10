/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 					:	IU_UN_ReSendSubscriberCESP200 
Description 		:	Forcer l’envoi au PCEE d’un souscripteur 
Valeurs de retour	:	@ReturnValue :
								> 0 : Réussite
								<= 0 : Échec.
Note					:	ADX0001362	IA	2007-04-26	Bruno Lapointe		Création
							ADX0002539	BR	2007-08-14	Bruno Lapointe		Ne supprimait les enregistrements 
																						200 du même type non envoyés
											2015-02-02	Donald Huppé	Faire un left join sur mo_state car il peut être null et la 200 ne se créé pas
											2015-02-13	Donald Huppé	Gestion du pays autre que CAN ou USA.
											2015-02-24	Pierre-Luc Simard	La ville peut être NULL
*************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_ReSendSubscriberCESP200] (
	@ConventionID INT) -- ID de la convention	
AS
BEGIN
	DECLARE @iResult INT
	
	SET @iResult = @ConventionID
	
	DECLARE @tCESPOfConventions TABLE (
		ConventionID INTEGER PRIMARY KEY,
		EffectDate DATETIME NOT NULL )

	INSERT INTO @tCESPOfConventions
		SELECT 
			C.ConventionID,
			EffectDate = -- Date d'entrée en vigueur de la convention pour le PCEE
				CASE 
					-- Avant le 1 janvier 2003 on envoi toujours la date d'entrée en vigueur de la convention
					WHEN C.dtRegStartDate < '2003-01-01' THEN C.dtRegStartDate
					-- La date d'entrée en vigueur de la convention est la récente c'est donc elle qu'on envoit
					WHEN C.dtRegStartDate > B.BirthDate THEN C.dtRegStartDate
					-- La date de naissance du bénéficiaire est la plus récente c'est donc elle qu'on envoit
					ELSE B.BirthDate		
				END
		FROM dbo.Un_Convention C 
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
		WHERE	C.ConventionID = @ConventionID
			AND C.tiCESPState > 0 -- Pré-validation minimums passe sur la convention
			AND C.bSendToCESP <> 0 -- À envoyer au PCEE			
			AND C.dtRegStartDate IS NOT NULL	
		GROUP BY 
			C.ConventionID, 
			C.dtRegStartDate,
			B.BirthDate

	-----------------
	BEGIN TRANSACTION
	-----------------

	DELETE
	FROM Un_CESP200
	WHERE iCESPSendFileID IS NULL -- Pas envoyé
		AND tiType = 4 -- Souscripteur
		AND ConventionID IN (SELECT ConventionID FROM @tCESPOfConventions)

	IF @@ERROR <> 0 
		SET @iResult = -1

	IF @iResult > 0
		-- Insert les enregistrements 200 Souscripteur
		INSERT INTO Un_CESP200 (
				ConventionID,
				HumanID,
				tiRelationshipTypeID,
				vcTransID,
				tiType,
				dtTransaction, 
				iPlanGovRegNumber,
				ConventionNo,
				vcSINorEN,
				vcFirstName,
				vcLastName,
				dtBirthdate,
				cSex,
				vcAddress1,
				vcAddress2,
				vcAddress3,
				vcCity,
				vcStateCode,
				CountryID,
				vcZipCode,
				cLang,
				vcTutorName,
				bIsCompany )
			SELECT
				C.ConventionID,
				HumanID = S.SubscriberID,
				C.tiRelationshipTypeID,
				'SUB',
				tiType = 4,
				dtTransaction = CS.EffectDate,
				iPlanGovRegNumber = P.PlanGovernmentRegNo,
				ConventionNo = C.ConventionNo,
				vcSINorEN = H.SocialNumber,
				vcFirstName = ISNULL(H.FirstName,''),
				vcLastName = H.LastName,
				dtBirthdate = H.BirthDate,
				cSex = H.SexID,
				vcAddress1 = A.Address,
				vcAddress2 = 
					CASE
						WHEN RTRIM(A.CountryID) <> 'CAN' THEN isnull(A.Statename,'')
					ELSE ''
					END,
				vcAddress3 =
					CASE
						WHEN RTRIM(A.CountryID) NOT IN ('CAN','USA') THEN ISNULL(Co.CountryName,'')
					ELSE ''
					END,
				vcCity = ISNULL(A.City,''),
				vcStateCode = 
					CASE
						WHEN RTRIM(A.CountryID) = 'CAN' THEN UPPER(ST.StateCode)
					ELSE '' 
					END,
				CountryID = A.CountryID, -- Normalement, si différent de CAN ou USA, on devrait mettre OTH, mais la foreign key su mo_country ne fonctionnerait plus. À la place, On gère ça dans la création du fichier ASCII dans SL_UN_CESPSendFileASCII
				vcZipCode = --A.ZipCode,
					CASE
						WHEN RTRIM(A.CountryID) = 'CAN' THEN A.ZipCode
					ELSE ''
					END,
				cLang = H.LangID,
				vcTutorName = NULL,
				bIsCompany = H.IsCompany
			FROM dbo.Un_Beneficiary B
			JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
			JOIN @tCESPOfConventions CS ON CS.ConventionID = C.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			JOIN Mo_Country Co ON Co.CountryID = A.CountryID
			left JOIN Mo_State ST ON ST.StateName = A.StateName

	IF @@ERROR <> 0 
		SET @iResult = -2
	ELSE
	BEGIN
		-- Inscrit le vcTransID avec le ID Ex: SUB + <iCESP200ID>.
		UPDATE Un_CESP200
		SET vcTransID = vcTransID+CAST(iCESP200ID AS VARCHAR(12))
		WHERE vcTransID = 'SUB'

		IF @@ERROR <> 0 
			SET @iResult = -3
	END
	
	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN(@iResult)
END


