/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepSaleSourceSales
Description         :	Procédure stockée du rapport : Ventes des représentants et agences par source de ventes.
Valeurs de retours  : 	Dataset de données du rapport
Note                :	ADX0000094	IA	2004-09-07	Bruno Lapointe		Création
						ADX0001366	BR	2005-03-28	Bruno Lapointe		Correction du détail pour les ventes de 
																		représentants sans directeurs.
						ADX0001206	IA	2007-01-08	Bruno Lapointe		Optimisation.
										2008-07-31 Patrick Robitaille	Utiliser le champ bReduitTauxConservationRep de la table
																		Un_UnitReductionReason au lieu d'une liste d'IDs
										2008-11-18 Patrick Robitaille	Intégrer le calcul des rétentions sur le nb. d'unités brutes
										2009-01-30	Patrick Robitaille	Correction sur le calcul du brut et du calcul des résiliations d'unités.  
																		Si une partie ou toutes les unités résiliées ont été réutilisées, le nb. 
																		d'unités résiliées est diminué du nb d'unités réutilisées.
										2018-12-02	Donald Huppé		Refaire la section du calcul des unités nettes selon la méthode standard
									
exec RP_UN_RepSaleSourceSales 1, 'REP', '2018-01-01', '2018-12-02', 'REP', 476221
exec RP_UN_RepSaleSourceSales 1, 'TOT', '2018-01-01', '2018-12-02', 'ALL', 476221
exec RP_UN_RepSaleSourceSales 1, 'AGY', '2018-01-01', '2018-12-02', 'ALL', 476221

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepSaleSourceSales] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@DataOrder CHAR(3), -- Résultat désiré : 'TOT': total, 'REP': par représentant, 'A;GY': par agence
	@StartDate DATETIME, -- Début de la période
	@EndDate DATETIME, -- Fin de la période
	@Type VARCHAR(3), -- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
	@RepID INTEGER) -- ID Unique du Rep
AS
BEGIN
	-- Retourne les unités vendus dans une période par régime et groupé par représentant et agence
	DECLARE 
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()


	create table #GrossANDNetUnits (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT,
		DateUnite DATETIME) 

	-- Les données des Rep
	INSERT #GrossANDNetUnits -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits_DateUnite --NULL, @StartDate, @EndDate, 0, 1
		@ReptreatmentID = NULL,
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1, -- On veut les résultats groupés par unitID.  Sinon, c'est groupé par RepID et BossID
		@QteMoisRecrue = 12,
		@incluConvT = 1


	CREATE TABLE #UnitsDetail (
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY,
		RepID INTEGER,
		SaleSourceID INTEGER,
		BossID INTEGER)

	-- Détail des unités
	INSERT INTO #UnitsDetail
		SELECT
			G.UnitID,
			UnitQty = SUM(Brut - (Retraits - Reinscriptions)),
			G.RepID,
			U.SaleSourceID,
			G.BossID
		FROM #GrossANDNetUnits G
		JOIN Un_Unit U on u.UnitID = G.UnitID
		GROUP BY
			G.UnitID,
			G.RepID,
			U.SaleSourceID,
			G.BossID
		HAVING SUM(Brut - (Retraits - Reinscriptions)) <> 0

	IF @DataOrder = 'AGY'
		-- Sélection finale par agence
		SELECT
			U.UnitQty,
			UnitPct =
				CASE
					WHEN U2.UnitQtyTotal <> 0 THEN U.UnitQty/U2.UnitQtyTotal*100
				ELSE 0
				END,
			BossID = ISNULL(U.BossID,0),
			AgencyName = 
				CASE 
					WHEN U.BossID IS NULL THEN 'Aucune'
				ELSE ISNULL(A.FirstName,'') + ' '+ ISNULL(A.LastName,'')
				END,
			SaleSourceDesc = ISNULL(SS.SaleSourceDesc,'Aucun'),
			SS.SaleSourceID
		FROM (
			SELECT 
				SaleSourceID, 
				BossID, 
				UnitQty = SUM(UnitQty)
			FROM #UnitsDetail
			GROUP BY 
				BossID, 
				SaleSourceID) U
		JOIN (
			SELECT 
				BossID, 
				UnitQtyTotal = SUM(UnitQty)
			FROM #UnitsDetail
			GROUP BY BossID) U2 ON U2.BossID = U.BossID OR (U2.BossID IS NULL AND U.BossID IS NULL)
		LEFT JOIN dbo.Mo_Human A ON A.HumanID = U.BossID
		LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		WHERE (U.BossID = @RepID AND @Type = 'DIR') -- Filtre
			OR (@Type = 'ALL') -- Filtre
		ORDER BY
			A.LastName,
			A.FirstName,
			U.BossID,
			UnitQty DESC,
			SS.SaleSourceDesc,
			SS.SaleSourceID
	ELSE IF @DataOrder = 'REP'
		-- Sélection finale par représentant
		SELECT
			UnitQty = U.UnitQty,
			UnitQtyTotal,
			UnitPct =
				CASE
					WHEN U2.UnitQtyTotal <> 0 THEN U.UnitQty / U2.UnitQtyTotal * 100
				ELSE 0
				END,
			R.RepCode,
			U.RepID,
			BossID = ISNULL(U.BossID,0),
			RepName = H.FirstName + ' '+ H.LastName,
			AgencyName = 
				CASE 
					WHEN U.BossID IS NULL THEN 'Aucune'
				ELSE ISNULL(A.FirstName,'') + ' '+ ISNULL(A.LastName,'')
				END,
			SaleSourceDesc = ISNULL(SS.SaleSourceDesc, 'Aucun'),
			SS.SaleSourceID,
			RepStatus =
				CASE
					WHEN (R.BusinessEnd <= GetDate()) THEN 'Inactif'
				ELSE 'Actif'
				END
		FROM (
			SELECT 
				SaleSourceID, 
				RepID, 
				BossID, 
				UnitQty = SUM(UnitQty)
			FROM #UnitsDetail
			GROUP BY 
				RepID, 
				BossID, 
				SaleSourceID
			) U
		JOIN (
			SELECT 
				RepID, 
				BossID, 
				UnitQtyTotal = SUM(UnitQty)
			FROM #UnitsDetail
			GROUP BY 
				RepID, 
				BossID) U2 ON U2.RepID = U.RepID AND (U2.BossID = U.BossID OR (U2.BossID IS NULL AND U.BossID IS NULL))
		JOIN Un_Rep R ON R.RepID = U.RepID
		JOIN dbo.Mo_Human H ON H.HumanID = U.RepID
		LEFT JOIN dbo.Mo_Human A ON A.HumanID = U.BossID
		LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		WHERE (U.RepID = @RepID AND @Type = 'REP') -- Filtre
			OR (U.BossID = @RepID AND @Type = 'DIR') -- Filtre
			OR (@Type = 'ALL') -- Filtre
		ORDER BY
			A.LastName,
			A.FirstName,
			U.BossID,
			RepStatus,
			H.LastName,
			H.FirstName,
			U.RepID,
			UnitQty DESC,
			SS.SaleSourceDesc,
			SS.SaleSourceID
	ELSE IF @DataOrder = 'TOT'
	BEGIN
		-- Sélection finale des totaux
		DECLARE 
			@TotalUnitQty DECIMAL(10,4)

		SELECT
			@TotalUnitQty = SUM(U.UnitQty)
		FROM #UnitsDetail U
		WHERE (U.RepID = @RepID AND @Type = 'REP') -- Filtre
			OR (U.BossID = @RepID AND @Type = 'DIR') -- Filtre
			OR (@Type = 'ALL') -- Filtre
		
		SELECT
			UnitQty = SUM(D.UnitQty),
			UnitPct =
				CASE
					WHEN @TotalUnitQty <> 0 THEN SUM(D.UnitQty)/@TotalUnitQty * 100
				ELSE 0
				END,
			SaleSourceDesc = ISNULL(SS.SaleSourceDesc,'Aucun'),
			SS.SaleSourceID
		FROM dbo.Un_Unit U
		JOIN #UnitsDetail D ON D.UnitID = U.UnitID
		LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		WHERE (D.RepID = @RepID AND @Type = 'REP') -- Filtre
			OR (D.BossID = @RepID AND @Type = 'DIR') -- Filtre
			OR (@Type = 'ALL') -- Filtre
		GROUP BY
			SS.SaleSourceDesc,
			SS.SaleSourceID
		ORDER BY
			UnitQty DESC,
			SS.SaleSourceDesc,
			SS.SaleSourceID
	END

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
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
				DATEDIFF(MILLISECOND, @dtBegin, @dtEnd)/1000,
				@dtBegin,
				@dtEnd,
				'Ventes des représentants et agences par source de ventes',
				'RP_UN_RepSaleSourceSales',
				'EXECUTE RP_UN_RepSaleSourceSales @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @DataOrder = '+@DataOrder+
					', @StartDate = '+CONVERT(VARCHAR(15), @StartDate, 103)+
					', @EndDate = '+CONVERT(VARCHAR(15), @EndDate, 103)+
					', @Type = '+@Type+
					', @RepID = '+CAST(@RepID AS VARCHAR)

END

/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_RepSaleSourceSales] 
	@ConnectID = 1, -- ID de connexion de l'usager
	@DataOrder = 'REP', -- Résultat désiré : 'TOT': total, 'REP': par représentant, 'AGY': par agence
	@StartDate = '2008-05-01', -- Début de la période
	@EndDate = '2008-05-31', -- Fin de la période
	@Type = 'REP', -- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
	@RepID = 149653 -- ID unique du représentant, 0 pour tous, 149653 pour Claude Cossette
*/


