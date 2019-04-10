/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                : 	RP_UN_StateInsuranceSummary
Description        : 	Rapport Journalier
Valeurs de retours : 	>0  : Tout à fonctionné
                      	<=0 : Erreur SQL

Note                :		
				2006-12-08	IA	Alain Quirion		Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_StateInsuranceSummary] (
	@ConnectID INTEGER,
	@StartDate DATETIME,
	@EndDate DATETIME)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SELECT 
		SA.StateName,
		SUM(Ct.SubscInsur) AS SubscInsur,
		SUM(Ct.BenefInsur) AS BenefInsur,
		SUM(Ct.SubscInsur + Ct.BenefInsur) AS SubscANDBenefInsur
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
	JOIN dbo.Mo_Adr SA ON SA.AdrID = S.AdrID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	WHERE O.OperDate >= @StartDate
		AND O.OperDate < @EndDate + 1
	GROUP BY 
		SA.Statename
	HAVING SUM(Ct.SubscInsur + Ct.BenefInsur) <> 0
	ORDER BY 
		SA.Statename

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = @siTraceReport FROM Un_Def

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
				'Rapport d''assurance par province entre le ' + CAST(@StartDate AS VARCHAR) + ' et le '+ CAST(@EndDate AS VARCHAR),
				'RP_UN_StateInsuranceSummary',
				'EXECUTE RP_UN_StateInsuranceSummary @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)			
	END	
END  


