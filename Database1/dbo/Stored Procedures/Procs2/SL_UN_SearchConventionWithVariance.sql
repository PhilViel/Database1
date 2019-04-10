/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionWithVariance
Description         :	Procédure de recherche de convention avec écarts entre le réel et le théorique.
Valeurs de retours  :	Dataset :
							ConventionID		INTEGER		ID de la convention.
							ConventionNo		VARCHAR(75)	Numéro de convention.
							SubscriberID		INTEGER		ID du souscripteur.
							SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
							RealCotisation 		MONEY		Solde réel des épargnes
							RealFee				MONEY		Solde réel des frais
							RealSum				MONEY		Total déposé
							TheoricCotisation	MONEY		Solde théorique des épargnes
							TheoricFee			MONEY		Solde théorique des frais
							TheoricSum			MONEY		Total thérique
							DiffSum				MONEY		Différence entre les totaux				
							Deposit				MONEY		Montant théorique d'un dépôt
							NbDiffDeposit		INTEGER		Nombre de dépôt en écart
							BreakingTypeID	 	MONEY		Type d'arrêt de paiement s'il y en a un
 
Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe		Création
						ADX0001178	IA	2006-10-20	Alain Quirion		Modification	: Ajout des date de début et de fin. Ajout du type de recherche.  Supression du statut
										2006-12-05	Alain Quirion		Optimisation
						ADX0001274	IA	2007-02-20	Alain Quirion		Écart de 2,00$ au lieu de 0,01$
						ADX0002348	BR	2007-04-11	Alain Quirion		Corrigé le bug des conventions terminés qui retourne les écart positif et les clés primaires en double quand la procédure est exécuté par deux personnes en même temps.
                                        2018-02-07  Pierre-Luc Simard   Exclure aussi les RIN partiel
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionWithVariance] (
	@ConnectID INTEGER,		-- ID de connexion
	@iType INTEGER,  		-- Type : Toutes les conventions =0, Payant par chèque seulement = 1, En Suspension = 2, En arrêt de paiement = 3, Actif ne payant pas par chèque seulement = 4, Avec écart d’un cent = 5, Terminées = 6
	@bIncludePositive INTEGER, 	-- Avec écarts positifs = 1, sans les écarts positifs = 0
	@dtStartDate DATETIME,		-- Date de début de recherche (0 pour inclure toutes les dates)
	@dtEndDate DATETIME,		-- Date de fin de recherche (0 pour inclure toutes les dates)
	@iRepID INTEGER = 0) 		-- Limiter les résultats selon un représentant, 0 pour tous
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()

	CREATE TABLE #TB_Rep (
		RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #TB_Rep
		EXEC SL_UN_BossOfRep @iRepID

	-- Retourne les conventions qui ont un écart entre le réel et le théorique 
	DECLARE 
		@Today DATETIME,
		@EndDate DATETIME,
		@OpenDays INTEGER

	SET @OpenDays = 0

	SELECT 
		@OpenDays = DaysAfterToTreat+DaysAddForNextTreatment
	FROM Un_AutomaticDepositTreatmentCfg
	WHERE DATEPART(dw, GETDATE()) = TreatmentDay

	SET @Today = dbo.FN_CRQ_DateNoTime(GETDATE())
	  
	SELECT 
		@EndDate = MAX(BankFileEndDate)
	FROM Un_BankFile

	CREATE TABLE #searchConv (
		ConventionID INTEGER PRIMARY KEY)
		
	CREATE TABLE #searchConvAndUnit(
		ConventionID INTEGER NOT NULL,
		UnitID INTEGER NOT NULL)

	DECLARE @SQL VARCHAR(1000),
			@SQL_ADDON VARCHAR(10)

	SET @SQL = 'ALTER TABLE #searchConvAndUnit ADD CONSTRAINT PKP_ConvAndUnit'
	
	SET @SQL_ADDON = '0'

	WHILE EXISTS (	SELECT *
					FROM tempdb..sysobjects
					WHERE xtype = 'PK' 
						AND [name] = 'PKP_ConvAndUnit' + @SQL_ADDON)
	BEGIN
		SET @SQL_ADDON = CAST(@SQL_ADDON AS INTEGER) + 1
	END

	SET @SQL = @SQL + @SQL_ADDON + ' PRIMARY KEY (ConventionID, UnitID)'

	EXEC (@SQL)		
	
	IF @iType = 0
		SELECT   
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName =
				CASE 
					WHEN H.IsCompany = 1 THEN H.LastName
				ELSE H.LastName + ', ' + H.FirstName
				END,
			RealCotisation = V.RealCotisation,
			RealFee = V.RealFee,
			RealSum = V.RealCotisation + V.RealFee,
			TheoricCotisation = (V.TheoricCotisation - V.TheoricFee),  
			V.TheoricFee,  
			TheoricSum = V.TheoricCotisation,
			DiffSum = V.RealCotisation + V.RealFee - V.TheoricCotisation,
			Deposit = ISNULL(V.Deposit,0),  
			NbDiffDeposit = ISNULL(ROUND((V.RealCotisation + V.RealFee - V.TheoricCotisation)/V.Deposit,1),0),
			BreakingTypeID = ISNULL(Br.BreakingTypeID, '')   
		FROM dbo.Un_Convention C  
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINConvention (NULL, GETDATE()) RIN ON RIN.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		LEFT JOIN #TB_Rep B ON S.RepID = B.RepID --OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN (  
			SELECT   
				C.ConventionID,   
				RealCotisation = SUM(T.RealCotisation),
				RealFee = SUM(T.RealFee),
				TheoricCotisation = SUM(T.TheoricCotisation),  
				TheoricFee = SUM(T.TheoricFee),  
				Deposit = SUM(T.Deposit),
				InforceDate = MIN(T.InForceDate)
			FROM dbo.Un_Convention C  
			JOIN (  
				SELECT   
					U.ConventionID,  
					RealCotisation = ISNULL(Ct.Cotisation,0),
					RealFee = ISNULL(Ct.Fee,0),
					TheoricCotisation = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Cotisation,0) + ISNULL(Ct.Fee,0)
							WHEN C.PmtTypeID = 'AUT' THEN 
								dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
						ELSE
							dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
						END,
					TheoricFee = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Fee,0)
							WHEN C.PmtTypeID = 'AUT' THEN 
								dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
						ELSE
							dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
						END,
					Deposit = ROUND(U.UnitQty * M.PmtRate,2),						
					U.UnitQty, 
					M.PmtRate, 
					Bi.BenefInsurRate, 
					M.SubscriberInsuranceRate,
					H.HalfSubscriberInsuranceRate, 
					St.StateTaxPct,
					U.InForceDate
				FROM dbo.Un_Convention C  
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				LEFT JOIN Mo_State St ON St.StateID = S.StateID
				LEFT JOIN Un_BenefInsur Bi ON Bi.BenefInsurID = U.BenefInsurID
				LEFT JOIN Un_HalfSubscriberInsurance H ON H.ModalID = M.ModalID
				LEFT JOIN (  
					SELECT   
						U.UnitID,  
						Cotisation = SUM(Ct.Cotisation),  
						Fee = SUM(Ct.Fee)
					FROM dbo.Un_Unit U  
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					WHERE O.OperTypeID <> 'CPA'
						OR OBF.OperID IS NOT NULL
						OR O.OperDate <= GETDATE()
					GROUP BY U.UnitID  
					) Ct ON Ct.UnitID = U.UnitID
				WHERE ISNULL(U.TerminatedDate,0) <= 0
					AND ISNULL(U.IntReimbDate,0) <= 0
					AND dbo.FN_UN_EstimatedNumberOfDeposit(U.InForceDate, @Today, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate) < M.PmtQty					
				) T ON T.ConventionID = C.ConventionID
			GROUP BY C.ConventionID  
			) V ON V.ConventionID = C.ConventionID
		LEFT JOIN (  
			SELECT  
				ConventionID,   
				BreakingTypeID  
			FROM Un_Breaking  
			WHERE @EndDate >= dbo.fn_Mo_DateNoTime(BreakingStartDate)
				AND( @EndDate < dbo.fn_Mo_DateNoTime(BreakingEndDate)
					OR dbo.fn_Mo_DateNoTime(BreakingEndDate) IS NULL
					)  
			) Br ON Br.ConventionID = C.ConventionID
		WHERE (	V.RealCotisation + V.RealFee - V.TheoricCotisation < 0		 		
		 		OR	( V.RealCotisation + V.RealFee - V.TheoricCotisation > 0
						AND @bIncludePositive <> 0 )
					)			 		
			AND ((V.InForceDate >= @dtStartDate AND V.InForceDate <= @dtEndDate) -- Entre les dates demandées
						OR @dtStartDate<=0 
						OR @dtEndDate<=0)
			AND ABS(V.RealCotisation + V.RealFee - V.TheoricCotisation) > 2.00	-- Dont l'écart est plus de 2,00$
			AND (B.RepID IS NOT NULL OR @iRepID = 0)
            AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les convention avec un RIN partiel ou complet
		ORDER BY C.ConventionNo  	  
 	ELSE IF @iType = 1
	BEGIN
		INSERT INTO #searchConv
			SELECT C.ConventionID
			FROM dbo.Un_Convention C
            LEFT JOIN dbo.fntCONV_ObtenirStatutRINConvention (NULL, GETDATE()) RIN ON RIN.ConventionID = C.ConventionID
			WHERE C.PmtTypeID = 'CHQ'
                AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les convention avec un RIN partiel ou complet
		
		SELECT   
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName =
				CASE 
					WHEN H.IsCompany = 1 THEN H.LastName
				ELSE H.LastName + ', ' + H.FirstName
				END,
			RealCotisation = V.RealCotisation,
			RealFee = V.RealFee,
			RealSum = V.RealCotisation + V.RealFee,
			TheoricCotisation = (V.TheoricCotisation - V.TheoricFee),  
			V.TheoricFee,  
			TheoricSum = V.TheoricCotisation,
			DiffSum = V.RealCotisation + V.RealFee - V.TheoricCotisation,
			Deposit = ISNULL(V.Deposit,0),  
			NbDiffDeposit = ISNULL(ROUND((V.RealCotisation + V.RealFee - V.TheoricCotisation)/V.Deposit,1),0),
			BreakingTypeID = ISNULL(Br.BreakingTypeID, '')
		FROM #searchConv SC 
		JOIN dbo.Un_Convention C ON C.ConventionID = SC.ConventionID 
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		LEFT JOIN #TB_Rep B ON S.RepID = B.RepID --OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN (  
			SELECT   
				C.ConventionID,   
				RealCotisation = SUM(T.RealCotisation),
				RealFee = SUM(T.RealFee),
				TheoricCotisation = SUM(T.TheoricCotisation),  
				TheoricFee = SUM(T.TheoricFee),  
				Deposit = SUM(T.Deposit),
				InforceDate = MIN(T.InForceDate)
			FROM #searchConv SC 
			JOIN dbo.Un_Convention C ON C.ConventionID = SC.ConventionID  
			JOIN (  
				SELECT   
					U.ConventionID,  
					RealCotisation = ISNULL(Ct.Cotisation,0),
					RealFee = ISNULL(Ct.Fee,0),
					TheoricCotisation = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Cotisation,0) + ISNULL(Ct.Fee,0)
							ELSE dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
						END,
					TheoricFee = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Fee,0)
							ELSE dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
						END,
					Deposit = ROUND(U.UnitQty * M.PmtRate,2),	
					U.UnitQty, 
					M.PmtRate, 
					Bi.BenefInsurRate, 
					M.SubscriberInsuranceRate,
					H.HalfSubscriberInsuranceRate, 
					St.StateTaxPct,
					U.InForceDate
				FROM #searchConv SC 
				JOIN dbo.Un_Convention C ON C.ConventionID = SC.ConventionID  
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				LEFT JOIN Mo_State St ON St.StateID = S.StateID
				LEFT JOIN Un_BenefInsur Bi ON Bi.BenefInsurID = U.BenefInsurID
				LEFT JOIN Un_HalfSubscriberInsurance H ON H.ModalID = M.ModalID
				LEFT JOIN (  
					SELECT   
						U.UnitID,  
						Cotisation = SUM(Ct.Cotisation),  
						Fee = SUM(Ct.Fee)
					FROM #searchConv SC 
					JOIN dbo.Un_Unit U ON U.ConventionID = SC.ConventionID    
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					WHERE O.OperTypeID <> 'CPA'
						OR OBF.OperID IS NOT NULL
						OR O.OperDate <= GETDATE()
					GROUP BY U.UnitID  
					) Ct ON Ct.UnitID = U.UnitID
				WHERE ISNULL(U.TerminatedDate,0) <= 0
					AND ISNULL(U.IntReimbDate,0) <= 0
					AND dbo.FN_UN_EstimatedNumberOfDeposit(U.InForceDate, @Today, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate) < M.PmtQty
				) T ON T.ConventionID = C.ConventionID
			GROUP BY C.ConventionID  
			) V ON V.ConventionID = C.ConventionID
		LEFT JOIN (  
			SELECT  
				SC.ConventionID,   
				BreakingTypeID
			FROM #searchConv SC 
			JOIN Un_Breaking B ON B.ConventionID = SC.ConventionID 
			WHERE @EndDate >= dbo.fn_Mo_DateNoTime(B.BreakingStartDate)
				AND( @EndDate < dbo.fn_Mo_DateNoTime(B.BreakingEndDate)
					OR dbo.fn_Mo_DateNoTime(B.BreakingEndDate) IS NULL
					)  
			) Br ON Br.ConventionID = C.ConventionID
		WHERE (	V.RealCotisation + V.RealFee - V.TheoricCotisation < 0		 		
		 		OR	( V.RealCotisation + V.RealFee - V.TheoricCotisation > 0
						AND @bIncludePositive <> 0 )
					)
			AND ((V.InForceDate >= @dtStartDate AND V.InForceDate <= @dtEndDate) -- Entre les dates demandées
						OR @dtStartDate<=0 
						OR @dtEndDate<=0)
			AND ABS(V.RealCotisation + V.RealFee - V.TheoricCotisation) > 2.00	-- Dont l'écart est plus de 2,00$
			AND (B.RepID IS NOT NULL OR @iRepID = 0)
		ORDER BY C.ConventionNo

		--DROP TABLE #TB_Rep  
	END
	ELSE IF @iType = 2
	BEGIN
		INSERT INTO #searchConv
			SELECT  
				DISTINCT B.ConventionID  
			FROM Un_Breaking B
            LEFT JOIN dbo.fntCONV_ObtenirStatutRINConvention (NULL, GETDATE()) RIN ON RIN.ConventionID = B.ConventionID
			WHERE @EndDate >= dbo.fn_Mo_DateNoTime(B.BreakingStartDate)
				AND( @EndDate < dbo.fn_Mo_DateNoTime(B.BreakingEndDate)
					OR dbo.fn_Mo_DateNoTime(B.BreakingEndDate) IS NULL)
				AND ISNULL(B.BreakingTypeID,'') = 'SUS'	--En suspenssion	
                AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les convention avec un RIN partiel ou complet
			
		SELECT DISTINCT
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName =
				CASE 
					WHEN H.IsCompany = 1 THEN H.LastName
				ELSE H.LastName + ', ' + H.FirstName
				END,
			RealCotisation = V.RealCotisation,
			RealFee = V.RealFee,
			RealSum = V.RealCotisation + V.RealFee,
			TheoricCotisation = (V.TheoricCotisation - V.TheoricFee),  
			V.TheoricFee,  
			TheoricSum = V.TheoricCotisation,
			DiffSum = V.RealCotisation + V.RealFee - V.TheoricCotisation,
			Deposit = ISNULL(V.Deposit,0),  
			NbDiffDeposit = ISNULL(ROUND((V.RealCotisation + V.RealFee - V.TheoricCotisation)/V.Deposit,1),0),
			BreakingTypeID = 'SUS'   
		FROM #searchConv SC
		JOIN dbo.Un_Convention C ON SC.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		LEFT JOIN #TB_Rep B ON S.RepID = B.RepID --OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN (  
			SELECT   
				C.ConventionID,   
				RealCotisation = SUM(T.RealCotisation),
				RealFee = SUM(T.RealFee),
				TheoricCotisation = SUM(T.TheoricCotisation),  
				TheoricFee = SUM(T.TheoricFee),  
				Deposit = SUM(T.Deposit),
				InforceDate = MIN(T.InForceDate)
			FROM #searchConv SC
			JOIN dbo.Un_Convention C ON SC.ConventionID = C.ConventionID  
			JOIN (  
				SELECT   
					U.ConventionID,  
					RealCotisation = ISNULL(Ct.Cotisation,0),
					RealFee = ISNULL(Ct.Fee,0),
					TheoricCotisation = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Cotisation,0) + ISNULL(Ct.Fee,0)
							WHEN C.PmtTypeID = 'AUT' THEN 
								dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
						ELSE
							dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
						END,
					TheoricFee = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Fee,0)
							WHEN C.PmtTypeID = 'AUT' THEN 
								dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
						ELSE
							dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
						END,
					Deposit = ROUND(U.UnitQty * M.PmtRate,2),	
					U.UnitQty, 
					M.PmtRate, 
					Bi.BenefInsurRate, 
					M.SubscriberInsuranceRate,
					H.HalfSubscriberInsuranceRate, 
					St.StateTaxPct,
					U.InForceDate
				FROM #searchConv SC
				JOIN dbo.Un_Convention C ON SC.ConventionID = C.ConventionID
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				LEFT JOIN Mo_State St ON St.StateID = S.StateID
				LEFT JOIN Un_BenefInsur Bi ON Bi.BenefInsurID = U.BenefInsurID
				LEFT JOIN Un_HalfSubscriberInsurance H ON H.ModalID = M.ModalID
				LEFT JOIN (  
					SELECT   
						U.UnitID,  
						Cotisation = SUM(Ct.Cotisation),  
						Fee = SUM(Ct.Fee)
					FROM #searchConv SC
					JOIN dbo.Un_Unit U ON SC.ConventionID = U.ConventionID
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					WHERE O.OperTypeID <> 'CPA'
						OR OBF.OperID IS NOT NULL
						OR O.OperDate <= GETDATE()
					GROUP BY U.UnitID  
					) Ct ON Ct.UnitID = U.UnitID
				WHERE ISNULL(U.TerminatedDate,0) <= 0
					AND ISNULL(U.IntReimbDate,0) <= 0
					AND dbo.FN_UN_EstimatedNumberOfDeposit(U.InForceDate, @Today, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate) < M.PmtQty					
				) T ON T.ConventionID = C.ConventionID
			GROUP BY C.ConventionID  
			) V ON V.ConventionID = C.ConventionID		
		WHERE (	V.RealCotisation + V.RealFee - V.TheoricCotisation < 0		 		
		 		OR	( V.RealCotisation + V.RealFee - V.TheoricCotisation > 0
						AND @bIncludePositive <> 0 )
					)		
			AND ((V.InForceDate >= @dtStartDate AND V.InForceDate <= @dtEndDate) -- Entre les dates demandées
						OR @dtStartDate<=0 
						OR @dtEndDate<=0)
			AND ABS(V.RealCotisation + V.RealFee - V.TheoricCotisation) > 2.00	-- Dont l'écart est plus de 2,00$
			AND (B.RepID IS NOT NULL OR @iRepID = 0)
		ORDER BY C.ConventionNo  
	END
	ELSE IF @iType = 3
	BEGIN
		INSERT INTO #searchConv
			SELECT  
				DISTINCT B.ConventionID  
			FROM Un_Breaking B
            LEFT JOIN dbo.fntCONV_ObtenirStatutRINConvention (NULL, GETDATE()) RIN ON RIN.ConventionID = B.ConventionID
			WHERE @EndDate >= dbo.fn_Mo_DateNoTime(B.BreakingStartDate)
				AND( @EndDate < dbo.fn_Mo_DateNoTime(B.BreakingEndDate)
					OR dbo.fn_Mo_DateNoTime(B.BreakingEndDate) IS NULL)
				AND ISNULL(B.BreakingTypeID,'') = 'STP'	--En arrete de paiement
                AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les convention avec un RIN partiel ou complet

		SELECT DISTINCT
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName =
				CASE 
					WHEN H.IsCompany = 1 THEN H.LastName
				ELSE H.LastName + ', ' + H.FirstName
				END,
			RealCotisation = V.RealCotisation,
			RealFee = V.RealFee,
			RealSum = V.RealCotisation + V.RealFee,
			TheoricCotisation = (V.TheoricCotisation - V.TheoricFee),  
			V.TheoricFee,  
			TheoricSum = V.TheoricCotisation,
			DiffSum = V.RealCotisation + V.RealFee - V.TheoricCotisation,
			Deposit = ISNULL(V.Deposit,0),  
			NbDiffDeposit = ISNULL(ROUND((V.RealCotisation + V.RealFee - V.TheoricCotisation)/V.Deposit,1),0),
			BreakingTypeID = 'STP'  
		FROM #searchConv SC
		JOIN dbo.Un_Convention C ON SC.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		LEFT JOIN #TB_Rep B ON S.RepID = B.RepID --OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN (  
			SELECT   
				C.ConventionID,   
				RealCotisation = SUM(T.RealCotisation),
				RealFee = SUM(T.RealFee),
				TheoricCotisation = SUM(T.TheoricCotisation),  
				TheoricFee = SUM(T.TheoricFee),  
				Deposit = SUM(T.Deposit),
				InforceDate = MIN(T.InForceDate)
			FROM #searchConv SC
			JOIN dbo.Un_Convention C ON SC.ConventionID = C.ConventionID  
			JOIN (  
				SELECT   
					U.ConventionID,  
					RealCotisation = ISNULL(Ct.Cotisation,0),
					RealFee = ISNULL(Ct.Fee,0),
					TheoricCotisation = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Cotisation,0) + ISNULL(Ct.Fee,0)
							WHEN C.PmtTypeID = 'AUT' THEN 
								dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
						ELSE
							dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
						END,
					TheoricFee = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Fee,0)
							WHEN C.PmtTypeID = 'AUT' THEN 
								dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
						ELSE
							dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
						END,
					Deposit = ROUND(U.UnitQty * M.PmtRate,2),	
					U.UnitQty, 
					M.PmtRate, 
					Bi.BenefInsurRate, 
					M.SubscriberInsuranceRate,
					H.HalfSubscriberInsuranceRate, 
					St.StateTaxPct,
					U.InForceDate
				FROM #searchConv SC
				JOIN dbo.Un_Convention C ON SC.ConventionID = C.ConventionID
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				LEFT JOIN Mo_State St ON St.StateID = S.StateID
				LEFT JOIN Un_BenefInsur Bi ON Bi.BenefInsurID = U.BenefInsurID
				LEFT JOIN Un_HalfSubscriberInsurance H ON H.ModalID = M.ModalID
				LEFT JOIN (  
					SELECT   
						U.UnitID,  
						Cotisation = SUM(Ct.Cotisation),  
						Fee = SUM(Ct.Fee)
					FROM #searchConv SC
					JOIN dbo.Un_Unit U ON SC.ConventionID = U.ConventionID
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					WHERE O.OperTypeID <> 'CPA'
						OR OBF.OperID IS NOT NULL
						OR O.OperDate <= GETDATE()
					GROUP BY U.UnitID  
					) Ct ON Ct.UnitID = U.UnitID
				WHERE ISNULL(U.TerminatedDate,0) <= 0
					AND ISNULL(U.IntReimbDate,0) <= 0
					AND dbo.FN_UN_EstimatedNumberOfDeposit(U.InForceDate, @Today, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate) < M.PmtQty					
				) T ON T.ConventionID = C.ConventionID
			GROUP BY C.ConventionID  
			) V ON V.ConventionID = C.ConventionID		
		WHERE (	V.RealCotisation + V.RealFee - V.TheoricCotisation < 0		 		
		 		OR	( V.RealCotisation + V.RealFee - V.TheoricCotisation > 0
						AND @bIncludePositive <> 0 )
					)		
			AND ((V.InForceDate >= @dtStartDate AND V.InForceDate <= @dtEndDate) -- Entre les dates demandées
						OR @dtStartDate<=0 
						OR @dtEndDate<=0)
			AND ABS(V.RealCotisation + V.RealFee - V.TheoricCotisation) > 2.00	-- Dont l'écart est plus de 2,00$
			AND (B.RepID IS NOT NULL OR @iRepID = 0)
		ORDER BY C.ConventionNo  
	END
	ELSE IF @iType = 4
	BEGIN
		INSERT INTO #searchConv
			SELECT 
				C.ConventionID  
			FROM dbo.Un_Convention C			
			LEFT JOIN (	SELECT 	ConventionID,
						BreakingTypeID
					FROM Un_Breaking
					WHERE @EndDate >= dbo.fn_Mo_DateNoTime(BreakingStartDate)
						AND( @EndDate < dbo.fn_Mo_DateNoTime(BreakingEndDate)
							OR dbo.fn_Mo_DateNoTime(BreakingEndDate) IS NULL)
					) Br ON Br.ConventionID = C.ConventionID			
            LEFT JOIN dbo.fntCONV_ObtenirStatutRINConvention (NULL, GETDATE()) RIN ON RIN.ConventionID = C.ConventionID
			WHERE ISNULL(BreakingTypeID,'') = ''	--4 Conventions actives ne payant pas par chèque seulment (sans écart d'un cent)
				AND C.PmtTypeID <> 'CHQ'							
                AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les convention avec un RIN partiel ou complet

		SELECT   
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName =
				CASE 
					WHEN H.IsCompany = 1 THEN H.LastName
				ELSE H.LastName + ', ' + H.FirstName
				END,
			RealCotisation = V.RealCotisation,
			RealFee = V.RealFee,
			RealSum = V.RealCotisation + V.RealFee,
			TheoricCotisation = (V.TheoricCotisation - V.TheoricFee),  
			V.TheoricFee,  
			TheoricSum = V.TheoricCotisation,
			DiffSum = V.RealCotisation + V.RealFee - V.TheoricCotisation,
			Deposit = ISNULL(V.Deposit,0),  
			NbDiffDeposit = ISNULL(ROUND((V.RealCotisation + V.RealFee - V.TheoricCotisation)/V.Deposit,1),0),
			BreakingTypeID = ''   
		FROM #searchConv SC
		JOIN dbo.Un_Convention C ON C.ConventionID = SC.ConventionID 
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		LEFT JOIN #TB_Rep B ON S.RepID = B.RepID --OR @iRepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN (  
				SELECT   
					C.ConventionID,   
					RealCotisation = SUM(T.RealCotisation),
					RealFee = SUM(T.RealFee),
					TheoricCotisation = SUM(T.TheoricCotisation),  
					TheoricFee = SUM(T.TheoricFee),  
					Deposit = SUM(T.Deposit),
					InforceDate = MIN(T.InForceDate)
				FROM #searchConv SC
				JOIN dbo.Un_Convention C ON C.ConventionID = SC.ConventionID 
				JOIN (  
					SELECT   
						U.ConventionID,  
						RealCotisation = ISNULL(Ct.Cotisation,0),
						RealFee = ISNULL(Ct.Fee,0),
						TheoricCotisation = 
							CASE 
								WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Cotisation,0) + ISNULL(Ct.Fee,0)
								WHEN C.PmtTypeID = 'AUT' THEN 
									dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
							ELSE
								dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
							END,
						TheoricFee = 
							CASE 
								WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Fee,0)
								WHEN C.PmtTypeID = 'AUT' THEN 
									dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
							ELSE
								dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
							END,
						Deposit = ROUND(U.UnitQty * M.PmtRate,2),	
						U.UnitQty, 
						M.PmtRate, 
						Bi.BenefInsurRate, 
						M.SubscriberInsuranceRate,
						H.HalfSubscriberInsuranceRate, 
						St.StateTaxPct,
						U.InForceDate
					FROM #searchConv SC
					JOIN dbo.Un_Convention C ON C.ConventionID = SC.ConventionID 
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
					JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
					JOIN Un_Modal M ON M.ModalID = U.ModalID
					LEFT JOIN Mo_State St ON St.StateID = S.StateID
					LEFT JOIN Un_BenefInsur Bi ON Bi.BenefInsurID = U.BenefInsurID
					LEFT JOIN Un_HalfSubscriberInsurance H ON H.ModalID = M.ModalID
					LEFT JOIN (  
						SELECT   
							U.UnitID,  
							Cotisation = SUM(Ct.Cotisation),  
							Fee = SUM(Ct.Fee)
						FROM #searchConv SC
						JOIN dbo.Un_Unit U ON U.ConventionID = SC.ConventionID
						JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
						WHERE O.OperTypeID <> 'CPA'
							OR OBF.OperID IS NOT NULL
							OR O.OperDate <= GETDATE()
						GROUP BY U.UnitID  
						) Ct ON Ct.UnitID = U.UnitID
					WHERE ISNULL(U.TerminatedDate,0) <= 0
						AND ISNULL(U.IntReimbDate,0) <= 0
						AND dbo.FN_UN_EstimatedNumberOfDeposit(U.InForceDate, @Today, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate) < M.PmtQty					
					) T ON T.ConventionID = C.ConventionID
				GROUP BY C.ConventionID  
				) V ON V.ConventionID = C.ConventionID
		WHERE (	V.RealCotisation + V.RealFee - V.TheoricCotisation < 0		 		
		 		OR	( V.RealCotisation + V.RealFee - V.TheoricCotisation > 0
						AND @bIncludePositive <> 0 )
					)
				AND ((V.InForceDate >= @dtStartDate AND V.InForceDate <= @dtEndDate) -- Entre les dates demandées
						OR @dtStartDate<=0 
						OR @dtEndDate<=0)
				AND ABS(V.RealCotisation + V.RealFee - V.TheoricCotisation) > 2.00	-- Dont l'écart est plus de 2,00$
				AND (B.RepID IS NOT NULL OR @iRepID = 0)
		ORDER BY C.ConventionNo  
	END
	ELSE IF @iType = 5
	BEGIN
		SELECT   
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName =
				CASE 
					WHEN H.IsCompany = 1 THEN H.LastName
				ELSE H.LastName + ', ' + H.FirstName
				END,
			RealCotisation = V.RealCotisation,
			RealFee = V.RealFee,
			RealSum = V.RealCotisation + V.RealFee,
			TheoricCotisation = (V.TheoricCotisation - V.TheoricFee),  
			V.TheoricFee,  
			TheoricSum = V.TheoricCotisation,
			DiffSum = V.RealCotisation + V.RealFee - V.TheoricCotisation,
			Deposit = ISNULL(V.Deposit,0),  
			NbDiffDeposit = ISNULL(ROUND((V.RealCotisation + V.RealFee - V.TheoricCotisation)/V.Deposit,1),0),
			BreakingTypeID = ISNULL(Br.BreakingTypeID, '')   
		FROM dbo.Un_Convention C  
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINConvention (NULL, GETDATE()) RIN ON RIN.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		LEFT JOIN #TB_Rep B ON S.RepID = B.RepID --OR @iRepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN (  
			SELECT   
				C.ConventionID,   
				RealCotisation = SUM(T.RealCotisation),
				RealFee = SUM(T.RealFee),
				TheoricCotisation = SUM(T.TheoricCotisation),  
				TheoricFee = SUM(T.TheoricFee),  
				Deposit = SUM(T.Deposit),
				InforceDate = MIN(T.InForceDate)
			FROM dbo.Un_Convention C  
            JOIN (  
				SELECT   
					U.ConventionID,  
					RealCotisation = ISNULL(Ct.Cotisation,0),
					RealFee = ISNULL(Ct.Fee,0),
					TheoricCotisation = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Cotisation,0) + ISNULL(Ct.Fee,0)
							WHEN C.PmtTypeID = 'AUT' THEN 
								dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
						ELSE
							dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate)
						END,
					TheoricFee = 
						CASE 
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.Fee,0)
							WHEN C.PmtTypeID = 'AUT' THEN 
								dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, DATEADD(DAY, @OpenDays, @Today), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
						ELSE
							dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, @Today, DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate), U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit)
						END,
					Deposit = ROUND(U.UnitQty * M.PmtRate,2),	
					U.UnitQty, 
					M.PmtRate, 
					Bi.BenefInsurRate, 
					M.SubscriberInsuranceRate,
					H.HalfSubscriberInsuranceRate, 
					St.StateTaxPct,
					U.InForceDate
				FROM dbo.Un_Convention C  
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				LEFT JOIN Mo_State St ON St.StateID = S.StateID
				LEFT JOIN Un_BenefInsur Bi ON Bi.BenefInsurID = U.BenefInsurID
				LEFT JOIN Un_HalfSubscriberInsurance H ON H.ModalID = M.ModalID
				LEFT JOIN (  
					SELECT   
						U.UnitID,  
						Cotisation = SUM(Ct.Cotisation),  
						Fee = SUM(Ct.Fee)
					FROM dbo.Un_Unit U  
					JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
					WHERE O.OperTypeID <> 'CPA'
						OR OBF.OperID IS NOT NULL
						OR O.OperDate <= GETDATE()
					GROUP BY U.UnitID  
					) Ct ON Ct.UnitID = U.UnitID
				WHERE ISNULL(U.TerminatedDate,0) <= 0
					AND ISNULL(U.IntReimbDate,0) <= 0
					AND dbo.FN_UN_EstimatedNumberOfDeposit(U.InForceDate, @Today, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate) < M.PmtQty					
				) T ON T.ConventionID = C.ConventionID
			GROUP BY C.ConventionID  
			--HAVING ABS(SUM(T.RealCotisation) + SUM(T.RealFee) - SUM(T.TheoricCotisation)) = 0.01
			) V ON V.ConventionID = C.ConventionID
		LEFT JOIN (  
			SELECT  
				ConventionID,   
				BreakingTypeID  
			FROM Un_Breaking  
			WHERE @EndDate >= dbo.fn_Mo_DateNoTime(BreakingStartDate)
				AND( @EndDate < dbo.fn_Mo_DateNoTime(BreakingEndDate)
					OR dbo.fn_Mo_DateNoTime(BreakingEndDate) IS NULL
					)  
			) Br ON Br.ConventionID = C.ConventionID
		WHERE (	V.RealCotisation + V.RealFee - V.TheoricCotisation < 0		 		
		 		OR	( V.RealCotisation + V.RealFee - V.TheoricCotisation > 0
						AND @bIncludePositive <> 0 )
					)
			AND ABS(V.RealCotisation + V.RealFee - V.TheoricCotisation) <= 2.00 --Plus petit ou égale à 2,00$
			AND ((V.InForceDate >= @dtStartDate AND V.InForceDate <= @dtEndDate) -- Entre les dates demandées
						OR @dtStartDate<=0 
						OR @dtEndDate<=0)
			AND (B.RepID IS NOT NULL OR @iRepID = 0)
            AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les convention avec un RIN partiel ou complet
		ORDER BY C.ConventionNo  
	END
	ELSE  	--6 Conventions terminées
	BEGIN
		INSERT INTO #searchConvAndUnit
			SELECT DISTINCT
				U.ConventionID,
				U.UnitID
			FROM dbo.Un_Unit U
            LEFT JOIN dbo.fntCONV_ObtenirStatutRINConvention (NULL, GETDATE()) RIN ON RIN.ConventionID = U.ConventionID
			WHERE U.TerminatedDate > 0
		        AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les convention avec un RIN partiel ou complet

		SELECT   
			ConventionID = C.ConventionID,  
			C.ConventionNo,  
			SubscriberID = C.SubscriberID,  
			SubscriberName =
				CASE 
					WHEN H.IsCompany = 1 THEN H.LastName
				ELSE H.LastName + ', ' + H.FirstName
				END,
			RealCotisation = SUM(Ct.Cotisation),  
			RealFee = SUM(Ct.Fee), 
			RealSum = SUM(Ct.Cotisation) + SUM(Ct.Fee),
			TheoricCotisation = 0,  
			TheoricFee = 0,  
			TheoricSum = 0,
			DiffSum = SUM(Ct.Cotisation) + SUM(Ct.Fee),
			Deposit = 0,  
			NbDiffDeposit = 0,
			BreakingTypeID = ''
		FROM #searchConvAndUnit SCU
		JOIN dbo.Un_Convention C ON C.ConventionID = SCU.ConventionID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		LEFT JOIN #TB_Rep B ON S.RepID = B.RepID --OR @iRepID = 0
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		--JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = SCU.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
		WHERE ( O.OperTypeID <> 'CPA'
				OR OBF.OperID > 0
				OR O.OperDate <= GETDATE()
				)  
			AND (B.RepID IS NOT NULL OR @iRepID = 0)
		GROUP BY 
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			H.LastName,
			H.FirstName,
			H.IsCompany
		HAVING (SUM(Ct.Cotisation) + SUM(Ct.Fee) < 0)
				OR ( SUM(Ct.Cotisation) + SUM(Ct.Fee) > 0
						AND @bIncludePositive <> 0)
	END

	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
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
				1,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Recherche de convention avec écart entre le '+ CAST(@dtStartDate AS VARCHAR) + ' et le ' + CAST(@dtEndDate AS VARCHAR)+
					' selon le type : '+ CAST(@iType AS VARCHAR) + CASE
												WHEN @bIncludePositive = 0 THEN ' en excluant les écart positifs'
												ELSE ' en incluant les écarts positifs'
											END,
				'SL_UN_SearchConventionWithVariance',
				'EXECUTE SL_UN_SearchConventionWithVariance @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
					', @iType ='+CAST(@iType AS VARCHAR)+
					', @dtStartDate ='+CAST(@dtStartDate AS VARCHAR)+	
					', @dtEndDate ='+CAST(@dtEndDate AS VARCHAR)+	
					', @iRepID ='+CAST(@iRepID AS VARCHAR)
	END	
	
	-- FIN DES TRAITEMENTS 
	RETURN 0
END