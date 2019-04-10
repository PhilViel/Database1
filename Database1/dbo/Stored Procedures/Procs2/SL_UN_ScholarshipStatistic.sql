/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_ScholarshipStatistic
Description         :	Procédure retournant les statistiques de bourses par l’année traitée.
Valeurs de retours  :	Dataset :
									PlanID				INTEGER		ID du plan (régime).
									PlanDesc				VARCHAR(75)	Régime.
									AutImpConventions	INTEGER		Nombre de conventions importées automatiquement aux bourses 
																			pour ce régime pour l’année en traitement.
									AutImpUnitQty		MONEY			Nombre d’unités importées automatiquement aux bourses pour ce 
																			régime pour l’année en traitement.
									ManImpConventions	INTEGER		Nombre de conventions importées manuellement aux bourses pour 
																			ce régime pour l’année en traitement.
									ManImpUnitQty		INTEGER		Nombre d’unités importées manuellement aux bourses pour ce 
																			régime pour l’année en traitement.
Note                :	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ScholarshipStatistic] 
AS
BEGIN
	DECLARE
		@iScholarshipYear INTEGER

	SELECT @iScholarshipYear = MAX(ScholarshipYear)
	FROM Un_Def

	SELECT
		P.PlanID, -- ID du plan (régime).
		P.PlanDesc, -- Régime.
		AutImpConventions = 
			COUNT	(DISTINCT
						CASE 
							WHEN C.ScholarshipEntryID IN ('A','S') THEN C.ConventionID
						ELSE NULL
						END
					), -- Nombre de conventions importées automatiquement aux bourses pour ce régime pour l’année en traitement.
		AutImpUnitQty =
			SUM	(	CASE
							WHEN C.ScholarshipEntryID IN ('A','S') THEN U.UnitQty
						ELSE 0
						END
					), -- Nombre d’unités importées automatiquement aux bourses pour ce régime pour l’année en traitement.
		ManImpConventions = 
			COUNT	(DISTINCT
						CASE 
							WHEN C.ScholarshipEntryID IN ('G','R') THEN C.ConventionID
						ELSE NULL
						END
					), -- Nombre de conventions importées manuellement aux bourses pour ce régime pour l’année en traitement.
		ManImpUnitQty =
			SUM	(	CASE
							WHEN C.ScholarshipEntryID IN ('G','R') THEN U.UnitQty
						ELSE 0
						END
					) -- Nombre d’unités importées manuellement aux bourses pour ce régime pour l’année en traitement.	
	FROM dbo.Un_Convention C
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	WHERE C.ScholarshipYear = @iScholarshipYear
		AND P.PlanTypeID = 'COL'
	GROUP BY
		P.PlanID,
		P.PlanDesc
	ORDER BY P.PlanDesc
END


