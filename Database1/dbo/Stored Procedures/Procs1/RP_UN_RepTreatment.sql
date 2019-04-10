/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepTreatment
Description         :	Procédure stockée du rapport : Rapport des commissions détaillés
Valeurs de retours  :	Dataset
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
					2008-01-25	Pierre-Luc Simard	Ajout d'un COALESCE pour accélérer
					2016-04-26	Pierre-Luc Simard	Ajout du représentant au niveau des unités, à la date du calcul
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepTreatment] (
	@ConnectID INTEGER,
	@RepTreatmentID INTEGER,
	@RepID INTEGER )
AS
BEGIN
	DECLARE
		@RepTreatmentDate MoGetDate,
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()
	
	IF @RepID = 0 	
		SET @RepID = NULL
	
	SELECT @RepTreatmentDate = RepTreatmentDate
	FROM Un_RepTreatment 
	WHERE RepTreatmentID = @RepTreatmentID
	
		SELECT 
			T.*,
			R.Statut,
			UnitRepCode = UR.RepCode,
			UniRepName = CASE WHEN HR.HumanID IS NULL THEN NULL ELSE HR.LastName + ', ' + HR.FirstName END 
		FROM Un_Dn_RepTreatment T
		JOIN (
			SELECT
				RepID, 
				Statut = 
					CASE
						WHEN BusinessEnd < @RepTreatmentDate THEN 'Inactif'
					ELSE 'Actif'
					END
			FROM Un_Rep
			) R ON R.RepID = T.RepID
		LEFT JOIN Un_Rep UR ON UR.RepID = T.UnitRepID 
		LEFT JOIN Mo_Human HR ON HR.HumanID = UR.RepID
		WHERE T.RepTreatmentID = @RepTreatmentID
			AND T.RepID = COALESCE(@RepID, T.RepID)
			--AND( @RepID = 0
			--	OR 
			--	@RepID = T.RepID
			--	)
		ORDER BY 
			T.RepName, 
			T.RepID, 
			T.RepRoleDesc, 
			T.FirstDepositDate, 
			T.ConventionNo

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
				'Rapport des commissions détaillés',
				'RP_UN_RepTreatment',
				'EXECUTE RP_UN_RepTreatment @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepTreatmentID = '+CAST(@RepTreatmentID AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_RepTreatment] 
	@ConnectID = 1, -- ID de connexion de l'usager
	@RepID = 149653, -- ID du représentant dont on veut la liste, 0 pour Tous, 149653 pour Claude Cossette
	@RepTreatmentID = 282 -- Numéro du traitement voulu
*/
