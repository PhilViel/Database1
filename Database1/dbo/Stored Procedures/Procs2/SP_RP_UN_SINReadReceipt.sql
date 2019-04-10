/****************************************************************************************************
  Rapport de fusion word des accusés réceptions de NAS
 ******************************************************************************
  2004-06-01	Bruno Lapointe			Création 
  2008-09-25	Josée Parent			Ne pas produire de DataSet pour les documents commandés
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_SINReadReceipt] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER, -- ID de la convention  
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER,
		@UserName VARCHAR(77)

	SET @Today = GetDate()	

	-- Table temporaire qui contient le certificat
	CREATE TABLE #Notice(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		ConventionNo VARCHAR(75),
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		SubscriberAddress VARCHAR(75),
		SubscriberCity VARCHAR(100),
		SubscriberState VARCHAR(75),
		SubscriberZipCode VARCHAR(75),
		SubscriberPhone VARCHAR(75),
		BeneficiaryFirstName VARCHAR(35),
		BeneficiaryLastName VARCHAR(50),
		LetterMedDate VARCHAR(75),
		SubscriberLongSexName VARCHAR(75),
		SubscriberShortSexName VARCHAR(75),
		FRABenefFutur VARCHAR(75),
		FRABenefBoursier VARCHAR(75), 
		ENUBenefHisHer VARCHAR(75), 
		ENUBenefHimHer VARCHAR(75),
		UserName VARCHAR(77)
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'SINReadReceipt'

	SELECT 
		@UserName = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON (CO.UserID = U.UserID)
	JOIN dbo.Mo_Human HU ON (HU.HumanID = U.UserID)
	WHERE (Co.ConnectID = @ConnectID);

	-- Remplis la table temporaire
	INSERT INTO #Notice
		SELECT
			T.DocTemplateID,
			HS.LangID,
			C.ConventionNo,
			SubscriberFirstName = HS.FirstName,
			SubscriberLastName = HS.LastName,
			SubscriberAddress = A.Address,
			SubscriberCity = A.City,
			SubscriberState = A.StateName,
			SubscriberZipCode = dbo.fn_Mo_FormatZIP(A.ZipCode, A.CountryID),
			SubscriberPhone = dbo.fn_Mo_FormatPhoneNo(A.Phone1,A.CountryID),
			BeneficiaryFirstName = HB.FirstName,
			BeneficiaryLastName = HB.LastName,
			LetterMedDate = dbo.fn_Mo_DateToLongDateStr (GetDate(), HS.LangID),
			SubscriberLongSexName = S.LongSexName,
			SubscriberShortSexName = S.ShortSexName,
			FRABenefFutur =
				CASE HB.SexID
					WHEN 'F' THEN 'future'
					WHEN 'M' THEN 'futur'
				ELSE '???'
				END,
			FRABenefBoursier =
				CASE HB.SexID
					WHEN 'F' THEN 'boursière'
					WHEN 'M' THEN 'boursier'
				ELSE '???'
				END, 
			ENUBenefHisHer =
				CASE HB.SexID
					WHEN 'F' THEN 'her'
					WHEN 'M' THEN 'his'
				ELSE '???'
				END, 
			ENUBenefHimHer =
				CASE HB.SexID
					WHEN 'F' THEN 'her'
					WHEN 'M' THEN 'him'
				ELSE '???'
				END,
			UserName = @UserName
		FROM dbo.Un_Convention C
		JOIN dbo.Mo_Human HS ON (HS.HumanID = C.SubscriberID)
		JOIN dbo.Mo_Adr A ON (A.AdrID = HS.AdrID)
		JOIN dbo.Mo_Human HB ON (HB.HumanID = C.BeneficiaryID)
		JOIN Mo_Sex S ON (HS.LangID = S.LangID) AND (HS.SexID = S.SexID)
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @DocTypeID)
			  AND (DocTemplateTime < @Today)
			GROUP BY LangID, DocTypeID
			) V ON (V.LangID = HS.LangID)
		JOIN CRQ_DocTemplate T ON (V.DocTypeID = T.DocTypeID) AND (V.DocTemplateTime = T.DocTemplateTime) AND (T.LangID = HS.LangID)
		WHERE (C.ConventionID = @ConventionID)

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(ConventionNo,''),
				ISNULL(SubscriberLastName,'')+', '+ISNULL(SubscriberFirstName,''),
				ISNULL(BeneficiaryLastName,'')+', '+ISNULL(BeneficiaryFirstName,''),
				ISNULL(LangID,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';'+
				ISNULL(SubscriberAddress,'')+';'+
				ISNULL(SubscriberCity,'')+';'+
				ISNULL(SubscriberState,'')+';'+
				ISNULL(SubscriberZipCode,'')+';'+
				ISNULL(SubscriberPhone,'')+';'+
				ISNULL(BeneficiaryFirstName,'')+';'+
				ISNULL(BeneficiaryLastName,'')+';'+
				ISNULL(LetterMedDate,'')+';'+
				ISNULL(SubscriberLongSexName,'')+';'+
				ISNULL(SubscriberShortSexName,'')+';'+
				ISNULL(FRABenefFutur,'')+';'+
				ISNULL(FRABenefBoursier,'')+';'+
				ISNULL(ENUBenefHisHer,'')+';'+
				ISNULL(ENUBenefHimHer,'')+';'+
				ISNULL(UserName,'')+';'
			FROM #Notice

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON (T.DocTemplateID = D.DocTemplateID)
			JOIN dbo.Un_Convention C ON (C.ConventionNo = D.DocGroup1)
			LEFT JOIN CRQ_DocLink L ON L.DocLinkID = C.ConventionID AND L.DocLinkType = 1 AND L.DocID = D.DocID
			WHERE L.DocID IS NULL
			  AND T.DocTypeID = @DocTypeID
			  AND D.DocOrderTime = @Today
			  AND D.DocOrderConnectID = @ConnectID	

		IF @DocAction = 2
			-- Dans le cas que l'usager a choisi imprimer et garder la trace dans la gestion 
			-- des documents, on indique qu'il a déjà été imprimé pour ne pas le voir dans 
			-- la queue d'impression
			INSERT INTO CRQ_DocPrinted(DocID, DocPrintConnectID, DocPrintTime)
				SELECT
					D.DocID,
					@ConnectID,
					@Today
				FROM CRQ_Doc D 
				JOIN CRQ_DocTemplate T ON (T.DocTemplateID = D.DocTemplateID)
				LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @ConnectID AND P.DocPrintTime = @Today
				WHERE P.DocID IS NULL
				  AND T.DocTypeID = @DocTypeID
				  AND D.DocOrderTime = @Today
				  AND D.DocOrderConnectID = @ConnectID					
	END

	IF @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID,
			LangID,
			ConventionNo,
			SubscriberFirstName,
			SubscriberLastName,
			SubscriberAddress,
			SubscriberCity,
			SubscriberState,
			SubscriberZipCode,
			SubscriberPhone,
			BeneficiaryFirstName,
			BeneficiaryLastName,
			LetterMedDate,
			SubscriberLongSexName,
			SubscriberShortSexName,
			FRABenefFutur,
			FRABenefBoursier, 
			ENUBenefHisHer, 
			ENUBenefHimHer,
			UserName
		FROM #Notice 
		WHERE @DocAction IN (1,2)
	END

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @DocTypeID)
			  AND (DocTemplateTime < @Today))
		RETURN -1 -- Pas de template d'entré ou en vigueur pour ce type de document
	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM #Notice)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #Notice;
END;


