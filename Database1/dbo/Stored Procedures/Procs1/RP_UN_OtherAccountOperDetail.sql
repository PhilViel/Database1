/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_OtherAccountOperDetail
Description         :	Soldes du rapport du compte GUI (Section 1)
Valeurs de retours  :	Dataset contenant les données
Note                :	
						2004-06-22 	Bruno Lapointe 	Point 12.16
						2004-09-27 	Bruno Lapointe	Correction
			ADX0001206	IA	2006-12-21	Alain Quirion	Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_OtherAccountOperDetail] (
	@ConnectID INTEGER,
	@StartDate DATETIME, -- Date de début de la période
	@EndDate DATETIME) -- Date de fin de la période
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SELECT 
		O.OperDate,
		OT.OperTypeDesc,
	   ConventionOperTypeDesc = ISNULL(T.ConventionOperTypeDesc,'Inconnu'),
		ConventionNo = ISNULL(C.ConventionNo,''),
		SubscriberName = 
			CASE 
				WHEN ISNULL(H.LastName,'') = '' THEN ''
			ELSE H.LastName+', '+H.FirstName 
			END,
	   Amount = 
			CASE 
				WHEN (V.OperID IS NOT NULL) AND (V.ConventionOperAmount*-1 = A.OtherAccountOperAmount) THEN CO.ConventionOperAmount * -1
			ELSE A.OtherAccountOperAmount
			END      
	FROM Un_OtherAccountOper A
	JOIN Un_Oper O ON O.OperID = A.OperID
	JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
	LEFT JOIN (
		SELECT 
			C.OperID,
			ConventionOperAmount = SUM(C.ConventionOperAmount)
		FROM Un_ConventionOper C
	   JOIN Un_OtherAccountOper A ON C.OperID = A.OperID
	   GROUP BY C.OperID
		) V ON (V.OperID = O.OperID)
	LEFT JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
	LEFT JOIN Un_ConventionOperType T ON T.ConventionOperTypeID = CO.ConventionOperTypeID
	LEFT JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
	LEFT JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
	WHERE O.OperDate >= @StartDate 
	  AND O.OperDate < @EndDate +1
	ORDER BY 
		O.OperDate,	
		OT.OperTypeDesc, 
		T.ConventionOperTypeDesc, 
		H.LastName, 
		H.FirstName, 
		C.ConventionNo

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
				'Rapport des opérations GUI entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_OtherAccountOperDetail',
				'EXECUTE RP_UN_OtherAccountOperDetail @ConnectID ='+CAST(@ConnectID AS VARCHAR)+	
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)
	END	
END


