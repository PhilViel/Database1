/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_RepProjectionSumary
Description         :	Retourne le sommaire d'une projection des commissions à une date donnée        
Valeurs de retours  :	
				
Note                :			2003-06-11   	Marc W		   	Création
 				 	2003-08-13   	Bruno Lapointe  	Modification (Optimisation du rapport pour que les pages soient générés plus vite)ADX0001206	
				IA	2006-12-22	Alain Quirion		Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepProjectionSumary](
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
		V2.RepProjectionYear,
		V2.RepProjectionDate,
		V2.PeriodCommBonus,   
		V2.YearCommBonus,     
		V2.Retenu,
		V2.Net,
		V2.PeriodCommBonusCad,
		V2.YearCommBonusCad,
		V2.AdvanceSolde,
		V2.AVSAmountSolde,
		V2.AVRAmountSolde,
		V2.AVS_AVRTotal
	FROM (
		SELECT 
			V.RepID,
			V.RepCode,
			V.RepName,
			CASE 
				WHEN ISNULL(R.RepID, 0) = 0 THEN 'Actif'
				ELSE 'Inactif'
				END AS Status
		FROM (
			SELECT DISTINCT
				RepID,
				RepCode,
				RepName
			FROM Un_RepProjectionSumary 
			WHERE RepProjectionDate = @RepProjectionDate
				AND (@RepID = 0 OR RepID = @RepID)) V
		LEFT JOIN Un_Rep R ON R.RepID = V.RepID AND BusinessEnd < @RepProjectionDate) V
	LEFT JOIN (
			SELECT 
	   		 	RepProjectionYear = YEAR(RepProjectionDate),
				RepID,
				RepProjectionDate,
	   			PeriodCommBonus,   
	    			YearCommBonus,     
		  		Retenu = AVSAmount + AVRAmount,           
				Net = PeriodCommBonus + AVSAmount + AVRAmount,
	    			PeriodCommBonusCad = PeriodCommBonus + PeriodCoveredAdvance,
		 		YearCommBonusCad = YearCommBonus + YearCoveredAdvance,  
	    			AdvanceSolde,
				AVSAmountSolde,
				AVRAmountSolde,
				AVS_AVRTotal = AdvanceSolde + AVSAmountSolde + AVRAmountSolde 
			FROM Un_RepProjectionSumary
			WHERE YEAR(RepProjectionDate) = YEAR(@RepProjectionDate)
				AND RepProjectionDate <= @RepProjectionDate
				AND (@RepID = 0 OR RepID = @RepID)) V2 ON V2.RepID = V.RepID
	ORDER BY V.RepName, V.RepID, V2.RepProjectionDate

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
				'Rapport sommaire des projections de commissions le ' + CAST(@RepProjectionDate AS VARCHAR),
				'RP_UN_RepProjectionSumary',
				'EXECUTE RP_UN_RepProjectionSumary @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @RepProjectionDate=' +  CAST(@RepProjectionDate AS VARCHAR)+
				', @RepID=' +  CAST(@RepID AS VARCHAR)
	END	
END

