/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_Scholarship2And3NoticeBatch
Description         :	Rapport de fusion Word des avis de deuxièmes et troisièmes bourses.
Valeurs de retours  :	Dataset de données
Note                :							2004-07-15	Bruno Lapointe		Création
						        ADX0000706	IA	2005-07-13	Bruno Lapointe		Pas de lettre pour les bénéficiaires dont
																				l'adresse est marquée perdue.
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les 
																				documents commandés
												2009-05-08	Pierre-Luc Simard	Ajout des colonnes LongSexName
												2011-05-03	Donald Huppé		Enlever les parenthèses autour de la province
												2011-05-04	Donald Huppé		Ajout du beneficiaryID
												2011-05-24	Pierre-Luc Simard	Ne pas générer de lettre pour les Individuel	
												2012-03-26	Eric Michaud	    Ajout de SubscriberAddress,SubscriberCityState,SubscriberZipCode,	
												2014-05-09	Pierre-Luc Simard	Ne pas générer de lettre pour les conventions dont la première bourse est admissible, 
																				puisque maintenant, les 3 bourses peuvent avoir le statut ADM, RES (en réserve) n'étant plus géré. 
                                                2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_Scholarship2And3NoticeBatch](
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN
    SELECT 1/0
    /*
	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER

	SET @Today = GetDate()	

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'Schol2and3Notice'

	-- Table temporaire qui contient les documents
	CREATE TABLE #Notice(
		DocTemplateID INTEGER,
		BeneficiaryShortSexName VARCHAR(75),
		BeneficiaryLongSexName VARCHAR(75),
		BeneficiaryFirstName VARCHAR(35),
		BeneficiaryLastName VARCHAR(50),
		BeneficiaryAddress VARCHAR(75),
		BeneficiaryCityState VARCHAR(175),
		BeneficiaryZipCode VARCHAR(75),
		ConventionNo VARCHAR(75),
		PlanDesc VARCHAR(75),
		SubscriberShortSexName VARCHAR(75),
		SubscriberLongSexName VARCHAR(75),
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		SubscriberAddress VARCHAR(75),
		SubscriberCityState VARCHAR(175),
		SubscriberZipCode VARCHAR(75),
		BeneficiaryID int
	)

	INSERT INTO #Notice
		SELECT * 
		FROM (
			SELECT DISTINCT
				T.DocTemplateID,
				BeneficiaryShortSexName = BHS.ShortSexName,
				BeneficiaryLongSexName = BHS.LongSexName,
				BeneficiaryFirstName = RTRIM(BH.FirstName),
				BeneficiaryLastName = RTRIM(BH.LastName),
				BeneficiaryAddress = RTRIM(A.Address),
				BeneficiaryCityState = ISNULL(RTRIM(A.City),'') + ' ' + ISNULL(RTRIM(A.StateName),'') + '',
				BeneficiaryZipCode = dbo.fn_Mo_FormatZIP(ISNULL(RTRIM(UPPER(A.ZipCode)),''), A.CountryID),
				C.ConventionNo,
				P.PlanDesc,
				SubscriberShortSexName = SHS.ShortSexName,
				SubscriberLongSexName = SHS.LongSexName,
				SubscriberFirstName = RTRIM(SH.FirstName),
				SubscriberLastName = RTRIM(SH.LastName),
				SubscriberAddress = RTRIM(ADS.Address),
				SubscriberCityState = ISNULL(RTRIM(ADS.City),'') + ' ' + ISNULL(RTRIM(ADS.StateName),'') + '',
				SubscriberZipCode = dbo.fn_Mo_FormatZIP(ISNULL(RTRIM(UPPER(ADS.ZipCode)),''), ADS.CountryID),
				C.BeneficiaryID
			FROM Un_Scholarship S
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human BH ON BH.HumanID = B.BeneficiaryID
			JOIN Mo_Sex BHS ON BHS.SexID = BH.SexID AND BHS.LangID = BH.LangID
			JOIN dbo.Un_Subscriber SU ON SU.SubscriberID = C.SubscriberID
			JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
			JOIN Mo_Sex SHS ON SHS.SexID = SH.SexID AND SHS.LangID = BH.LangID
			LEFT JOIN dbo.Mo_Adr A ON A.AdrID = BH.AdrID
			LEFT JOIN dbo.Mo_Adr ADS ON ADS.AdrID = SH.AdrID
			JOIN Un_Scholarship S1 ON S1.ConventionID = S.ConventionID AND S1.ScholarshipNo = 1 AND S1.ScholarshipStatusID NOT IN ('ADM','WAI','TPA') -- Exclu les conventions dont la première bourse est admissible
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
			WHERE S.ScholarshipNo > 1
				AND S.ScholarshipStatusID IN ('ADM','WAI','TPA')
				--AND B.bAddressLost = 0
				AND SU.AddressLost = 0
				AND P.PlanTypeID <> 'IND'
		) S	
		ORDER BY
			S.DocTemplateID,
			S.BeneficiaryLastName,
			S.BeneficiaryFirstName,
			S.ConventionNo

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(BeneficiaryLastName,'')+', '+ISNULL(BeneficiaryFirstName,''),
				ISNULL(ConventionNo,''),
				ISNULL(SubscriberLastName,'')+', '+ISNULL(SubscriberFirstName,''),
				ISNULL(BeneficiaryShortSexName,'')+';'+
				ISNULL(BeneficiaryLongSexName,'')+';'+
				ISNULL(BeneficiaryFirstName,'')+';'+
				ISNULL(BeneficiaryLastName,'')+';'+
				ISNULL(BeneficiaryAddress,'')+';'+
				ISNULL(BeneficiaryCityState,'')+';'+
				ISNULL(BeneficiaryZipCode,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(PlanDesc,'')+';'+
				ISNULL(SubscriberShortSexName,'')+';'+
				ISNULL(SubscriberLongSexName,'')+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';'+
				ISNULL(SubscriberAddress,'')+';'+
				ISNULL(SubscriberCityState,'')+';'+
				ISNULL(SubscriberZipCode,'')+';'+
				LTRIM(RTRIM(CAST(BeneficiaryID as varchar(8)))) + ';'
			FROM #Notice

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT DISTINCT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			JOIN dbo.Un_Convention C ON C.ConventionNo = D.DocGroup2
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
			BeneficiaryShortSexName,
			BeneficiaryLongSexName,
			BeneficiaryFirstName,
			BeneficiaryLastName,
			BeneficiaryAddress,
			BeneficiaryCityState,
			BeneficiaryZipCode,
			ConventionNo,
			PlanDesc,
			SubscriberShortSexName,
			SubscriberLongSexName,
			SubscriberFirstName,
			SubscriberLastName,
			SubscriberAddress,
			SubscriberCityState,
			SubscriberZipCode, 
			BeneficiaryID
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