/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepProjection
Description         :	Retourne toutes le détail d'une projection des commissions à une date donné        
Valeurs de retours  :	
				
Note                :			2003-06-09   	marcw   		Création
  					2003-08-13   	Bruno Lapointe  	Modification (Optimisation du rapport pour que les pages soient générés plus vite)
				IA	2006-12-22	Alain Quirion		Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepProjection](
	@ConnectID            INTEGER,   --ID de connection de l'usager
  	@RepProjectionDate    DATETIME, --Date de la projection voulue
  	@RepID                INTEGER)   --ID du représentant si il y en a un ou 0 pour tous
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SELECT  
		V.RepID,
		V.RepCode,
		V.RepName,
		V.Status,
		V2.RepProjectionDate,
		V2.RepLevelID,
		V2.ConventionID,
		V2.FirstDepositDate,
		V2.InForceDate,
		V2.SubscriberName,
		V2.ConventionNo,
		V2.RepName,
		V2.RepCode,
		V2.RepLicenseNo,
		V2.RepRoleDesc,
		V2.RepLevelShortDesc,
		V2.UnitQty, 
		V2.TotalFee,
		V2.CoverdAdvance,
		V2.ServiceComm, 
		V2.PeriodComm, 
		V2.CumComm, 
		V2.ServiceBusinessBonus,
		V2.PeriodBusinessBonus,
		V2.CumBusinessBonus, 
		V2.PaidAmount, 
		V2.CommExpenses,
		V2.SweepstakeBonusAjust
	FROM (
		SELECT 
		V.RepID,
		V.RepCode,
		V.RepName,
		Status = CASE 
				WHEN ISNULL(R.RepID, 0) = 0 THEN 'Actif'
				ELSE 'Inactif'
			END
		FROM (	
			SELECT  
				RepID,
				RepCode,
				RepName
			FROM Un_RepProjection 
			WHERE RepProjectionDate = @RepProjectionDate
				AND (@RepID = 0 OR RepID = @RepID)
			UNION 
			SELECT 
				RepID,
				RepCode,
				RepName
			FROM Un_RepProjectionSumary 
			WHERE RepProjectionDate = @RepProjectionDate
				AND (@RepID = 0 OR RepID = @RepID)) V
		LEFT JOIN Un_Rep R ON R.RepID = V.RepID AND BusinessEnd < @RepProjectionDate) V
	LEFT JOIN (
			SELECT  
				RepProjectionDate,
				RepID,
				RepLevelID, 
				ConventionID,
				FirstDepositDate,
				InForceDate,
				SubscriberName,
				ConventionNo,
				RepName,
				RepCode,
				RepLicenseNo,
				RepRoleDesc,
				RepLevelShortDesc,
				UnitQty,
				TotalFee,
				CoverdAdvance,
				ServiceComm,
				PeriodComm,
				CumComm,
				ServiceBusinessBonus,
				PeriodBusinessBonus,
				CumBusinessBonus,
				PaidAmount,
				CommExpenses,
				SweepstakeBonusAjust = 0 
			FROM Un_RepProjection
			WHERE RepProjectionDate = @RepProjectionDate
				AND (@RepID = 0 OR RepID = @RepID)) V2 ON V2.RepID = V.RepID
	ORDER BY V.RepName, V.RepID, V2.RepProjectionDate, V2.RepID, V2.RepLevelID, V2.ConventionNo, V2.FirstDepositDate

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
				'Rapport des projections de commissions le ' + CAST(@RepProjectionDate AS VARCHAR),
				'RP_UN_RepProjection',
				'EXECUTE RP_UN_RepProjection @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @RepProjectionDate=' +  CAST(@RepProjectionDate AS VARCHAR)+
				', @RepID=' +  CAST(@RepID AS VARCHAR)
	END	
END

