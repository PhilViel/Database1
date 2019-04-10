/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RESCheckLetter
Description         :	de chèque de remboursement d’épargne
Valeurs de retours  :	Dataset de données
Note                :				
						ADX0001169	IA	2006-10-26	Alain Quirion		Création																retournera « 2004, 2005 » et le champ « LastYear » retournera « 2006 ».
						ADX0001350	DM	2007-04-10	Alain Quirion		Ajout du champ agreement_s
										2008-09-25	Josée Parent		Ne pas produire de DataSet pour les documents 
																		commandés
										2012-06-05	Donald Huppé		enelver le PRIMARY KEY sur @ConventionGlobalCheckTable
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RESCheckLetter] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager qui a commandé le calcul
	@iCheckIDs INTEGER, -- ID du blob contenant la liste des ID des chèques séparés par des virgules
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN  
	DECLARE 
		@Today DATETIME

	DECLARE @TableDocTypeID TABLE(
		DocTypeID INTEGER)

	DECLARE @NbDocTemplates INTEGER	

	SET @Today = GETDATE()

	INSERT INTO @TableDocTypeID
	SELECT DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'RESCheckLetter_1'
		OR DocTypeCode = 'RESCheckLetter_2'
		OR DocTypeCode = 'RESCheckLetter_3'
		OR DocTypeCode = 'RESCheckLetter_4'

	SELECT @NbDocTemplates = COUNT(DocTemplateID)
	FROM CRQ_DocTemplate
	WHERE DocTypeID IN (SELECT * FROM @TableDocTypeID)
			  AND (DocTemplateTime < @Today)

	DECLARE @ConventionCheckTable TABLE(
		CheckID INTEGER,
		ConventionID INTEGER,
		ConventionNo VARCHAR(30),
		Total MONEY,
		Cotisation MONEY,
		Fee MONEY)

	DECLARE @DocTable TABLE(
		iCheckID INTEGER,
		ConventionID_1 INTEGER,
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
		de_la_ou_des_convention_s VARCHAR(20),
		citee_s VARCHAR(10),
		agreement_s VARCHAR(20),
		Convention_1 VARCHAR(30),
		Capital_depose_1 VARCHAR(20),
		Frais_encourus_1 VARCHAR(20),
		Epargne_1 VARCHAR(20),
		Convention_2 VARCHAR(30),
		Capital_depose_2 VARCHAR(20),
		Frais_encourus_2 VARCHAR(20),
		Epargne_2 VARCHAR(20),
		Convention_3 VARCHAR(30),
		Capital_depose_3 VARCHAR(20),
		Frais_encourus_3 VARCHAR(20),
		Epargne_3 VARCHAR(20),
		Convention_4 VARCHAR(30),
		Capital_depose_4 VARCHAR(20),
		Frais_encourus_4 VARCHAR(20),
		Epargne_4 VARCHAR(20)		
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

	--Suppression de ceux qui ne respectent pas les règles
	DELETE 
	FROM @tOperOfCheck
	WHERE iCheckID IN (	
			SELECT 
				OC.iCheckID
			FROM @tOperOfCheck OC
			JOIN Un_Cotisation Ct ON Ct.OperID = OC.OperID AND Ct.UnitID = OC.UnitID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
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
			LEFT JOIN Un_UnitReductionCotisation URC2 ON UR.UnitReductionID = URC2.UnitReductionID AND URC2.CotisationID <> URC.CotisationID
			LEFT JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
			LEFT JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperTypeID = 'TFR'
			WHERE UR.ReductionDate <> ISNULL(U.TerminatedDate,0) -- La résiliation n'est pas complète
				OR URR.UnitReductionReason = 'sans NAS après un (1) an' -- La raison de résiliation est "sans NAS après un (1) an"
				OR CCS.ConventionStateID <> 'FRM' -- La convention n'est pas résilié.
				OR O2.OperID IS NULL -- Il n'y pas de transfert de frais (TFR)
				)

	INSERT INTO @ConventionCheckTable
		SELECT 
			OC.iCheckID,
			C.ConventionID,
			C.ConventionNo,
			Total = (Ct.Cotisation+Ct.Fee+Ct2.Cotisation+Ct2.Fee)*-1, 
			(Ct.Cotisation+Ct2.Cotisation)*-1, 
			(Ct.Fee+Ct2.Fee)*-1	
		FROM @tOperOfCheck OC
		JOIN Un_Cotisation Ct ON Ct.OperID = OC.OperID AND Ct.UnitID = OC.UnitID
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
		JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
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
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperTypeID = 'TFR' -- Transfert de frais
		WHERE UR.ReductionDate = ISNULL(U.TerminatedDate,0) -- La résiliation est complète
			AND URR.UnitReductionReason <> 'sans NAS après un (1) an' -- La raison de résiliation n'est pas "sans NAS après un (1) an"
			AND CCS.ConventionStateID = 'FRM' -- La convention est résilié.				

	-- Supprime ceux qui ont plus de 4 conventions liés au chèque
	DELETE 
	FROM @ConventionCheckTable
	WHERE CheckID IN (	SELECT CheckID
						FROM @ConventionCheckTable
						GROUP BY CheckID
						HAVING COUNT(DISTINCT ConventionID) > 4)

	--Création d'une tble globale pour faire la sommation de résiliation d'une même convention sur plusieurs groupes d'unités
	DECLARE @ConventionGlobalCheckTable TABLE (
		CheckID INTEGER,
		ConventionID INTEGER,-- PRIMARY KEY,
		ConventionNo VARCHAR(15),
		Total MONEY,
		Cotisation MONEY,
		Fee MONEY)

	INSERT INTO @ConventionGlobalCheckTable
		SELECT	CheckID,
				ConventionID,
				ConventionNo,
				Total = SUM(Total),
				Cotisation = SUM(Cotisation),
				Fee = SUM(Fee)
		FROM @ConventionCheckTable
		GROUP BY
				CheckID,
				ConventionID,
				ConventionNo

	IF @NbDocTemplates >= 8	--Les 4 templates doivent être créés (x2 pour anglais francais)
	BEGIN
		--Création du document
		INSERT INTO @DocTable
		SELECT
			CH.iCheckID,
			CC1.ConventionID,
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
			montant_du_cheque = dbo.fn_Mo_MoneyToStr((SUM(ISNULL(CC1.Cotisation,0.00)) + SUM(ISNULL(CC2.Cotisation,0.00)) + SUM(ISNULL(CC3.Cotisation,0.00)) + SUM(ISNULL(CC4.Cotisation,0.00))), H.LangID, 1),
			de_la_ou_des_convntion_s = CASE 
											WHEN ISNULL(SUM(CC2.Total),-1) = -1 THEN 'de la convention'
											ELSE 'des conventions'
										END,
			citee_s = CASE 
							WHEN ISNULL(SUM(CC2.Total),-1) = -1 THEN 'citée'
							ELSE 'citées'
						END,
			agreement_s = CASE 
								WHEN ISNULL(SUM(CC2.Total),-1) = -1 THEN 'agreement'
								ELSE 'agreements'
							END,
			Convention_1 = ISNULL(CC1.ConventionNo,''),
			Capital_depose_1 = dbo.fn_Mo_MoneyToStr(SUM(CC1.Total), H.LangID, 1),
			Frais_encourus_1 = dbo.fn_Mo_MoneyToStr(SUM(CC1.Fee), H.LangID, 1),		
			Epargne_1 = dbo.fn_Mo_MoneyToStr(SUM(CC1.Cotisation), H.LangID, 1),
			Convention_2 = ISNULL(CC2.ConventionNo,''),
			Capital_depose_2 = dbo.fn_Mo_MoneyToStr(SUM(CC2.Total), H.LangID, 1),
			Frais_encourus_2 = dbo.fn_Mo_MoneyToStr(SUM(CC2.Fee), H.LangID, 1),	
			Epargne_2 = dbo.fn_Mo_MoneyToStr(SUM(CC2.Cotisation), H.LangID, 1),
			Convention_3 = ISNULL(CC3.ConventionNo,''),
			Capital_depose_3 = dbo.fn_Mo_MoneyToStr(SUM(CC3.Total), H.LangID, 1),
			Frais_encourus_3 = dbo.fn_Mo_MoneyToStr(SUM(CC3.Fee), H.LangID, 1),		
			Epargne_3 = dbo.fn_Mo_MoneyToStr(SUM(CC3.Cotisation), H.LangID, 1),
			Convention_4 = ISNULL(CC4.ConventionNo,''),
			Capital_depose_4 = dbo.fn_Mo_MoneyToStr(SUM(CC4.Total), H.LangID, 1),
			Frais_encourus_4 = dbo.fn_Mo_MoneyToStr(SUM(CC4.Fee), H.LangID, 1),	
			Epargne_4 = dbo.fn_Mo_MoneyToStr(SUM(CC4.Cotisation), H.LangID, 1)	
		FROM @ConventionGlobalCheckTable CC1
		JOIN CHQ_Check CH ON CH.iCheckID = CC1.CheckID
		LEFT JOIN @ConventionGlobalCheckTable CC2 ON CC1.CheckID = CC2.CheckID AND CC1.ConventionID <> CC2.ConventionID
		LEFT JOIN @ConventionGlobalCheckTable CC3 ON CC2.CheckID = CC3.CheckID AND CC2.ConventionID <> CC3.ConventionID AND CC1.ConventionID <> CC3.ConventionID
		LEFT JOIN @ConventionGlobalCheckTable CC4 ON CC3.CheckID = CC4.CheckID AND CC1.ConventionID <> CC4.ConventionID AND CC2.ConventionID <> CC4.ConventionID AND CC3.ConventionID <> CC4.ConventionID
		JOIN dbo.Un_Convention C ON C.ConventionID = CC1.ConventionID
		JOIN dbo.Mo_Human H ON H.HumanID = CH.iPayeeID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		LEFT JOIN Mo_Sex S ON S.SexID = H.SexID AND S.LangID = H.LangID
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
				SELECT 
					T.LangID,
					T.DocTypeID,
					D.DocTypeCode,
					DocTemplateTime = MAX(T.DocTemplateTime)
				FROM CRQ_DocTemplate T
				JOIN CRQ_DocType D ON D.DocTypeID = T.DocTypeID
				WHERE DocTemplateTime < @Today
				GROUP BY T.LangID, T.DocTypeID, D.DocTypeCode
				) V ON V.LangID = H.LangID AND V.DocTypeCode = CASE
											WHEN CC4.ConventionID IS NOT NULL THEN 'RESCheckLetter_4'
											WHEN CC3.ConventionID IS NOT NULL THEN 'RESCheckLetter_3'
											WHEN CC2.ConventionID IS NOT NULL THEN 'RESCheckLetter_2'
											ELSE 'RESCheckLetter_1'
										END
		JOIN CRQ_DocTemplate T ON V.DocTypeID = T.DocTypeID AND V.DocTemplateTime = T.DocTemplateTime AND T.LangID = H.LangID
		GROUP BY 
			CH.iCheckID,
			CC1.ConventionID,
			T.DocTemplateID,				
			H.LangID,	
			S.LongSexName,
			S.ShortSexName,
			H.IsCompany,
			H.LastName,
			H.FirstName,
			H.LastName,
			A.CountryID,
			A.Address,
			A.City,
			A.StateName,
			A.ZipCode,
			CC1.ConventionNo,
			CC2.ConventionNo,
			CC3.ConventionNo,
			CC4.ConventionNo			

		DECLARE @iCheckID INTEGER,
				@ConventionNo_1 VARCHAR(30),
				@ConventionNo_2 VARCHAR(30),
				@ConventionNo_3 VARCHAR(30),
				@ConventionNo_4 VARCHAR(30)

		CREATE TABLE #tCheckID(
			iCheckID INTEGER )

		INSERT INTO #tCheckID
			SELECT iCheckID
			FROM @DocTable
			GROUP BY iCheckID
			HAVING COUNT(*) > 1	-- Chèque avec plusieurs conventions

		-- Boucle qui supprime les doublons sur plusieurs conventions
		WHILE EXISTS (SELECT * FROM #tCheckID)
		BEGIN
			SELECT TOP 1
				@iCheckID = tC.iCheckID,
				@ConventionNo_1 = DT.Convention_1,
				@ConventionNo_2 = DT.Convention_2,
				@ConventionNo_3 = DT.Convention_3,
				@ConventionNo_4 = DT.Convention_4
			FROM #tCheckID tC
			JOIN @DocTable DT ON DT.iCheckID = tC.iCheckID

			DELETE 
			FROM @DocTable
			WHERE iCheckID = @iCheckID
				AND (Convention_1 <> @ConventionNo_1 --Supprimer seulement les doublons avec le même iCheckID
						OR Convention_2 <> @ConventionNo_2
						OR Convention_3 <> @ConventionNo_3
						OR Convention_4 <> @ConventionNo_4)

			--Suppresion dans la table temporaires des ch`ques
			DELETE 
			FROM #tCheckID
			WHERE iCheckID = @iCheckID
		END					

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
					ISNULL(de_la_ou_des_convention_s,'')+';'+
					ISNULL(citee_s,'')+';'+
					ISNULL(agreement_s,'')+';'+
					ISNULL(Convention_1,'')+';'+
					ISNULL(Capital_depose_1,'')+';'+
					ISNULL(Frais_encourus_1,'')+';'+		
					ISNULL(Epargne_1,'')+';'+	
					ISNULL(Convention_2,'')+';'+
					ISNULL(Capital_depose_2,'')+';'+
					ISNULL(Frais_encourus_2,'')+';'+		
					ISNULL(Epargne_2,'')+';'+
					ISNULL(Convention_3,'')+';'+
					ISNULL(Capital_depose_3,'')+';'+
					ISNULL(Frais_encourus_3,'')+';'+		
					ISNULL(Epargne_3,'')+';'+
					ISNULL(Convention_4,'')+';'+
					ISNULL(Capital_depose_4,'')+';'+
					ISNULL(Frais_encourus_4,'')+';'+		
					ISNULL(Epargne_4,'')+';'
				FROM @DocTable
	
			-- Fait un lient entre le document et la convention pour que retrouve le document 
			-- dans l'historique des documents de la convention
			INSERT INTO CRQ_DocLink 
				SELECT
					C.ConventionID,
					1,
					D.DocID
				FROM CRQ_Doc D 
				JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
				JOIN dbo.Un_Convention C ON (C.ConventionNo = D.DocGroup1)
				LEFT JOIN CRQ_DocLink L ON L.DocLinkID = C.ConventionID AND L.DocLinkType = 1 AND L.DocID = D.DocID
				WHERE L.DocID IS NULL
				   --AND T.DocTypeID = @DocTypeID
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
					  --AND T.DocTypeID = @DocTypeID
					  AND D.DocOrderTime = @Today
					  AND D.DocOrderConnectID = @ConnectID		
		END
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
			de_la_ou_des_convention_s,
			citee_s,
			agreement_s,
			Convention_1,
			Capital_depose_1,
			Frais_encourus_1,		
			Epargne_1,
			Convention_2,
			Capital_depose_2,
			Frais_encourus_2,		
			Epargne_2,
			Convention_3,
			Capital_depose_3,
			Frais_encourus_3,		
			Epargne_3,
			Convention_4,
			Capital_depose_4,
			Frais_encourus_4,	
			Epargne_4	
		FROM @DocTable
		WHERE @DocAction IN (1,2)	
	END

	IF @NbDocTemplates < 8	--Doit avoir un template pour les 4 types de documents (x2 anglais francais)
		RETURN -1 -- Pas de template d'entré ou en vigueur pour ces type de document	
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


