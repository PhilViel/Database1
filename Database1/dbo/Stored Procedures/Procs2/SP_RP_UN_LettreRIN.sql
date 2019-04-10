/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc
Nom                 :	SP_RP_UN_LettreRIN
Description         :	Régime Individuel – lettre RIN
Valeurs de retours  :	
GLPI	2011-10-11	Eric Michaud		Création

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_LettreRIN] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER, -- ID de la convention  
	@Cotisation MONEY, -- ID de la convention 
	@FlagPAE BIT,
	@FlagFerme BIT,	 
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER,
		@UserName VARCHAR(77),
		@LettreRINPAETXT1 VARCHAR(max),
		@LettreRINPAETXT2 VARCHAR(max),
		@LettreRINFermeTXT1 VARCHAR(max),
		@LettreRINFermeTXT2 VARCHAR(max),
		@LineStep VARCHAR(2)		
		
	SET @Today = GetDate()	
	
	SET @LineStep = CHAR(13) 
	
/*	IF @FlagPAE = 1
	BEGIN
		set @LettreRINPAETXT1 = (SELECT vcValeur_Parametre
								FROM tblGENE_TypesParametre T
								JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
								WHERE vcCode_Type_Parametre = 'LettreRINPAETXT1' AND P.vcDimension1 = HS.LangID)

		set @LettreRINPAETXT2 = @LineStep + (SELECT vcValeur_Parametre
								FROM tblGENE_TypesParametre T
								JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
								WHERE vcCode_Type_Parametre = 'LettreRINPAETXT2' AND P.vcDimension1 = HS.LangID)
	END

	IF @FlagFerme = 1
	BEGIN
		set @LettreRINFermeTXT1 = @LineStep + (SELECT vcValeur_Parametre
									FROM tblGENE_TypesParametre T
									JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
									WHERE vcCode_Type_Parametre = 'LettreRINFermeTXT1' AND P.vcDimension1 = HS.LangID)

		set @LettreRINFermeTXT2 = (SELECT vcValeur_Parametre
									FROM tblGENE_TypesParametre T
									JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
									WHERE vcCode_Type_Parametre = 'LettreRINFermeTXT2' AND P.vcDimension1 = HS.LangID)
	END

*/
	-- Table temporaire qui contient l'information
	CREATE TABLE #Lettre(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		ConventionNo VARCHAR(75),
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		SubscriberAddress VARCHAR(75),
		SubscriberCity VARCHAR(100),
		SubscriberState VARCHAR(75),
		SubscriberZipCode VARCHAR(75),
		BeneficiaryFirstName VARCHAR(35),
		BeneficiaryLastName VARCHAR(50),
		LetterMedDate VARCHAR(75),
		SubscriberShortSexName VARCHAR(75),
		SubscriberLongSexName VARCHAR(75),
		Amount VARCHAR(20),
		LettreRINPAETXT1 VARCHAR(max),
		LettreRINPAETXT2 VARCHAR(max),
		LettreRINFerme VARCHAR(max)
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'LettreRIN'

	SELECT 
		@UserName = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON (CO.UserID = U.UserID)
	JOIN dbo.Mo_Human HU ON (HU.HumanID = U.UserID)
	WHERE (Co.ConnectID = @ConnectID);

	-- Remplis la table temporaire
	INSERT INTO #Lettre
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
			BeneficiaryFirstName = HB.FirstName,
			BeneficiaryLastName = HB.LastName,
			LetterMedDate = dbo.fn_Mo_DateToLongDateStr (GetDate(), HS.LangID),
			SubscriberShortSexName = S.ShortSexName,
			SubscriberLongSexName = S.LongSexName,
			Amount= dbo.fn_Mo_MoneyToStr(ABS(@Cotisation), HS.LangID , 1),
			LettreRINPAETXT1 = 	CASE WHEN @FlagPAE = 1 THEN
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreRINPAETXT1' AND P.vcDimension1 = HS.LangID)
								END,			
			LettreRINPAETXT2 = CASE WHEN @FlagPAE = 1 THEN
									@LineStep + (SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreRINPAETXT2' AND P.vcDimension1 = HS.LangID)
								END,
			LettreRINFerme = CASE WHEN @FlagFerme = 1 THEN
								@LineStep + (SELECT vcValeur_Parametre
									FROM tblGENE_TypesParametre T
									JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
									WHERE vcCode_Type_Parametre = 'LettreRINFermeTXT1' AND P.vcDimension1 = HS.LangID)
								+ C.ConventionNo +
								(SELECT vcValeur_Parametre
									FROM tblGENE_TypesParametre T
									JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
									WHERE vcCode_Type_Parametre = 'LettreRINFermeTXT2' AND P.vcDimension1 = HS.LangID)
								END
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
		JOIN Un_Plan P ON C.PlanID = P.PlanID
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
				ISNULL(BeneficiaryFirstName,'')+';'+
				ISNULL(BeneficiaryLastName,'')+';'+
				ISNULL(LetterMedDate,'')+';'+
				ISNULL(SubscriberShortSexName,'')+';'+
				ISNULL(SubscriberLongSexName,'')+';'+
				ISNULL(Amount,'')+';'+
				ISNULL(LettreRINPAETXT1,'')+';'+
				ISNULL(LettreRINPAETXT2,'')+';'+
				ISNULL(LettreRINFerme,'')+';'
			FROM #Lettre

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

	-- Produit un dataset pour la fusion
	IF @DocAction <> 0
	SELECT 
		DocTemplateID,
		LangID,
		ConventionNo = l.ConventionNo,
		SubscriberFirstName,
		SubscriberLastName,
		SubscriberAddress,
		SubscriberCity,
		SubscriberState,
		SubscriberZipCode,
		BeneficiaryFirstName,
		BeneficiaryLastName,
		LetterMedDate,
		SubscriberShortSexName,
		SubscriberLongSexName,
		Amount,
		LettreRINPAETXT1,
		LettreRINPAETXT2,
		LettreRINFerme
	FROM #Lettre l
	--JOIN dbo.Un_Convention c on l.ConventionNo = c.ConventionNo
	--join un_plan p on c.planid = p.planid 
	WHERE @DocAction IN (1,2)

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
			FROM #Lettre)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #Lettre;
END;


