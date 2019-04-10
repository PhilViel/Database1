/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_Beneficiary_IU
Description         :	Fait les validations BD d'un bénéficiaire.
Valeurs de retours  :	Dataset :
									Code		VARCHAR(3)		Code d'erreur
									Info1		VARCHAR(100)	Premier champ d'information
									Info2		VARCHAR(100)	Deuxième champ d'information
									Info3		VARCHAR(100)	Troisième champ d'information
Note                :						2004-06-08	Bruno Lapointe		Création
								ADX0000692	IA	2005-05-05	Bruno Lapointe		Ajout des calidations B02 et B03
								ADX0000826	IA	2006-03-14	Bruno Lapointe		Adaptation des bénéficiaires pour PCEE 4.3
								ADX0000798	IA	2006-03-17	Bruno Lapointe		Saisie des principaux responsables
								ADX0001011	IA	2006-06-02	Mireya Gonthier		Validation du NAS sur  l'ajout et la modification de bénéficiaire.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Beneficiary_IU] (
	@BeneficiaryID INTEGER, -- ID Unique du bénéficiaire (0 = Insertion, > 0 = Modification)
	@BirthDate DATETIME, -- Date de naissance
	@iTutorID INTEGER, -- ID du tuteur
	@bTutorIsSubscriber BIT, -- True : le tuteur est un souscripteur (Un_BeneficiaryID.iTutorID = Un_Subscriber.iTutorID).  False : le tuteur est un tuteur (Un_BeneficiaryID.iTutorID = Un_Tutor.iTutorID).
	@SocialNumber VARCHAR(75), -- Numéro d'assurance social du bénéficiaire
	@tiPCGType TINYINT, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Entreprise)
	@vcPCGFirstName VARCHAR(40), -- Prénom du principal responsable s’il s’agit d’un souscripteur ou d’une personne. Nom de l’entreprise principal responsable dans l’autre cas.
	@vcPCGLastName VARCHAR(50), -- Nom du principal responsable s’il s’agit d’un souscripteur ou d’une personne.
	@vcPCGSINOrEN VARCHAR(15) ) -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
AS
BEGIN
	-- B01 -> Age du bénéficiaire versus la modalité de paiement
	-- B02 -> Tant que l’adresse du tuteur sera manquante ou incomplète, aucun document ne pourra être expédié à ce tuteur 
	--	B03 -> Le prénom du principal responsable est obligatoire puisqu’au moins une convention du bénéficiaire réclame ou a réclamée le BEC ou la SCEE + 
	--	B04 -> Le nom du principal responsable est obligatoire puisqu’au moins une convention du bénéficiaire réclame ou a réclamée le BEC ou la SCEE + 
	-- B05 -> Le NAS du principal responsable est obligatoire puisqu’au moins une convention du bénéficiaire réclame ou a réclamée le BEC ou la SCEE +  
	-- B06 -> Le NE du principal responsable est obligatoire puisqu’au moins une convention du bénéficiaire réclame ou a réclamée le BEC ou la SCEE + 
	-- B07 -> Le NAS est obligatoire puisqu’au moins une convention est à l’état REEE 
	-- B08 -> Le NAS est déjà utilisé par un autre bénéficiaire
	-- B09 -> Le NAS est déjà utilisé par un souscripteur
	CREATE TABLE #WngAndErr(
		Code VARCHAR(3),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	CREATE TABLE #ConventionNo(
		ConventionNo VARCHAR(75)
	)

	-- B01 -> Age du bénéficiaire versus la modalité de paiement
	INSERT INTO #ConventionNo
		EXEC SP_VL_UN_BenefAgeVsModalForBeneficiary @BeneficiaryID, @BirthDate

	INSERT INTO #WngAndErr
		SELECT 
			'B01',
			ConventionNo,
			'',
			''
		FROM #ConventionNo

	DROP TABLE #ConventionNo

	-- B02 -> Tant que l’adresse du tuteur sera manquante ou incomplète, aucun document ne pourra être expédié à ce tuteur.
	IF NOT EXISTS
			(
			SELECT
				H.HumanID
			FROM dbo.Mo_Human H
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			WHERE @iTutorID = H.HumanID
				AND LTRIM(ISNULL(A.Address,'')) <> ''
				AND LTRIM(ISNULL(A.City,'')) <> ''
				AND LTRIM(ISNULL(A.StateName,'')) <> ''
				AND LTRIM(ISNULL(A.CountryID,'')) <> ''
				AND LTRIM(ISNULL(A.ZipCode,'')) <> ''
			)
		INSERT INTO #WngAndErr
			SELECT 
				'B02',
				'',
				'',
				''

	--	B03 -> Le prénom du principal responsable est obligatoire puisqu’au moins une convention du bénéficiaire réclame ou a réclamée le BEC ou la SCEE + 
	IF @tiPCGType IN (0,1)
	AND ISNULL(RTRIM(@vcPCGFirstName),'') = ''
	AND EXISTS (
		SELECT
			*
		FROM dbo.Un_Convention 
		WHERE BeneficiaryID = @BeneficiaryID
			AND( bACESGRequested <> 0
				OR bCLBRequested <> 0
				)
		)
		INSERT INTO #WngAndErr
			SELECT 
				'B03',
				'',
				'',
				''

	--	B04 -> Le nom du principal responsable est obligatoire puisqu’au moins une convention du bénéficiaire réclame ou a réclamée le BEC ou la SCEE + 
	IF ISNULL(RTRIM(@vcPCGLastName),'') = ''
	AND EXISTS (
		SELECT
			*
		FROM dbo.Un_Convention 
		WHERE BeneficiaryID = @BeneficiaryID
			AND( bACESGRequested <> 0
				OR bCLBRequested <> 0
				)
		)
		INSERT INTO #WngAndErr
			SELECT 
				'B04',
				'',
				'',
				''

	-- B05 -> Le NAS du principal responsable est obligatoire puisqu’au moins une convention du bénéficiaire réclame ou a réclamée le BEC ou la SCEE +  
	IF @tiPCGType IN (0,1)
	AND ISNULL(RTRIM(@vcPCGSINOrEN),'') = ''
	AND EXISTS (
		SELECT
			*
		FROM dbo.Un_Convention 
		WHERE BeneficiaryID = @BeneficiaryID
			AND( bACESGRequested <> 0
				OR bCLBRequested <> 0
				)
		)
		INSERT INTO #WngAndErr
			SELECT 
				'B05',
				'',
				'',
				''

	-- B06 -> Le NE du principal responsable est obligatoire puisqu’au moins une convention du bénéficiaire réclame ou a réclamée le BEC ou la SCEE + 
	IF @tiPCGType IN (2,3)
	AND ISNULL(RTRIM(@vcPCGSINOrEN),'') = ''
	AND EXISTS (
		SELECT
			*
		FROM dbo.Un_Convention 
		WHERE BeneficiaryID = @BeneficiaryID
			AND( bACESGRequested <> 0
				OR bCLBRequested <> 0
				)
		)
		INSERT INTO #WngAndErr
			SELECT 
				'B06',
				'',
				'',
				''

	-- B07 -> Le NAS est obligatoire puisqu’au moins une convention est à l’état REEE 
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
				WHERE C.BeneficiaryID = @BeneficiaryID
				  AND S.StartDate <= GETDATE()
				GROUP BY S.ConventionID
				) T
			JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
			JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
			) CS ON C.ConventionID = CS.ConventionID
		WHERE ISNULL(RTRIM(@SocialNumber),'') = '' -- Pas de NAS
			AND C.BeneficiaryID = @BeneficiaryID -- La convention appartient au souscripteur
			AND I.InForceDate > '1998-12-31' -- Date d'entrée en vigueur de la convention après le 31 décembre 1998
			AND CS.ConventionStateID = 'REE' -- État de la convention REEE
		)
		INSERT INTO #WngAndErr
			SELECT 
				'B07',
				'',
				'',
				''
	-- B08 -> Le NAS est déjà utilisé par un autre bénéficiaire
	IF EXISTS (
		SELECT *
		FROM dbo.Un_Beneficiary B
		JOIN dbo.Mo_Human H ON  H.HumanID = B.BeneficiaryID
		WHERE ISNULL(@SocialNumber,'') <> '' 		--Le NAS n'est pas vide
			AND @BeneficiaryID <> H.HumanID		--Pas la même personne
			AND @SocialNumber = H.SocialNumber 	--Même numéro d'assurance social
		)
		INSERT INTO #WngAndErr
			SELECT 
				'B08',
				'',
				'',
				''
	-- B09 -> Le NAS est déjà utilisé par un souscripteur
	IF EXISTS (
		SELECT *
		FROM dbo.Un_Subscriber S
		JOIN dbo.Mo_Human H ON  H.HumanID = S.SubscriberID
		WHERE ISNULL(@SocialNumber,'') <> '' 		--Le NAS n'est pas vide
			AND @BeneficiaryID <> H.HumanID		--Pas la même personne
			AND @SocialNumber = H.SocialNumber 	--Même numéro d'assurance social
			AND H.IsCompany = 0			--Pas une compagnie
		)
		INSERT INTO #WngAndErr
			SELECT 
				'B09',
				'',
				'',
				''
	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
END


