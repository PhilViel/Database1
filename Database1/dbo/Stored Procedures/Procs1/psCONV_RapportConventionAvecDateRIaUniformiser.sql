/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportConventionAvecDateRIaUniformiser
Nom du service		: 
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportConventionAvecDateRIaUniformiser
				
Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-04-29		Maxime Martel						Création du service	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportConventionAvecDateRIaUniformiser]
AS
BEGIN
	SELECT 
		--U.ConventionID,
		U.ConventionNo,
		dtRIN_Estime_MIN = MIN(U.dtRIN_Estime),
		dtRIN_Estime_Max = MAX(U.dtRIN_Estime),
		NB_GrpUnit = COUNT(U.UnitID)
	FROM (
		SELECT 
			C.ConventionID,
			C.ConventionNo,
			dtRIN_Estime = dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust),
			U.UnitID
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		WHERE P.PlanTypeID = 'COL'
			AND U.TerminatedDate IS NULL
			AND U.IntReimbDate IS NULL
		) U
	GROUP BY 
		U.ConventionID,
		U.ConventionNo
	HAVING MIN(U.dtRIN_Estime) <> MAX(U.dtRIN_Estime)
END


