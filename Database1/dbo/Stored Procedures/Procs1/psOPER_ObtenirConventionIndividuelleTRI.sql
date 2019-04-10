/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psOPER_ObtenirConventionIndividuelleTRI
Nom du service		:		Obtenir Convention Individuelle TRI
But					:		Rapport de fusion word des contrats individuels
Facette				:		OPER
Reférence			:		UniAccés-Noyau-OPER

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iConnectID 			Identifiant de la connection
						iUnitIDs			ID du blob
						iDocAction			Identifiant de l'action à prendre avec le document

Exemple d'appel:
				@iConnectID  = 1, --ID de connection de l'usager
				@iUnitID = 318766, --ID du blob
				@iDocAction = 0 -- Identifiant de l'action à prendre avec le document

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
											Code de retour						C'est un code de retour qui indique si la requête s'est terminée avec succès ou non

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-04-07					Frédérick Thibault						Création de procédure

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirConventionIndividuelleTRI] (
	@iConnectID INTEGER, -- ID de connexion de l'usager
	@iUnitIDs INTEGER, -- ID du blob contenant les UnitID séparés par des « , » des groupes d’unités dont on veut générer le document.  		
	@iDocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

	DECLARE
		@dtAujourdhui DATETIME,
		@iCurUnitID INTEGER,
		@iDocTypeID INTEGER

	SET @dtAujourdhui = GetDate()	

	CREATE TABLE #UnitInReport (
		UnitID INTEGER PRIMARY KEY )

	INSERT INTO #UnitInReport
		SELECT DISTINCT Val
		FROM dbo.FN_CRQ_BlobToIntegerTable(@iUnitIDs)

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
		@iDocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'TRIConvIndividuel'

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
			InForceDate = dbo.fn_mo_DateToLongDateStr(MIN(U.InForceDate), HS.LangID),
			TerminatedDate = dbo.fn_mo_DateToLongDateStr((SELECT [dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL)), HS.LangID),

			InitDepositAmount = dbo.fn_Mo_MoneyToStr(CO.Cotisation, HS.LangID, 0),
			MemberFees = dbo.fn_Mo_MoneyToStr(CO2.Fee, HS.LangID, 0),
			TotalAmount = dbo.fn_Mo_MoneyToStr(CO2.Cotisation + CO2.Fee, HS.LangID, 0)

		FROM #UnitInReport			UIR
		JOIN tblOper_OperationsRIO	OpRIO	ON (UIR.UnitID = OpRIO.iID_Unite_Source AND OpRIO.bRIO_Annulee = 0)
		JOIN Un_Convention			C		ON (C.ConventionID = OpRIO.iID_Convention_Destination)
		JOIN Un_Subscriber			S		ON (S.SubscriberID = C.SubscriberID)
		JOIN dbo.Mo_Human				HS		ON (HS.HumanID = S.SubscriberID)
		JOIN Mo_Adr					Adr		ON (Adr.AdrID = HS.AdrID)
		JOIN dbo.Mo_Human				HB		ON (HB.HumanID = C.BeneficiaryID)		
		JOIN Un_Unit				U		ON (U.ConventionID = C.ConventionID)
		
		JOIN (	SELECT	 SUM(Cotisation)	AS Cotisation
						--,MAX(Fee)			AS Fee
						,UnitID
						,RIO.iID_Convention_Destination 
						--,RIO.iID_Oper_RIO	AS IDOpRio
						,RIO.iID_Convention_Source AS IDConvSource
				FROM Un_Cotisation C1
				JOIN tblOper_OperationsRIO RIO	ON	(C1.OperId = RIO.iID_Oper_RIO) 
												AND	RIO.bRIO_Annulee = 0 AND RIO.bRIO_QuiAnnule = 0
				GROUP BY UnitId
						,iID_Convention_Destination
						--,RIO.iID_Oper_RIO
						,RIO.iID_Convention_Source
				)AS CO						ON	CO.UnitID = U.UnitID 
											AND	CO.iID_Convention_Destination = OpRIO.iID_Convention_Destination
											--AND IDOpRio = OpRIO.iID_Oper_RIO 
											AND IDConvSource = OpRIO.iID_Convention_Source 
					
		JOIN (	SELECT	 Un.ConventionID	AS ConventionID
						,SUM(CT.Cotisation) AS Cotisation
						,SUM(CT.Fee)		AS Fee
				FROM Un_Cotisation	CT
				JOIN Un_Unit		UN ON UN.UnitID = CT.UnitID 
				GROUP BY Un.ConventionID
				) AS CO2					ON CO2.ConventionID = OpRIO.iID_Convention_Destination

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
			WHERE (DocTypeID = @iDocTypeID)
			  AND (DocTemplateTime < @dtAujourdhui)
			GROUP BY LangID, DocTypeID
			) V ON (V.LangID = HS.LangID)
		JOIN CRQ_DocTemplate T ON (V.DocTypeID = T.DocTypeID) AND (V.DocTemplateTime = T.DocTemplateTime) AND (T.LangID = HS.LangID)
		
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
			CO.Cotisation,
			--CO.Fee,
			CO2.Cotisation,
			CO2.Fee,
			C.dtRegEndDateAdjust,
			HR.FirstName,
			HR.LastName,
			C.dtInforceDateTIN,			
			U2.InforceDate

	-- Gestion des documents
	IF @iDocAction IN (0,2)
	BEGIN

		DECLARE curUnToDo CURSOR FOR
			SELECT DISTINCT 
				UnitID
			FROM #Convention C

		OPEN curUnToDo ;

	      FETCH NEXT FROM curUnToDo INTO @iCurUnitID

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			-- Crée le document dans la gestion des documents
			INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
				SELECT 
					DocTemplateID,
					@iConnectID,
					@dtAujourdhui,
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
				WHERE UnitID = @iCurUnitID

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
				  AND DocOrderTime = @dtAujourdhui
				  AND DocOrderConnectID = @iConnectID	

			-- Fait un lien entre le document et le groupe d'unités pour qu'on retrouve le document 
			-- dans l'historique des documents du groupe d'unités
			INSERT INTO CRQ_DocLink 
				SELECT
					@iCurUnitID,
					2,
					D.DocID
				FROM CRQ_Doc D 
				LEFT JOIN CRQ_DocLink L ON (L.DocID = D.DocID) AND (DocLinkType = 2)
				WHERE L.DocID IS NULL
				  AND DocOrderTime = @dtAujourdhui
				  AND DocOrderConnectID = @iConnectID	

			IF @iDocAction = 2
				-- Dans le cas que l'usager a choisi imprimer et garder la trace dans la gestion 
				-- des documents, on indique qu'il a déjà été imprimé pour ne pas le voir dans 
				-- la queue d'impression
				INSERT INTO CRQ_DocPrinted(DocID, DocPrintConnectID, DocPrintTime)
					SELECT DISTINCT
						D.DocID,
						@iConnectID,
						@dtAujourdhui
					FROM CRQ_Doc D 
					JOIN CRQ_DocLink L ON (L.DocID = D.DocID)
					JOIN dbo.Un_Unit U ON ((U.ConventionID = L.DocLinkID) AND (DocLinkType = 1)) 
										OR ((U.UnitID = L.DocLinkID) AND (DocLinkType = 2)) 
					LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @iConnectID AND P.DocPrintTime = @dtAujourdhui
					WHERE P.DocID IS NULL
					  AND U.UnitID = @iCurUnitID
					  AND DocOrderTime = @dtAujourdhui
					  AND DocOrderConnectID = @iConnectID	

	      	FETCH NEXT FROM curUnToDo INTO @iCurUnitID
		END

		CLOSE curUnToDo 
		DEALLOCATE curUnToDo 
	
	END

	-- Produit un dataset pour la fusion
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
	WHERE @iDocAction IN (1,2)
	ORDER BY SubscriberLastName, SubscriberFirstName

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @iDocTypeID)
			  AND (DocTemplateTime < @dtAujourdhui))
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


