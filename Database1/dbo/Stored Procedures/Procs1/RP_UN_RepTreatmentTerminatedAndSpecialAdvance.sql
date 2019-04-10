/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepTreatmentTerminatedAndSpecialAdvance
Description         :	Procédure stockée du rapport : Rapport des commissions (Avance sur résiliation et avances couvertes)
Valeurs de retours  :	Dataset
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
					2008-01-25	Pierre-Luc Simard	Condition remplacée par un COALESCE
					2017-01-12	Donald Huppé		Retirer le insert dans Un_Trace
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepTreatmentTerminatedAndSpecialAdvance] (
	@ConnectID INTEGER,
	@RepID INTEGER,
	@RepTreatmentID INTEGER)
AS
BEGIN
	DECLARE
		@RepTreatmentDate DATETIME,
		@LastRepTreatmentDate DATETIME,
		@SpecialAdvanceDate DATETIME,
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	IF @RepID = 0 	
		SET @RepID = NULL

	SELECT 
		@RepTreatmentDate = RepTreatmentDate
	FROM Un_Reptreatment
	WHERE RepTreatmentID = @RepTreatmentID

	SELECT 
		@LastRepTreatmentDate = MAX(RepTreatmentDate)
	FROM Un_Reptreatment
	WHERE RepTreatmentID < @RepTreatmentID

	SELECT 
		CASE 
			WHEN S.RepTreatmentDate = @RepTreatmentDate THEN ISNULL(SA.Amount,0) 
		ELSE 0
		END AS SpecialAdvance,
		CASE 
			WHEN S.RepTreatmentDate = @RepTreatmentDate THEN ISNULL(AVR.AVRAmount,0) 
		ELSE 0
		END AS TerminatedAdvance, 
		CASE 
			WHEN S.RepTreatmentDate = @RepTreatmentDate THEN ISNULL(S.Advance,0) + ISNULL(SA.Amount,0) + ISNULL(AVR.AVRAmount,0)  
		ELSE 0
		END AS Advances, 
		CASE 
			WHEN S.RepTreatmentDate = @RepTreatmentDate THEN ISNULL(S.Advance,0) + ISNULL(LSA.Amount,0) + ISNULL(LAVR.AVRAmount,0)  
		ELSE 0
		END AS CalcAdvances, 
		CASE 
			WHEN S.RepTreatmentDate = @RepTreatmentDate THEN ISNULL(S.FuturCom,0)  
		ELSE 0
		END AS FuturComs,
		CASE
			WHEN (ISNULL(S.FuturCom,0) = 0) OR (S.RepTreatmentDate <> @RepTreatmentDate) THEN 0
		ELSE ROUND(((ISNULL(S.Advance,0) + ISNULL(SA.Amount,0) + ISNULL(AVR.AVRAmount,0))*100) / ISNULL(S.FuturCom,0),2)
		END CommPcts,
		CASE
			WHEN (ISNULL(S.FuturCom,0) = 0) OR (S.RepTreatmentDate <> @RepTreatmentDate) THEN 0
		ELSE ROUND(((ISNULL(S.Advance,0) + ISNULL(LSA.Amount,0) + ISNULL(LAVR.AVRAmount,0))*100) / ISNULL(S.FuturCom,0),2)
		END CalcCommPcts,
		S.RepID
	FROM Un_Dn_ReptreatmentSumary S
	JOIN (

		SELECT 
			RepID,
			MaxRepTreatmentDate = MAX(RepTreatmentDate)
		FROM Un_Dn_ReptreatmentSumary
		WHERE RepTreatmentID = @RepTreatmentID
		GROUP BY RepID

		) M ON (M.RepID = S.RepID) AND (M.MaxRepTreatmentDate = S.RepTreatmentDate)
	LEFT JOIN (

		SELECT 
			RepID,
			SUM(RepChargeAmount) AS AVRAmount
		FROM Un_RepCharge 
		WHERE RepChargeTypeID = 'AVR'  
		  AND RepChargeDate <= @RepTreatmentDate   
		GROUP BY RepID

		) AVR ON (AVR.RepID = S.RepID)
	LEFT JOIN (

		SELECT 
			RepID,
			SUM(RepChargeAmount) AS AVRAmount
		FROM Un_RepCharge 
		WHERE RepChargeTypeID = 'AVR'  
		  AND RepChargeDate <= @LastRepTreatmentDate   
		GROUP BY RepID

		) LAVR ON (LAVR.RepID = S.RepID)
	LEFT JOIN (

		SELECT 
			RepID,
			SUM(Amount) AS Amount
		FROM Un_SpecialAdvance 
		WHERE EffectDate <= @RepTreatmentDate
		GROUP BY RepID 

		) SA ON (SA.RepID = S.RepID)  
	LEFT JOIN (

		SELECT 
			RepID,
			SUM(Amount) AS Amount
		FROM Un_SpecialAdvance 
		WHERE (EffectDate <= @RepTreatmentDate)
		  AND ((@RepTreatmentID > RepTreatmentID) OR (RepTreatmentID IS NULL))
		GROUP BY RepID 

		) LSA ON LSA.RepID = S.RepID
	WHERE S.RepTreatmentID = @RepTreatmentID
		AND S.RepID = COALESCE(@RepID, S.RepID)
		--AND( @RepID = 0
		--	OR S.RepId = @RepID
		--	)

/*
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
				'Rapport des commissions (Avance sur résiliation et avances couvertes)',
				'RP_UN_RepTreatmentTerminatedAndSpecialAdvance',
				'EXECUTE RP_UN_RepTreatmentTerminatedAndSpecialAdvance @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepTreatmentID = '+CAST(@RepTreatmentID AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
*/
END
