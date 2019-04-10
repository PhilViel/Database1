/****************************************************************************************************
	Liste des raison de ne pas commander de chèques
******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_NoChequeReason] (
	@NoChequeReasonID INTEGER, -- ID unique de la raison (0 = Tous)
	@NoChequeReasonActive BIT) -- (0 : Tous, <> 0 : Seulement les actives)
AS
BEGIN
	SELECT
		R.NoChequeReasonID,
		R.NoChequeReason,
		R.NoChequeReasonActive,
		R.NoChequeReasonImplicationID,
		ActiveCount = ISNULL(COUNT(U.UnitReductionID),0)
	FROM Un_NoChequeReason R
	LEFT JOIN Un_UnitReduction U ON R.NoChequeReasonID=U.NoChequeReasonID
	WHERE @NoChequeReasonID = R.NoChequeReasonID
		OR (@NoChequeReasonID = 0
		AND (@NoChequeReasonActive = 0
		  OR (@NoChequeReasonActive <> 0
		  AND R.NoChequeReasonActive <> 0)))
	GROUP BY 
		R.NoChequeReasonID,
		R.NoChequeReason,
		R.NoChequeReasonActive,
		R.NoChequeReasonImplicationID
	ORDER BY NoChequeReason
END

