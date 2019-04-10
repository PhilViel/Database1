/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESP100And200Tool
Description         :	Renvoi les données pour l’outil de traitement des erreurs sur 100 et 200
Valeurs de retours  :	Dataset :
				iCESP800ID			INTEGER		ID unique de l’erreur.
				iTransactionType	INTEGER		Type de transaction en erreur (100 ou 200)
				bModified			BIT			Indique quand le bénéficiaire ou le souscripteur selon le cas aura été modifié sur une des données envoyées au PCEE depuis l’envoi de l’enregistrement 200 revenus en erreur.
				ConventionID		INTEGER		ID de la convention
				ConventionNo		VARCHAR(75)	Numéro de convention.
				tiType				TINYINT		Type de 200, 3 = bénéficiaire et 4 = souscripteur., 5,6,7 a afficher tel quel
				SubscriberID		INTEGER		ID du souscripteur
				vcSubscriber		VARCHAR(87)	Nom et prénom du souscripteur de la convention.
				Phone1				VARCHAR(27)	Téléphone à la maison du souscripteur.
				BeneficiaryID		INTEGER		ID du bénéficiaire
				vcBeneficiary		VARCHAR(87)	Nom et prénom du bénéficiaire
				vcErrFieldName		VARCHAR(30)	Champ en erreur
				siCESP800ErrorID	INTEGER		Code de l’erreur
				vcCESP800Error		VARCHAR(200)	Description de l’erreur
				HumanID				INTEGER		ID de l’humain, bénéficiaire ou souscripteur selon le type de 200 (tiType)
				FirstName			VARCHAR(35)	Prénom
				bFirstName			BIT			Indique si le prénom est en erreur.
				LastName				VARCHAR(50)	Nom
				bLastName			BIT			Indique si le nom est en erreur.
				SocialNumber		VARCHAR(75)	NAS (Numéro d’assurance social)
				bSocialNumber		BIT			Indique si le NAS est en erreur
				BirthDate			DATETIME		Date de naissance
				bBirthDate			BIT			Indique si la date de naissance est en erreur
				SexID					CHAR(1)		Sexe ’F’ = ‘Féminin’ et ‘M’ = ‘Masculin’
				bSex					BIT			Indique si le sexe est en erreur
				dtRead				DATETIME		Date de réception du fichier d’erreur.
				vcTransID			VARCHAR(15)	ID PCEE
				ConventionStateName	VARCHAR(75)	État actuel de la convention
				vcNote				VARCHAR(75)	Note de l'usager qui traite cette erreur.
Note                :	ADX0001153	IA	2006-11-09	Alain Quirion			Création
						ADX0001422	IA	2007-06-23	Bruno Lapointe			Ajout vcNote
										2010-04-14	Jean-François Gauthier	Correction afin de tenir compte du ConventionID 
										2014-10-23	Donald Huppé			Dans les 200, bModified est 1 si, en plus, le NAS actuel du bénéficiaire ou sousc de la convention est différent du NAS de la 200 en erreur
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESP100And200Tool](
	@iCESP800ID INT =0)	--ID du 800
AS
BEGIN
	DECLARE @CESP800ToTreat TABLE(
		iCESP800ID INTEGER PRIMARY KEY)
	
	IF @iCESP800ID = 0
		INSERT INTO @CESP800ToTreat
			SELECT C8T.iCESP800ID
			FROM Un_CESP800ToTreat C8T
	ELSE
		INSERT INTO @CESP800ToTreat
			SELECT C8T.iCESP800ID
			FROM Un_CESP800ToTreat C8T
			WHERE C8T.iCESP800ID = @iCESP800ID

	DECLARE @ConventionTable TABLE(
		ConventionID INTEGER PRIMARY KEY)

	INSERT INTO @ConventionTable
		SELECT DISTINCT C1.ConventionID
		FROM @CESP800ToTreat C8T
		JOIN Un_CESP100 C1 ON C1.iCESP800ID = C8T.iCESP800ID
		-----
		UNION
		-----
		SELECT DISTINCT C2.ConventionID
		FROM @CESP800ToTreat C8T
		JOIN Un_CESP200 C2 ON C2.iCESP800ID = C8T.iCESP800ID

	DECLARE @ConventionState TABLE(
		ConventionID INTEGER,
		ConventionStateID CHAR(3),		
		ConventionStateName VARCHAR(20))

	-- Insère les états de convention
	INSERT INTO @ConventionState
		SELECT 		
			T.ConventionID,
			CS.ConventionStateID,		
			CS.ConventionStateName
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				S.ConventionID,
				MaxDate = MAX(S.StartDate)
			FROM @ConventionTable CT
			JOIN Un_ConventionConventionState S ON S.ConventionID = CT.ConventionID
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			WHERE S.StartDate <= GETDATE()
			GROUP BY S.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID
		WHERE CCS.ConventionStateID <> 'FRM'

	--Recherche des erreurs sur les 100
	SELECT 
		iCESP800ID = C8T.iCESP800ID,
		iTransactionType = 100,
		bModified = CAST((CASE 
					WHEN ISNULL(C1B.iCESP100ID,-1) = -1 THEN 0
					ELSE 1
				END) AS BIT),				
		ConventionID = C.ConventionID,
		ConventionNo = C.ConventionNo,
		tiType = NULL,
		SubscriberID = S.SubscriberID,
		vcSubscriber = CASE HS.isCompany
					WHEN 1 THEN ISNULL(HS.LastName,'')
					ELSE ISNULL(HS.FirstName,'') + ' ' + ISNULL(HS.LastName,'')
				END,
		Phone1 = A.Phone1,
		BeneficiaryID = B.BeneficiaryID,
		vcBeneficiary = HB.FirstName + ' ' + HB.LastName,
		vcErrFieldName = C8.vcErrFieldName,
		siCESP800ErrorID = C8.siCESP800ErrorID,
		vcCESP800Error = C8E.vcCESP800Error,			
		HumanID = NULL,
		FirstName = '',
		bFirstName = CAST(1 AS BIT),
		LastName = '',
		bLastName = CAST(1 AS BIT),
		SocialNumber = '',
		bSocialNumber = CAST(1 AS BIT),		
		BirthDate = 0,
		bBirthDate = CAST(1 AS BIT),
		SexID = 'U',
		bSex = CAST(1 AS BIT),	
		dtRead = CRF.dtRead,
		vcTransID = C8.vcTransID,
		ConventionStateName = CCS.ConventionStateName,
		C8T.vcNote
	FROM @CESP800ToTreat Tmp
	JOIN Un_CESP800ToTreat C8T ON Tmp.iCESP800ID = C8T.iCESP800ID
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8T.iCESP800ID
	JOIN Un_CESP800Error C8E ON C8E.siCESP800ErrorID = C8.siCESP800ErrorID
	JOIN Un_CESP100 C1 ON C1.iCESP800ID = C8T.iCESP800ID	
	JOIN dbo.Un_Convention C ON C.ConventionID = C1.ConventionID
	LEFT JOIN Un_CESP100 C1B ON C1B.ConventionID = C.ConventionID AND C1B.iCESP100ID > C1.iCESP100ID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human HS ON HS.HumanID = S.SubscriberID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN @ConventionState CCS ON C.ConventionID = CCS.ConventionID
	-----
	UNION	-- Recherche des erreurs sur les 200
	-----
	SELECT 
		iCESP800ID = C8T.iCESP800ID,
		iTransactionType = 200,
		bModified = CAST((CASE 
					WHEN ISNULL(C2B.iCESP200ID,-1) <> -1 or (C2.tiType = 3 and HB.SocialNumber <> c2.vcSINorEN) or (C2.tiType = 4 and HS.SocialNumber <> c2.vcSINorEN) THEN 1
					ELSE 0
				END) AS BIT),			
		ConventionID = C.ConventionID,
		ConventionNo = C.ConventionNo,
		tiType = C2.tiType,
		SubscriberID = S.SubscriberID,
		vcSubscriber = CASE HS.isCompany
					WHEN 1 THEN ISNULL(HS.LastName,'')
					ELSE ISNULL(HS.FirstName,'') + ' ' + ISNULL(HS.LastName,'')
				END,
		Phone1 = A.Phone1,
		BeneficiaryID = B.BeneficiaryID,
		vcBeneficiary = HB.FirstName + ' ' + HB.LastName,
		vcErrFieldName = C8.vcErrFieldName,
		siCESP800ErrorID = C8.siCESP800ErrorID,
		vcCESP800Error = C8E.vcCESP800Error,			
		HumanID = C2.HumanID,
		FirstName = 	CASE C2.tiType
					WHEN 3 THEN HB.FirstName
					WHEN 4 THEN HS.FirstName
					ELSE ''
				END,
		bFirstName = C8.bFirstName,
		LastName = CASE C2.tiType
					WHEN 3 THEN HB.LastName
					WHEN 4 THEN HS.LastName
					ELSE ''
				END,
		bLastName = C8.bLastName,
		SocialNumber = CASE C2.tiType
					WHEN 3 THEN HB.SocialNumber
					WHEN 4 THEN HS.SocialNumber
					ELSE ''
				END,
		bSocialNumber = CAST((CASE C8.tyCESP800SINID
					WHEN 1 THEN 1
					ELSE 0
				END) AS BIT),		
		BirthDate = CASE C2.tiType
					WHEN 3 THEN HB.BirthDate
					WHEN 4 THEN HS.BirthDate
					ELSE 0
				END,
		bBirthDate = C8.bBirthDate,
		SexID = CASE C2.tiType
					WHEN 3 THEN HB.SexID
					WHEN 4 THEN HS.SexID
					ELSE ''
				END,
		bSex = C8.bSex,	
		dtRead = CRF.dtRead,
		vcTransID = C8.vcTransID,
		ConventionStateName = CCS.ConventionStateName,
		C8T.vcNote
	FROM 
		@CESP800ToTreat Tmp
		JOIN Un_CESP800ToTreat C8T 
			ON Tmp.iCESP800ID = C8T.iCESP800ID
		JOIN Un_CESP800 C8 
			ON C8.iCESP800ID = C8T.iCESP800ID
		JOIN Un_CESP800Error C8E 
			ON C8E.siCESP800ErrorID = C8.siCESP800ErrorID
		JOIN Un_CESP200 C2 
			ON C2.iCESP800ID = C8T.iCESP800ID
		JOIN dbo.Un_Convention C 
			ON C.ConventionID = C2.ConventionID
		LEFT JOIN Un_CESP200 C2B 
			ON C2B.HumanID = C2.HumanID AND C2B.ConventionID = C2.ConventionID AND C2B.iCESP200ID > C2.iCESP200ID -- 2010-04-14 : JFG : Ajout du lien sur le ConventionID
		JOIN dbo.Un_Subscriber S 
			ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Mo_Human HS 
			ON HS.HumanID = S.SubscriberID
		LEFT JOIN dbo.Mo_Adr A 
			ON A.AdrID = HS.AdrID
		JOIN dbo.Un_Beneficiary B 
			ON B.BeneficiaryID = C.BeneficiaryID
		JOIN dbo.Mo_Human HB 
			ON HB.HumanID = B.BeneficiaryID
		JOIN Un_CESPReceiveFile CRF 
			ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
		JOIN @ConventionState CCS 
			ON C.ConventionID = CCS.ConventionID 
	ORDER BY 
		dtRead, ConventionNo, tiType

END


