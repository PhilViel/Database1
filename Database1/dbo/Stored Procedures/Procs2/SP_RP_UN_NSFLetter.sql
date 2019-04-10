/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_RP_UN_NSFLetter
Description         :	Rapport de fusion word des lettres de NSF.
Valeurs de retours  :	Dataset
Note                :						2004-05-26	Bruno Lapointe		Création
								ADX0000225	UP	2004-09-02	Bruno Lapointe		Arranger formatage du montant
								ADX0000510	IA	2004-11-17	Bruno Lapointe		Une lettre par opération.
								ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
								ADX0001929	BR 2006-08-04	Bruno Lapointe		Fait un lien entre l'opération et le docuement.
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les 
																				documents commandés
												2017-11-17	Donald Huppé		Ajout de SubscriberID INTEGER, Nombre_S ,Nombre_VOS pour la nouvelle lettre

exec SP_RP_UN_NSFLetter 1,510560, 30272050, 1
exec SP_RP_UN_NSFLetter 1,0, 30272055, 1


*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_NSFLetter] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER, -- ID de la convention, si le @OperID = 0 il va chercher la dernier NSF de la convention
	@OperID INTEGER, -- ID de l'opération.  Si = 0 alors va chercher la dernière opération de la convention (@ConventionID)
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
		@NSFRaison VARCHAR(75),
		@CPADateRecup DATETIME,
		@DocIDBefore INTEGER,
		@DocIDAfter INTEGER,
		@BenefPrenom VARCHAR(75),
		@Nombre_S VARCHAR(1),
		@Nombre_VOS VARCHAR(10)

	SET @Today = GETDATE()

	-- Si @OperID <=0 alors va chercher le dernier NSF de la convention.
	IF @OperID <= 0 
	BEGIN 
		SET @OperID = 0

		SELECT 
			@OperID = ISNULL(MAX(O.OperID),0)
		FROM Un_Oper O
		JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		WHERE U.ConventionID = @ConventionID
		  AND O.OperTypeID = 'NSF'
	END

	-- Table temporaire qui contient le certificat
	CREATE TABLE #Letter(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		ConventionNo VARCHAR(2000),
		LetterMedDate VARCHAR(75),
		SubscriberName VARCHAR(87),
		SubscriberAddress VARCHAR(75),
		SubscriberCity VARCHAR(100),
		SubscriberState VARCHAR(75),
		SubscriberZipCode VARCHAR(75),
		SubscriberCountry VARCHAR(75), 
		NSFDate VARCHAR(75), 
		OperID INTEGER,
		Amount VARCHAR(75),
		CPADateRecup VARCHAR(75),
		NSFRaison VARCHAR(75),        
		LongSexName VARCHAR(75),
		ShortSexName VARCHAR(75),
		UserName VARCHAR(87),
		SubscriberLastName VARCHAR(50),
		SubscriberFirstName VARCHAR(35),
		SubscriberID INTEGER,
		Nombre_S VARCHAR(1),
		Nombre_VOS VARCHAR(10)
	)

	-- Curseur de détail des objets d'opérations (Un_Oper)
	DECLARE CrConventionNo CURSOR FOR
		SELECT 
			C.ConventionNo
			,BenefPrenom = HB.FirstName
		FROM Un_Cotisation Ct 
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN dbo.Mo_Human HB on HB.HumanID = C.BeneficiaryID
		WHERE Ct.OperID = @OperID
		-----
		UNION
		-----
		SELECT 
			C.ConventionNo
			,BenefPrenom = HB.FirstName
		FROM Un_ConventionOper CO 
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		JOIN dbo.Mo_Human HB on HB.HumanID = C.BeneficiaryID
		WHERE CO.OperID = @OperID
			
	-- Ouvre le curseur
	OPEN CrConventionNo

	-- Va chercher la première opération
	FETCH NEXT FROM CrConventionNo
	INTO
		@ConventionNo, @BenefPrenom

	SET @ConventionNos = ''

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @ConventionNos = ''
			SET @ConventionNos = @ConventionNo + ' (' + @BenefPrenom + ')'
		ELSE
			SET @ConventionNos = @ConventionNos+', '+@ConventionNo + ' (' + @BenefPrenom + ')'
	
		FETCH NEXT FROM CrConventionNo
		INTO
			@ConventionNo, @BenefPrenom
	END

	-- Libère le curseur
	CLOSE CrConventionNo
	DEALLOCATE CrConventionNo


	SET @Nombre_S = CASE WHEN @ConventionNos LIKE '%,%' THEN 's' ELSE '' END
	SET @Nombre_VOS = CASE WHEN @ConventionNos LIKE '%,%' THEN 'vos' ELSE 'votre' END


	SELECT 
		@NSFDate = ISNULL(R.OperDate,O.OperDate),
		@NSFRaison = ISNULL(BRT.BankReturnTypeDesc,''),
		@CPADateRecup =
			CASE 
				WHEN R.OperID IS NULL THEN NULL
			ELSE DATEADD(MONTH,2, R.OperDate)
			END
	FROM Un_Oper O
	LEFT JOIN Mo_BankReturnLink BRL ON BRL.BankReturnCodeID = O.OperID
	LEFT JOIN Mo_BankReturnType BRT ON BRT.BankReturnTypeID = BRL.BankReturnTypeID
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

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'NSFLetter'

	SELECT 
		@UserName = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON (CO.UserID = U.UserID)
	JOIN dbo.Mo_Human HU ON (HU.HumanID = U.UserID)
	WHERE (Co.ConnectID = @ConnectID);

	-- Remplis la table temporaire
	INSERT INTO #Letter
		SELECT  
			T.DocTemplateID,
			HS.LangID,
			@ConventionNos,
			LetterMedDate = dbo.fn_Mo_DateToLongDateStr(GETDATE() , HS.LangID),
			SubscriberName = HS.FirstName + ' ' + HS.LastName,
			SubscriberAddress = A.Address,
			SubscriberCity = A.City,
			SubscriberState = A.StateName,
			SubscriberZipCode = dbo.fn_Mo_FormatZip(A.ZipCode, A.CountryID),
			SubscriberCountry = A.CountryID, 
			NSFDate = dbo.fn_Mo_DateToLongDateStr(@NSFDate, HS.LangID), 
			@OperID,
			Amount = dbo.fn_Mo_MoneyToStr(@NSFAmount*-1, HS.LangID, 1),
			CPADateRecup = dbo.fn_Mo_DateToLongDateStr(@CPADateRecup, HS.LangID),
			NSFRaison = @NSFRaison,        
			Sx.LongSexName,
			Sx.ShortSexName,
			UserName = @UserName,      
			SubscriberLastName = HS.LastName,
			SubscriberFirstName = HS.FirstName,
			S.SubscriberID,
			@Nombre_S,
			@Nombre_VOS
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
		INSERT INTO CRQ_Doc (
				DocTemplateID, 
				DocOrderConnectID, 
				DocOrderTime, 
				DocGroup1, 
				DocGroup2, 
				DocGroup3, 
				Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(SUBSTRING(ConventionNO,1,100),''),
				ISNULL(SubscriberLastName+', '+SubscriberFirstName,''),
				ISNULL(NSFRaison,''),
				ISNULL(LangID,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(LetterMedDate,'')+';'+
				ISNULL(SubscriberName,'')+';'+
				ISNULL(SubscriberAddress,'')+';'+
				ISNULL(SubscriberCity,'')+';'+
				ISNULL(SubscriberState,'')+';'+
				ISNULL(SubscriberZipCode,'')+';'+
				ISNULL(SubscriberCountry,'')+';'+
				ISNULL(NSFDate,'')+';'+
				ISNULL(CAST(OperID AS VARCHAR),'')+';'+
				ISNULL(Amount,'')+';'+
				ISNULL(CPADateRecup,'')+';'+
				ISNULL(NSFRaison,'')+';'+
				ISNULL(LongSexName,'')+';'+
				ISNULL(ShortSexName,'')+';'+
				ISNULL(UserName,'')+';' +
				ISNULL(SubscriberLastName,'')+';' +
				ISNULL(SubscriberFirstName,'')+';' +
				ISNULL(CAST(SubscriberID AS VARCHAR),'')+';'+
				ISNULL(Nombre_S,'')+';'+
				ISNULL(Nombre_VOS,'')+';'
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

		-- Fait un lien entre le document et l'opération pour pouvoir supprimer le document si on supprime l'opération
		INSERT INTO CRQ_DocLink 
			SELECT
				@OperID,
				10,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			LEFT JOIN CRQ_DocLink L ON L.DocLinkID = @OperID AND L.DocLinkType = 10 AND L.DocID = D.DocID
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
			LangID,
			ConventionNo,
			LetterMedDate,
			SubscriberName,
			SubscriberAddress,
			SubscriberCity,
			SubscriberState,
			SubscriberZipCode,
			SubscriberCountry, 
			NSFDate, 
			OperID,
			Amount,
			CPADateRecup,
			NSFRaison,        
			LongSexName,
			ShortSexName,
			UserName,
			SubscriberLastName,
			SubscriberFirstName,
			SubscriberID,
			Nombre_S,
			Nombre_VOS
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


