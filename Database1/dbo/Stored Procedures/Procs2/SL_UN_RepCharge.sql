/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepCharge
Description         :	Procédure retournant l’historique des ajustements et retenus pour un représentant.
Valeurs de retours  :	Dataset :
									RepChargeID			INTEGER			ID unique de l’ajustement ou de la retenu.
									RepID					INTEGER			ID du représentant.
									RepChargeTypeID	CHAR(3)			ID du type de charge.
									RepChargeDesc		VARCHAR(255)	Note indiquant la raison de l’ajustement ou de la retenu.
									RepChargeAmount	MONEY				Montant de l’ajustement(+) ou de la retenu(-)
									RepTreatmentID		INTEGER			ID unique du traitement de commissions dans lequel
																				l'ajustement ou la retenu a été traité. Null = pas encore
																				traité.
									RepChargeDate		DATETIME			Date à laquelle l'ajustement ou la retenu a eu lieu.
									RepName				VARCHAR(87)		Nom, prénom du représentant.
									RepChargeTypeDesc	VARCHAR(75)		Nom du type d'ajustement ou de retenu.
									RepTreatmentDate	DATETIME			Date du traitement de commissions.
Note                :	ADX0000721	IA	2005-07-15	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepCharge] (
	@RepChargeID INTEGER, -- ID unique de l’ajustement ou de la retenu
	@RepID INTEGER ) -- ID du représentant
AS 
BEGIN
	SELECT 
		C.RepChargeID, -- ID unique de l’ajustement ou de la retenu.
		C.RepID, -- ID du représentant.
		C.RepChargeTypeID, -- ID du type de charge.
		C.RepChargeDesc, -- Note indiquant la raison de l’ajustement ou de la retenu.
		C.RepChargeAmount, -- Montant de l’ajustement(+) ou de la retenu(-)
		C.RepTreatmentID, -- ID unique du traitement de commissions dans lequel l'ajustement ou la retenu a été traité. Null = pas encore traité.
		C.RepChargeDate, -- Date à laquelle l'ajustement ou la retenu a eu lieu.
		RepName = H.LastName + ', ' + H.FirstName, -- Nom, prénom du représentant.
		CT.RepChargeTypeDesc, -- Nom du type d'ajustement ou de retenu.
		RepTreatmentDate = ISNULL(R.RepTreatmentDate,0) -- Date du traitement de commissions.
	FROM Un_RepCharge C
	JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID
	JOIN dbo.Mo_Human H ON H.HumanID = C.RepID
	LEFT JOIN Un_RepTreatment R ON R.RepTreatmentID = C.RepTreatmentID
	WHERE C.RepID = @RepID
		OR C.RepChargeID = @RepChargeID
	ORDER BY
		C.RepChargeDate,
		C.RepChargeID
END


