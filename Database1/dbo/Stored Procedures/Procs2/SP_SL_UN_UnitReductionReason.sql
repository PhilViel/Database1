/****************************************************************************************************
	Liste des raisons de résiliations du système
******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
	2008-07-30 Patrick Robitaille
		Ajout de la gestion du champ bReduitTauxConservationRep
******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_UnitReductionReason] (
	@UnitReductionReasonID INTEGER, -- ID unique de la raison (0 = Tous)
	@UnitReductionReasonActive BIT) -- (0 : Tous, <> 0 : Seulement les actives)
AS
BEGIN
	SELECT 
		R.UnitReductionReasonID,
		R.UnitReductionReason,
		R.UnitReductionReasonActive,
		R.bReduitTauxConservationRep,
		ActiveCount = ISNULL(COUNT(U.UnitReductionID),0)
	FROM Un_UnitReductionReason R
	LEFT JOIN Un_UnitReduction U ON R.UnitReductionReasonID=U.UnitReductionReasonID
	WHERE (@UnitReductionReasonID = R.UnitReductionReasonID)
		OR (@UnitReductionReasonID = 0
		AND (@UnitReductionReasonActive = 0
		  OR (@UnitReductionReasonActive <> 0
		  AND R.UnitReductionReasonActive <> 0)))
	GROUP BY 
		R.UnitReductionReasonID,
		R.UnitReductionReason,
		R.UnitReductionReasonActive,
		R.bReduitTauxConservationRep
	ORDER BY UnitReductionReason
END

