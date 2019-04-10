/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_ConventionBourseEtudeRUI
Description         :	Rapport de fusion word des conventions Intermédiaire, REEEflex et Universitas
Valeurs de retours  :	Dataset de données
Note                :					
										2004-05-21	Bruno Lapointe		Création
						ADX0000589	IA	2004-11-19	Bruno Lapointe		Prendre la date de dernier dépôt pour contrat 
																		et relevés de dépôts inscrit par l'usager si pas vide.
						ADX0000670	IA	2005-03-14	Bruno Lapointe		Retourne la date de dernier dépôt pour relevés
																		et contrats.
										2006-05-15	Mireya Gonthier		Renommée SP_RP_UN_ConventionBourseEtudeRUI remplacé par
																		RP_UN_ConventionBourseEtudeRUI
						ADX0000983	IA 	2006-05-15	Mireya Gonthier		Remplacer la date du 1 novembre  par le 
																		1 septembre dans les documents de l'émission.
						ADX0001114	IA	2006-11-17	Alain Quirion		Utilisé la fonction FN_UN_EstimatedIntReimbDate avec paramètre IntReimbDateAjust.
						ADX0001374	IA	2007-05-30	Alain Quirion		Le champ ConvLastDepositDate devra tenir compte de la modalité de paiement du groupe d’unités.					
						ADX0001355	IA	2007-06-06	Alain Quirion		Utilisation de dtRegEndDateAdjust en remplacement de RegEndDateAddyear
										2008-07-17	Pierre-Luc Simard	Modification pour ne plus retourner de dataset inutilement 
																		si le document n'est pas généré immédiatement
										2008-11-24	Josée Parent		Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
										2010-11-10	Donald Huppé		Ajout d'un filtre sur le DocFiltreID dans l'insertion dans CRQ_DocLink pour le UnitID
																		Cela permet d'éviter l'ajout de la lettre d'émission et les certificats dans l'historique du groupe d'unité.
																		GLPI 3890
										2011-09-13	Eric Michaud		Enlever la référence a la date de ConventionID GLPI5982															
										2012-02-14	Éric Deshaies		Modifier la date de la convention pour utiliser la
																		date d'entrée en vigueur de l'obligation légale du contrat.

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ConventionBourseEtudeRUI] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@UnitID INTEGER, -- ID du groupe d'unités  
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN
	DECLARE
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
		SubscriberZipCode VARCHAR(75),
		SubscriberPhone VARCHAR(75),
		BeneficiaryFirstName VARCHAR(35),
		BeneficiaryLastName VARCHAR(50),
		BeneficiaryBirthDate VARCHAR(75),
		ConventionNo VARCHAR(75),
		RepID INTEGER,
		RepName VARCHAR(77),
		InForceDate VARCHAR(75),
		TerminatedDate VARCHAR(75),
		YearQualif INTEGER,
		ConvLastDepositDate VARCHAR(75),
		ConvReimbDate VARCHAR(75),
		ConvDepositMode VARCHAR(75),
		ConvNbrDeposit INTEGER,
		ConvNbrUnit VARCHAR(75),
		MntTotalSouscrit VARCHAR(75),
		MntDepotCotisation VARCHAR(75),
		MntDepotAss VARCHAR(75),
		MntDepotAssTaxe VARCHAR(75),
		MntTotalDepot VARCHAR(75)
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType T
	JOIN dbo.Un_Unit U ON (U.UnitID = @UnitID)
	JOIN Un_Modal M ON (M.ModalID = U.ModalID)
	JOIN Un_Plan P ON (P.PlanID = M.PlanID)
	WHERE (T.DocTypeCode = 'CnvIntermediaire' AND P.PlanDesc = 'Sélect 2000, Plan B')
		OR (T.DocTypeCode = 'CnvReeeflex' AND P.PlanDesc = 'Reeeflex')
		OR (T.DocTypeCode = 'CnvUniversitas' AND P.PlanDesc = 'Universitas')

	-- Remplis la table temporaire
	INSERT INTO #Convention
		SELECT
			T.DocTemplateID,
			HS.LangID,
			U.ConventionID,
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
			S.RepID,
			RepName = HR.LastName + ', ' + HR.FirstName,
			InForceDate = dbo.fn_mo_DateToLongDateStr([dbo].[fnCONV_ObtenirEntreeVigueurObligationLegale](C.ConventionID), HS.LangID),
			TerminatedDate = dbo.fn_mo_DateToLongDateStr((SELECT [dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL)), HS.LangID),
			YearQualif = C.YearQualif,
			ConvLastDepositDate = 					
							dbo.fn_mo_DateToLongDateStr(
								CASE 
									WHEN ISNULL(U.LastDepositForDoc,0) <= 0 THEN
										CASE 
											WHEN M.PmtQTY = 1 THEN U.InforceDate
											ELSE DATEADD(MONTH,(12/M.PmtByYearID)*(M.PmtQTY-1), CAST(CAST(YEAR(U.InForceDate) AS CHAR(4)) + '-' + CAST(MONTH(CASE WHEN M.PmtByYearID = 1 THEN C.FirstPmtDate ELSE U.InForceDate END) AS CHAR(2)) + '-' + CAST(DAY(C.FirstPmtDate) AS CHAR(2)) AS DATETIME))
										END
									ELSE 
										U.LastDepositForDoc
								END ,HS.LangID),
			ConvReimbDate = dbo.fn_mo_DateToLongDateStr(dbo.fn_Un_EstimatedIntReimbDate (M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) ,HS.LangID),
			ConvDepositMode = 
				CASE C.PmtTypeID
					WHEN 'CHQ' THEN 
						CASE HS.LangID
							WHEN 'FRA' THEN 'Chèque'
							WHEN 'ENU' THEN 'Cheque'
						ELSE '???'
						END
				ELSE 
					CASE HS.LangID
						WHEN 'FRA' THEN 'Automatique'
						WHEN 'ENU' THEN 'Automatic Deposit'
					ELSE '???'
					END
				END,
			ConvNbrDeposit = M.PmtQTY,
			ConvNbrUnit = dbo.fn_Mo_FloatToStr(U.UnitQTY, HS.LangID, 3, 0),
			MntTotalSouscrit = dbo.fn_Mo_MoneyToStr((ROUND(U.UnitQTY * M.PmtRate,2) * M.PmtQty) , HS.LangID, 0),
			MntDepotCotisation = dbo.fn_Mo_MoneyToStr(ROUND(U.UnitQTY * M.PmtRate,2) , HS.LangID, 0),
			MntDepotAss = 
				CASE U.WantSubscriberInsurance
					WHEN 1 THEN dbo.fn_Mo_MoneyToStr(ROUND(M.SubscriberInsuranceRate*U.UnitQty,2), HS.LangID, 0)
				ELSE dbo.fn_Mo_MoneyToStr(0 , HS.LangID, 0)
				END,
			MntDepotAssTaxe = 
				CASE U.WantSubscriberInsurance
					WHEN 1 THEN dbo.fn_Mo_MoneyToStr(ROUND((ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) * ST.StateTaxPct) + .0049,2), HS.LangID, 0)
				ELSE dbo.fn_Mo_MoneyToStr(0 , HS.LangID, 0)
				END,
			MntTotalDepot = 
				CASE U.WantSubscriberInsurance
					WHEN 1 THEN dbo.fn_Mo_MoneyToStr(ROUND(U.UnitQTY * M.PmtRate,2) +
						ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) +
						ROUND((ROUND(M.SubscriberInsuranceRate*U.UnitQty,2) * ST.StateTaxPct) + .0049,2), HS.LangID, 0)
				ELSE dbo.fn_Mo_MoneyToStr(ROUND(U.UnitQTY * M.PmtRate,2) , HS.LangID, 0)
				END
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON (U.ConventionID = C.ConventionID)
		JOIN dbo.Un_Subscriber S ON (S.SubscriberID = C.SubscriberID)
		JOIN dbo.Mo_Human HS ON (HS.HumanID = S.SubscriberID)
		JOIN dbo.Mo_Adr Adr ON (Adr.AdrID = HS.AdrID)
		JOIN dbo.Mo_Human HB ON (HB.HumanID = C.BeneficiaryID)
		LEFT JOIN dbo.Mo_Human HR ON (HR.HumanID = S.RepID)
		JOIN Un_Modal M ON (M.ModalID = U.ModalID)
		JOIN Un_Plan P ON (P.PlanID = M.PlanID)
		LEFT JOIN Mo_State ST ON (ST.StateID = S.StateID)
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
					ISNULL(CAST(YearQualif AS VARCHAR),'')+';'+
					ISNULL(ConvLastDepositDate,'')+';'+
					ISNULL(ConvReimbDate,'')+';'+
					ISNULL(ConvDepositMode,'')+';'+
					ISNULL(CAST(ConvNbrDeposit AS VARCHAR),'')+';'+
					ISNULL(ConvNbrUnit,'')+';'+
					ISNULL(MntTotalSouscrit,'')+';'+
					ISNULL(MntDepotCotisation,'')+';'+
					ISNULL(MntDepotAss,'')+';'+
					ISNULL(MntDepotAssTaxe,'')+';'+
					ISNULL(MntTotalDepot,'')+';'
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
				JOIN CRQ_DocTemplate T ON (T.DocTemplateID = D.DocTemplateID) -- modif du 2010-11-10
				LEFT JOIN CRQ_DocLink L ON (L.DocID = D.DocID) AND (DocLinkType = 2)
				WHERE L.DocID IS NULL
				  AND T.DocTypeID = @DocTypeID -- modif du 2010-11-10
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
			RepName,
			InForceDate,
			TerminatedDate,
			YearQualif,
			ConvLastDepositDate,
			ConvReimbDate,
			ConvDepositMode,
			ConvNbrDeposit,
			ConvNbrUnit,
			MntTotalSouscrit,
			MntDepotCotisation,
			MntDepotAss,
			MntDepotAssTaxe,
			MntTotalDepot
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


