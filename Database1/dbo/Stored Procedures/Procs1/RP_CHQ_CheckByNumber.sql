/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	RP_CHQ_CheckByNumber
Description         :	Procédure qui retournera la liste des chèques par numéro
Valeurs de retours  :	Dataset :
					iCheckNumber		Le numéro tel qu'imprimé sur le chèque
					dtEmission		La date d'émission du chèque
					vcName			Le destinataire
					vcRefType		Le type d'opération qui genère le chèque
					fCheckAmount		Le montant du chèque
					vcStatusDescription	Le statut de chèque
					vcReason		La raison de l'historique

Note                :	ADX0000715	IA	2005-09-06	Bernie MacIntyre			Création
								ADX0001058	IA	2006-08-01	Alain Quirion		Modification : Renvoi seulement le nom s'il s'agit d'une compagnie
								ADX0001421	IA	2007-06-12	Bruno Lapointe		Afficher les numéros de chèques manquant.
												2010-06-10	Donald Huppé		Ajout des régime et groupe de régime
												2011-01-05	Donald Huppé		gérer @iID_regroupement_Regime=0(eu lieu de NULL) pour "Sans regroupement de régime"
exec RP_CHQ_CheckByNumber 75000,75876, 0

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_CHQ_CheckByNumber](
	@iStartNumber int,	-- Le numéro de début de recherche
	@iEndNumber int,	-- Le numéro de fin de recherche
	@iID_regroupement_Regime int)
AS
BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT
		GrRegimne = RR.vcDescription,
		Regime = P.PlanDesc,
		C.iCheckNumber,
		dtEmission = dbo.FN_CRQ_DateNoTime(C.dtEmission),
		vcName = 
			CASE 
				WHEN OD.iOperationID IS NULL THEN ''
				WHEN H.IsCompany = 0 THEN ISNULL(H.LastName,'') + ', ' + ISNULL(H.FirstName,'')
				WHEN H.IsCompany = 1 THEN ISNULL(H.LastName,'')
			END,
		vcRefType = ISNULL(O.vcRefType,''),
		fCheckAmount = C.fAmount,
		CS.vcStatusDescription,
		CH.vcReason
	FROM CHQ_Check C -- select * from CHQ_Check
	LEFT JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
	LEFT JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
	LEFT JOIN CHQ_Operation O ON OD.iOperationID = O.iOperationID
	LEFT JOIN (
		SELECT
			OP.iOperationID,
			iOperationPayeeID = MAX(iOperationPayeeID)
		FROM CHQ_OperationPayee OP
		WHERE OP.iPayeeChangeAccepted = 1
		GROUP BY OP.iOperationID
		) VOP ON O.iOperationID = VOP.iOperationID
	LEFT JOIN CHQ_OperationPayee OP ON OP.iOperationPayeeID = VOP.iOperationPayeeID
	JOIN (
		SELECT 
			CH.iCheckID,
			iCheckHistoryID = MAX(CH.iCheckHistoryID)
		FROM CHQ_CheckHistory CH
		JOIN (
			SELECT
				iCheckID,
				dtHistory = MAX(dtHistory)
			FROM CHQ_CheckHistory
			GROUP BY iCheckID
			) V ON V.iCheckID = CH.iCheckID AND V.dtHistory = CH.dtHistory
		GROUP BY CH.iCheckID
		) MCH ON MCH.iCheckID = C.iCheckID
	JOIN CHQ_CheckHistory CH ON CH.iCheckHistoryID = MCH.iCheckHistoryID
	JOIN CHQ_CheckStatus CS ON CH.iCheckStatusID = CS.iCheckStatusID
	LEFT JOIN dbo.Mo_Human H ON OP.iPayeeID = H.HumanID
	
	LEFT JOIN UN_PLAN P ON P.PlanID = C.iID_Regime
	LEFT JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	
	WHERE 
		(C.iCheckNumber BETWEEN @iStartNumber AND @iEndNumber)
		AND ( 
				(@iID_regroupement_Regime <> 0 AND RR.iID_regroupement_Regime = @iID_regroupement_Regime)
				OR
				(@iID_regroupement_Regime = 0 AND RR.iID_regroupement_Regime is NULL)
			)
	ORDER BY C.iCheckNumber

	RETURN 0
END


