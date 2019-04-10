/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_OperLinkToCHQOperation
Description         :	Retourne l'opération UniAcces (Un_Oper), lié à l'opération du mnodule des chèques.
Valeurs de retours  :	Dataset :
									OperID		INTEGER			ID de l'opération (Un_Oper).
									PlanTypeID	CHAR(3)			Chaîne de 3 caractères identifiant le type du plan 
																		('IND' = Individuel, 'COL' = Collectif).
Note                :	ADX0000709	IA	2005-09-13	Bruno Lapointe		Création
								ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_OperLinkToCHQOperation] (
	@iOperationID INTEGER ) -- ID de l'opération du module des chèques
AS
BEGIN
	SELECT DISTINCT
		V.OperID, -- ID de l'opération (Un_Oper)
		P.PlanTypeID -- Chaîne de 3 caractères identifiant le type du plan ('IND' = Individuel, 'COL' = Collectif).
	FROM (
			SELECT
				V.OperID,
				ConventionID = MIN(V.ConventionID)
			FROM (
				SELECT
					Ct.OperID,
					U.ConventionID
				FROM Un_Cotisation Ct
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN Un_OperLinkToCHQOperation O ON O.OperID = Ct.OperID
				WHERE O.iOperationID = @iOperationID
				-----
				UNION
				-----
				SELECT
					CO.OperID,
					CO.ConventionID
				FROM Un_ConventionOper CO
				JOIN Un_OperLinkToCHQOperation O ON O.OperID = CO.OperID
				WHERE O.iOperationID = @iOperationID
				-----
				UNION
				-----
				SELECT
					CE.OperID,
					CE.ConventionID
				FROM Un_CESP CE
				JOIN Un_OperLinkToCHQOperation O ON O.OperID = CE.OperID
				WHERE O.iOperationID = @iOperationID
					AND( CE.fCESG <> 0
						OR CE.fACESG <> 0
						OR CE.fCLB <> 0
						)
				) V
			GROUP BY V.OperID
			) V 
	JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
END


