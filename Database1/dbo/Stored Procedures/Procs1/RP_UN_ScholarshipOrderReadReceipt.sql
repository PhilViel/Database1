﻿/*  *************************************************************
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
Nom                 :	RP_UN_ScholarshipOrderReadReceipt
Description         :	Rapport de fusion Word d'accusé réception de demande de bourses.
Valeurs de retours  :	Dataset de données
Note                :						2004-07-15	Bruno Lapointe		Création 
								ADX0000942	BR	2004-08-20	Bruno Lapointe		Correction du format de la date de la lettre
																							incorrect
								ADX0001059	BR	2004-09-02	Bruno Lapointe		Ne se mettait pas toujours dans l'historique des
																							documents quand commandé.
								ADX0000706	IA	2005-07-13	Bruno Lapointe		Pas de lettre pour les bénéficiaires dont
																							l'adresse est marquée perdue.
								ADX0000982	IA	2006-05-11	Alain Quirion		Ordre du nom du bénéficiaire selon la norme Nom, Prénom.  3e champs d'info sera maintenant le numéro de la bourse suivi d'un trait d'union et du nom du souscripteur au lieu de la date
												2008-06-09	Pierre-Luc Simard	Ajout du champ ShortSexName
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les 
																				documents commandés
												2011-05-03	Donald Huppé		Enlever les parenthèses autour de la province
												2011-06-30  Eric Michaud		Ajout des champs BeneficiaryCity,BeneficiaryState,BeneficiaryID,
																				SubscriberFirstName,SubscriberLastName
												2012-10-22	Donald Huppé		glpi 8428 : correction du calcul de MAX(Su.ScholarShipNo).  On recherche pour le conventionID passé en paramètre.  
																				J'ignore comment ça pu fonctionner avant cette correction
												2012-12-12	Donald Huppé		Ajout de BeneficiaryLastname	
                                                2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée
																				
exec RP_UN_ScholarshipOrderReadReceipt 1, 212565,1
													
insert into CRQ_DocTypeDataFormat (DocTypeID,DocTypeTime,DocTypeDataFormat,StoredProcedureName)
values (22,getdate(),'a;LetterDate@ftString;LongSexName@ftString;ShortSexName@ftString;BeneficiaryName@ftString;BeneficiaryAddress@ftString;BeneficiaryCityState@ftString;BeneficiaryZipCode@ftString;ConventionNo@ftString;PlanDesc@ftString;CompleteFile@ftString;IncompleteFile@ftString;CompleteSIN@ftString;BirthCertificate@ftString;CaseOfJanuary@ftString;SchoolReport@ftString;RegistrationProof@ftString;BeneficiaryCity@ftString;BeneficiaryState@ftString;BeneficiaryID@ftString;SubscriberFirstName@ftString;SubscriberLastName@ftString;BeneficiaryLastname@ftString;','SP_RP_UN_ScholarshipChequeLetter')
																				
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipOrderReadReceipt](
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER, -- ID Unique de la convention
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
	WHERE DocTypeCode = 'ScholOrdReadReceipt'

	-- Table temporaire qui contient les documents
	CREATE TABLE #ReadReceipt(
		DocTemplateID INTEGER,
		LetterDate VARCHAR(20),
		LongSexName VARCHAR(75),
		ShortSexName VARCHAR(75),
		BeneficiaryName VARCHAR(86),
		BeneficiaryNameInverted VARCHAR(86),
		BeneficiaryAddress VARCHAR(75),
		BeneficiaryCityState VARCHAR(175),
		BeneficiaryZipCode VARCHAR(75),
		ConventionNo VARCHAR(75),
		PlanDesc VARCHAR(75),
		CompleteFile VARCHAR(1),
		IncompleteFile VARCHAR(1),
		CompleteSIN VARCHAR(1),
		BirthCertificate VARCHAR(1),
		CaseOfJanuary VARCHAR(1),
		SchoolReport VARCHAR(1),
		RegistrationProof VARCHAR(1),
		ScholarShipNo INTEGER,
		SubscriberName VARCHAR(86),
		BeneficiaryCity VARCHAR(100),
		BeneficiaryState VARCHAR(75),
		BeneficiaryID INTEGER,
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		BeneficiaryLastname VARCHAR(50)
	)

	INSERT INTO #ReadReceipt
		SELECT 
			T.DocTemplateID,
			LetterDate = dbo.fn_Mo_DateToLongDateStr(GetDate(), BH.LangID), 
			X.LongSexName,
			X.ShortSexName,
			BeneficiaryName = RTRIM(BH.FirstName) + ' ' + RTRIM(BH.LastName),
			BeneficiaryNameInverted = RTRIM(BH.LastName) + ', ' + RTRIM(BH.FirstName),
			BeneficiaryAddress = RTRIM(A.Address),
			BeneficiaryCityState = ISNULL(RTRIM(A.City),'') + ' ' + ISNULL(RTRIM(A.StateName),'') + '',
			BeneficiaryZipCode = dbo.fn_Mo_FormatZIP (ISNULL(RTRIM(UPPER(A.ZipCode)),''), A.CountryID),
			ConventionNo =
				CASE P.PlanID
					WHEN 11 THEN 'b' + RTRIM(C.ConventionNo)
				ELSE RTRIM(C.ConventionNo)
				END,
			P.PlanDesc,
			CompleteFile = 
				CASE
					WHEN ((RTRIM(BH.SocialNumber) <> '') OR (BH.ResidID <> 'CAN')) AND 
						 B.BirthCertificate = 1 AND 
						 B.SchoolReport = 1 AND 
						 B.RegistrationProof = 1 AND
						 B.CaseOfJanuary = 0 THEN 'X'
				ELSE ''
				END ,
			IncompleteFile = 
				CASE
					WHEN ((RTrim(BH.SocialNumber) = '') AND (BH.ResidID = 'CAN')) THEN 'X'
					WHEN ((RTrim(BH.SocialNumber) <> '') OR (BH.ResidID <> 'CAN')) AND (B.BirthCertificate = 1) AND (B.CaseOfJanuary = 1) THEN ''
					WHEN ((RTrim(BH.SocialNumber) = '') AND (BH.ResidID = 'CAN')) OR (B.BirthCertificate = 0) THEN 'X'
					WHEN ((RTrim(BH.SocialNumber) = '') AND (BH.ResidID = 'CAN')) OR (B.BirthCertificate = 0) OR (B.SchoolReport = 0) OR (B.RegistrationProof = 0) AND (B.CaseOfJanuary = 0) THEN 'X'
				ELSE ''
				END,
			CompleteSIN =
				CASE
					WHEN ((RTrim(BH.SocialNumber) = '') AND (BH.ResidID = 'CAN')) THEN 'X'
				ELSE ''
				END,
			BirthCertificate =
				CASE
					WHEN (B.BirthCertificate = 1) THEN ''
				ELSE 'X'
				END,
			CaseOfJanuary =
				CASE
					WHEN B.CaseOfJanuary = 1 THEN 'X'
				ELSE ''
				END,
			SchoolReport =
				CASE
					WHEN (B.SchoolReport = 1) THEN ''
					WHEN (B.SchoolReport = 0)  AND (B.CaseOfJanuary = 1) THEN ''
				ELSE 'X'
				END,
			RegistrationProof =
				CASE
					WHEN (B.RegistrationProof = 1) THEN ''
					WHEN (B.RegistrationProof = 0)  AND (B.CaseOfJanuary = 1) THEN ''
				ELSE 'X'
				END,
			ScholarShipNo = Ss.ScholarShipNo,
			SubscriberName = RTRIM(SH.LastName) + ', ' + RTRIM(SH.FirstName),
			BeneficiaryCity = ISNULL(RTRIM(A.City),''),
			BeneficiaryState = ISNULL(RTRIM(A.StateName),'') + '',
			BeneficiaryID = B.BeneficiaryID,
			SubscriberFirstName = RTRIM(SH.FirstName),
			SubscriberLastName = RTRIM(SH.LastName),
			BeneficiaryLastname = BH.LastName
		FROM dbo.Un_Convention C 
		JOIN Un_ScholarShip S ON S.ConventionID = C.ConventionID -- IA-ADX0000982
		LEFT JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		JOIN dbo.Mo_Human BH ON BH.HumanID = B.BeneficiaryID
		JOIN Mo_Sex X ON X.SexID = BH.SexID AND X.LangID = BH.LangID
		JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = BH.AdrID
		JOIN ( -- IA-ADX0000982		Pour avoir le no. de bourse le plus grand parmis les admissible, en attente ou à payé
			SELECT
				ScholarShipNo = MAX(Su.ScholarShipNo)
			FROM
				Un_ScholarShip Su
			WHERE Su.ConventionID = @ConventionID
			AND ScholarShipStatusID IN ('ADM','WAI','TPA')
			) Ss ON Ss.ScholarShipNo = S.ScholarShipNo 
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
		ORDER BY
			T.DocTemplateID

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(BeneficiaryNameInverted,''),
				ISNULL(ConventionNo,''),
				CAST(ScholarShipNo AS VARCHAR(2))+' - '+ISNULL(SubscriberName,''),
				ISNULL(LetterDate,'')+';'+
				ISNULL(LongSexName,'')+';'+
				ISNULL(ShortSexName,'')+';'+
				ISNULL(BeneficiaryName,'')+';'+
				ISNULL(BeneficiaryAddress,'')+';'+
				ISNULL(BeneficiaryCityState,'')+';'+
				ISNULL(BeneficiaryZipCode,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(PlanDesc,'')+';'+
				ISNULL(CompleteFile,'')+';'+
				ISNULL(IncompleteFile,'')+';'+
				ISNULL(CompleteSIN,'')+';'+
				ISNULL(BirthCertificate,'')+';'+
				ISNULL(CaseOfJanuary,'')+';'+
				ISNULL(SchoolReport,'')+';'+
				ISNULL(RegistrationProof,'')+';'+
				ISNULL(BeneficiaryCity,'')+';'+
				ISNULL(BeneficiaryState,'')+';'+
			    cast(BeneficiaryID as varchar(15))+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';'+
				ISNULL(BeneficiaryLastname,'')+';'
			FROM #ReadReceipt

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT DISTINCT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			JOIN dbo.Un_Convention C ON C.ConventionNo = D.DocGroup2 OR 'b'+C.ConventionNo = D.DocGroup2
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
			LetterDate,
			LongSexName,
			ShortSexName,
			BeneficiaryName,
			BeneficiaryAddress,
			BeneficiaryCityState,
			BeneficiaryZipCode,
			ConventionNo,
			PlanDesc,
			CompleteFile,
			IncompleteFile,
			CompleteSIN,
			BirthCertificate,
			CaseOfJanuary,
			SchoolReport,
			RegistrationProof,
			BeneficiaryCity,
			BeneficiaryState,
			BeneficiaryID,
			SubscriberFirstName,
			SubscriberLastName,
			BeneficiaryLastname
		FROM #ReadReceipt 
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
			FROM #ReadReceipt)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #ReadReceipt
    */
END