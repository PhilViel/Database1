/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_RP_UN_NSFLetterForCHQ
Description         :	Rapport de fusion word des lettres de NSF sur CHQ et PRD
Valeurs de retours  :	Dataset
Note                :	ADX0000510	IA	2004-11-17	Bruno Lapointe		Création
								ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les 
																				documents commandés
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_NSFLetterForCHQ] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@OperID INTEGER, -- ID de l'opération
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS 
BEGIN 

	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER,
		@UserName VARCHAR(77),
		@ConventionNo VARCHAR(75),
		@ConventionNos VARCHAR(7000),
		@NSFDate DATETIME,
		@NSFAmount MONEY,
		@DocIDBefore INTEGER,
		@DocIDAfter INTEGER

	SET @Today = GetDate()	

	-- Table temporaire qui contient le certificat
	CREATE TABLE #Letter(
		DocTemplateID INTEGER,
		LetterDate VARCHAR(75), -- Date de la commande de la lettre. 
		Title VARCHAR(75), -- Ce sera le titre de courtoisie du souscripteur (Ex : Monsieur, Sir, Madame, Miss, etc.)
		SubscriberFirstName VARCHAR(75), -- Le prénom du souscripteur
		SubscriberLastName VARCHAR(77), -- Le nom de famille du souscripteur
		SubscriberAddress VARCHAR(75), -- L’adresse du souscripteur (Numéro civique, rue et numéro d’appartement)
		SubscriberCity VARCHAR(100), -- La ville de l’adresse du souscripteur
		SubscriberState VARCHAR(75), -- Province du souscripteur
		SubscriberZipCode VARCHAR(75), -- Code postal du souscripteur
		SubscriberCountry VARCHAR(75), -- Pays du souscripteur
		ConventionNos VARCHAR(7000), -- Numéros des conventions qui sont affectées par l’effet retournés séparés par des virgules.
		NSFDate VARCHAR(75), -- Date d’opération (financière) du NSF.
		NSFAmount VARCHAR(75), -- Montant de l’effet retourné.
		UserName VARCHAR(77) -- Nom de l'usager qui a commandé la lettre
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'NSFLetterForCHQ'

	SELECT 
		@UserName = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON (CO.UserID = U.UserID)
	JOIN dbo.Mo_Human HU ON (HU.HumanID = U.UserID)
	WHERE (Co.ConnectID = @ConnectID)

	-- Curseur de détail des objets d'opérations (Un_Oper)
	DECLARE CrConventionNo CURSOR FOR
		SELECT 
			C.ConventionNo
		FROM Un_Cotisation Ct 
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		WHERE Ct.OperID = @OperID
		-----
		UNION
		-----
		SELECT 
			C.ConventionNo
		FROM Un_ConventionOper CO 
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		WHERE CO.OperID = @OperID
			
	-- Ouvre le curseur
	OPEN CrConventionNo

	-- Va chercher la première opération
	FETCH NEXT FROM CrConventionNo
	INTO
		@ConventionNo

	SET @ConventionNos = ''

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @ConventionNos = ''
			SET @ConventionNos = @ConventionNo
		ELSE
			SET @ConventionNos = @ConventionNos+', '+@ConventionNo
	
		FETCH NEXT FROM CrConventionNo
		INTO
			@ConventionNo
	END

	-- Libère le curseur
	CLOSE CrConventionNo
	DEALLOCATE CrConventionNo

	SELECT 
		@NSFDate = ISNULL(R.OperDate,O.OperDate)
	FROM Un_Oper O
	LEFT JOIN Mo_BankReturnLink BRL ON BRL.BankReturnCodeID = O.OperID
	LEFT JOIN Un_Oper R ON R.OperID = BRL.BankReturnSourceCodeID
	WHERE O.OperID = @OperID

	SET @NSFAmount = 0

	SELECT 
		@NSFAmount = ISNULL(SUM(ConventionOperAmount),0)
	FROM Un_ConventionOper
	WHERE OperID = @OperID

	SELECT 
		@NSFAmount = @NSFAmount + ISNULL(SUM(Cotisation+Fee+BenefInsur+SubscInsur+TaxOnInsur),0)
	FROM Un_Cotisation
	WHERE OperID = @OperID

	-- Remplis la table temporaire
	INSERT INTO #Letter
		SELECT  
			T.DocTemplateID,
			LetterDate = dbo.fn_Mo_DateToLongDateStr(GetDate() , HS.LangID),
			Title = Sx.LongSexName,
			SubscriberFirstName = HS.FirstName,
			SubscriberLastName = HS.LastName,
			SubscriberAddress = A.Address,
			SubscriberCity = A.City,
			SubscriberState = A.StateName,
			SubscriberZipCode = dbo.fn_Mo_FormatZip(A.ZipCode, A.CountryID),
			SubscriberCountry = Cy.CountryName, 
			ConventionNos = @ConventionNos,
			NSFDate = dbo.fn_Mo_DateToLongDateStr(@NSFDate , HS.LangID), 
			NSFAmount = dbo.fn_Mo_MoneyToStr(@NSFAmount*-1, HS.LangID, 1),
			UserName = @UserName        
		FROM (
			SELECT C.SubscriberID
			FROM Un_Oper O 
			JOIN Un_Cotisation CO ON CO.OperID = O.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			WHERE O.OperID = @OperID
			-----
			UNION
			----- 
			SELECT C.SubscriberID
			FROM Un_ConventionOper CO 
			JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
			WHERE CO.OperID = @OperID
			) S
		JOIN dbo.Mo_Human HS ON HS.HumanID = S.SubscriberID
		JOIN Mo_Sex Sx ON Sx.SexID = HS.SexID AND Sx.LangID = HS.LangID
		JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
		JOIN Mo_Country Cy ON Cy.CountryID = A.CountryID
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @DocTypeID
			  AND (DocTemplateTime < @Today)
			GROUP BY 
				LangID, 
				DocTypeID
			) V ON V.LangID = HS.LangID
		JOIN CRQ_DocTemplate T ON V.DocTypeID = T.DocTypeID AND V.DocTemplateTime = T.DocTemplateTime AND T.LangID = HS.LangID

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN
		SET @DocIDBefore = IDENT_CURRENT('CRQ_Doc')+1

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(SUBSTRING(ConventionNos,1,100),''),
				ISNULL(SubscriberLastName+', '+SubscriberFirstName,''),
				ISNULL(NSFAmount,''),
				ISNULL(LetterDate,'')+';'+
				ISNULL(Title,'')+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';'+
				ISNULL(SubscriberAddress,'')+';'+
				ISNULL(SubscriberCity,'')+';'+
				ISNULL(SubscriberState,'')+';'+
				ISNULL(SubscriberZipCode,'')+';'+
				ISNULL(SubscriberCountry,'')+';'+
				ISNULL(ConventionNos,'')+';'+
				ISNULL(NSFDate,'')+';'+
				ISNULL(NSFAmount,'')+';'+
				ISNULL(UserName,'')+';'
			FROM #Letter
		SET @DocIDAfter = SCOPE_IDENTITY()

		-- Fait un lien entre les documents et les conventions pour qu'on retrouve le document 
		-- dans l'historique des documents des conventions
		INSERT INTO CRQ_DocLink 
			SELECT
				C.ConventionID,
				1,
				D.DocID
			FROM (
				SELECT 
					C.ConventionID
				FROM Un_Cotisation Ct 
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				WHERE Ct.OperID = @OperID
				-----
				UNION
				-----
				SELECT 
					C.ConventionID
				FROM Un_ConventionOper CO 
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				WHERE CO.OperID = @OperID
				) C
			JOIN CRQ_Doc D ON D.DocID BETWEEN @DocIDBefore AND @DocIDAfter
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
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
				WHERE D.DocID BETWEEN @DocIDBefore AND @DocIDAfter
				  AND P.DocID IS NULL
				  AND T.DocTypeID = @DocTypeID
				  AND D.DocOrderTime = @Today
				  AND D.DocOrderConnectID = @ConnectID					
	END

	IF @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID,
			DateLettre = LetterDate, -- Date de la commande de la lettre. 
			TitreCourtoisie = Title, -- Ce sera le titre de courtoisie du souscripteur (Ex : Monsieur, Sir, Madame, Miss, etc.)
			PrenomSouscripteur = SubscriberFirstName, -- Le prénom du souscripteur
			NomSouscripteur = SubscriberLastName, -- Le nom de famille du souscripteur
			Adresse = SubscriberAddress, -- L’adresse du souscripteur (Numéro civique, rue et numéro d’appartement)
			Ville = SubscriberCity, -- La ville de l’adresse du souscripteur
			Province = SubscriberState, -- Province du souscripteur
			CodePostal = SubscriberZipCode, -- Code postal du souscripteur
			Pays = SubscriberCountry, -- Pays du souscripteur
			NoConventions = ConventionNos, -- Numéros des conventions qui sont affectées par l’effet retournés séparés par des virgules.
			DateNSF = NSFDate, -- Date d’opération (financière) du NSF.
			MontantNSF = NSFAmount, -- Montant de l’effet retourné.
			Usager = UserName -- Nom de l'usager qui a commandé la lettre
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


