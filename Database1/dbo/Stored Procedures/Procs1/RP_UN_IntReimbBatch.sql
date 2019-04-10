/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : RP_UN_IntReimbBatch
Description         : Rapport de fusion word des remboursements intégraux
Valeurs de retours  : @Dataset :
									DocTemplateID			INTEGER			ID unique du modèle RTF word.
									LangID					CHAR(3)			Langue (code) du souscripteur.
									DocumentDate			DATETIME			Date de commande du document.
									ConventionNo			VARCHAR(75)		Numéro de convention.
									SubscriberFirstName	VARCHAR(35)		Prénom du souscripteur.
									SubscriberLastName	VARCHAR(50)		Nom du souscripteur.
									SubscriberAddress		VARCHAR(75)		Adresse du souscripteur.
									SubscriberCity			VARCHAR(100)	Ville du souscripteur.
									SubscriberState		VARCHAR(75)		Province du souscripteur.
									SubscriberZipCode		VARCHAR(10)		Code postal du souscripteur.
									SubscriberPhone		VARCHAR(27)		Téléphone du souscripteur.
									LongSexName				VARCHAR(75)		Titre de courtoisie long (Monsieur, Madame, Sir, Madam).
									ShortSexName			VARCHAR(75)		Titre de courtoisie court (Ms., Mr., Mme., M.).
									YearQualif				INTEGER			Année de qualification.
									Username					VARCHAR(77)		Nom de l’usager qui a commandé la lettre.
									Amount 					MONEY				Montant du remboursement.
Note                :						2004-05-21	Bruno Lapointe		Création
								ADX0000694	IA	2005-06-08	Bruno Lapointe		Replacer le paramètre @Date par @UnitIDs.
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les 
																				documents commandés
												2011-02-08	Donald Huppé	Ajout du champ "Regime" (GLPi 5040)
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_IntReimbBatch](
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@UnitIDs	INTEGER, -- ID du blob contenant les UnitID séparés par des « , » des groupes d’unités dont on veut générer le document.  
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER,
		@UserName VARCHAR(77)

	SET @Today = GetDate()	

	CREATE TABLE #UnitInReport (
		UnitID INTEGER PRIMARY KEY )

	INSERT INTO #UnitInReport
		SELECT DISTINCT Val
		FROM dbo.FN_CRQ_BlobToIntegerTable(@UnitIDs)

	-- Table temporaire qui contient le document
	CREATE TABLE #Letter(
		ConventionID INTEGER,
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		DocumentDate VARCHAR(75),
		ConventionNo VARCHAR(75),
		Regime VARCHAR(50),
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		SubscriberAddress VARCHAR(75),
		SubscriberCity VARCHAR(100),
		SubscriberState VARCHAR(75),
		SubscriberZipCode VARCHAR(75),
		SubscriberPhone VARCHAR(75),
		LongSexName VARCHAR(75),
		ShortSexName VARCHAR(75),
		YearQualif INTEGER,
		Amount VARCHAR(75),
		Username VARCHAR(77) 
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'RI'

	SELECT 
		@UserName = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON CO.UserID = U.UserID
	JOIN dbo.Mo_Human HU ON HU.HumanID = U.UserID
	WHERE Co.ConnectID = @ConnectID

	-- Remplis la table temporaire
	INSERT INTO #Letter
		SELECT
			CON.ConventionID,
			T.DocTemplateID,
			SUB.LangID,
			DocumentDate = dbo.fn_Mo_DateToLongDateStr (GetDate(), SUB.LangID),
			CON.ConventionNo,
			Regime = RR.vcDescription,
			SubscriberFirstName = SUB.FirstName,
			SubscriberLastName = SUB.LastName,
			SubscriberAddress = A.Address,
			SubscriberCity = A.City,
			SubscriberState = A.StateName,
			SubscriberZipCode = dbo.fn_Mo_FormatZIP(A.ZipCode, A.CountryID),
			SubscriberPhone = dbo.fn_Mo_FormatPhoneNo(A.Phone1,A.CountryID),
			LongSexName = ISNULL(S.LongSexName,'???'),
			ShortSexName = ISNULL(S.ShortSexName,'???'),
			CON.YearQualif,
			Amount = dbo.fn_Mo_MoneyToStr(ABS(SUM(CO.Cotisation) + SUM(CO.Fee)), SUB.LangID, 0),
			Username = @UserName 
		FROM dbo.Un_Convention CON
		JOIN Un_Plan P on CON.PlanID = P.PlanID
		JOIN tblCONV_RegroupementsRegimes RR on RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN dbo.Un_Unit U ON U.ConventionID = CON.ConventionID
		JOIN #UnitInReport UIR ON UIR.UnitID = U.UnitID
		JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = CO.OperID AND O.OperTypeID = 'RIN'
		JOIN dbo.Mo_Human SUB ON SUB.HumanID = CON.SubscriberID
		JOIN dbo.Mo_Adr A ON A.AdrID = SUB.AdrID
		JOIN dbo.Mo_Human BEN ON BEN.HumanID = CON.BeneficiaryID
		JOIN Mo_Sex S ON SUB.LangID = S.LangID AND SUB.SexID = S.SexID
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @DocTypeID
			  AND (DocTemplateTime < @Today)
			GROUP BY LangID, DocTypeID
			) V ON V.LangID = SUB.LangID
		JOIN CRQ_DocTemplate T ON V.DocTypeID = T.DocTypeID AND V.DocTemplateTime = T.DocTemplateTime AND T.LangID = SUB.LangID
		WHERE U.IntReimbDate IS NOT NULL 
		  AND NOT EXISTS (
					SELECT 
					OC.OperSourceID 
					FROM Un_OperCancelation OC 
					WHERE OC.OperSourceID = O.OperID)
		GROUP BY 
			CON.ConventionID,
			T.DocTemplateID,
			SUB.LangID, 
			CON.ConventionNo,
			RR.vcDescription,
			SUB.LastName,
			SUB.FirstName,
			A.Address, 
			A.City,
			A.StateName, 
			A.ZipCode, 
			A.CountryID,
			A.Phone1,
			A.CountryID,
			S.LongSexName, 
			S.ShortSexName, 
			CON.YearQualif
		ORDER BY
			T.DocTemplateID,
			SUB.LastName,
			SUB.FirstName,
			CON.ConventionNo

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
				'',
				ISNULL(LangID,'')+';'+
				ISNULL(DocumentDate,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(Regime,'')+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';'+
				ISNULL(SubscriberAddress,'')+';'+
				ISNULL(SubscriberCity,'')+';'+
				ISNULL(SubscriberState,'')+';'+
				ISNULL(SubscriberZipCode,'')+';'+
				ISNULL(SubscriberPhone,'')+';'+
				ISNULL(LongSexName,'')+';'+
				ISNULL(ShortSexName,'')+';'+
				ISNULL(CAST(YearQualif AS VARCHAR),'')+';'+
				ISNULL(Amount,'')+';'+
				ISNULL(Username,'')+';' 
			FROM #Letter

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			JOIN dbo.Un_Convention C ON C.ConventionNo = D.DocGroup1
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
				JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
				LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @ConnectID AND P.DocPrintTime = @Today
				WHERE P.DocID IS NULL
				  AND T.DocTypeID = @DocTypeID
				  AND D.DocOrderTime = @Today
				  AND D.DocOrderConnectID = @ConnectID					
	END

	-- Inscrit l'étape 5 du remboursement intégral en batch
	INSERT INTO Un_IntReimbStep (
			UnitID,
			iIntReimbStep,
			dtIntReimbStepTime,
			ConnectID )
		SELECT
			UIR.UnitID,
			5,
			GETDATE(),
			@ConnectID
		FROM #UnitInReport UIR
		JOIN dbo.Un_Unit U ON U.UnitID = UIR.UnitID
		JOIN #Letter L ON L.ConventionID = U.ConventionID

	DROP TABLE #UnitInReport

	IF @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID,
			LangID,
			DocumentDate,
			ConventionNo,
			Regime,
			SubscriberFirstName,
			SubscriberLastName,
			SubscriberAddress,
			SubscriberCity,
			SubscriberState,
			SubscriberZipCode,
			SubscriberPhone,
			LongSexName,
			ShortSexName,
			YearQualif,
			Amount,
			Username 
		FROM #Letter 
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
			FROM #Letter)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #Letter
END


