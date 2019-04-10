/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RESCheckWithoutNAS
Description         :	de chèque de remboursement d’épargne
Valeurs de retours  :	Dataset de données
Note                :				ADX0001169	IA	2006-10-27	Alain Quirion		Création					
													2008-09-25	Josée Parent		Ne pas produire de DataSet pour les documents 
																					commandés	
													2010-02-24	Donald Huppé		Additionner les montants car il peut y avoir 
																					plus d'un groupe d'unité par convention (GLPI 3139)
retournera « 2004, 2005 » et le champ « LastYear » retournera « 2006 ».

exec RP_UN_RESCheckWithoutNAS 290498,425409,1

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RESCheckWithoutNAS] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager qui a commandé le calcul
	@iCheckIDs INTEGER,  -- ID du blob contenant la liste des ID des chèques séparés par des virgules
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN  
	DECLARE 
		@DocTypeID INTEGER,
		@Today DATETIME,
		@tempCheckID INTEGER
	
	SET @Today = GETDATE()

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE (DocTypeCode = 'RESCheckWithoutNAS')

	CREATE TABLE #ConventionCheckTable(
		ConventionCheckID INTEGER IDENTITY(1,1),
		CheckID INTEGER,
		ConventionID INTEGER,
		ConventionNo VARCHAR(30),
		montant_cheque MONEY,
		Total MONEY,
		Cotisation MONEY,
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
		montant_du_cheque VARCHAR(20),
		Convention_1 VARCHAR(30),
		Frais_encourus_1 VARCHAR(20),
		Epargne_1 VARCHAR(20)			
	)

	-- Table qui contient tout les groupes d'unités liés aux chèques
	DECLARE @tOperOfCheck TABLE (
		OperID INTEGER PRIMARY KEY,
		iCheckID INTEGER NOT NULL,
		UnitID INTEGER NOT NULL )

	INSERT INTO @tOperOfCheck
		SELECT DISTINCT Ct.OperID, CH.iCheckID, Ct.UnitID
		FROM CHQ_Check CH
		JOIN CHQ_CheckOperationDetail COP ON CH.iCheckID = COP.iCheckID
		JOIN CHQ_OperationDetail OD ON COP.iOperationDetailID = OD.iOperationDetailID
		JOIN Un_OperLinkToCHQOperation OL ON OD.iOperationID = OL.iOperationID
		JOIN Un_Cotisation Ct ON Ct.OperID = OL.OperID
		JOIN dbo.FN_CRI_BlobToIntegerTable(@iCheckIDs) BC ON BC.iVal = CH.iCheckID

	INSERT INTO #ConventionCheckTable(	CheckID,
										ConventionID,
										ConventionNo,
										montant_cheque,
										Total,
										Cotisation,
										Fee)
		SELECT 
			OC.iCheckID,
			C.ConventionID,
			C.ConventionNo,	
			0,
			Total = (Ct.Cotisation+Ct.Fee+Ct2.Cotisation+Ct2.Fee)*-1, 
			(Ct.Cotisation+Ct2.Cotisation)*-1, 
			(Ct.Fee+Ct2.Fee)*-1	
		FROM @tOperOfCheck OC
		JOIN Un_Cotisation Ct ON Ct.OperID = OC.OperID AND Ct.UnitID = OC.UnitID
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
		JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID -- select * from Un_UnitReductionReason
		JOIN (	
			SELECT 
				CCS.ConventionID,
				MaxDate = MAX(CCS.StartDate)
			FROM @tOperOfCheck OC
			JOIN dbo.Un_Unit U ON U.UnitID = OC.UnitID
			JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = U.ConventionID
			GROUP BY CCS.ConventionID
			) CS ON U.ConventionID = CS.ConventionID
		JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = CS.ConventionID AND CCS.StartDate = CS.MaxDate
		JOIN Un_UnitReductionCotisation URC2 ON UR.UnitReductionID = URC2.UnitReductionID AND URC2.CotisationID <> URC.CotisationID
		JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperTypeID = 'TFR'
		WHERE UR.ReductionDate = ISNULL(U.TerminatedDate,0) -- La résiliation n'est pas complète
			--AND URR.UnitReductionReason = 'sans NAS après un (1) an' -- La raison de résiliation est "sans NAS après un (1) an"
				AND URR.UnitReductionReasonID = 7 -- La raison de résiliation est "sans NAS après un (1) an"
				AND CCS.ConventionStateID = 'FRM' -- La convention est résilié.
	
	-- Supprime ceux qui ont plus de 1 conventions liés au chèque
	/*DELETE 
	FROM @ConventionCheckTable
	WHERE CheckID IN (	SELECT CheckID
				FROM @ConventionCheckTable
				GROUP BY CheckID
				HAVING COUNT(*) > 1)*/
	-- BR-ADX0002258 : La lettre doit être commandée et la convention la plus ancienne doit apparaitre seulement

	UPDATE #ConventionCheckTable
	SET 
		montant_cheque = SumCotisation	
		,Fee = sumFee	-- GLPI 3139
		,Cotisation = SumCotisation -- GLPI 3139
	FROM #ConventionCheckTable
	JOIN (
		SELECT 
			CheckID, 
			SumCotisation = SUM(Cotisation)
			,SumFee = sum(Fee) -- GLPI 3139
		FROM #ConventionCheckTable
		GROUP BY CheckID
		) V ON V.CheckID = #ConventionCheckTable.CheckID	

	--Supprime les chèques identiques
	DECLARE CUR_CheckIDs CURSOR FOR
		SELECT DISTINCT
				CheckID
		FROM #ConventionCheckTable

	OPEN CUR_CheckIDs

	FETCH NEXT FROM CUR_CheckIDs
		INTO 
			@tempCheckID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		DELETE 
		FROM #ConventionCheckTable
		WHERE CheckID = @tempCheckID
			AND ConventionCheckID NOT IN (	SELECT MAX(ConventionCheckID)
											FROM #ConventionCheckTable
											WHERE CheckID = @tempCheckID)

		FETCH NEXT FROM CUR_CheckIDs
		INTO 
			@tempCheckID
	END

	CLOSE CUR_CheckIDs
	DEALLOCATE CUR_CheckIDs
	
	--Création du document
	INSERT INTO @DocTable
	SELECT DISTINCT 
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
		montant_du_cheque = dbo.fn_Mo_MoneyToStr(CC1.montant_cheque, H.LangID, 1),
		Convention_1 = ISNULL(CC1.ConventionNo,''),
		Frais_encourus_1 = dbo.fn_Mo_MoneyToStr(CC1.Fee, H.LangID, 1),		
		Epargne_1 = dbo.fn_Mo_MoneyToStr(CC1.Cotisation, H.LangID, 1)	
	FROM #ConventionCheckTable CC1
	JOIN CHQ_Check CH ON CH.iCheckID = CC1.CheckID
	JOIN dbo.Un_Convention C ON C.ConventionID = CC1.ConventionID
	JOIN dbo.Mo_Human H ON H.HumanID = CH.iPayeeID
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
	GROUP BY	T.DocTemplateID,
				H.LangID,							
				S.LongSexName,
				S.ShortSexName,
				H.IsCompany,
				H.LastName,
				H.FirstName,
				A.CountryID,
				A.Address,
				A.City,
				A.StateName,
				A.ZipCode,
				CC1.montant_cheque,
				CC1.ConventionNo,
				CC1.Fee,		
				CC1.Cotisation
	
	-- Gestion des documents
	IF @DocAction IN (0,2,3)
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
				ISNULL(montant_du_cheque,'')+';'+				
				ISNULL(Convention_1,'')+';'+
				ISNULL(Frais_encourus_1,'')+';'+		
				ISNULL(Epargne_1,'')+';'				
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

	IF @DocAction <> 3 AND @DocAction <> 0
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
			montant_du_cheque,
			Convention_1,
			Frais_encourus_1,		
			Epargne_1
		FROM @DocTable
		WHERE @DocAction IN (1,2)
	END

	DROP TABLE #ConventionCheckTable

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


