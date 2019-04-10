/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 : 	RP_UN_IntReimbSummary
Description         : 	
Valeurs de retours  : 	Dataset de données
Note                :		
				2004-09-01 	Bruno Lapointe		Création	
				2006-12-12	Alain Quirion		Optimisation
*************************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_IntReimbSummary] (	
	@ConnectID INTEGER,
	@StartDate DATETIME, 	-- Date de début de la période
	@EndDate DATETIME) 	-- Date de fin de la période
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SELECT 
		P.PlanID, -- ID unique du plan
		P.PlanDesc, -- Nom du plan
		C.YearQualif, -- Année de qualification de la convention
		UnitQty = SUM(U.UnitQty), -- Nombre d’unités pour lesquelles il y eu un remboursement intégral dans la période
		Fee = -SUM(Ct.Fee), -- Frais remboursés lors de remboursement intégral dans la période 
		Cotisation = -SUM(Ct.Cotisation) -- Épargnes remboursés lors de remboursement intégral dans la période
	FROM Un_Plan P
	JOIN dbo.Un_Convention C ON C.PlanID = P.PlanID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	WHERE (O.OperTypeID = 'RIN')
	  AND (O.OperDate >= @StartDate)
	  AND (O.OperDate < @EndDate+1)
	GROUP BY 
		P.PlanID,
		P.OrderOfPlanInReport,
		P.PlanDesc,
		C.YearQualif
	ORDER BY
		P.OrderOfPlanInReport,
		P.PlanDesc,
		C.YearQualif

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
				'Rapport du sommaire des rembourserments intégrales du '+CAST(@StartDate AS VARCHAR) + ' au ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_IntReimbSummary',
				'EXECUTE RP_UN_IntReimbSummary @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)			
	END	
END


