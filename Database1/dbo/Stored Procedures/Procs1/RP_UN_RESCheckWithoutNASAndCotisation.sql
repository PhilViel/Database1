/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RESCheckWithoutNASAndCotisation
Description         :	de chèque de remboursement d’épargne
Valeurs de retours  :	Dataset de données
Note                :			ADX0001169	IA	2006-10-27	Alain Quirion		Création																retournera « 2004, 2005 » et le champ « LastYear » retournera « 2006 ».
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les 
																				documents commandés
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RESCheckWithoutNASAndCotisation] (
	@ConnectID INTEGER, 		-- ID Unique de connexion de l'usager qui a commandé le calcul
	@iConventionID INTEGER,   	-- ID de la convention
	@DocAction INTEGER)	 	-- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN  
	DECLARE 
		@DocTypeID INTEGER,
		@Today DATETIME,
		@iOperID INTEGER
	
	SET @Today = GETDATE()

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE (DocTypeCode = 'RESCheckWoNASAndCot')

	DECLARE @ConventionTable TABLE(
		ConventionID INTEGER,
		ConventionNo VARCHAR(30),
		Fee MONEY)

	DECLARE @DocTable TABLE(
		DocTemplateID INTEGER,
		LangID CHAR(3), 
		Date VARCHAR(30),
		Appel1 VARCHAR(20),
		Appel2 VARCHAR(20),
		Destinataire VARCHAR(127),
		DestinataireInfo2 VARCHAR(127),
		Adresse VARCHAR(75),
		Ville VARCHAR(100),
		Province VARCHAR(75),
		Code_Postal VARCHAR(10),
		Convention_1 VARCHAR(30),
		Frais_encourus_1 VARCHAR(20)	
	)

	-- Va chercher la plus récente résiliation de la convention.
	SELECT @iOperID = ISNULL(MAX(O.OperID),0)
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	WHERE U.ConventionID = @iConventionID
		AND O.OperTypeID = 'RES'
		AND O.OperDate IN ( 
				SELECT OperDate = MAX(O.OperDate)
				FROM dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				WHERE U.ConventionID = @iConventionID
					AND O.OperTypeID = 'RES'
				)

	IF @iOperID > 0 
	BEGIN
		INSERT INTO @ConventionTable	
		SELECT 
			C.ConventionID,
			C.ConventionNo,
			Ct.Fee*-1 + CASE 
								WHEN ISNULL(O2.OperID,-1) = -1 THEN 0
								ELSE ISNULL(Ct2.Fee,0.00) * -1
						END								
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
		JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
		JOIN (	
			SELECT 
				CCS.ConventionID,
				MaxDate = MAX(CCS.StartDate)
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = U.ConventionID
			WHERE Ct.OperID = @iOperID
			GROUP BY CCS.ConventionID
			) CS ON U.ConventionID = CS.ConventionID
		JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = CS.ConventionID AND CCS.StartDate = CS.MaxDate
		LEFT JOIN Un_UnitReductionCotisation URC2 ON UR.UnitReductionID = URC2.UnitReductionID AND URC2.CotisationID <> URC.CotisationID
		LEFT JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
		LEFT JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperTypeID = 'TFR'
		WHERE	Ct.OperID = @iOperID
			AND( UR.ReductionDate = ISNULL(U.TerminatedDate,0) -- La résiliation est complète
				AND URR.UnitReductionReason = 'sans NAS après un (1) an' -- La raison de résiliation est "sans NAS après un (1) an"
				AND CCS.ConventionStateID = 'FRM' -- La convention est résilié.
				AND Ct.Cotisation = 0 -- Épargnes accumulés
				)
	END

	--Création du document
	INSERT INTO @DocTable
	SELECT 
		T.DocTemplateID,
		H.LangID,
		Date = ISNULL(dbo.fn_mo_DateToLongDateStr(@Today,H.LangID),''),					
		Appel1 = ISNULL(S.LongSexName,''),
		Appel2 = ISNULL(S.ShortSexName,''),
		Destinataire =	CASE H.IsCompany
							WHEN 1 THEN ISNULL(H.LastName,'')
							ELSE ISNULL(H.FirstName,'') + ' ' + ISNULL(H.LastName,'')
						END,
		DestinataireInfo2 =	CASE H.IsCompany
								WHEN 1 THEN ISNULL(H.LastName,'')
								ELSE ISNULL(H.LastName,'') + ', ' + ISNULL(H.FirstName,'')
							END,
		Adresse = ISNULL(A.Address,''),
		Ville = ISNULL(A.City,''),
		Province = ISNULL(A.StateName,''),
		Code_Postal = dbo.fn_Mo_FormatZip(A.ZipCode, A.CountryID),
		Convention_1 = ISNULL(CC1.ConventionNo,''),
		Frais_encourus_1 = dbo.fn_Mo_MoneyToStr(CC1.Fee, H.LangID, 1)	
	FROM @ConventionTable CC1
	JOIN dbo.Un_Convention C ON C.ConventionID = CC1.ConventionID
	JOIN dbo.Un_Subscriber SU ON SU.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human H ON H.HumanID = SU.SubscriberID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Mo_Sex S ON S.SexID = H.SexID AND S.LangID = H.LangID
	JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				T.LangID,
				T.DocTypeID,
				DocTemplateTime = MAX(T.DocTemplateTime)
			FROM CRQ_DocTemplate T
			WHERE DocTypeID = @DocTypeID
				AND DocTemplateTime < @Today
			GROUP BY T.LangID, T.DocTypeID
			) V ON V.LangID = H.LangID 
	JOIN CRQ_DocTemplate T ON V.DocTypeID = T.DocTypeID AND V.DocTemplateTime = T.DocTemplateTime AND T.LangID = H.LangID

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN
		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(Convention_1,''),
				ISNULL(DestinataireInfo2,''),
				'',
				ISNULL(LangID,'')+';'+
				ISNULL(CAST(Date AS VARCHAR),'')+';'+						
				ISNULL(Appel1,'')+';'+
				ISNULL(Appel2,'')+';'+
				ISNULL(Destinataire,'')+';'+
				ISNULL(Adresse,'')+';'+
				ISNULL(Ville,'')+';'+
				ISNULL(Province,'')+';'+
				ISNULL(Code_Postal,'')+';'+							
				ISNULL(Convention_1,'')+';'+				
				ISNULL(Frais_encourus_1,'')+';'							
			FROM @DocTable

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

	IF @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID,
			LangID,
			Date,					
			Appel1,
			Appel2,
			Destinataire,
			Adresse,
			Ville ,
			Province,
			Code_Postal,		
			Convention_1,		
			Frais_encourus_1		
		FROM @DocTable
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
			FROM @DocTable)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)
END


