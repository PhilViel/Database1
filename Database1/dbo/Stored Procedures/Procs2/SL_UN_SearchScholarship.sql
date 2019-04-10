/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
	Procédure de recherche de bourse
			
		ADX0000894	BR	2004-10-01 	Bruno Lapointe		Migration et modification de la valeur du statut (Description au lieu du code)		
						2006-11-29	Alain Quirion		Optimisation
						2011-08-10	Frédérick Thibault	Ajout des conventions RIO source avec bourse REN
                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée
						
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchScholarship] (	
	@ConnectID INTEGER,
	@ScholarshipNo INTEGER,
	@ScholarshipStatusID CHAR(3),
	@RepID INTEGER) 
AS
BEGIN
	-- Création d'une table temporaire
	CREATE TABLE #tRep (
		RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #tRep
		EXECUTE SL_UN_BossOfRep @RepID

	DECLARE 
		@Today DATETIME,
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()
	SET @Today = GETDATE()

	DECLARE @tSearchScholarship TABLE (
		ScholarshipID INTEGER PRIMARY KEY)

	-- Statut de bourse, Numéro de bourse
	INSERT INTO @tSearchScholarship
		SELECT S.ScholarshipID
		FROM Un_Scholarship S		
		WHERE S.ScholarshipStatusID = @ScholarshipStatusID
			AND S.ScholarshipNo = @ScholarshipNo			
	
	SELECT 
		PlanCode = 	
			CASE C.PlanID
				WHEN 8 THEN 'A'
				WHEN 11 THEN 'B'
			ELSE ''
			END,
		C.ConventionID,
		C.ConventionNo,
		C.BeneficiaryID,
		SubscriberName = RTRIM(SH.LastName) + ', ' + RTRIM(SH.FirstName),
		BeneficiaryName = RTRIM(BH.LastName) + ', ' + RTRIM(BH.FirstName),
		BeneficiaryBirthDate = BH.BirthDate,
		S.ScholarshipNo,
		ScholarshipStatusID =
			CASE S.ScholarshipStatusID
				WHEN 'RES' THEN 'En réserve'
				WHEN 'PAD' THEN 'Payée'
				WHEN 'ADM' THEN 'Admissible'
				WHEN 'WAI' THEN 'En attente'
				WHEN 'TPA' THEN 'À payer'
				WHEN 'DEA' THEN 'Décès'
				WHEN 'REN' THEN 'Renonciation'
				WHEN '25Y' THEN '25 ans'
				WHEN '24Y' THEN '24 ans'
			ELSE ''
			END
	FROM @tSearchScholarship SS
	JOIN Un_Scholarship S ON SS.ScholarShipID = S.ScholarShipID
	JOIN dbo.Un_Convention C ON S.ConventionID = C.ConventionID
	JOIN dbo.Mo_Human BH ON C.BeneficiaryID = BH.HumanID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID		
	JOIN dbo.Un_Subscriber SU ON C.SubscriberID = SU.SubscriberID
	JOIN #tRep R ON SU.RepID = R.RepID OR R.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
	LEFT JOIN tblOPER_OperationsRIO RIO ON RIO.iID_Convention_Source = C.ConventionID
	WHERE S.YearDeleted = 0 OR (S.YearDeleted <> 0 AND RIO.iID_Operation_RIO IS NOT NULL)
	ORDER BY 
		SH.LastName,
		SH.FirstName,
		BH.LastName,
		BH.FirstName,
		C.ConventionNo
	
	/** GESTION DES REQUÊTES TROP LONGUES**/
	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
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
				1,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Recherche de bourses numéro ' 
					+ CAST(@ScholarshipNo AS VARCHAR) 
					+ ' de statut : '
					+	CASE @ScholarshipStatusID
							WHEN 'RES' THEN 'En réserve'
							WHEN 'PAD' THEN 'Payée'
							WHEN 'ADM' THEN 'Admissible'
							WHEN 'WAI' THEN 'En attente'
							WHEN 'TPA' THEN 'À payer'
							WHEN 'DEA' THEN 'Décès'
							WHEN 'REN' THEN 'Renonciation'
							WHEN '25Y' THEN '25 ans'
							WHEN '24Y' THEN '24 ans'
						END,
				'SL_UN_SearchScholarship',
				'EXECUTE SL_UN_SearchScholarship @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
					', @ScholarshipNo ='+CAST(@ScholarshipNo AS VARCHAR)+
					', @ScholarshipStatusID ='+@ScholarshipStatusID+		
					', @RepID ='+CAST(@RepID AS VARCHAR)
	END	
	
	-- FIN DES TRAITEMENTS 
	RETURN 0
END