/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SP_RP_UN_ProjectionTotal
Description         :	STORED PROCEDURE DE FUSION EXCEL DES TOTAUX DES PROJECTIONS
Valeurs de retours  :	
				
Note                :		2004-04-14 				Dominic Létourneau	Migration ancienne stored proc selon nouveaux standards
				ADX0001206	IA	2006-12-22	Alain Quirion		Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ProjectionTotal] (
	@ConnectID INTEGER) -- Identifiant unique de la connection
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	DECLARE @FirstDate MoDate
	
	-- Retrouve la date de projection dans la table de configuration
	SELECT @FirstDate = ISNULL(RepProjectionTreatmentDate, GETDATE())
	FROM Un_Def
	
	-- Retourne les bonis et les frais de commission par date de projection 
	SELECT 
		StartDate = ISNULL(V2.StartDate, @FirstDate),
		V1.EndDate,
		V1.PeriodComBonus,
		V1.CommissionFee
	FROM (-- Retrouve la somme des bonis de commission et la somme des frais de commission par date de projection 
			SELECT 
				EndDate = RepProjectionDate,
				PeriodComBonus = SUM(PeriodCommBonus),
				CommissionFee = SUM(PeriodCommBonus + PeriodCoveredAdvance)
			FROM Un_RepProjectionSumary
			GROUP BY RepProjectionDate) V1
	JOIN (-- Retrouve la date de début et de fin de projection 
					SELECT 
						StartDate = MAX(S2.RepProjectionDate) + 1 , 
						EndDate = S1.RepProjectionDate
					FROM Un_RepProjectionSumary S1
					LEFT JOIN Un_RepProjectionSumary S2 
						ON S2.RepProjectionDate < S1.RepProjectionDate
					GROUP BY s1.RepProjectionDate 
				) V2 
		ON V2.EndDate = V1.EndDate
	ORDER BY V1.EndDate

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
				'Rapport des projections de commissions totales',
				'RP_UN_ProjectionTotal',
				'EXECUTE RP_UN_ProjectionTotal @ConnectID ='+CAST(@ConnectID AS VARCHAR)
	END	
END

