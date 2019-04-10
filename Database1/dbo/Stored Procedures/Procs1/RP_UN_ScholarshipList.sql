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
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_ScholarshipList
Description         :	Liste des bourses
Valeurs de retours  :					
Note                :			
					2006-12-18	IA 	Alain Quirion	Optimisation	
                    2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipList] (
@ConnectID INTEGER)
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SELECT 
		PlanDesc = CASE S.ScholarshipStatusID
			WHEN 'DEA' THEN RTRIM(P.PlanDesc) + ', Bourse ' + RTRIM(CAST(S.ScholarshipNo AS VARCHAR)) + ' - Résiliation pour décès'
			WHEN 'REN' THEN RTRIM(P.PlanDesc) + ', Bourse ' + RTRIM(CAST(S.ScholarshipNo AS VARCHAR)) + ' - Résiliation pour renonciation'
			WHEN '25Y' THEN RTRIM(P.PlanDesc) + ', Bourse ' + RTRIM(CAST(S.ScholarshipNo AS VARCHAR)) + ' - Résiliation pour 25 ans de régime'
			WHEN '24Y' THEN RTRIM(P.PlanDesc) + ', Bourse ' + RTRIM(CAST(S.ScholarshipNo AS VARCHAR)) + ' - Résiliation pour 24 ans d''age'
			ELSE RTRIM(P.PlanDesc) + ', Bourse ' + RTRIM(CAST(S.ScholarshipNo AS VARCHAR))
		END,
		C.ConventionNo,
		SubscriberName = RTRIM(SH.LastName) + ', ' + RTRIM(SH.FirstName),
		BeneficiaryName = RTRIM(BH.LastName) + ', ' + RTRIM(BH.FirstName),
		BeneficiaryBirthDate = BH.BirthDate,
		ScholarshipStatusDesc = CASE S.ScholarshipStatusID
						WHEN 'DEA' THEN 'Décès'
						WHEN 'REN' THEN 'Renonciation'
						WHEN '25Y' THEN '25 ans de régime'
						WHEN '24Y' THEN '24 ans d''age'
						WHEN 'RES' THEN 'En réserve'
						WHEN 'PAD' THEN 'Payée'
						WHEN 'ADM' THEN 'Admissible'
						WHEN 'WAI' THEN 'En attente'
						WHEN 'TPA' THEN 'À payer'
						ELSE 'État inconnue'
					END,
		U.UnitQty,
		S.ScholarshipAmount
	FROM dbo.Mo_Human BH
	JOIN dbo.Un_Convention C ON C.BeneficiaryID = BH.HumanID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN VUn_UnitByConvention U ON U.ConventionID = C.ConventionID
	JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
	JOIN Un_Scholarship S ON S.ConventionID = C.ConventionID
	WHERE S.ScholarshipStatusID <> 'PAD'
		AND S.YearDeleted = 0
	ORDER BY 
		P.PlanDesc,
		S.ScholarshipNo,
		S.ScholarshipStatusID,
		SH.LastName,
		SH.FirstName,
		BH.LastName,
		BH.FirstName

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
				'Rapport des listes des bourses',
				'RP_UN_ScholarshipList',
				'EXECUTE RP_UN_ScholarshipList @ConnectID ='+CAST(@ConnectID AS VARCHAR)
	END	
*/
END