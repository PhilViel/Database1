/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_ScholarshipReminderNotice
Description         :	Rapport de fusion Word des lettres de rappels aux boursiers.
Valeurs de retours  :	Dataset de données
Note                :						2004-06-01	Bruno Lapointe		Création
								ADX0000706	IA	2005-07-13	Bruno Lapointe		Pas de lettre pour les bénéficiaires dont
																							l'adresse est marquée perdue.
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les 
																				documents commandés
												2010-11-11	Donald Huppé		Ajout des champs SubscriberFirstName et SubscriberLastName
												2011-08-15	Eric Michaud		Ajout des champs LongSexName SubscriberAdress SubscriberCity
																				SubscriberState SubscriberZipCode
                                                2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

exec RP_UN_ScholarshipReminderNotice 497974,136581,1,1																				
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipReminderNotice] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER, -- ID Unique de la convention
	@ScholarshipNo INTEGER, -- ID de la bourse
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

    SELECT 1/0
    /*
	DECLARE 
		@UserName VARCHAR(75),
		@ScholarshipYear INTEGER,
		@Today DATETIME,
		@DocTypeID INTEGER
 
	SET @Today = GetDate()	

	-- Table temporaire qui contient les documents
	CREATE TABLE #Notice(
		DocTemplateID INTEGER,
		LetterMedDate VARCHAR(75),
		BeneficiaryLongSexName VARCHAR(75),
		BeneficiaryShortSexName VARCHAR(75),
		LangID VARCHAR(3),
		BeneficiaryFirstName VARCHAR(35),
		BeneficiaryLastName VARCHAR(50),
		BeneficiaryAddress VARCHAR(75),
		BeneficiaryCity VARCHAR(100),
		BeneficiaryState VARCHAR(75),
		BeneficiaryZipCode VARCHAR(75),
		ConventionNo VARCHAR(75),
		PlanName VARCHAR(75),
		ScholarshipNo VARCHAR(75),      
		LastScholarship BIT, 
		NextYear INTEGER,
		UserName VARCHAR(77),
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		LongSexName VARCHAR(75),
		SubscriberAddress VARCHAR(75),
		SubscriberCity VARCHAR(100),
		SubscriberState VARCHAR(75),
		SubscriberZipCode VARCHAR(75)
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'ScholReminderNotice'

	-- Va chercher le nom de l'usager
	SELECT 
		@UserName = HU.FirstName + ' ' + HU.LastName 
	FROM Mo_Connect CO
	JOIN Mo_User U ON CO.UserID = U.UserID
	JOIN dbo.Mo_Human HU ON HU.HumanID = U.UserID
	WHERE Co.ConnectID = @ConnectID
 
	-- Remplis la table temporaire
	INSERT INTO #Notice
		SELECT
			T.DocTemplateID,
			LetterMedDate = dbo.fn_mo_DateToLongDateStr(GetDate(), BH.LangID),
			BeneficiaryLongSexName = X.LongSexName,
			BeneficiaryShortSexName = X.ShortSexName,
			BH.LangID,
			BeneficiaryFirstName = RTRIM(BH.FirstName),
			BeneficiaryLastName = RTRIM(BH.LastName),
			BeneficiaryAddress = RTRIM(A.Address),
			BeneficiaryCity = ISNULL(RTRIM(A.City),''),
			BeneficiaryState = ISNULL(RTRIM(A.StateName),''),
			BeneficiaryZipCode = dbo.fn_Mo_FormatZip(ISNULL(RTRIM(UPPER(A.ZipCode)),''), A.CountryID),
			C.ConventionNo,
			PlanName = P.PlanDesc,
			ScholarshipNo =
				CASE BH.LangID
					WHEN 'FRA' THEN 
						CASE
							WHEN @ScholarshipNo = 1 THEN '1iere'
						ELSE CAST(@ScholarshipNo AS VARCHAR(2))+'e'
						END
					WHEN 'ENU' THEN 
						CASE
							WHEN @ScholarshipNo IN (1,21,31) THEN CAST(@ScholarshipNo AS varchar(2)) + 'st' 
							WHEN @ScholarshipNo IN (2, 22) THEN CAST(@ScholarshipNo AS varchar(2)) + 'nd'
							WHEN @ScholarshipNo IN (3,23) THEN CAST(@ScholarshipNo AS varchar(2)) + 'rd'  
						ELSE CAST(@ScholarshipNo AS VARCHAR(2)) + 'th'
						END
		   	END,      
			LastScholarship =
				CASE SC.LastScholarshipID
					WHEN @ScholarshipNo THEN 1
				ELSE 0
				END, 
			NextYear = (SELECT ScholarshipYear + 1 FROM Un_Def),
			UserName = @UserName,
			SubscriberFirstName = RTRIM(SH.FirstName),
			SubscriberLastName = RTRIM(SH.LastName),
			LongSexName = W.LongSexName,
			SubscriberAddress = RTRIM(Z.Address),
			SubscriberCity = ISNULL(RTRIM(Z.City),''),
			SubscriberState = ISNULL(RTRIM(Z.StateName),''),
			SubscriberZipCode = dbo.fn_Mo_FormatZip(ISNULL(RTRIM(UPPER(Z.ZipCode)),''), Z.CountryID)
		FROM dbo.Un_Convention C 
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
/*		JOIN (
			SELECT DISTINCT 
				U.ConventionID,
				S.UnitStateID
			FROM dbo.Un_Unit U
			JOIN (
				SELECT 
					U.UnitID,
					StartDate = MAX(StartDate)
				FROM dbo.Un_Unit U
				JOIN Un_UnitUnitState S ON S.UnitID = U.UnitID
				WHERE S.StartDate <= @Today
				  AND U.ConventionID = @ConventionID
				GROUP BY U.UnitID) M ON M.UnitID = U.UnitID
			JOIN Un_UnitUnitState S ON S.UnitID = U.UnitID AND S.StartDate = M.StartDate
			WHERE S.UnitStateID IN ('RBA', 'R1B', 'R2B')
			) USt ON USt.ConventionID = C.ConventionID
*/		LEFT JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN dbo.Mo_Human BH ON BH.HumanID = C.BeneficiaryID
		JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
		JOIN Mo_Sex X ON X.SexID = BH.SexID AND X.LangID = BH.LangID
		JOIN Mo_Sex W ON W.SexID = SH.SexID AND W.LangID = SH.LangID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = BH.AdrID
		LEFT JOIN dbo.Mo_Adr Z ON Z.AdrID = SH.AdrID
		-- Trouve la bourse qui sera la dernière 
		LEFT JOIN (
			SELECT 
				ConventionID, 
				LastScholarshipID = MAX(ScholarshipID)
			FROM Un_Scholarship
			WHERE YearDeleted = 0
			GROUP BY ConventionID 
			) SC ON SC.ConventionID = C.ConventionID
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @DocTypeID
			  AND (DocTemplateTime < @Today)
			GROUP BY LangID, DocTypeID
			) V ON V.LangID = BH.LangID
		JOIN CRQ_DocTemplate T ON V.DocTypeID = T.DocTypeID AND V.DocTemplateTime = T.DocTemplateTime AND T.LangID = BH.LangID
		WHERE C.ConventionID = @ConventionID
			AND B.bAddressLost = 0

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(ConventionNO,''),
				ISNULL(BeneficiaryLastName,'')+', '+ISNULL(BeneficiaryFirstName,''),
				ISNULL(ScholarshipNo,''),
				ISNULL(LetterMedDate,'')+';'+
				ISNULL(BeneficiaryLongSexName,'')+';'+
				ISNULL(BeneficiaryShortSexName,'')+';'+
				ISNULL(LangID,'')+';'+
				ISNULL(BeneficiaryFirstName,'')+';'+
				ISNULL(BeneficiaryLastName,'')+';'+
				ISNULL(BeneficiaryAddress,'')+';'+
				ISNULL(BeneficiaryCity,'')+';'+
				ISNULL(BeneficiaryState,'')+';'+
				ISNULL(BeneficiaryZipCode,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(PlanName,'')+';'+
				ISNULL(ScholarshipNo,'')+';'+
				ISNULL(CAST(LastScholarship AS VARCHAR),'')+';'+
				ISNULL(CAST(NextYear AS VARCHAR),'')+';'+
				ISNULL(UserName,'')+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';' +
				ISNULL(LongSexName,'')+';'+
				ISNULL(SubscriberAddress,'')+';'+
				ISNULL(SubscriberCity,'')+';'+
				ISNULL(SubscriberState,'')+';'+
				ISNULL(SubscriberZipCode,'')+';'
			FROM #Notice

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

	IF @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID,
			LetterMedDate,
			BeneficiaryLongSexName,
			BeneficiaryShortSexName,
			LangID,
			BeneficiaryFirstName,
			BeneficiaryLastName,
			BeneficiaryAddress,
			BeneficiaryCity,
			BeneficiaryState,
			BeneficiaryZipCode,
			ConventionNo,
			PlanName,
			ScholarshipNo,      
			LastScholarship, 
			NextYear,
			UserName,
			SubscriberFirstName,
			SubscriberLastName,
			LongSexName,
			SubscriberAddress,
			SubscriberCity,
			SubscriberState,
			SubscriberZipCode
		FROM #Notice 
		WHERE @DocAction IN (1,2)
	END

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @DocTypeID
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

	DROP TABLE #Notice
    */
END