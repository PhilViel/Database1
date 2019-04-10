/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_PlanValues
Description         :	Procédure retournant les valeurs unitaires des bourses.
Valeurs de retours  :	Dataset :
									PlanID				INTEGER		ID unique du plan.
									PlanDesc				VARCHAR(75)	Description du plan.
									ScholarshipYear	INTEGER		Année de bourse.
									ScholarshipNo		INTEGER		Numéro de bourse.
									UnitValue			MONEY			Valeur de la bourse par unité.
Note                :	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
                                        2018-11-08  Pierre-Luc Simard   Utilisation du champ NomPlan

exec SL_UN_PlanValues 0,0
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_PlanValues] (
	@PlanID INTEGER, -- ID du plan, 0 = tous.
	@OnlyForTreatDate BIT) 	-- 0 = Tous, 1 = uniquement seulement correspondant à l’année de qualification en traitement 
									-- dans l’outil de PAE en lot.
AS
BEGIN
	DECLARE
		@iScholarshipYear INTEGER

	-- Cherche l'année de bourses traitée
	SELECT @iScholarshipYear = MAX(ScholarshipYear)
	FROM Un_Def

	SELECT
		PV.PlanID, -- ID unique du plan.
		PlanDesc = P.NomPlan,
		PV.ScholarshipYear, -- Année de bourse.
		PV.ScholarshipNo, -- Numéro de bourse.
		PV.UnitValue -- Valeur de la bourse par unité.
	FROM Un_PlanValues PV
	JOIN Un_Plan P ON P.PlanID = PV.PlanID
	WHERE	( @PlanID = 0
			OR @PlanID = P.PlanID
			)
		AND( @OnlyForTreatDate = 0
			OR @iScholarshipYear = PV.ScholarshipYear
			)
END