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
Copyrights (c) 2003 Gestion Universitas Inc
Nom                 :	SP_RP_UN_LettreAjoutUnit
Description         :	Lettre d'ajout d'unité
Valeurs de retours  :	

		2012-03-01	Eric Michaud		Création
		2018-11-08	Maxime Martel		Utilisation de planDesc_ENU de la table plan
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_LettreAjoutUnit] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@UnitID INTEGER, -- ID de la convention  
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN
	
	SELECT Deprecated = 1/0

	/*
	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER,
		@UserName VARCHAR(77),
--		@LettreTXT1 VARCHAR(max),
--		@LettreTXT2 VARCHAR(max),
--		@LettreTXT2gras VARCHAR(max),
--		@LettreTXT3 VARCHAR(max),
		@LineStep VARCHAR(4)		
		
	SET @Today = GetDate()	
	
	SET @LineStep = CHAR(13)+ CHAR(13)
	
	-- Table temporaire qui contient l'information
	CREATE TABLE #Lettre(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		ConventionNo VARCHAR(75),
		PlanName VARCHAR(75),
		SubscriberID VARCHAR(75),
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
		LettreTXT1 VARCHAR(max),
		LettreTXT2 VARCHAR(max),
		LettreTXT2gras VARCHAR(max),
		LettreTXT3 VARCHAR(max),
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'LettreAjoutUnites'

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
			PlanName = upper(case 
					when HS.LangID = 'ENU' then p.PlanDesc_ENU
					else p.plandesc 
					end),
			SubscriberID = HS.HumanID,
			SubscriberFirstName = HS.FirstName,
			SubscriberLastName = HS.LastName,
			SubscriberAddress = A.Address,
			SubscriberCity = A.City,
			SubscriberState = A.StateName,
			SubscriberZipCode = dbo.fn_Mo_FormatZIP(A.ZipCode, A.CountryID),
			BeneficiaryFirstName = HB.FirstName,
			BeneficiaryLastName = HB.LastName,
			LetterMedDate = dbo.fn_Mo_DateToLongDateStr (GetDate(), HS.LangID),
			SubscriberShortSexName = SS.ShortSexName,
			SubscriberLongSexName = SS.LongSexName,
			LettreTXT1 = CASE WHEN M.PmtByYearID > 1 then   --mensuel
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo1' AND P.vcDimension1 = HS.LangID)
									+ dbo.fn_Mo_MoneyToStr(CASE ISNULL(C.PmtTypeID, '')WHEN 'AUT' THEN ISNULL(AMT.MonthTheoricAmount,0) END,HS.LangID,1)+
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo2' AND P.vcDimension1 = HS.LangID)
									+rtrim(ltrim(cast(datepart(day,C.FirstPmtDate) AS char)))+
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo3' AND P.vcDimension1 = HS.LangID) 
											
								WHEN M.PmtByYearID = 1 AND M.PmtQty > 1  then --annuel
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo4' AND P.vcDimension1 = HS.LangID)
									+ dbo.fn_Mo_MoneyToStr(ROUND(M.PmtRate * (U.UnitQty),2) + ISNULL(U.SubscribeAmountAjustment,0) + ISNULL(AAT.MonthTheoricAmount,0) +-- Cotisation et frais
											dbo.FN_CRQ_TaxRounding
												((	CASE U.WantSubscriberInsurance -- Assurance souscripteur
														WHEN 0 THEN 0
													ELSE ROUND(M.SubscriberInsuranceRate * (U.UnitQty),2)
													END +
													ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
												(1+ISNULL(St.StateTaxPct,0))),HS.LangID,1) + '.' -- Taxes 
									--dbo.fn_Mo_MoneyToStr(isnull(CO.Cotisation,0) + isnull(CO.Fee,0),HS.LangID,1)+
									/*(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo5' AND P.vcDimension1 = HS.LangID)*/
									--+  dbo.fn_Mo_DateToLongDateStr(dateadd(year,1,C.FirstPmtDate), HS.LangID) 
											
								WHEN M.PmtByYearID = 1 AND M.PmtQty = 1  then --forfaitaire
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo6' AND P.vcDimension1 = HS.LangID)
									+ dbo.fn_Mo_MoneyToStr(ROUND(M.PmtRate * (U.UnitQty),2) +  ISNULL(U.SubscribeAmountAjustment,0) + -- Cotisation et frais
											dbo.FN_CRQ_TaxRounding
												((	CASE U.WantSubscriberInsurance -- Assurance souscripteur
														WHEN 0 THEN 0
													ELSE ROUND(M.SubscriberInsuranceRate * (U.UnitQty),2)
													END +
													ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
												(1+ISNULL(St.StateTaxPct,0))),HS.LangID,1) + -- Taxes 
									--dbo.fn_Mo_MoneyToStr(isnull(CO.Cotisation,0) + isnull(CO.Fee,0) ,HS.LangID,1)+
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo7' AND P.vcDimension1 = HS.LangID) 
								END,			
			LettreTXT2 = CASE WHEN hb.socialnumber is null THEN
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo8' AND P.vcDimension1 = HS.LangID) 
								END,			

			LettreTXT2gras = @LineStep +CASE WHEN hb.socialnumber is null THEN
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo8a' AND P.vcDimension1 = HS.LangID)
								END,			
			LettreTXT3 = @LineStep + CASE WHEN hb.socialnumber is not null THEN
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo9' AND P.vcDimension1 = HS.LangID)+
										upper(case 
												when HS.LangID = 'ENU' then p.PlanDesc_ENU
												else p.plandesc 
											end) +
										(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo10' AND P.vcDimension1 = HS.LangID)+
										CASE
											WHEN (U.UnitQty = 1) THEN 
												CASE HS.LangID
													WHEN 'FRA' THEN '1,000 unité'
													WHEN 'ENU' THEN '1.000 unit'
												END
										ELSE  
											CASE HS.LangID
												WHEN 'FRA' THEN   replace(convert(varchar,convert(decimal(10,3), U.UnitQty)),'.',',') + CASE WHEN U.UnitQty < 1 THEN ' unité' ELSE ' unités' END
												WHEN 'ENU' THEN convert(varchar,convert(decimal(10,3), U.UnitQty)) + CASE WHEN U.UnitQty < 1 THEN ' unit' ELSE ' units' END
											END
										END	+									
										(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettreAjoutUnitTXTinfo11' AND P.vcDimension1 = HS.LangID)
							
								END
								
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human HS ON (HS.HumanID = C.SubscriberID)
		JOIN dbo.Mo_Adr A ON (A.AdrID = HS.AdrID)
		JOIN dbo.Mo_Human HB ON (HB.HumanID = C.BeneficiaryID)
		JOIN Mo_Sex SS ON (HS.LangID = SS.LangID) AND (HS.SexID = SS.SexID)
--		left JOIN UN_Cotisation CO ON CO.UnitID = U.UnitID
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
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		LEFT JOIN Mo_State St ON St.StateID = S.StateID
		LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
		LEFT JOIN (-- 09.18 (1.1) Ajout montant de prélèvement automatique mensuel théorique sur convention
			SELECT
				U.ConventionID,
				MonthTheoricAmount = 
					SUM(
						ROUND(M.PmtRate * U.UnitQty,2) + -- Cotisation et frais
						dbo.FN_CRQ_TaxRounding
							((	CASE U.WantSubscriberInsurance -- Assurance souscripteur
									WHEN 0 THEN 0
								ELSE ROUND(M.SubscriberInsuranceRate * U.UnitQty,2)
								END +
								ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
							(1+ISNULL(St.StateTaxPct,0)))) -- Taxes
			FROM dbo.Un_Unit U
			JOIN Un_Modal M ON U.ModalID = M.ModalID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			LEFT JOIN Mo_State St ON St.StateID = S.StateID
			LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
			LEFT JOIN (
				SELECT
					U.UnitID,
					CotisationFee = SUM(Ct.Fee+Ct.Cotisation)
				FROM dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				WHERE C.SubscriberID = C.SubscriberID
				GROUP BY U.UnitID
				) Ct ON U.UnitID = Ct.UnitID
			WHERE C.SubscriberID = C.SubscriberID
			  AND M.PmtByYearID = 12
			  AND ISNULL(Ct.CotisationFee,0) < M.PmtQty * ROUND(M.PmtRate * U.UnitQty,2)
			  AND C.ConventionID = (select ConventionID FROM dbo.Un_Unit where unitid = @UnitID) 
			GROUP BY U.ConventionID
			) AMT ON C.ConventionID = AMT.ConventionID 
		LEFT JOIN (-- 09.18 (1.1) Ajout montant de prélèvement automatique mensuel théorique sur convention
			SELECT
				U.ConventionID,
				U.UnitID,
				MonthTheoricAmount = 
					SUM(
						ROUND(M.PmtRate * U.UnitQty,2)+  -- Cotisation et frais
						dbo.FN_CRQ_TaxRounding
							((	CASE U.WantSubscriberInsurance -- Assurance souscripteur
									WHEN 0 THEN 0
								ELSE ROUND(M.SubscriberInsuranceRate * U.UnitQty,2)
								END +
								ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
							(1+ISNULL(St.StateTaxPct,0)))) -- Taxes
			FROM dbo.Un_Unit U
			JOIN Un_Modal M ON U.ModalID = M.ModalID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			LEFT JOIN Mo_State St ON St.StateID = S.StateID
			LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
			LEFT JOIN (
				SELECT
					U.UnitID,
					CotisationFee = SUM(Ct.Fee+Ct.Cotisation)
				FROM dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				WHERE C.SubscriberID = C.SubscriberID
				GROUP BY U.UnitID
				) Ct ON U.UnitID = Ct.UnitID
			WHERE C.SubscriberID = C.SubscriberID
			  AND M.PmtByYearID = 1
			  AND ISNULL(Ct.CotisationFee,0) < M.PmtQty * ROUND(M.PmtRate * U.UnitQty,2)
			  AND C.ConventionID = (select ConventionID FROM dbo.Un_Unit where unitid = @UnitID) 
			GROUP BY U.ConventionID,U.UnitID
			) AAT ON C.ConventionID = AAT.ConventionID and U.UnitID <> AAT.UnitID			
		WHERE (U.UnitID = @UnitID)

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
				ISNULL(PlanName,'')+';'+
				ISNULL(SubscriberID,'')+';'+
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
				ISNULL(LettreTXT1,'')+';'+
				ISNULL(LettreTXT2,'')+';'+
				ISNULL(LettreTXT2gras,'')+';'+
				ISNULL(LettreTXT3,'')+';'
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
		PlanName,
		SubscriberID,
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
		LettreTXT1,
		LettreTXT2,
		LettreTXT2gras,
		LettreTXT3
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
	*/
END;