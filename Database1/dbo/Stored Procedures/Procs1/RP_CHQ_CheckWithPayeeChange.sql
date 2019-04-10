/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	RP_CHQ_CheckWithPayeeChange
Description         :	Procédure qui retournera les chèques ayant un changement de destinataire sur opérations
Valeurs de retours  :	Dataset :
									iCheckID			ID du chèque
									dtEmission			La date d'émission du chèque
									vcStatusDescription		Le statut de chèque
									iCheckNumber			Le numéro tel qu'imprimé sur le chèque
									vcName				Le destinataire
									vcRefType			Le type d'opération qui genère le chèque
									fCheckAmount			Le montant du chèque
									vcOriginalName			Nom du destinataire original
									vcReason				Raison du changement de destinataire
									vcDescription			La description de l'opération (convention)
									fOperAmount			Le montant de l'opération
									
Note                :	ADX0000715	IA	2005-09-06	Bernie MacIntyre	Création
						ADX0001969	BR	2006-06-09	Bruno Lapointe		Modification : Changé destinataire proposé pour destinataire original.
						ADX0001058	IA	2006-08-01	Alain Quirion		Modification : Renvoi seulement le nom s'il s'agit d'une compagnie
										2010-06-10	Donald Huppé		Ajout des régime et groupe de régime
										2010-08-10	Donald Huppé		enlever paramètre de groupe de régime, mais on conserve régime et groupe de régime dans le dataset retourné
										
exec RP_CHQ_CheckWithPayeeChange '2009-01-01','2010-06-15','AVC;OUT;PAE;RES;RET;RGC;RIN;TFR','1;2;3;4;5',3
										
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_CHQ_CheckWithPayeeChange](
	@dtStart datetime,		-- La date de début de recherche 
	@dtEnd datetime,		-- La date de fin din recherche
	@vcRefType varchar(255),	-- Liste délimitée des types d'opérations (AVC;OUT)
	@vcStatusIDs varchar(255)	-- Liste délimitées des statuts de chèque (1;2 i.e. Proposé et Accepté)
	/*@iID_regroupement_Regime int*/ )
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		C.iCheckID,
		dtEmission = dbo.FN_CRQ_DateNoTime(C.dtEmission),
		CS.vcStatusDescription,
		C.iCheckNumber,
		vcName = 
			CASE H.IsCompany 
				WHEN 0 THEN ISNULL(H.LastName,'') + ', ' + ISNULL(H.FirstName,'')
				WHEN 1 THEN ISNULL(H.LastName,'')
			END,
		O.vcRefType,
		fCheckAmount = C.fAmount,
		vcOriginalName = 
			CASE HOrig.IsCompany
				WHEN 0 THEN
					CASE
						WHEN HOrig.LastName IS NULL AND HOrig.FirstName IS NULL THEN ''
						ELSE ISNULL(HOrig.LastName,'') + ', ' + ISNULL(HOrig.FirstName,'')
					END
				WHEN 1 THEN
					ISNULL(HOrig.LastName,'')
			END,
		OPProp.vcReason,
		O.vcDescription,
		fOperAmount = OD.fAmount,
		Regime = isnull(P.PlanDesc,'ND'),
		GrRegime = isnull(RR.vcDescription,'ND')
	FROM (
		SELECT DISTINCT
			C.iCheckID
		FROM CHQ_Check C
		JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
		JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
		JOIN CHQ_Operation O ON OD.iOperationID = O.iOperationID
		JOIN (
			SELECT
				iOperationID
			FROM CHQ_OperationPayee
			GROUP BY iOperationID
			HAVING COUNT(iOperationPayeeID) > 1
			) VOP ON O.iOperationID = VOP.iOperationID
		WHERE	C.dtEmission BETWEEN @dtStart AND @dtEnd
			AND O.vcRefType IN (SELECT VarCharValue FROM dbo.FN_CRI_ParseTextToTable(@vcRefType, ';'))
			AND C.iCheckStatusID IN (SELECT IntegerValue FROM dbo.FN_CRI_ParseTextToTable(@vcStatusIDs, ';'))
		) V
	JOIN CHQ_Check C ON V.iCheckID = C.iCheckID
	JOIN CHQ_CheckOperationDetail COD ON COD.iCheckID = C.iCheckID
	JOIN CHQ_OperationDetail OD ON OD.iOperationDetailID = COD.iOperationDetailID
	JOIN CHQ_Operation O ON OD.iOperationID = O.iOperationID AND OD.vcAccount = O.vcAccount
	JOIN (
		SELECT
			iOperationID,
			iOperationPayeeID = 
				MAX(
					CASE 
						WHEN iPayeeChangeAccepted = 1 THEN iOperationPayeeID
					ELSE 0
					END),
			iOperationPayeeIDOrig = 
				CASE
					WHEN COUNT(iOperationPayeeID) = 1 THEN 0
				ELSE MIN(iOperationPayeeID)
				END,
			iOperationPayeeIDProp = 
				CASE
					WHEN COUNT(iOperationPayeeID) = 1 THEN 0
				ELSE MAX(iOperationPayeeID)
				END
		FROM CHQ_OperationPayee
		GROUP BY iOperationID
		) VOP ON O.iOperationID = VOP.iOperationID
	JOIN CHQ_OperationPayee OP ON OP.iOperationPayeeID = VOP.iOperationPayeeID
	LEFT JOIN CHQ_OperationPayee OPOrig ON OPOrig.iOperationPayeeID = VOP.iOperationPayeeIDOrig
	LEFT JOIN CHQ_OperationPayee OPProp ON OPProp.iOperationPayeeID = VOP.iOperationPayeeIDProp
	JOIN CHQ_CheckStatus CS ON C.iCheckStatusID = CS.iCheckStatusID
	JOIN dbo.Mo_Human H ON OP.iPayeeID = H.HumanID
	LEFT JOIN dbo.Mo_Human HOrig ON OPOrig.iPayeeID = HOrig.HumanID
	
	LEFT JOIN UN_PLAN P ON P.PlanID = C.iID_Regime
	LEFT JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime

/*
	WHERE	( 
			(@iID_regroupement_Regime IS NOT NULL AND RR.iID_regroupement_Regime = @iID_regroupement_Regime)
			OR
			(@iID_regroupement_Regime IS NULL AND RR.iID_regroupement_Regime is NULL)
			)
*/	
	ORDER BY 
		isnull(RR.vcDescription,'ND'),
		isnull(P.PlanDesc,'ND'),
		C.iCheckNumber, 
		C.iCheckStatusID,
		C.iCheckID,
		O.vcRefType,
		vcName,
		fCheckAmount,
		O.vcDescription,
		fOperAmount

	RETURN 0
END


