/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc.
Nom 			: RP_UN_CESGConventionWithExceedingCotisation
Description 		: Conventions avec contributions en excès
Valeurs de retour	: Dataset
Note			: 
						2004-09-02	Bruno Lapointe	Création
			 ADX0001180 	BR 	2004-12-06 	Yann Le Dreff 	Separation de la requete imbriquee en 
										2 requetes distinctes en passant par 
										une table temporaire (evite le probleme d'ASTA Timeout)
			ADX0001206	IA	2006-12-08	Alain Quirion	Optimisation
****************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CESGConventionWithExceedingCotisation](
	@ConnectID INTEGER)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	-- Table temporaire
	CREATE TABLE #WTemp(
		ConventionID INTEGER,
		ProcessedYear INTEGER,
		AnnualCotisationFee MONEY)

	-- Requete 1 :	
	INSERT INTO #WTemp
	SELECT
		C.ConventionID,
		ProcessedYear = DATEPART(yyyy,CO.EffectDate),
		AnnualCotisationFee = SUM(Cotisation + Fee)
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = CO.OperID
	JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
	WHERE OT.GovernmentTransTypeID IN ('11')
		AND (CO.EffectDate >= '1998-02-01')
	GROUP BY 
		C.ConventionID, 
		DATEPART(yyyy,CO.EffectDate)
	HAVING SUM(Cotisation + Fee) > 4000

	-- Requete 2 :
	SELECT
		C.ConventionNo,
		V.AnnualCotisationFee,
		OT.OperTypeDesc,
		O.OperDate,
		CO.EffectDate,
		CO.Cotisation,
		CO.Fee
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = CO.OperID
	JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
	JOIN #WTemp V ON V.ConventionID = C.ConventionID AND V.ProcessedYear = DATEPART(yyyy,CO.EffectDate)
	WHERE OT.GovernmentTransTypeID IN ('11')
	ORDER BY
		C.ConventionNo,
		EffectDate

	DROP TABLE #WTemp

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
				'Rapport de convention avec contribution en excès',
				'RP_UN_CESGConventionWithExceedingCotisation',
				'EXECUTE RP_UN_CESGConventionWithExceedingCotisation @ConnectID ='+CAST(@ConnectID AS VARCHAR)					
	END	
END


