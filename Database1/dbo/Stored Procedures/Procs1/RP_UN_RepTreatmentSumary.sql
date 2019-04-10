/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepTreatmentSumary
Description         :	Procédure stockée du rapport : Rapport sommaire des commissions
Valeurs de retours  :	Dataset
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
					2008-01-25	Pierre-Luc Simard	Ajout d'un COALESCE pour accélérer
					2008-10-06	Pierre-Luc Simard	Trier les actifs et les inactifs
					2008-11-18	Donald Huppé		Trier par Rep et Directeur
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepTreatmentSumary] (
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
	IF @RepID = 0 	
		SET @RepID = NULL

	SELECT @RepTreatmentDate = RepTreatmentDate
	FROM Un_RepTreatment
	WHERE RepTreatmentID = @RepTreatmentID

	SELECT 
		S.*,
		Statut = 
			CASE
				WHEN R.BusinessEnd < @RepTreatmentDate THEN 'Inactif'
			ELSE 'Actif'
			END
	FROM Un_Dn_RepTreatmentSumary S
	JOIN Un_Rep R ON S.RepId = R.RepID
	JOIN (
		SELECT 
			ReptreatmentID,
			RepID
		FROM Un_Dn_RepTreatment U
		-----
		UNION 
		-----
		SELECT 
			RepTreatmentID,
			RepID
		FROM Un_RepCharge
		) T ON S.RepTreatmentID = T.RepTreatmentID AND S.RepID = T.RepID
	LEFT JOIN (
		SELECT 
			REPID,
			reprole = max(rl.reprole)
		FROM UN_RepLevelHist RLH
		JOIN (
			SELECT 
				RepLevelID, 
				RepRole  = CASE WHEN reproleid = 'REP' THEN 0 ELSE 1 END 
			FROM un_replevel
			) RL ON RLH.replevelID = RL.replevelID
		WHERE ENDDATE IS NULL 
		GROUP BY RLH.REPID
			) RR ON RR.RepID = R.RepID
	WHERE S.RepTreatmentID = @RepTreatmentID
		AND S.RepID = COALESCE(@RepID, S.RepID)
	ORDER BY 
		CASE WHEN R.BusinessEnd < @RepTreatmentDate THEN 'Inactif' ELSE 'Actif' END,
		isnull(RR.RepRole,0) DESC, -- Si c'est null (le rep n'est pas dans UN_RepLevelHist) alors on le met dans les REP
		S.RepName, 
		S.RepID, 
		S.RepTreatmentDate, 
		S.RepTreatmentID

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
				'Rapport sommaire des commissions',
				'RP_UN_RepTreatmentSumary',
				'EXECUTE RP_UN_RepTreatmentSumary @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepTreatmentID = '+CAST(@RepTreatmentID AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
*/
END


/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_RepTreatmentSumary] 
	@ConnectID = 1, -- ID de connexion de l'usager
	@RepID = 0, -- ID du représentant dont on veut la liste, 0 pour Tous, 149653 pour Claude Cossette
	@RepTreatmentID = 282 -- Numéro du traitement voulu
*/

