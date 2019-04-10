/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : TT_UN_RecreateGovernmentPrevalError
Description         : Révalue les erreurs de pré validations pour toutes les conventions
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
Note                :	ADX0000578	IA	2004-11-25	Bruno Lapointe		Migration et correction des erreurs de pré 
										validations
								ADX0001177	BR	2004-12-01	Bruno Lapointe		Changement des codes d'erreurs et des validations
	 							ADX0000692	IA	2005-05-04	Bruno Lapointe		Prendre le tuteur du iTutorID au lieu de celui du
																							champ texte TutorName
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_RecreateGovernmentPrevalError] (
	@ConnectID INTEGER) -- ID unique de connextion de l'usager
AS
BEGIN
	DECLARE
		@iErrorID MoID,
		@iConventionID MoID,
		@iBeneficiaryID MoID,
		@iSubscriberID MoID,
		@dtInForceDate MoDate,
		@iUnBenefLinkTypeID UnBenefLinkType,
		@vcSocialNumber MoDesc,
		@vcFirstName MoDesc,
		@vcLastName MoDesc,
		@dtBirthDate MoDate,
		@cSexID MoDesc,
		@vcAddress MoDesc,
		@vcCity MoDesc,
		@vcStateCode MoDesc,
		@cCountryID MoDesc,
		@vcZipCode MoDesc,
		@cLangID MoDesc,
		@iTutorID INTEGER,
		@bIsCompany BIT

	DELETE 
	FROM Un_GovernmentPrevalError

	DECLARE PrevalCursor CURSOR FOR
		SELECT 
			C.ConventionID,
			VI.InForceDate,
			tiRelationshipTypeID,
			H.BirthDate
		FROM dbo.Un_Convention C
		JOIN (
			SELECT 
				ConventionID, 
				InForceDate = MIN(InForceDate)
			FROM dbo.Un_Unit 
			WHERE InforceDate IS NOT NULL
			GROUP BY ConventionID
			) VI ON VI.ConventionID = C.ConventionID
		JOIN (
			SELECT 
				ConventionID,
				IntReimbDate = MAX(IntReimbDate)
			FROM dbo.Un_Unit 
			GROUP BY ConventionID
			) VT ON VT.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human h ON (H.HumanID = C.BeneficiaryID)
		WHERE VT.IntReimbDate IS NULL 
			OR (VT.IntReimbDate >= '01-01-1998')

	OPEN PrevalCursor
		
	FETCH NEXT FROM PrevalCursor INTO
		@iConventionID,
		@dtInForceDate,
		@iUnBenefLinkTypeID,
		@dtBirthDate

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Validation du type de lien du bénéficiaire 
		IF ISNULL(@iUnBenefLinkTypeID,0) NOT IN (1,2,3,4,5,6)
			-- Le lien de parenté doit en être un reconnu
			INSERT INTO Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				@ConnectID, 
				'Un_Convention', 
				@iConventionID, 
				60)

		FETCH NEXT FROM PrevalCursor INTO
			@iConventionID,
			@dtInForceDate,
			@iUnBenefLinkTypeID,
			@dtBirthDate
	END
	CLOSE PrevalCursor
	DEALLOCATE PrevalCursor

	DECLARE PrevalCursor CURSOR FOR
		SELECT
			S.SubscriberID,
			H.SocialNumber,
			H.FirstName,
			H.LastName,
			H.BirthDate,
			H.SexID,
			A.Address,
			A.City,
			ST.StateCode,
			A.CountryID,
			ZipCode = REPLACE(A.ZipCode,' ',''),
			H.LangID,
			H.IsCompany
		FROM dbo.Un_Subscriber S
		JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
		JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		LEFT JOIN Mo_State ST ON ST.StateName = A.StateName
		JOIN dbo.Un_Convention C ON C.SubscriberID = S.SubscriberID OR ISNULL(C.CoSubscriberID,0) = S.SubscriberID
		JOIN (
			SELECT 
				ConventionID,
				IntReimbDate = MAX(IntReimbDate)
			FROM dbo.Un_Unit 
			GROUP BY ConventionID
			) VT ON VT.ConventionID = C.ConventionID
		WHERE VT.IntReimbDate IS NULL
			OR (VT.IntReimbDate >= '01-01-1998')

	OPEN PrevalCursor
	
	FETCH NEXT FROM PrevalCursor INTO
		@iSubscriberID,
		@vcSocialNumber,
		@vcFirstName,
		@vcLastName,
		@dtBirthDate,
		@cSexID,
		@vcAddress,
		@vcCity,
		@vcStateCode,
		@cCountryID,
		@vcZipCode,
		@cLangID,
		@bIsCompany

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @vcSocialNumber = REPLACE(ISNULL(@vcSocialNumber,''),' ','')
	
		-- Validation du NAS
		IF @vcSocialNumber = ''
			-- Le NAS du souscripteur est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Subscriber', 
				@iSubscriberID, 
				31)
		ELSE IF LEN(@vcSocialNumber) <> 9
			-- Le NAS du souscripteur doit avoir neuf (9) chiffres
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Subscriber', 
				@iSubscriberID, 
				32)
		ELSE
		BEGIN
			IF dbo.FN_CRI_CheckSin(@vcSocialNumber,@bIsCompany) = 0
				-- Le NAS du souscripteur n'est pas valide selon le calcul du coefficient 10 amélioré.
				INSERT Un_GovernmentPrevalError (
					ConnectID, 
					TableName, 
					CodeID, 
					ErrorCode)
				VALUES (
					1, 
					'Un_Subscriber', 
					@iSubscriberID, 
					33)
		END
	
		-- Validation du prenom
		IF RTRIM(LTRIM(ISNULL(@vcFirstName,''))) = ''
			-- Le prénom du souscripteur est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Subscriber', 
				@iSubscriberID, 
				34)
	
		-- Validation du Nom
		IF RTRIM(LTRIM(ISNULL(@vcLastName,''))) = ''
			-- Le nom du souscripteur est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Subscriber', 
				@iSubscriberID, 
				35)
				
		-- Validation de l'adresse
		IF RTRIM(LTRIM(ISNULL(@vcAddress,''))) = ''
			-- L'adresse du souscripteur est obligatoire (#civique, rue et #appartement s'il y a lieu)
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Subscriber', 
				@iSubscriberID, 
				36)
	
		-- Validation de la ville
		IF RTRIM(LTRIM(ISNULL(@vcCity,''))) = ''
			-- La ville du souscripteur est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Subscriber', 
				@iSubscriberID, 
				37)
	
		-- Validation de la province
		IF @cCountryID = 'CAN' AND RTRIM(LTRIM(@vcStateCode)) = ''
			-- La province du souscripteur est obligatoire si le pays est CANADA
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Subscriber', 
				@iSubscriberID, 
				38)
			
		IF @cCountryID = 'CAN' AND
			RTRIM(LTRIM(@vcStateCode)) <> '' AND
			UPPER(@vcStateCode) <> 'AB' AND
			UPPER(@vcStateCode) <> 'BC' AND
		 	UPPER(@vcStateCode) <> 'MB' AND
			UPPER(@vcStateCode) <> 'NB' AND
			UPPER(@vcStateCode) <> 'NF' AND
			UPPER(@vcStateCode) <> 'NS' AND
			UPPER(@vcStateCode) <> 'NT' AND
			UPPER(@vcStateCode) <> 'NU' AND
			UPPER(@vcStateCode) <> 'ON' AND
			UPPER(@vcStateCode) <> 'PE' AND
			UPPER(@vcStateCode) <> 'QC' AND
			UPPER(@vcStateCode) <> 'PQ' AND
			UPPER(@vcStateCode) <> 'SK' AND
			UPPER(@vcStateCode) <> 'YT'
			-- La province du souscripteur doit être canadienne quand le pays est CANADA
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Subscriber', 
				@iSubscriberID, 
				39)
		
		IF @cCountryID <> 'CAN' AND 
			RTRIM(LTRIM(ISNULL(@cCountryID,''))) NOT IN ('', 'UNK') AND
			RTRIM(LTRIM(@vcStateCode)) <> '' AND
			(UPPER(@vcStateCode) = 'AB' OR
			 UPPER(@vcStateCode) = 'BC' OR
			 UPPER(@vcStateCode) = 'MB' OR
			 UPPER(@vcStateCode) = 'NB' OR
			 UPPER(@vcStateCode) = 'NF' OR
			 UPPER(@vcStateCode) = 'NS' OR
			 UPPER(@vcStateCode) = 'NT' OR
			 UPPER(@vcStateCode) = 'NU' OR
			 UPPER(@vcStateCode) = 'ON' OR
			 UPPER(@vcStateCode) = 'PE' OR
			 UPPER(@vcStateCode) = 'QC' OR
			 UPPER(@vcStateCode) = 'PQ' OR
			 UPPER(@vcStateCode) = 'SK' OR
			 UPPER(@vcStateCode) = 'YT')
			-- La province du souscripteur ne doit pas être canadienne quand le pays n'est pas CANADA
		    INSERT Un_GovernmentPrevalError (
		      ConnectID, 
		      TableName, 
		      CodeID, 
		      ErrorCode)
		    VALUES (
		      1, 
		      'Un_Subscriber', 
		      @iSubscriberID, 
		      40)
	
		-- Validation du pays
		IF RTRIM(LTRIM(ISNULL(@cCountryID,''))) IN ('', 'UNK')
			-- Le pays du souscripteur est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Subscriber', 
				@iSubscriberID, 
				41)
	
		-- Validation du code postal
		IF @cCountryID = 'CAN'
		BEGIN
			SET @vcZipCode = REPLACE(ISNULL(@vcZipCode,''),' ','')
	
			IF @vcZipCode = ''
				-- Le code postal du souscripteur est obligatoire si le pays est CANADA
				INSERT Un_GovernmentPrevalError (
					ConnectID, 
					TableName, 
					CodeID, 
					ErrorCode)
				VALUES (
					1, 
					'Un_Subscriber', 
					@iSubscriberID, 
					42)
			ELSE
			BEGIN
				IF LEN ( @vcZipCode ) <> 6
				OR SUBSTRING ( @vcZipCode, 1, 1 ) NOT BETWEEN  'A' AND 'Y'
				OR SUBSTRING ( @vcZipCode, 1, 1 ) IN ( 'D', 'F', 'I', 'O', 'U', 'W' )
				OR SUBSTRING ( @vcZipCode, 2, 1 ) NOT BETWEEN '0' AND '9'
				OR SUBSTRING ( @vcZipCode, 3, 1 ) NOT BETWEEN 'A' AND 'Z'
				OR SUBSTRING ( @vcZipCode, 3, 1 ) IN ( 'D', 'F', 'I', 'O', 'U' )
				OR SUBSTRING ( @vcZipCode, 4, 1 ) NOT BETWEEN '0' AND '9'
				OR SUBSTRING ( @vcZipCode, 5, 1 ) NOT BETWEEN 'A' AND 'Z'
				OR SUBSTRING ( @vcZipCode, 5, 1 ) IN ( 'D', 'F', 'I', 'O', 'U' )
				OR SUBSTRING ( @vcZipCode, 6, 1 ) NOT BETWEEN '0' AND '9'
					-- Le code postal du souscripteur doit être valide
					INSERT Un_GovernmentPrevalError (
						ConnectID, 
						TableName, 
						CodeID, 
						ErrorCode)
					VALUES (
						1, 
						'Un_Subscriber', 
						@iSubscriberID, 
						43)
			END
		END

		FETCH NEXT FROM PrevalCursor INTO
			@iSubscriberID,
			@vcSocialNumber,
			@vcFirstName,
			@vcLastName,
			@dtBirthDate,
			@cSexID,
			@vcAddress,
			@vcCity,
			@vcStateCode,
			@cCountryID,
			@vcZipCode,
			@cLangID,
			@bIsCompany
	END
	CLOSE PrevalCursor
	DEALLOCATE PrevalCursor

	DECLARE PrevalCursor CURSOR FOR
		SELECT
			B.BeneficiaryID,
			H.SocialNumber,
			H.FirstName,
			H.LastName,
			H.BirthDate,
			H.SexID,
			A.Address,
			A.City,
			ST.StateCode,
			A.CountryID,
			ZipCode = REPLACE(A.ZipCode,' ',''),
			H.LangID,
			B.iTutorID
		FROM dbo.Un_Beneficiary B
		JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
		JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		LEFT JOIN Mo_State ST ON ST.StateName = A.StateName
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
		JOIN (
			SELECT 
				ConventionID,
				IntReimbDate = MAX(IntReimbDate)
			FROM dbo.Un_Unit 
			GROUP BY ConventionID
			) VT ON VT.ConventionID = C.ConventionID
		WHERE VT.IntReimbDate IS NULL 
			OR (VT.IntReimbDate >= '01-01-1998')

	OPEN PrevalCursor

	FETCH NEXT FROM PrevalCursor INTO
		@iBeneficiaryID,
		@vcSocialNumber,
		@vcFirstName,
		@vcLastName,
		@dtBirthDate,
		@cSexID,
		@vcAddress,
		@vcCity,
		@vcStateCode,
		@cCountryID,
		@vcZipCode,
		@cLangID,
		@iTutorID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @vcSocialNumber = REPLACE(ISNULL(@vcSocialNumber,''),' ','')
	
		-- Validation du NAS
		IF @vcSocialNumber = ''
			-- Le NAS du bénéficiaire est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				1)
		ELSE IF LEN(@vcSocialNumber) <> 9
			-- Le NAS du bénéficiaire doit avoir neuf (9) chiffres
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				2)
		ELSE
		BEGIN
			IF dbo.FN_CRI_CheckSin(@vcSocialNumber,0) = 0
				-- Le NAS du bénéficiaire n'est pas valide selon le calcul du coefficient 10 amélioré.
				INSERT Un_GovernmentPrevalError (
					ConnectID, 
					TableName, 
					CodeID, 
					ErrorCode)
				VALUES (
					1, 
					'Un_Beneficiary', 
					@iBeneficiaryID, 
					3)
		END
	
		-- Validation du prenom
		IF RTRIM(LTRIM(ISNULL(@vcFirstName,''))) = ''
			-- Le prénom du bénéficiaire est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				4)
	
		-- Validation du Nom
		IF RTRIM(LTRIM(ISNULL(@vcLastName,''))) = ''
			-- Le nom du bénéficiaire est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				5)
				
		-- Validation de la date de naissance
		IF ISNULL(@dtBirthDate,0) <= 0
			-- Le date de naissance du bénéficiaire est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				6)
		
		-- Validation du sexe
		IF ISNULL(@cSexID,'') = ''
			-- Le sexe du bénéficiaire est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				7)
		ELSE IF @cSexID NOT IN ('F','M')
			-- Le sexe du bénéficiaire doit être maxculin ou féminin
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				8)
	
		-- Validation de l'adresse
		IF RTRIM(LTRIM(ISNULL(@vcAddress,''))) = ''
			-- L'adresse du bénéficiaire est obligatoire (#civique, rue et #appartement s'il y a lieu)
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				9)
	
		-- Validation de la ville
		IF RTRIM(LTRIM(ISNULL(@vcCity,''))) = ''
			-- La ville du bénéficiaire est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				10)
	
		-- Validation de la province
		IF @cCountryID = 'CAN' AND RTRIM(LTRIM(@vcStateCode)) = ''
			-- La province du bénéficiaire est obligatoire si le pays est CANADA
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				11)
			
		IF @cCountryID = 'CAN' AND
			RTRIM(LTRIM(@vcStateCode)) <> '' AND
			UPPER(@vcStateCode) <> 'AB' AND
			UPPER(@vcStateCode) <> 'BC' AND
		 	UPPER(@vcStateCode) <> 'MB' AND
			UPPER(@vcStateCode) <> 'NB' AND
			UPPER(@vcStateCode) <> 'NF' AND
			UPPER(@vcStateCode) <> 'NS' AND
			UPPER(@vcStateCode) <> 'NT' AND
			UPPER(@vcStateCode) <> 'NU' AND
			UPPER(@vcStateCode) <> 'ON' AND
			UPPER(@vcStateCode) <> 'PE' AND
			UPPER(@vcStateCode) <> 'QC' AND
			UPPER(@vcStateCode) <> 'PQ' AND
			UPPER(@vcStateCode) <> 'SK' AND
			UPPER(@vcStateCode) <> 'YT'
			-- La province du bénéficiaire doit être canadienne quand le pays est CANADA
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				12)
		
		IF @cCountryID <> 'CAN' AND 
			RTRIM(LTRIM(ISNULL(@cCountryID,''))) NOT IN ('', 'UNK') AND
			RTRIM(LTRIM(@vcStateCode)) <> '' AND
			(UPPER(@vcStateCode) = 'AB' OR
			 UPPER(@vcStateCode) = 'BC' OR
			 UPPER(@vcStateCode) = 'MB' OR
			 UPPER(@vcStateCode) = 'NB' OR
			 UPPER(@vcStateCode) = 'NF' OR
			 UPPER(@vcStateCode) = 'NS' OR
			 UPPER(@vcStateCode) = 'NT' OR
			 UPPER(@vcStateCode) = 'NU' OR
			 UPPER(@vcStateCode) = 'ON' OR
			 UPPER(@vcStateCode) = 'PE' OR
			 UPPER(@vcStateCode) = 'QC' OR
			 UPPER(@vcStateCode) = 'PQ' OR
			 UPPER(@vcStateCode) = 'SK' OR
			 UPPER(@vcStateCode) = 'YT')
			-- La province du bénéficiaire ne doit pas être canadienne quand le pays n'est pas CANADA
		    INSERT Un_GovernmentPrevalError (
		      ConnectID, 
		      TableName, 
		      CodeID, 
		      ErrorCode)
		    VALUES (
		      1, 
		      'Un_Beneficiary', 
		      @iBeneficiaryID, 
		      13)
	
		-- Validation du pays
		IF RTRIM(LTRIM(ISNULL(@cCountryID,''))) IN ('', 'UNK')
			-- Le pays du bénéficiaire est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				14)
	
		-- Validation du code postal
		IF @cCountryID = 'CAN'
		BEGIN
			SET @vcZipCode = REPLACE(ISNULL(@vcZipCode,''),' ','')
	
			IF @vcZipCode = ''
				-- Le code postal du bénéficiaire est obligatoire si le pays est CANADA
				INSERT Un_GovernmentPrevalError (
					ConnectID, 
					TableName, 
					CodeID, 
					ErrorCode)
				VALUES (
					1, 
					'Un_Beneficiary', 
					@iBeneficiaryID, 
					15)
			ELSE
			BEGIN
				IF LEN ( @vcZipCode ) <> 6
				OR SUBSTRING ( @vcZipCode, 1, 1 ) NOT BETWEEN  'A' AND 'Y'
				OR SUBSTRING ( @vcZipCode, 1, 1 ) IN ( 'D', 'F', 'I', 'O', 'U', 'W' )
				OR SUBSTRING ( @vcZipCode, 2, 1 ) NOT BETWEEN '0' AND '9'
				OR SUBSTRING ( @vcZipCode, 3, 1 ) NOT BETWEEN 'A' AND 'Z'
				OR SUBSTRING ( @vcZipCode, 3, 1 ) IN ( 'D', 'F', 'I', 'O', 'U' )
				OR SUBSTRING ( @vcZipCode, 4, 1 ) NOT BETWEEN '0' AND '9'
				OR SUBSTRING ( @vcZipCode, 5, 1 ) NOT BETWEEN 'A' AND 'Z'
				OR SUBSTRING ( @vcZipCode, 5, 1 ) IN ( 'D', 'F', 'I', 'O', 'U' )
				OR SUBSTRING ( @vcZipCode, 6, 1 ) NOT BETWEEN '0' AND '9'
					-- Le code postal du bénéficiaire doit être valide
					INSERT Un_GovernmentPrevalError (
						ConnectID, 
						TableName, 
						CodeID, 
						ErrorCode)
					VALUES (
						1, 
						'Un_Beneficiary', 
						@iBeneficiaryID, 
						16)
			END
		END
	
		-- Validation de la langue
		IF ISNULL(@cLangID,'UNK') IN ('UNK','')
			-- La langue du bénéficiaire est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				17)
	
		-- Validation du tuteur
		IF ISNULL(@iTutorID,0) = 0
			-- Le tuteur du bénéficiaire est obligatoire
			INSERT Un_GovernmentPrevalError (
				ConnectID, 
				TableName, 
				CodeID, 
				ErrorCode)
			VALUES (
				1, 
				'Un_Beneficiary', 
				@iBeneficiaryID, 
				18)

		FETCH NEXT FROM PrevalCursor INTO
			@iBeneficiaryID,
			@vcSocialNumber,
			@vcFirstName,
			@vcLastName,
			@dtBirthDate,
			@cSexID,
			@vcAddress,
			@vcCity,
			@vcStateCode,
			@cCountryID,
			@vcZipCode,
			@cLangID,
			@iTutorID
	END
	CLOSE PrevalCursor
	DEALLOCATE PrevalCursor
END


