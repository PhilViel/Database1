/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepTreatmentRep
Description         :	Procédure stockée du rapport : Rapport des commissions détaillés (Liste des représentants)
Valeurs de retours  :	Dataset
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepTreatmentRep] (
	@ConnectID INTEGER,
	@RepID INTEGER,
	@RepTreatmentID INTEGER)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@RepTreatmentDate DATETIME

	SET @dtBegin = GETDATE()

	SELECT @RepTreatmentDate = RepTreatmentDate
	FROM Un_RepTreatment
	WHERE RepTreatmentID = @RepTreatmentID

	SELECT DISTINCT 
		RepID,
		RepCode,
		RepName
	INTO #Temp
	FROM Un_Dn_RepTreatment 
	WHERE RepTreatmentID = @RepTreatmentID
		AND( @RepID = 0
			OR @RepID = RepID
			)

	SELECT DISTINCT 
		V.RepID,
		V.RepCode,
		V.RepName,
		R.Statut
	FROM (
		SELECT DISTINCT 
			RepID,
			RepCode,
			RepName
		FROM #Temp
		---------
		UNION ALL
		---------
		SELECT DISTINCT
			C.RepID,
			R.RepCode,
			RepName = H.LastName+' '+H.FirstName 
		FROM Un_Rep R
		JOIN Un_RepCharge C ON C.RepID = R.RepID 
		JOIN dbo.Mo_Human H ON R.RepID = H.HumanID 
		LEFT JOIN (
			SELECT DISTINCT 
				RepID,
				RepCode,
				RepName
			FROM #Temp 
			) V ON V.RepID = C.RepID
		WHERE C.RepTreatmentID = @RepTreatmentID
			AND( @RepID = 0
				OR @RepID = C.RepID
				)
			AND V.RepID IS NULL
		) V     
	JOIN (
		SELECT
			RepID, 
			Statut = 
				CASE
					WHEN BusinessEnd < @RepTreatmentDate THEN 'Inactif'
				ELSE 'Actif'
				END
		FROM Un_Rep
		) R ON R.RepID = V.RepID
	ORDER BY 
		V.RepName, 
		V.RepID 

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def
/*
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
				'Rapport des commissions détaillés (Liste des représentants)',
				'RP_UN_RepTreatmentRep',
				'EXECUTE RP_UN_RepTreatmentRep @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepTreatmentID = '+CAST(@RepTreatmentID AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
*/
END


