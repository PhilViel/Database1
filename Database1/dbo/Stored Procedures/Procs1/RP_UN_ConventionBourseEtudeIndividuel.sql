/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_ConventionBourseEtudeIndividuel
Description         :	Rapport de fusion word des contrats individuels
Valeurs de retours  :
Note				:
								2003-09-09	Sylvain			Modification : Utilisation de la plus petite date InForce des groupes 
															d'unité de la convention (Un_Unit) au lieu de la date InForce du groupe 
															d'unité
								2004-05-25	Bruno			Modification : Migration et gestion des documents
				ADX0001355	IA	2007-06-06	Alain Quirion	Utilisation de dtRegEndDateAdjust en remplacement de RegEndDateAddyear
								2008-07-17	Pierre-Luc Simard	Modification pour ne plus retourner de dataset inutilement 
																si le document n'est pas généré immédiatement
								2008-11-24	Josée Parent		Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
								2012-02-14	Éric Deshaies		Modifier la date de la convention pour utiliser la
																date d'entrée en vigueur de l'obligation légale du contrat.
 ************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ConventionBourseEtudeIndividuel] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@UnitID INTEGER, -- ID du groupe d'unité
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

	DECLARE
		@InitDeposit MONEY,
		@MemberFees MONEY,
		@Today DATETIME,
		@IUnitID INTEGER,
		@DocTypeID INTEGER

	SET @Today = GetDate()	

	-- Table temporaire qui contient le certificat
	CREATE TABLE #Convention(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		ConventionID INTEGER,
		UnitID INTEGER,
		SubscriberLastName VARCHAR(50),
		SubscriberFirstName VARCHAR(35),
		SubscriberAddress VARCHAR(75),
		SubscriberCity VARCHAR(100),
		SubscriberState VARCHAR(75),
		SubscriberZipCode VARCHAR(10),
		SubscriberPhone VARCHAR(75),
		BeneficiaryFirstName VARCHAR(35),
		BeneficiaryLastName VARCHAR(50),
		BeneficiaryBirthDate VARCHAR(75),
		ConventionNo VARCHAR(75),
		RepID INTEGER,
		RepName VARCHAR(77),
		InForceDate VARCHAR(75),
		TerminatedDate VARCHAR(75),
		InitDepositAmount VARCHAR(75),
		MemberFees VARCHAR(75),
		TotalAmount VARCHAR(75)
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'ConvIndividuel'

	-- Va chercher les montants de cotisation et de frais
	SELECT
		@InitDeposit = ISNULL(SUM(CO.Cotisation), 0),
		@MemberFees = ISNULL(SUM(CO.Fee), 0)
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation CO ON (CO.UnitID = U.UnitID)
	WHERE (U.UnitID = @UnitID)

	-- Remplis la table temporaire
	INSERT INTO #Convention
		SELECT
			T.DocTemplateID,
			HS.LangID,
			C.ConventionID,
			U.UnitID,
			SubscriberLastName = HS.LastName,
			SubscriberFirstName = HS.FirstName,
			SubscriberAddress = Adr.Address,
			SubscriberCity = Adr.City,
			SubscriberState = Adr.StateName,
			SubscriberZipCode = dbo.fn_Mo_FormatZIP(Adr.ZipCode, ADR.CountryID),
			SubscriberPhone = dbo.fn_Mo_FormatPhoneNo(Adr.Phone1,ADR.CountryID),
			BeneficiaryFirstName = HB.FirstName,
			BeneficiaryLastName = HB.LastName,
			BeneficiaryBirthDate = dbo.fn_mo_DateToLongDateStr(HB.BirthDate, HS.LangID),
			C.ConventionNo,
			RepID = MIN(U.RepID),
			RepName = HR.LastName + ', ' + HR.FirstName,
			InForceDate = dbo.fn_mo_DateToLongDateStr([dbo].[fnCONV_ObtenirEntreeVigueurObligationLegale](C.ConventionID), HS.LangID),
			TerminatedDate = dbo.fn_mo_DateToLongDateStr((SELECT [dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL)), HS.LangID),
			InitDepositAmount = dbo.fn_Mo_MoneyToStr(@InitDeposit, HS.LangID, 0),
			MemberFees = dbo.fn_Mo_MoneyToStr(@MemberFees, HS.LangID, 0),
			TotalAmount = dbo.fn_Mo_MoneyToStr(SUM(@InitDeposit + @MemberFees), HS.LangID, 0)
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Subscriber S ON (S.SubscriberID = C.SubscriberID)
		JOIN dbo.Mo_Human HS ON (HS.HumanID = S.SubscriberID)
		JOIN dbo.Mo_Adr Adr ON (Adr.AdrID = HS.AdrID)
		JOIN dbo.Mo_Human HB ON (HB.HumanID = C.BeneficiaryID)
		JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
		JOIN (
			SELECT ConventionID, MIN(InForceDate) AS InForceDate
			FROM dbo.Un_Unit 
			GROUP BY ConventionID
			) U2 ON (U2.ConventionID = U.ConventionID)
		LEFT JOIN dbo.Mo_Human HR ON (HR.HumanID = S.RepID)
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
		WHERE (U.UnitID = @UnitID)
		GROUP BY 
			T.DocTemplateID,
			HS.LangID, 
			C.ConventionID,
			U.UnitID,
			HS.LastName, 
			HS.FirstName, 
			Adr.Address, 
			Adr.City, 
			Adr.StateName,	
			Adr.ZipCode, 
			Adr.Phone1, 
			Adr.CountryID, 
			HB.FirstName, 
			HB.LastName, 
			HB.BirthDate, 
			C.ConventionNo,
			C.dtRegEndDateAdjust,
			HR.FirstName,
			HR.LastName,
			C.dtInforceDateTIN,
			U2.InforceDate

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		DECLARE UnToDo CURSOR FOR
			SELECT DISTINCT 
				UnitID
			FROM #Convention C

		OPEN UnToDo;

      FETCH NEXT FROM UnToDo
 INTO @IUnitID

		WHILE (@@FETCH_STATUS = 0)
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
					ISNULL(CAST(ConventionID AS VARCHAR),'')+';'+
					ISNULL(CAST(UnitID AS VARCHAR),'')+';'+
					ISNULL(SubscriberLastName,'')+';'+
					ISNULL(SubscriberFirstName,'')+';'+
					ISNULL(SubscriberAddress,'')+';'+
					ISNULL(SubscriberCity,'')+';'+
					ISNULL(SubscriberState,'')+';'+
					ISNULL(SubscriberZipCode,'')+';'+
					ISNULL(SubscriberPhone,'')+';'+
					ISNULL(BeneficiaryFirstName,'')+';'+
					ISNULL(BeneficiaryLastName,'')+';'+
					ISNULL(BeneficiaryBirthDate,'')+';'+
					ISNULL(ConventionNo,'')+';'+
					ISNULL(CAST(RepID AS VARCHAR),'')+';'+
					ISNULL(RepName,'')+';'+
					ISNULL(InForceDate,'')+';'+
					ISNULL(TerminatedDate,'')+';'+
					ISNULL(InitDepositAmount,'')+';'+
					ISNULL(MemberFees,'')+';'+
					ISNULL(TotalAmount,'')+';'
				FROM #Convention 
				WHERE UnitID = @IUnitID

			-- Fait un lien entre le document et la convention pour qu'on retrouve le document 
			-- dans l'historique des documents de la convention
			INSERT INTO CRQ_DocLink 
				SELECT
					C.ConventionID,
					1,
					D.DocID
				FROM CRQ_Doc D 
				JOIN dbo.Un_Convention C ON (C.ConventionNo = D.DocGroup1)
				LEFT JOIN CRQ_DocLink L ON (L.DocID = D.DocID) AND (DocLinkType = 1)
				WHERE L.DocID IS NULL
				  AND DocOrderTime = @Today
				  AND DocOrderConnectID = @ConnectID	

			-- Fait un lien entre le document et le groupe d'unités pour qu'on retrouve le document 
			-- dans l'historique des documents du groupe d'unités
			INSERT INTO CRQ_DocLink 
				SELECT
					@IUnitID,
					2,
					D.DocID
				FROM CRQ_Doc D 
				LEFT JOIN CRQ_DocLink L ON (L.DocID = D.DocID) AND (DocLinkType = 2)
				WHERE L.DocID IS NULL
				  AND DocOrderTime = @Today
				  AND DocOrderConnectID = @ConnectID	

			IF @DocAction = 2
				-- Dans le cas que l'usager a choisi imprimer et garder la trace dans la gestion 
				-- des documents, on indique qu'il a déjà été imprimé pour ne pas le voir dans 
				-- la queue d'impression
				INSERT INTO CRQ_DocPrinted(DocID, DocPrintConnectID, DocPrintTime)
					SELECT DISTINCT
						D.DocID,
						@ConnectID,
						@Today
					FROM CRQ_Doc D 
					JOIN CRQ_DocLink L ON (L.DocID = D.DocID)
					JOIN dbo.Un_Unit U ON ((U.ConventionID = L.DocLinkID) AND (DocLinkType = 1)) 
										OR ((U.UnitID = L.DocLinkID) AND (DocLinkType = 2)) 
					LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @ConnectID AND P.DocPrintTime = @Today
					WHERE P.DocID IS NULL
					  AND U.UnitID = @IUnitID
					  AND DocOrderTime = @Today
					  AND DocOrderConnectID = @ConnectID	

	      FETCH NEXT FROM UnToDo
	      INTO @IUnitID
		END

		CLOSE UnToDo
		DEALLOCATE UnToDo
	
	END

	-- Produit un dataset pour la fusion
	IF @DocAction <> 0
		SELECT 
			DocTemplateID,
			LangID,
			SubscriberLastName,
			SubscriberFirstName,
			SubscriberAddress,
			SubscriberCity,
			SubscriberState,
			SubscriberZipCode,
			SubscriberPhone,
			BeneficiaryFirstName,
			BeneficiaryLastName,
			BeneficiaryBirthDate,
			ConventionNo,
			RepID,
			RepName,
			InForceDate,
			TerminatedDate,
			InitDepositAmount,
			MemberFees,
			TotalAmount
		FROM #Convention 
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
				ConventionNO
			FROM #Convention)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #Convention;
END


