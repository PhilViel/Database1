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
Nom                 :	RP_UN_IntReimbRegistrationProof
Description         :	Rapport de fusion word des preuves d'inscription pour remboursement intégral
Valeurs de retours  :	Dataset de données
Note                :			
							2004-05-26	Bruno Lapointe		Création 
			ADX0001114	IA	2006-11-17	Alain Quirion		Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate)
			ADX0002340	BR	2007-03-12	Alain Quirion		Correction de la vérification du document déjà commandé
			ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
							2008-05-13	Pierre-Luc Simard	Ajout du nom du plan
							2008-09-25	Josée Parent		Ne pas produire de DataSet pour les 
															documents commandés
							2010-01-05	Donald Huppé		Regrouper par convention (GLPI 2499)
							2011-01-06	Donald Huppé		Ajout de SubscriberID
							2011-02-09	Donald Huppé		Ajout de SoldeIncitatif (GLPI 5027)
							2014-08-04	Donald Huppé		glpi 12070
							2014-08-11	Donald Huppé		Reflex en anglais
							2015-03-11	Donald Huppé		glpi 13819 : correction du calcul de Amount (montant souscrit)
							2017-03-17	Donald Huppé		jira ti-7315 : PlanDesc en majuscule
							2018-11-08	Maxime Martel		utilisation de planDesc_Enu de la table plan

exec RP_UN_IntReimbRegistrationProof 816478,'133540',0
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_IntReimbRegistrationProof](
	@ConnectID INTEGER, 	-- ID de connexion de l'usager
	@ConventionID INTEGER, 	-- ID de la convention  
	@DocAction INTEGER) 	-- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN
	
	SELECT Deprecated = 1/0

	/*
	DECLARE 
		@Today DATETIME,
		@DateSoldeIncitatif DATETIME,
		@DocTypeID INTEGER,
		@UserName VARCHAR(77)

	SET @Today = GETDATE()	
	
	SET @DateSoldeIncitatif =	CAST(YEAR(GETDATE())-1 AS VARCHAR(4)) + '-12-31'

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'PreuveInscriptionRI'

	-- Table temporaire qui contient les documents
	CREATE TABLE #RegistrationProof(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		DocumentDate VARCHAR(75),
		ConventionNo VARCHAR(75),
		SubsFirstName VARCHAR(35),
		SubsLastName VARCHAR(50),
		SubsAddress VARCHAR(75),
		SubsCity VARCHAR(100),
		SubsState VARCHAR(75),
		SubsZipCode VARCHAR(75),
		SubsPhone VARCHAR(75),
		OfficePhone VARCHAR(75),
		LongSexName VARCHAR(75),
		ShortSexName VARCHAR(75),
		BenefFirstName VARCHAR(35),
		BenefLastName VARCHAR(50),
		GrantAmount VARCHAR(75),
		EstimatedIntReimbDate VARCHAR(75),
		FallingDueDate VARCHAR(75),
		PostponedIntReimbDate VARCHAR(75),
		Username VARCHAR(75),
		Amount VARCHAR(75),
		SoldeIncitatif VARCHAR(75),
		PlanDesc VARCHAR(75),
		SubscriberID INTEGER,

		BeneficiaryID VARCHAR(15),
		BeneficiaryLongSexName VARCHAR(75),
		BeneficiaryShortSexName VARCHAR(75),
		BeneficiaryAddress VARCHAR(75),
		BeneficiaryCity VARCHAR(75),
		BeneficiaryState VARCHAR(75),
		BeneficiaryCountry VARCHAR(75),
		BeneficiaryZipCode VARCHAR(75)
	)

	SELECT 
		@UserName = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON (CO.UserID = U.UserID)
	JOIN dbo.Mo_Human HU ON (HU.HumanID = U.UserID)
	WHERE (Co.ConnectID = @ConnectID)

	INSERT INTO #RegistrationProof

		select
			DocTemplateID,
			LangID,
			DocumentDate,
			ConventionNo,
			SubsFirstName,
			SubsLastName,
			SubsAddress,
			SubsCity,
			SubsState,
			SubsZipCode,
			SubsPhone,
			OfficePhone,
			LongSexName,
			ShortSexName,
			BenefFirstName,
			BenefLastName,
			GrantAmount,
			EstimatedIntReimbDate = MIN(EstimatedIntReimbDate),
			FallingDueDate = MIN(FallingDueDate),
			PostponedIntReimbDate = MIN(PostponedIntReimbDate),
			Username,
			Amount = dbo.fn_Mo_MoneyToStr( SUM(Amount), LangID, 0),
			SoldeIncitatif,
			PlanDesc = UPPER(V.PlanDesc),
			SubscriberID,

			BeneficiaryID = cast(BeneficiaryID AS VARCHAR(15)),
			BeneficiaryLongSexName,
			BeneficiaryShortSexName,
			BeneficiaryAddress,
			BeneficiaryCity,
			BeneficiaryState,
			BeneficiaryCountry,
			BeneficiaryZipCode

		FROM (

			SELECT
				T.DocTemplateID,
				SUB.LangID,
				DocumentDate = dbo.fn_Mo_DateToLongDateStr (GetDate(), SUB.LangID),
				CON.ConventionNo,
				SubsFirstName = SUB.FirstName,
				SubsLastName = SUB.LastName,
				SubsAddress = A.Address,
				SubsCity = A.City,
				SubsState = A.StateName,
				SubsZipCode = dbo.fn_Mo_FormatZIP(A.ZipCode, A.CountryID),
				SubsPhone = dbo.fn_Mo_FormatPhoneNo(A.Phone1,A.CountryID),
				OfficePhone = dbo.fn_Mo_FormatPhoneNo(A.Phone2,A.CountryID),
				LongSexName = ISNULL(S.LongSexName,'???'),
				ShortSexName = ISNULL(S.ShortSexName,'???'),
				BenefFirstName = BEN.FirstName,
				BenefLastName = BEN.LastName,
				GrantAmount = dbo.fn_Mo_MoneyToStr(ISNULL(GG.fCESG,0), SUB.LangID, 0),
				EstimatedIntReimbDate = dbo.fn_Mo_DateToLongDateStr (dbo.fn_Un_EstimatedIntReimbDate( M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust), SUB.LangID),
				FallingDueDate = dbo.fn_Mo_DateToLongDateStr (DATEADD ( MONTH , -1, (dbo.fn_Un_EstimatedIntReimbDate( M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) +9)), SUB.LangID),
				PostponedIntReimbDate = CASE 
								WHEN MONTH(dbo.fn_Un_EstimatedIntReimbDate( M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)) < 9 THEN dbo.fn_Mo_DateToLongDateStr (CAST(CAST(YEAR(dbo.fn_Un_EstimatedIntReimbDate( M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)) AS VARCHAR) + '-09-15' AS DATETIME), SUB.LangID)
								ELSE dbo.fn_Mo_DateToLongDateStr (CAST(CAST(YEAR(dbo.fn_Un_EstimatedIntReimbDate( M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust))+1 AS VARCHAR) + '-09-15' AS DATETIME), SUB.LangID)
							END,
				Username = @UserName,
				Amount = ISNULL(V1.CotisationFee,0),
				/*
				Amount = 
					CASE 
						WHEN P.PlanTypeID = 'IND' THEN
							-- dbo.fn_Mo_MoneyToStr((ROUND(U.UnitQty * M.PmtRate,2) * M.PmtQty) - ROUND(M.FeeByUnit * U.UnitQty,2), SUB.LangID, 0) 
							(ROUND(U.UnitQty * M.PmtRate,2) * M.PmtQty) - ROUND(M.FeeByUnit * U.UnitQty,2)
					ELSE
						-- dbo.fn_Mo_MoneyToStr(ROUND(U.UnitQty * M.PmtRate,2) * M.PmtQty, SUB.LangID, 0) 
						ROUND(U.UnitQty * M.PmtRate,2) * M.PmtQty
					END,
				*/
				SoldeIncitatif = dbo.fn_Mo_MoneyToStr(ISNULL(SoldeIncitatif,0), SUB.LangID, 0),
				PlanDesc = case WHEN SUB.LangID = 'ENU' then p.PlanDesc_ENU else P.PlanDesc end,
				CON.SubscriberID,

				CON.BeneficiaryID,
				BeneficiaryLongSexName = sb.LongSexName,
				BeneficiaryShortSexName = sb.ShortSexName,
				BeneficiaryAddress = ab.Address,
				BeneficiaryCity = ab.City,
				BeneficiaryState = ab.StateName,
				BeneficiaryCountry = ab.CountryID,
				BeneficiaryZipCode =  dbo.fn_Mo_FormatZIP(ab.ZipCode, Ab.CountryID)

			FROM dbo.Un_Convention CON
			JOIN dbo.Un_Unit U ON (U.ConventionID = CON.ConventionID)
			JOIN Un_Modal M ON (M.ModalID = U.ModalID)
			JOIN UN_Plan P ON (P.PlanID = M.PlanID) 
			LEFT JOIN (
				SELECT 
					ConventionID,
					fCESG = SUM(fCESG+fACESG)
				FROM Un_CESP CE
				JOIN Un_Oper O ON O.OperID = CE.OperID
				GROUP BY ConventionID
				HAVING SUM(fCESG+fACESG) > 0 
				) GG ON (GG.ConventionID = CON.ConventionID)
			JOIN dbo.Mo_Human SUB ON (SUB.HumanID = CON.SubscriberID)
			JOIN dbo.Mo_Adr A ON (A.AdrID = SUB.AdrID)
			JOIN dbo.Mo_Human BEN ON (BEN.HumanID = CON.BeneficiaryID)
			JOIN Mo_Sex S ON (SUB.LangID = S.LangID)AND(SUB.SexID = S.SexID)
			JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
				SELECT 
					LangID,
					DocTypeID,
					DocTemplateTime = MAX(DocTemplateTime)
				FROM CRQ_DocTemplate
				WHERE (DocTypeID = @DocTypeID)
				  AND (DocTemplateTime < @Today)
				GROUP BY LangID, DocTypeID
				) V ON (V.LangID = SUB.LangID)
			JOIN CRQ_DocTemplate T ON (V.DocTypeID = T.DocTypeID) AND (V.DocTemplateTime = T.DocTemplateTime) AND (T.LangID = SUB.LangID)
			JOIN Mo_Sex Sb ON (BEN.LangID = Sb.LangID)AND(BEN.SexID = Sb.SexID)
			JOIN dbo.Mo_Adr AB on BEN.AdrID = AB.AdrID

			LEFT JOIN dbo.Mo_Connect Co ON Co.ConnectID = U.PmtEndConnectID
			LEFT JOIN dbo.Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
			LEFT JOIN (
				SELECT 
					U.UnitID,CotisationFee = SUM(Ct.Cotisation + Ct.Fee),Cotisation = SUM(Ct.Cotisation)
				FROM 
					dbo.Un_Unit U
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
				WHERE U.ConventionID = @ConventionID
				GROUP BY 
					U.UnitID
					) V1 ON V1.UnitID = U.UnitID
						
			LEFT JOIN ( -- SOLDE DES INCITATIFS GOUVERNEMENTAUX (SCEE + IQEE)
			
				SELECT 
					ConventionID,
					SoldeIncitatif = SUM(SCEE + IQEE)
				FROM (
				
					SELECT --iqee reçu et rendement
						CO.ConventionID,
						SCEE=0,
						IQEE = SUM(ConventionOperAmount)
					FROM 
						Un_ConventionOper CO
						JOIN dbo.Un_Convention c on c.conventionid = co.conventionid
						JOIN un_oper O ON CO.Operid = O.OperID
						JOIN tblOPER_OperationsCategorie OC ON OC.cID_Type_Oper_Convention = CO.ConventionOperTypeID
						JOIN tblOPER_CategoriesOperation COP ON COP.iID_Categorie_Oper = OC.iID_Categorie_Oper
					WHERE 
						O.OperDate <= @DateSoldeIncitatif --'2010-12-31'
						and c.conventionID = @ConventionID
						AND	COP.vcCode_Categorie IN (
							'OPER_MONTANTS_IQEE',
							'OPER_RENDEMENTS_IQEE')
					GROUP BY 
						CO.ConventionID

					UNION ALL

					SELECT  -- scee total
						conventionid,
						SCEE = sum(SCEE + SCEE_Rend),
						IQEE = 0
					FROM (
						select -- scee REÇU
							c.conventionid,
							SCEE = sum(fcesg + facesg + fCLB),
							SCEE_Rend = 0
						FROM un_cesp ce
						JOIN dbo.Un_Convention c on c.conventionid = ce.conventionid
						JOIN un_oper op on ce.operid = op.operid
						WHERE op.operdate <= @DateSoldeIncitatif--'2010-12-31'
						AND c.conventionID = @ConventionID
						GROUP BY c.conventionid			
							
						UNION ALL
						
						SELECT -- Rendement SCEE
							 co.conventionid,
							 SCEE = 0,
							 SCEE_Rend = sum(CO.ConventionOperAmount)
						FROM Un_ConventionOper CO
						JOIN dbo.Un_Convention c on c.conventionid = co.conventionid
						JOIN un_oper o on co.operid = o.operid
						WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST')
						AND o.operdate <= @DateSoldeIncitatif --'2010-12-31'
						AND c.conventionID = @ConventionID
						GROUP BY co.conventionid	
						) V	
					GROUP BY conventionid	
				)Q
				GROUP BY
					conventionid
			
				)ICT ON  ICT.CONVENTIONID = CON.ConventionID
			
			WHERE CON.ConventionID NOT IN (	-- Enlever ceux dont la preuve dinscription a déjà été commandé		
											SELECT L.DocLinkID
											FROM CRQ_DocLink L
											JOIN CRQ_Doc D ON L.DocID = D.DocID
											JOIN CRQ_DocTemplate DT ON DT.DocTemplateID = D.DocTemplateID AND DT.DocTypeID = @DocTypeID
											WHERE L.DocLinkID = @ConventionID
											)	
				 AND (CON.ConventionID = @ConventionID)

			) V

		GROUP BY 

			DocTemplateID,
			LangID,
			DocumentDate,
			ConventionNo,
			SubsFirstName,
			SubsLastName,
			SubsAddress,
			SubsCity,
			SubsState,
			SubsZipCode,
			SubsPhone,
			OfficePhone,
			LongSexName,
			ShortSexName,
			BenefFirstName,
			BenefLastName,
			GrantAmount,
			Username,
			SoldeIncitatif,
			PlanDesc,
			SubscriberID,
			BeneficiaryID,
			BeneficiaryLongSexName,
			BeneficiaryShortSexName,
			BeneficiaryAddress,
			BeneficiaryCity,
			BeneficiaryState,
			BeneficiaryCountry,
			BeneficiaryZipCode

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
				ISNULL(SubsLastName,'')+', '+ISNULL(SubsFirstName,''),
				ISNULL(BenefLastName,'')+', '+ISNULL(BenefFirstName,''),
				ISNULL(LangID,'')+';'+
				ISNULL(DocumentDate,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(SubsFirstName,'')+';'+
				ISNULL(SubsLastName,'')+';'+
				ISNULL(SubsAddress,'')+';'+
				ISNULL(SubsCity,'')+';'+
				ISNULL(SubsState,'')+';'+
				ISNULL(SubsZipCode,'')+';'+
				ISNULL(SubsPhone,'')+';'+
				ISNULL(OfficePhone,'')+';'+
				ISNULL(LongSexName,'')+';'+
				ISNULL(ShortSexName,'')+';'+
				ISNULL(BenefFirstName,'')+';'+
				ISNULL(BenefLastName,'')+';'+
				ISNULL(GrantAmount,'')+';'+
				ISNULL(EstimatedIntReimbDate,'')+';'+
				ISNULL(FallingDueDate,'')+';'+
				ISNULL(PostponedIntReimbDate,'')+';'+
				ISNULL(Username,'')+';'+
				ISNULL(Amount,'')+';'+
				ISNULL(SoldeIncitatif,'')+';'+
				ISNULL(PlanDesc,'')+';'+
				ISNULL(CAST(SubscriberID AS VARCHAR),'')+';'+
				ISNULL(BeneficiaryID,'')+';'+
				ISNULL(BeneficiaryLongSexName,'')+';'+
				ISNULL(BeneficiaryShortSexName,'')+';'+
				ISNULL(BeneficiaryAddress,'')+';'+
				ISNULL(BeneficiaryCity,'')+';'+
				ISNULL(BeneficiaryState,'')+';'+
				ISNULL(BeneficiaryCountry,'')+';'+
				ISNULL(BeneficiaryZipCode,'')+';'
			FROM #RegistrationProof

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT DISTINCT
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
			DocumentDate,
			ConventionNo,
			SubsFirstName,
			SubsLastName,
			SubsAddress,
			SubsCity,
			SubsState,
			SubsZipCode,
			SubsPhone,
			OfficePhone,
			LongSexName,
			ShortSexName,
			BenefFirstName,
			BenefLastName,
			GrantAmount,
			EstimatedIntReimbDate,
			FallingDueDate,
			PostponedIntReimbDate,
			Username,
			Amount,
			SoldeIncitatif,
			PlanDesc,
			SubscriberID,

			BeneficiaryID,
			BeneficiaryLongSexName,
			BeneficiaryShortSexName,
			BeneficiaryAddress,
			BeneficiaryCity,
			BeneficiaryState,
			BeneficiaryCountry,
			BeneficiaryZipCode

		FROM #RegistrationProof 
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
			FROM #RegistrationProof)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #RegistrationProof;
	*/
END