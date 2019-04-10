/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : VL_UN_Convention_IU
Description        : Fait les validations BD d'une convention avant sa sauvegarde.
Valeurs de retours : Dataset de données
Note               :					IA	2004-06-01	Bruno Lapointe		Création
											IA	2004-06-02	Bruno Lapointe		Point 10.11.03 (1.2) : Changement de bénéficiaire, le bénéficiaire doit avoir un NAS
							ADX0001028	BR	2004-08-27	Bruno Lapointe		La validation du NAS vide lors de changement de bénéficiaire ne regardait pas s'il y avait eu un changement de bénéficiaire.
							ADX0000831	IA	2004-06-02	Bruno Lapointe		Adaptation des conventions pour PCEE 4.3
											2010-02-11	Pierre Paquet		Ajustement sur la validation de la vérification de l'âge.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Convention_IU] (
	@ConventionID INTEGER, -- ID Unique de la convention (0 = Insertion, > 0 = Modification)
	@SubscriberID INTEGER, -- ID Unique du souscripteur 
	@CoSubscriberID INTEGER, -- ID Unique du co-souscripteur 
	@BeneficiaryID INTEGER)  -- ID unique du bénéficiaire
AS
BEGIN
	-- C01 -> Age maximum pour l'assurance souscripteur
	-- C02 -> Age minimal du souscripteur
	-- C03 -> Assurance souscripteur uniquement pour les résidents du canada
	-- C04 -> Age du bénéficiaire versus la modalité de paiement
	-- C05 -> Co-souscripteur sans NAS
	-- C06 -> Maximum de capital assuré
	-- C07 -> Changement de bénéficiaire, le bénéficiaire doit avoir un NAS
	-- C08 -> Le NAS du souscripteur doit différer de celui du bénéficiaire. 
	-- C09 -> Le NAS du souscripteur doit différer de celui du co-souscripteur.
	-- C10 -> Le NAS du co-souscripteur doit différer de celui du bénéficiaire.
	-- C11 -> Un souscripteur qui passe les pré-validations PCEE est requis. 
	-- C12 -> Un co-souscripteur qui passe les pré-validations PCEE est requis.
	-- C13 -> Un bénéficiaire qui passe les pré-validations PCEE est requis.

	DECLARE 
		@Result INTEGER

	CREATE TABLE #WngAndErr(
		Code VARCHAR(3),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	CREATE TABLE #ConventionNo(
		ConventionNo VARCHAR(75)
	)

	IF @ConventionID > 0
	BEGIN
		-- C01 -> Age maximum pour l'assurance souscripteur
		IF EXISTS (
			SELECT *
			FROM dbo.Mo_Human S
			WHERE S.HumanID = @SubscriberID
				AND S.IsCompany = 0 
				AND S.BirthDate > 0
			)
		BEGIN
			EXEC @Result = SP_VL_UN_MaxSubscInsurAgeForConvention @SubscriberID, @ConventionID
			IF @Result <= 0 
				INSERT INTO #WngAndErr
					SELECT 
						'C01',
						'',
						'',
						''
		END
	
		-- C02 -> Age minimal du souscripteur
		IF EXISTS (
			SELECT *
			FROM dbo.Mo_Human S
			WHERE S.HumanID = @SubscriberID
				AND S.IsCompany = 0 
				AND S.BirthDate > 0
			)
		BEGIN
			EXEC @Result = SP_VL_UN_MinSubscriberAgeForConvention @SubscriberID, @ConventionID
			IF @Result <= 0 
				INSERT INTO #WngAndErr
					SELECT 
						'C02',
						'',
						'',
						''
		END
	
		-- C03 -> Assurance souscripteur uniquement pour les résidents du canada
		INSERT INTO #ConventionNo
			EXEC SP_VL_UN_SubsInsOnlyForCanadianForConvention @ConventionID, @SubscriberID
		INSERT INTO #WngAndErr
			SELECT 
				'C03',
				ConventionNo,
				'',
				''
			FROM #ConventionNo
		DELETE FROM #ConventionNo
/*
		-- C04 -> Age du bénéficiaire versus la modalité de paiement
		EXEC @Result = SP_VL_UN_BenefAgeVsModalForConvention @ConventionID, @BeneficiaryID
		IF @Result <= 0 
			INSERT INTO #WngAndErr
				SELECT 
					'C04',
					'',
					'',
					''
*/
	END

	-- C05 -> Co-souscripteur sans NAS
	EXEC @Result = SP_VL_UN_NASOfCoSubscriberForConvention @CoSubscriberID
	IF @Result <= 0 
		INSERT INTO #WngAndErr
			SELECT 
				'C05',
				'',
				'',
				''

	-- C06 -> Maximum de capital assuré
	CREATE TABLE #MaxFaceAmount(
		MaxFaceAmount MONEY,
		TotalCapitalInsured MONEY
	)
	INSERT INTO #MaxFaceAmount
		EXEC SP_VL_UN_MaxFaceAmountForConvention @SubscriberID, @ConventionID
	INSERT INTO #WngAndErr
		SELECT 
			'C06',
			CAST(MaxFaceAmount AS VARCHAR),
			CAST(TotalCapitalInsured AS VARCHAR),
			''
		FROM #MaxFaceAmount
	DROP TABLE #MaxFaceAmount

	-- C07 -> Changement de bénéficiaire, le bénéficiaire doit avoir un NAS
	EXEC @Result = SP_VL_CRQ_HumanHaveNAS @BeneficiaryID
	IF @Result <= 0 AND 
		EXISTS (
			SELECT
				ConventionID
			FROM dbo.Un_Convention 
			WHERE ConventionID = @ConventionID
			  AND BeneficiaryID <> @BeneficiaryID
			)
		INSERT INTO #WngAndErr
			SELECT 
				'C07',
				'',
				'',
				''

	-- C08 -> Le NAS du souscripteur doit différer de celui du bénéficiaire. 
	IF @ConventionID > 0 --(Vérification effectuée lors de l'édition seulement)
	AND EXISTS (
		SELECT *
		FROM dbo.Mo_Human S, Mo_Human B
		WHERE B.HumanID = @BeneficiaryID
			AND S.HumanID = @SubscriberID
			AND B.SocialNumber = S.SocialNumber
		)
		INSERT INTO #WngAndErr
			SELECT 
				'C08',
				'',
				'',
				''
		
	-- C09 -> Le NAS du souscripteur doit différer de celui du co-souscripteur.
	IF ISNULL(@CoSubscriberID,0) > 0
	AND EXISTS (
		SELECT *
		FROM dbo.Mo_Human S, Mo_Human CS
		WHERE CS.HumanID = @CoSubscriberID
			AND S.HumanID = @SubscriberID
			AND CS.SocialNumber = S.SocialNumber
		)
		INSERT INTO #WngAndErr
			SELECT 
				'C09',
				'',
				'',
				''

	-- C10 -> Le NAS du co-souscripteur doit différer de celui du bénéficiaire.
	IF EXISTS (
		SELECT *
		FROM dbo.Mo_Human CS, Mo_Human B
		WHERE CS.HumanID = @CoSubscriberID
			AND B.HumanID = @BeneficiaryID
			AND B.SocialNumber = CS.SocialNumber
		)
		INSERT INTO #WngAndErr
			SELECT 
				'C10',
				'',
				'',
				''

	-- C11 -> Un souscripteur qui passe les pré-validations PCEE est requis. 
	IF EXISTS (
		SELECT *
		FROM dbo.Un_Subscriber S, Un_CESP100 G1
		WHERE S.SubscriberID = @SubscriberID
			AND G1.ConventionID = @ConventionID
			AND G1.iCESPSendFileID IS NOT NULL
			AND S.tiCESPState = 0
		)
		INSERT INTO #WngAndErr
			SELECT 
				'C11',
				'',
				'',
				''

	-- C12 -> Un co-souscripteur qui passe les pré-validations PCEE est requis.
	IF EXISTS (
		SELECT *
		FROM dbo.Un_Subscriber S, Un_CESP100 G1
		WHERE S.SubscriberID = @CoSubscriberID
			AND G1.ConventionID = @ConventionID
			AND G1.iCESPSendFileID IS NOT NULL
			AND S.tiCESPState = 0
		)
		INSERT INTO #WngAndErr
			SELECT 
				'C12',
				'',
				'',
				''

	-- C13 -> Un bénéficiaire qui passe les pré-validations PCEE est requis.
	IF EXISTS (
		SELECT *
		FROM dbo.Un_Beneficiary B, Un_CESP100 G1
		WHERE B.BeneficiaryID = @BeneficiaryID
			AND G1.ConventionID = @ConventionID
			AND G1.iCESPSendFileID IS NOT NULL
			AND B.tiCESPState = 0
		)
		INSERT INTO #WngAndErr
			SELECT 
				'C13',
				'',
				'',
				''

	DROP TABLE #ConventionNo

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
END


