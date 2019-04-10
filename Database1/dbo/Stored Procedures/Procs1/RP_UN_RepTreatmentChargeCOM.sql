/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepTreatmentChargeCOM
Description         :	Procédure stockée du rapport : Rapport des commissions détaillés (Ajustements)
Valeurs de retours  :	Dataset
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepTreatmentChargeCOM] (
	@ConnectID INTEGER,
	@RepID INTEGER,
	@RepTreatmentID INTEGER)
AS 
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SELECT 
		C.RepID,
		CT.RepChargeTypeID,
		CT.RepChargeTypeDesc,
		RepChargeAmount = SUM(C.RepChargeAmount)
	FROM Un_RepCharge C
	JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID
	WHERE C.RepTreatmentID = @RepTreatmentID
		AND( @RepID = 0 
			OR @RepID = C.RepID
			)
		AND CT.RepChargeTypeComm <> 0
	GROUP BY 
		C.RepID, 
		CT.RepChargeTypeID, 
		CT.RepChargeTypeDesc 
	ORDER BY 
		C.RepID 

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
				'Rapport des commissions détaillés (Ajustements)',
				'RP_UN_RepTreatmentChargeCOM',
				'EXECUTE RP_UN_RepTreatmentChargeCOM @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepTreatmentID = '+CAST(@RepTreatmentID AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END

