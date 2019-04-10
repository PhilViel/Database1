/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepProjectionGrandTotal
Description         :	Retourne le grand total d'une projection     
Valeurs de retours  :	
				
Note                :		2003-07-03   				Marc W   		Création
 			 	2003-08-14   				Bruno Lapointe  	Correction (Les retenus n'était pas inclus)
				ADX0001206	IA	2006-12-22	Alain Quirion		Optimisation
*********************************************************************************************************************/
CREATE PROC [dbo].[RP_UN_RepProjectionGrandTotal]( 
	@ConnectID INTEGER,            --ID unique de la connection
  	@RepProjectionDate DATETIME,   --Date de la projection
  	@RepID INTEGER )               --ID unique du représentant ou si 0 de toutes les représentants 
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SELECT
		P.RepProjectionDate,
		TotalFee = SUM(P.TotalFee),
		CoveredAdvance = SUM(P.CoverdAdvance),
		PeriodComm = SUM(P.PeriodComm),
		PeriodBusinessBonus = SUM(P.PeriodBusinessBonus),
		SweepstakeTot = ISNULL(S.AVRAmount,0) + ISNULL(S.AVSAmount,0),
		PaidTotal = SUM(P.PaidAmount) + ISNULL(S.AVRAmount,0) + ISNULL(S.AVSAmount,0),
		ExpensesTotal = SUM(P.CommExpenses)
	FROM Un_RepProjection P
	LEFT JOIN (
			SELECT 
				RepProjectionDate,
				AVRAmount = SUM(AVRAmount),
				AVSAmount = SUM(AVSAmount)
			FROM Un_RepProjectionSumary 
			WHERE RepProjectionDate = @RepProjectionDate 
				AND (@RepID = 0 OR RepID = @RepID)
			GROUP BY RepProjectionDate) S ON S.RepProjectionDate = P.RepProjectionDate 
	WHERE P.RepProjectionDate = @RepProjectionDate
		AND (@RepID = 0 OR P.RepID = @RepID)
	GROUP BY P.RepProjectionDate, S.AVRAmount, S.AVSAmount

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
				'Rapport des projections totales de commissions le ' + CAST(@RepProjectionDate AS VARCHAR),
				'RP_UN_RepProjectionGrandTotal',
				'EXECUTE RP_UN_RepProjectionGrandTotal @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @RepProjectionDate=' +  CAST(@RepProjectionDate AS VARCHAR)+
				', @RepID=' +  CAST(@RepID AS VARCHAR)
	END	
END

