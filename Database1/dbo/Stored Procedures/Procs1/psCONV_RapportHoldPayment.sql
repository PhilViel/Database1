/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	psCONV_RapportHoldPayment (basé sur SL_UN_SearchConventionHoldPayment)
Description         :	Recherche des conventions qui sont en arrêt de paiements pendant une journée de la 
								période.
								
Paramètres			@arretDansInterval : indique qu'on veut voir seulement ceux qui ont débuté dans la plage
					@historique :	indique qu'on veut voir, en plus, les arrêts qui ont eu lieu et terminé avant la plage, pour les convention avec arrêt dans l'intervale
								
Valeurs de retours  :	Dataset :
									ConventionID		INTEGER		ID de la convention.
									ConventionNo		VARCHAR(75)	Numéro de convention.
									SubscriberID		INTEGER		ID du souscripteur.
									SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
									BreakingStartDate DATETIME		Date de début de l'arrêt de paiement  
									BreakingEndDate	DATETIME		Date de fin de l'arrêt de paiement
									BreakingReason		VARCHAR(75)	Raison de l'arrêt
									Cotisation 			MONEY			Solde réel des épargnes
									RealAmount			MONEY			Solde réel des épargnes et des frais 
									EstimatedAmount 	MONEY			Montant théorique d'épargnes et de frais 
Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe			Création
						ADX0001185	IA	2006-11-30	Bruno Lapointe			Optimisation
										2013-07-31  Maxime Martel			ajout de l'option "tous" et de l'option
																			qui affiche l'historique d'arrêt de paiement 
																			et l'option qui permet de lister les arrêts de 
																			paiement qui ont commencés entre les dates
										2013-11-21	Donald Huppé			correction de l'utilisation de  @arretDansInterval et @historique
																					
								exec psCONV_RapportHoldPayment '2013-08-06', '2013-10-01', 149478, 2, 1, 1
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportHoldPayment] (	
	@StartDate DATETIME,  -- Date de début de la période
	@EndDate DATETIME, -- Date de fin de la période
	@RepID INTEGER = 0, -- Limiter les résultats selon un représentant, 0 pour tous
	@UserID integer,
	@arretDansInterval bit = 0,
	@historique bit = 0 ) 
AS
BEGIN
	
	-- Création d'une table temporaire
	CREATE TABLE #tB_Rep (
		RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	declare @rep bit = 0
			
	select @rep = count(distinct repid) from Un_Rep where RepID = @UserID 

	if @rep = 1
	begin
		INSERT #TB_Rep
			EXEC SL_UN_BossOfRep @userID
		end
	else
	begin
		INSERT #TB_Rep
			select RepID from Un_Rep
	end

	if @RepID <> 0
	begin
		delete #TB_Rep where RepID <> @RepID
	end

	CREATE TABLE #tConvBreaking (
		ConventionID INTEGER PRIMARY KEY,
		EstimatedAmount MONEY NOT NULL )

	-- Retrouve les montants théoriques (estimés) par convention
	INSERT INTO #tConvBreaking
		SELECT 
			U.ConventionID,  
			EstimatedAmount = SUM(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, GETDATE(), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate))  
		FROM dbo.Un_Convention C  
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Breaking B ON B.ConventionID = C.ConventionID
		WHERE
		(	( B.BreakingStartDate < @StartDate
					AND ISNULL(B.BreakingEndDate, @StartDate) >= @StartDate
					)
				OR ( B.BreakingStartDate >= @StartDate
					AND B.BreakingStartDate <= @EndDate
					)
				)
			AND ISNULL(U.TerminatedDate, 0) < 1
			AND ISNULL(U.IntReimbDate,0) < 1
		GROUP BY U.ConventionID

	-- Retourne les conventions qui sont en arrêt de paiement pendant une journée de la période 
	SELECT
		estRep = @rep,
		representant = rh.LastName + ', ' + rh.FirstName + ' (' + rep.RepCode + ')',
		C.ConventionID,  
		C.ConventionNo,  
		C.SubscriberID,  
		SubscriberName = 
			CASE 
				WHEN H.IsCompany = 1 THEN H.LastName
			ELSE H.LastName + ', ' + H.FirstName
			END,
		BreakingStartDate = dbo.fn_Mo_DateNoTime(B.BreakingStartDate),  
		BreakingEndDate = dbo.fn_Mo_DateNoTime(B.BreakingEndDate),  
		B.BreakingReason,  
		Cotisation = ISNULL(SUM(Ct.Cotisation),0),  
		RealAmount = ISNULL(SUM(Ct.Cotisation + Ct.Fee),0),  
		T.EstimatedAmount,
		A.Phone1 
	FROM #tConvBreaking T
	JOIN dbo.Un_Convention C ON C.ConventionID = T.ConventionID
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN #TB_Rep R ON S.RepID = R.RepID
	JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
	JOIN dbo.Mo_Adr A on h.AdrID = A.AdrID 
	JOIN Un_Breaking B ON B.ConventionID = C.ConventionID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN un_rep Rep on s.RepID = rep.RepID
	JOIN dbo.mo_human rh on rep.RepID = rh.HumanID 
	LEFT JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID

	WHERE	
		(
			ISNULL(U.TerminatedDate,'3000-01-01') > @EndDate
			AND ISNULL(U.IntReimbDate,'3000-01-01') > @EndDate

		)
		AND 
		(
			(
				@arretDansInterval = 0
				AND (B.BreakingStartDate <= @EndDate 
				AND isnull(B.BreakingEndDate,'3000-01-01') >= @StartDate ) -- il y a une période d'arrêt pendant la plage
			)  

			OR ( 
				@arretDansInterval = 1
				AND B.BreakingStartDate BETWEEN @StartDate AND @EndDate -- Début de l'arrêt dans la plage
			) 
			
			OR (
				@historique = 1
				AND isnull(B.BreakingEndDate,'3000-01-01') <= @StartDate	-- un arrêt a eu lieu avant la plage, 
																			-- pour les conventions qui sont en arrêt pendant la plage (@arretDansInterval = 0) 
																			-- ou qui ont débuté dedans (@arretDansInterval = 1)
				AND B.ConventionID in 
						(	
							select ConventionID
							from Un_Breaking B1
							where 
								(
								@arretDansInterval = 0
								AND B1.BreakingStartDate <= @EndDate and isnull(B1.BreakingEndDate,'3000-01-01') >= @StartDate 
								)
								OR
								(
								@arretDansInterval = 1
								AND B.BreakingStartDate BETWEEN @StartDate AND @EndDate 
								)
						)
						
			)
		)
		
	GROUP BY 
		C.ConventionID, 
		C.ConventionNo, 
		C.SubscriberID, 
		H.LastName, 
		H.FirstName,
		H.IsCompany, 
		B.BreakingStartDate, 
		B.BreakingEndDate, 
		B.BreakingReason, 
		T.EstimatedAmount,
		rh.LastName,
		rh.FirstName,
		rep.RepCode,
		a.Phone1 
	ORDER BY 
		C.ConventionNo  

	DROP TABLE #tB_Rep 
END


