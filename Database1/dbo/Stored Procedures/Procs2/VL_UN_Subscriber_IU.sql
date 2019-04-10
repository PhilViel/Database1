/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                :	VL_UN_Subscriber_IU
Description        :	Fait les validations BD d'un souscripteur avant sa sauvegarde.
Valeurs de retours :	>0  : Tout à fonctionné
                      <=0 : Erreur SQL
								-1 : 	Erreur à la création du log
								-2 : 	Erreur à la suppression du souscripteur
Note               :						2004-05-26	Bruno Lapointe	Création
							ADX0000826	IA	2006-03-15	Bruno Lapointe			Adaptation des souscripteurs pour PCEE 4.3
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Subscriber_IU] (
	@SubscriberID INTEGER, -- ID Unique du souscripteur (0 = Insertion, > 0 = Modification)
	@BirthDate DATETIME, -- Date de naissance
	@ResidID VARCHAR(4), -- Pays de résidence
	@SocialNumber VARCHAR(75), -- NAS du souscripteur
	@IsCompany BIT ) -- Indique si le souscripteur est une compagnie 
AS
BEGIN
	-- S01 -> Age maximum pour l'assurance souscripteur
	-- S02 -> Age minimal du souscripteur
	-- S03 -> Assurance souscripteur uniquement pour les résidents du canada
	-- S04 -> Co-souscripteur sans NAS
	-- S05 -> Le NAS est déjà utilisé par un autre souscripteur. 
	-- S06 -> Le NAS est déjà utilisé par un bénéficiaire.
	-- S07 -> Le NAS est obligatoire puisqu’au moins une convention signée après le 31 décembre 1998 est à l’état REEE. 

	CREATE TABLE #WngAndErr(
		Code VARCHAR(3),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	CREATE TABLE #ConventionNo(
		ConventionNo VARCHAR(75)
	)

	-- S01 -> Age maximum pour l'assurance souscripteur
	IF @IsCompany = 0 AND @BirthDate > 0
		INSERT INTO #ConventionNo
			EXEC SP_VL_UN_MaxSubscInsurAgeForSubscriber @SubscriberID, @BirthDate

	INSERT INTO #WngAndErr
		SELECT 
			'S01',
			ConventionNo,
			'',
			''
		FROM #ConventionNo

	DELETE FROM #ConventionNo

	-- S02 -> Age minimal du souscripteur
	IF @IsCompany = 0 AND @BirthDate > 0
		INSERT INTO #ConventionNo
			EXEC SP_VL_UN_MinSubscriberAgeForSubscriber @SubscriberID, @BirthDate

	INSERT INTO #WngAndErr
		SELECT 
			'S02',
			ConventionNo,
			'',
			''
		FROM #ConventionNo

	DELETE FROM #ConventionNo

	-- S03 -> Assurance souscripteur uniquement pour les résidents du canada
	INSERT INTO #ConventionNo
		EXEC SP_VL_UN_SubsInsOnlyForCanadianForSubscriber @SubscriberID, @ResidID

	INSERT INTO #WngAndErr
		SELECT 
			'S03',
			ConventionNo,
			'',
			''
		FROM #ConventionNo

	DELETE FROM #ConventionNo

	-- S04 -> Co-souscripteur sans NAS
	INSERT INTO #ConventionNo
		EXEC SP_VL_UN_NASOfCoSubscriberForSubscriber @SubscriberID

	INSERT INTO #WngAndErr
		SELECT 
			'S04',
			ConventionNo,
			'',
			''
		FROM #ConventionNo

	DROP TABLE #ConventionNo

	-- S05 -> Le NAS est déjà utilisé par un autre souscripteur. 
	IF EXISTS (
		SELECT *
		FROM dbo.Un_Subscriber S
		JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
		WHERE ISNULL(@SocialNumber,'') <> '' -- Le NAS n'est pas vide
			AND @SubscriberID <> S.SubscriberID -- Pas la même personne
			AND @SocialNumber = H.SocialNumber -- Même numéro d'assurance social
			AND @IsCompany = H.IsCompany -- Même type
		)
		INSERT INTO #WngAndErr
			SELECT 
				'S05',
				'',
				'',
				''

	-- S06 -> Le NAS est déjà utilisé par un bénéficiaire.
	IF EXISTS (
		SELECT *
		FROM dbo.Un_Beneficiary B
		JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
		WHERE ISNULL(@SocialNumber,'') <> '' -- Le NAS n'est pas vide
			AND @SubscriberID <> H.HumanID -- Pas la même personne
			AND @SocialNumber = H.SocialNumber -- Même numéro d'assurance social
			AND @IsCompany = 0 -- Pas une compagnie
		)
		INSERT INTO #WngAndErr
			SELECT 
				'S06',
				'',
				'',
				''

	-- S07 -> Le NAS est obligatoire puisqu’au moins une convention signée après le 31 décembre 1998 est à l’état REEE. 
	IF EXISTS (
		SELECT *
		FROM dbo.Un_Convention C
		JOIN (-- Retourne la date d'entrée en vigueur de la convention
			SELECT 
				ConventionID,
				InForceDate = MIN(InForceDate)
			FROM dbo.Un_Unit 
			GROUP BY ConventionID
			) I ON I.ConventionID = C.ConventionID
		JOIN (-- Retrouve l'état actuel d'une convention
			SELECT 
				T.ConventionID,
				CS.ConventionStateID,
				CS.ConventionStateName
			FROM (-- Retourne la plus grande date de début d'un état par convention
				SELECT 
					S.ConventionID,
					MaxDate = MAX(S.StartDate)
				FROM Un_ConventionConventionState S
				JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
				WHERE C.SubscriberID = @SubscriberID
				  AND S.StartDate <= GETDATE()
				GROUP BY S.ConventionID
				) T
			JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
			JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
			) CS ON C.ConventionID = CS.ConventionID
		WHERE ISNULL(RTRIM(@SocialNumber),'') = '' -- Pas de NAS
			AND C.SubscriberID = @SubscriberID -- La convention appartient au souscripteur
			AND I.InForceDate > '1998-12-31' -- Date d'entrée en vigueur de la convention après le 31 décembre 1998
			AND CS.ConventionStateID = 'REE' -- État de la convention REEE
		)
		INSERT INTO #WngAndErr
			SELECT 
				'S07',
				'',
				'',
				''

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr;
END;


