/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	RP_CHQ_CheckByStatus
Description         :	Procédure qui retournera la liste des chèques par état (statut)
Valeurs de retours  :	Dataset :
									iCheckID			ID du chèque
									dtEmission			La date d'émission du chèque
									vcStatusDescription		Le statut de chèque
									bPayeeMod			Indique s’il y a un changement de destinataire. 
									iCheckNumber			Le numéro tel qu'imprimé sur le chèque
									vcName				Le destinataire
									vcRefType			Le type d'opération qui genère le chèque
									fCheckAmount			Le montant du chèque
									vcDescription			La description de l'opération (convention)
									fOperAmount			Le montant de l'opération
Note                :	ADX0000715	IA	2005-09-06	Bernie MacIntyre			Création
			ADX0001058	IA	2006-08-01	Alain Quirion				Modification : Renvoi seulement le nom s'il s'agit d'une compagnie
							2010-06-10	Donald Huppé		Ajout des régime et groupe de régime
							2011-01-05	Donald Huppé		gérer @iID_regroupement_Regime=0(eu lieu de NULL) pour "Sans regroupement de régime"
							
exec RP_CHQ_CheckByStatus '2010-11-01','2011-06-15','1;2;3;4;5',0

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_CHQ_CheckByStatus](
	@dtStart datetime,		-- La date de début de recherche
	@dtEnd datetime,		-- La date de fin de recherche
	@vcStatusIDs varchar(255),	-- Liste délimitée des statuts de chèque (1;2 i.e. Proposé et Accepté
	@iID_regroupement_Regime int)
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		C.iCheckID,
		C.dtEmission,
		CS.vcStatusDescription,
		bPayeeMod = 
			CASE
				WHEN DH.iCheckID IS NOT NULL THEN CAST(1 AS BIT)
			ELSE CAST(0 AS BIT)
			END,
		C.iCheckNumber,
		vcName = CASE H.IsCompany 
				WHEN 0 THEN ISNULL(H.LastName,'') + ', ' + ISNULL(H.FirstName,'')
				WHEN 1 THEN ISNULL(H.LastName,'')
			END,
		O.vcRefType,
		fCheckAmount = C.fAmount,
		O.vcDescription,
		OD.fAmount
	FROM CHQ_OperationDetail OD
	JOIN CHQ_Operation O ON OD.iOperationID = O.iOperationID
	JOIN (
		SELECT
			OP.iOperationID,
			iOperationPayeeID = MAX(iOperationPayeeID)
		FROM CHQ_OperationPayee OP
		WHERE OP.iPayeeChangeAccepted = 1
		GROUP BY OP.iOperationID
		) VOP ON O.iOperationID = VOP.iOperationID
	JOIN CHQ_OperationPayee OP ON OP.iOperationPayeeID = VOP.iOperationPayeeID
	JOIN CHQ_CheckOperationDetail COD ON OD.iOperationDetailID = COD.iOperationDetailID
	JOIN CHQ_Check C
	JOIN CHQ_CheckStatus CS ON C.iCheckStatusID = CS.iCheckStatusID ON COD.iCheckID = C.iCheckID
	LEFT JOIN (
		SELECT DISTINCT
			COD.iCheckID
		FROM (
			SELECT DISTINCT
				iOperationID
			FROM CHQ_OperationPayee
			GROUP BY
				iOperationID
			HAVING COUNT(iOperationPayeeID) > 1
			) V
		JOIN CHQ_OperationDetail OD ON V.iOperationID = OD.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON OD.iOperationDetailID = COD.iOperationDetailID
		) DH ON DH.iCheckID = C.iCheckID
	LEFT JOIN dbo.Mo_Human H ON OP.iPayeeID = H.HumanID
	LEFT JOIN UN_PLAN P ON P.PlanID = C.iID_Regime
	LEFT JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime

	WHERE	C.dtEmission BETWEEN @dtStart AND @dtEnd
		AND OD.fAmount > 0
		AND C.iCheckStatusID IN (SELECT IntegerValue FROM dbo.FN_CRI_ParseTextToTable(@vcStatusIDs, ';'))
		AND ( 
			(@iID_regroupement_Regime <> 0 AND RR.iID_regroupement_Regime = @iID_regroupement_Regime)
			OR
			(@iID_regroupement_Regime = 0 AND RR.iID_regroupement_Regime is NULL)
			)
	ORDER BY 
		O.dtOperation,
		C.iCheckStatusID,
		O.vcRefType,
		vcName,
		fCheckAmount,
		C.iCheckID,
		O.vcDescription,
		OD.fAmount

	RETURN 0
END


