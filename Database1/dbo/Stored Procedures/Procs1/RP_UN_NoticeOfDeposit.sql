/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_NoticeOfDeposit
Description         :	Procédure retournant les données nécessaires à la fusion des avis de 
								retard pour les conventions payant par chèques.  Il retourne les données 
								qui sont entre les deux dates (StartDate et EndDate)
Valeurs de retours  :	Dataset de données
Note                :				2004-05-26				Bruno Lapointe 	Migration
						2004-05-31				Bruno Lapointe	Ne sort pas de relevés pour les souscripteurs dont 
																				l'adresse perdue Point 10.8.7.1 (2.1) 
						ADX0000441	IA	2004-06-03	Bruno Lapointe	Pas d'avis quand le montant souscrit est atteint 
											2004-06-15	Bruno Lapointe	Point 12.41.03
						ADX0000689	IA	2005-04-15	Bruno Lapointe	Point 10.72
						ADX0001422	BR	2005-05-16	Bruno Lapointe 	Correction du bug : Les taxes ne prennait pas en 
																				compte les réductions d'unités.  De plus, les 
																				réductions d'unités ne prennait pas compte des 
																				changements de mode de dépôts et de la condition du 
																				1 avril 2005.
						ADX0001435	BR	2005-05-20	Bruno Lapointe	Correction problème des deux groupes d'unités.
						ADX0000906	UP	2006-03-31	Bruno Lapointe	Si la date d'entrée en vigueur du groupe d'unités
																				est plus petit que la date de la première et seul
																				historique de modalité, on prend la date d'entrée en 
																				vigueur du groupe d'unités pour calcul l'assurance.
						ADX0001200	IA	2006-11-14	Alain Quirion	Les montants d’assurance souscripteur, d’assurance bénéficiaire et de taxe seront maintenant celle d’un dépôt théorique
						ADX0001206	IA	2006-12-19	Alain Quirion	Optimisation
						ADX0002304	BR	2007-02-22	Bruno Lapointe	Correction de calcul de la cotisation pour qu'il comble aussi les retards.
						ADX0002384	BR	2007-04-16	Bruno Lapointe	Ne sortir que les avis quand le montant d'épargne en retard
																				est de plus de 0.00$
										2008-09-25	Josée Parent	Ne pas produire de DataSet pour les 
																	documents commandés
										2012-05-10	Donald Huppé	GLPI 7563 : Ajout de SubscriberID
										2015-08-18	Donald Huppé	Ajout du paramètre @PmtTypeID (val par défaut CHQ, pour faire comme avant) pour utilisation par le rapport psREPR_RapportAvisCotisationAnnuelle avec AUT et CHQ en paramètre
										2016-04-08	Donald Huppé	jira ti-1855 : vérifer la présence d'un horraire de prélèvement et utiliser cette date (si elle existe) à la place de FirstPmtDate. Seulement pour les Annuels automatiques (AUT).
										2018-09-05	Donald Huppé	jira prod-11172 : vérifier les RIN partiel et complet (au lieu de juste complet)  avec fntCONV_ObtenirStatutRINUnite

exec RP_UN_NoticeOfDeposit 1, '2016-07-06','2016-07-06',1, 'AUT'
exec RP_UN_NoticeOfDeposit 2926332,'2015-08-18 00:00:00','2015-10-31 00:00:00',1,NULL
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_NoticeOfDeposit] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager qui a appellé la fusion
	@StartDate DATETIME, -- Date délimitant le début de la période dans laquel le dépôt en retard doit avoir eu lieu.
	@EndDate DATETIME, -- Date délimitant la fin de la période dans laquel le dépôt en retard doit avoir eu lieu.
	@DocAction INTEGER, -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
	@PmtTypeID varchar(3) = 'CHQ')
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @PmtTypeID  = ISNULL(@PmtTypeID,'CHQ')

	SET @dtBegin = GETDATE()

	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER,
		@AutomaticDepositDate DATETIME

	SET @Today = GetDate()	

	-- Table temporaire qui contient les documents
	CREATE TABLE #Notice(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		ConventionNo VARCHAR(75),
		SubscriberName VARCHAR(77),
		SubscriberAddress VARCHAR(75),
		SubscriberCity VARCHAR(100),
		SubscriberState VARCHAR(75),
		SubscriberZipCode VARCHAR(75),
		SubscriberCountry VARCHAR(75),
		PlanName VARCHAR(75),
		YearQualif INTEGER,
		BeneficiaryName VARCHAR(77),	
		DepositDate VARCHAR(75),
		ReelAmount VARCHAR(75), 
		EstimatedAmount VARCHAR(75), 
		AssAmount VARCHAR(75),
		TaxeAmount VARCHAR(75),
		Amount VARCHAR(75), 
		TotalAmount VARCHAR(75),
		SubscriberID int
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'NoticeOfDeposit'

	SET @AutomaticDepositDate = @StartDate

	-- Creation table temporaire 
	CREATE TABLE #Temp (
		ConventionID INTEGER,
		UnitID INTEGER,
		TheoricalAmount FLOAT,
		TheoricalSousAssAmount FLOAT,
		TheoricalBenefAssAmount FLOAT,
		TheoricalTaxesAmount FLOAT,
		DepositDate DATETIME
		)

	CREATE TABLE #searchConv(
		ConventionID INTEGER PRIMARY KEY)

	INSERT INTO #searchConv
		SELECT DISTINCT C.ConventionID
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @EndDate) RIN ON RIN.UnitID = U.UnitID
		WHERE (ISNULL(U.TerminatedDate,0) <= 0) -- Exclus les conventions résiliées
			AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
			--AND (ISNULL(U.IntReimbDate,0) <= 0) -- Exclus les conventions en remboursement intégral
			AND (U.ActivationConnectID > 0)
			AND U.PmtEndConnectID IS NULL -- Exclus les fins de paiement forcée
			AND C.PmtTypeID = @PmtTypeID --'CHQ' 

	CREATE TABLE #MaxModalHistory (
		UnitID INTEGER PRIMARY KEY,
		StartDate DATETIME )

	INSERT INTO #MaxModalHistory
		SELECT  
			U.UnitID,
			StartDate =
				CASE
					WHEN MAX(StartDate) >= '2005-04-01'
						AND U.InForceDate > '2005-04-01'
						AND MAX(StartDate) > U.InForceDate
						AND COUNT(UnitModalHistoryID) = 1 THEN U.InForceDate
					WHEN MAX(StartDate) >= '2005-04-01' THEN MAX(StartDate)
				ELSE
					'2005-04-01'
				END
		FROM Un_UnitModalHistory H
		JOIN dbo.Un_Unit U ON U.UnitID = H.UnitID
		GROUP BY U.UnitID, U.InForceDate

	WHILE @AutomaticDepositDate < (@EndDate + 1)
	BEGIN
		INSERT INTO #Temp
			SELECT  
				C.ConventionID,
				U.UnitID,
				TheoricalAmount = ROUND(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(MONTH, MJ.MonthAjustment,@AutomaticDepositDate), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)-T.CotisationFee,2),
				TheoricalSousAssAmount = CASE  
								WHEN U.WantSubscriberInsurance = 0 THEN 0
								WHEN MU.UnitID IS NULL THEN 
									ROUND(U.UnitQty * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate),2)
								WHEN U.UnitQty >= 1 THEN
									ROUND(ROUND(1 * M.SubscriberInsuranceRate,2) + 
									((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate)),2)
								ELSE ROUND(U.UnitQty * M.SubscriberInsuranceRate,2) 
							END,
				TheoricalBenefAssAmount = ROUND(ISNULL(BI.BenefInsurRate,0),2),
				TheoricalTaxesAmount = 0,
				DepositDate = @AutomaticDepositDate 
			FROM #searchConv SC
			JOIN dbo.Un_Convention C ON C.ConventionID = SC.ConventionID
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN (
				SELECT 
					U.UnitID,
					MonthAjustment =  
						CASE 
							WHEN MONTH(C.FirstPmtDate) > MONTH(U.InForceDate) THEN 
								MONTH(U.InForceDate) - MONTH(C.FirstPmtDate) + 12
							WHEN MONTH(C.FirstPmtDate) < MONTH(U.InForceDate) THEN 
								MONTH(U.InForceDate) - MONTH(C.FirstPmtDate)
							ELSE 0
						END
				FROM #searchConv SC
				JOIN dbo.Un_Unit U ON U.ConventionID = SC.ConventionID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				) MJ ON MJ.UnitID = U.UnitID
			JOIN #MaxModalHistory MH ON MH.UnitID = U.UnitID
			JOIN Un_Modal M ON M.ModalID = U.ModalID			
			LEFT JOIN Un_HalfSubscriberInsurance HSI ON HSI.ModalID = M.ModalID
			LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID	
			LEFT JOIN (
					SELECT 
						Ct.UnitID,
						CotisationFee = SUM(Ct.Cotisation+Ct.Fee)				
					FROM Un_Cotisation Ct
					JOIN #MaxModalHistory MH ON MH.UnitID = Ct.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					GROUP BY Ct.UnitID
					) T ON T.UnitID = U.UnitID 
			LEFT JOIN (
					SELECT MIN(UnitID) AS UnitID 
					FROM dbo.Un_Unit 
					GROUP BY ConventionID 
					) MU ON MU.UnitID = U.UnitID
			LEFT JOIN(
					SELECT ConventionID 
					FROM Un_Breaking 
					WHERE ( @AutomaticDepositDate >= BreakingStartDate )
						AND( BreakingEndDate IS NULL
							OR ( BreakingEndDate <= 0 )
							OR ( @AutomaticDepositDate <= BreakingEndDate )
							) 
					) V1 ON V1.ConventionID = C.ConventionID
			LEFT JOIN(
					SELECT UnitID
					FROM Un_UnitHoldPayment
					WHERE (@AutomaticDepositDate >= StartDate)
						AND( EndDate IS NULL
							OR ( EndDate <= 0 )
							OR ( @AutomaticDepositDate <= EndDate )
							) 
					) V2 ON V2.UnitID = U.UnitID
			LEFT JOIN(
					SELECT ad.UnitID,FirstAutomaticDepositDate = MAX(ad.FirstAutomaticDepositDate)
					FROM 
						Un_AutomaticDeposit ad
						join Un_Unit u on u.UnitID = ad.UnitID
						join Un_Convention c on u.ConventionID = c.ConventionID
						join Un_Modal m on u.ModalID = m.ModalID
					WHERE m.PmtByYearID = 1 AND m.PmtQty > 1
					AND C.PmtTypeID = 'AUT'
					AND @AutomaticDepositDate BETWEEN ad.StartDate AND isnull(ad.EndDate,'9999-12-31')
					GROUP BY ad.UnitID
				)DepotAUTAnnuel ON DepotAUTAnnuel.UnitID = U.UnitID

			WHERE V1.ConventionID IS NULL -- Sert à la détection d'un arrêt de paiement sur le groupe d'unité				
				AND V2.UnitID IS NULL -- Sert à la détection d'un arrêt de paiement sur le groupe d'unité
				AND (M.PmtQty > 1) -- Exclus les uniques
				AND M.PmtByYearID = 1 -- Annuel seulement				
				
				AND (
						(DepotAUTAnnuel.UnitID IS NULL 
						-- Les 3 prochaines lignes s'assure que ce soit le jour du prélèvement
						AND DAY(C.FirstPmtDate) = DAY(@AutomaticDepositDate)
						AND ((MONTH(DATEADD(MONTH, MJ.MonthAjustment,@AutomaticDepositDate)) - MONTH(U.InForceDate)) % (12/M.PmtByYearID) = 0)
						AND (MONTH(DATEADD(MONTH, MJ.MonthAjustment,@AutomaticDepositDate)) <> MONTH(U.InForceDate) OR YEAR(DATEADD(MONTH, MJ.MonthAjustment,@AutomaticDepositDate)) <> YEAR(U.InForceDate))
						)
					OR
						(DepotAUTAnnuel.UnitID IS NOT NULL 
						AND DAY(DepotAUTAnnuel.FirstAutomaticDepositDate) = DAY(@AutomaticDepositDate)
						AND MONTH(DepotAUTAnnuel.FirstAutomaticDepositDate) = MONTH(@AutomaticDepositDate)
						)
					)
				
				AND ISNULL(T.CotisationFee,0) < (ROUND(U.UnitQty * M.PmtRate,2) * M.PmtQty)

 		SET @AutomaticDepositDate = @AutomaticDepositDate + 1
	END

	INSERT INTO #Notice
		SELECT 
			T.DocTemplateID,
			HS.LangID,
			C.ConventionNo,
			SubscriberName = HS.FirstName + ' ' + HS.LastName,
			SubscriberAddress = A.Address,
			SubscriberCity = A.City,
			SubscriberState = A.StateName,
			SubscriberZipCode = dbo.fn_Mo_FormatZip(A.ZipCode, A.CountryID),
			SubscriberCountry = A.CountryID,
			PlanName = P.PlanDesc,
			C.YearQualif,
			BeneficiaryName = HB.FirstName + ' ' + HB.LastName,	
			DepositDate = dbo.fn_Mo_DateToShortDateStr(Tem.DepositDate,HS.LangID),
			ReelAmount = dbo.fn_Mo_MoneyToStr(0, HS.LangID, 1), 
			EstimatedAmount = dbo.fn_Mo_MoneyToStr(SUM(Tem.TheoricalAmount), HS.LangID, 1), 
			AssAmount = dbo.fn_Mo_MoneyToStr( SUM(Tem.TheoricalSousAssAmount + Tem.TheoricalBenefAssAmount), HS.LangID, 1),
			TaxeAmount = dbo.fn_Mo_MoneyToStr( SUM( ROUND( ( (Tem.TheoricalSousAssAmount + Tem.TheoricalBenefAssAmount) 
																* ISNULL(St.StateTaxPct,0) ) + 0.0049,2)), HS.LangID, 1),
			Amount = dbo.fn_Mo_MoneyToStr( SUM(Tem.TheoricalAmount), HS.LangID, 1), 
			TotalAmount = dbo.fn_Mo_MoneyToStr(
						(  SUM(Tem.TheoricalSousAssAmount + Tem.TheoricalBenefAssAmount) + 
						  -- calc taxe sur diff de Ass
						   ROUND( (SUM(Tem.TheoricalSousAssAmount) + SUM(Tem.TheoricalBenefAssAmount)) 
															 * ISNULL(St.StateTaxPct,0) + 0.0049,2)) + 
						   SUM(Tem.TheoricalAmount), HS.LangID, 1), 
			C.SubscriberID
		FROM #Temp Tem
		JOIN dbo.Un_Convention C ON (C.ConventionID = Tem.ConventionID)
		JOIN dbo.Un_Subscriber S ON (S.SubscriberID = C.SubscriberID)
		JOIN dbo.Mo_Human HS ON (HS.HumanID = S.SubscriberID)
		JOIN dbo.Mo_Adr A ON (A.AdrID = HS.AdrID)
		JOIN dbo.Mo_Human HB ON (HB.HumanID = C.BeneficiaryID)
		JOIN Un_Plan P ON (P.PlanID = C.PlanID)
		LEFT JOIN Mo_State St ON (St.StateID = S.StateID)
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
		WHERE S.AddressLost = 0 -- Exclus les souscripteurs dont l'adresse est perdue
		GROUP BY 
			T.DocTemplateID,
			C.ConventionNo, 
			HS.FirstName, 
			HS.LastName,
			A.Address, 
			A.City, 
			A.StateName, 
			A.ZipCode,
			A.CountryID,
			P.PlanDesc,
			C.YearQualif,
			HB.FirstName, 
			HB.LastName,
			Tem.DepositDate,
			HS.LangID,
			St.StateTaxPct, 
			C.SubscriberID
		HAVING SUM(Tem.TheoricalAmount) > 0
		ORDER BY 
			T.DocTemplateID,
			Tem.DepositDate, 
			HS.LastName, 
			HS.FirstName, 
			C.ConventionNo   

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(ConventionNO,''),
				ISNULL(DepositDate,''),
				ISNULL(TotalAmount,''),
				ISNULL(LangID,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(SubscriberName,'')+';'+
				ISNULL(SubscriberAddress,'')+';'+
				ISNULL(SubscriberCity,'')+';'+
				ISNULL(SubscriberState,'')+';'+
				ISNULL(SubscriberZipCode,'')+';'+
				ISNULL(SubscriberCountry,'')+';'+
				ISNULL(PlanName,'')+';'+
				ISNULL(CAST(YearQualif AS VARCHAR),'')+';'+
				ISNULL(BeneficiaryName,'')+';'+
				ISNULL(DepositDate,'')+';'+
				ISNULL(ReelAmount,'')+';'+
				ISNULL(EstimatedAmount,'')+';'+
				ISNULL(AssAmount,'')+';'+
				ISNULL(TaxeAmount,'')+';'+
				ISNULL(Amount,'')+';'+
				ISNULL(TotalAmount,'')+';'+
				ISNULL(CAST(SubscriberID AS VARCHAR),'')+';'
			FROM #Notice

		-- Fait un lien entre le document et la convention pour que retrouve le document 
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
			ConventionNo,
			SubscriberName,
			SubscriberAddress,
			SubscriberCity,
			SubscriberState,
			SubscriberZipCode,
			SubscriberCountry,
			PlanName,
			YearQualif,
			BeneficiaryName,	
			DepositDate,
			ReelAmount, 
			EstimatedAmount, 
			AssAmount,
			TaxeAmount,
			Amount, 
			TotalAmount,
			SubscriberID
		FROM #Notice 
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

	DROP TABLE #Temp
	DROP TABLE #Notice

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
	BEGIN
		-- Insère un log de l'objet inséré.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Rapport des avis de dépôt entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_NoticeOfDeposit',
				'EXECUTE RP_UN_NoticeOfDeposit @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+	
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+
				', @DocAction ='+CAST(@DocAction AS VARCHAR)
	END	
END


