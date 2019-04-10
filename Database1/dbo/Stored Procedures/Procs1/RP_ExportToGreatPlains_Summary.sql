/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc
Nom                 :	RP_ExportToGreatPlains_Summary
						
Description         :	Retourne le montant total par compte selon le type de chèque et la plage de date demandée
Valeurs de retours  :	Dataset
							

Note                :	2008-12-09	Donald Huppé
						2010-07-09	Pierre-Luc Simard	Modification des comptes pour la gestion des fiducies
						2010-08-26	Pierre-Luc Simard	Ajout du paramètre pour générer les fichiers par code de chéquier

-- exec RP_ExportToGreatPlains_Summary '2010-08-01','2010-08-31','OUT', 'FID-Reeeflex'
****************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_ExportToGreatPlains_Summary] (
	@DateFrom MoDateOption,  
	@DateTo MoDateOption,
	@Type nvarchar(20),
	@vcCode_Chequier nvarchar(50)) -- Code de chéquier dans Great Plains) 
AS
BEGIN


	SELECT
		CHQ.Compte,
		Montant = sum(CHQ.Montant)
	FROM (
		SELECT 
			CHQ_Check.iCheckNumber AS NoCheque, 
			CHQ_OperationDetail.vcAccount AS Compte, 
			Sum(-CHQ_OperationDetail.fAmount) AS Montant
		FROM 
			CHQ_Check 
			JOIN CHQ_CheckOperationDetail ON CHQ_Check.iCheckID = CHQ_CheckOperationDetail.iCheckID 
			JOIN CHQ_OperationDetail ON CHQ_CheckOperationDetail.iOperationDetailID = CHQ_OperationDetail.iOperationDetailID 
			JOIN CHQ_Operation ON CHQ_OperationDetail.iOperationID = CHQ_Operation.iOperationID 
			JOIN Un_OperLinkToCHQOperation ON CHQ_Operation.iOperationID = Un_OperLinkToCHQOperation.iOperationID
			LEFT JOIN Un_Plan P ON P.PlanID = CHQ_Check.iID_Regime
			LEFT JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		WHERE ISNULL(RR.vcCode_Chequier_GreatPlains,'ROYALE') = @vcCode_Chequier 
		GROUP BY 
			CHQ_Check.iCheckNumber, 
			CHQ_OperationDetail.vcAccount, 
			CHQ_Check.dtEmission, 
			CHQ_Operation.vcRefType, 
			CHQ_Check.iCheckStatusID
		HAVING 
			CHQ_OperationDetail.vcAccount NOT IN ('00-1100-0-00','00-1105-1-00','00-1105-2-00','00-1105-3-00') 
			AND CHQ_Check.iCheckStatusID = 4
			AND CHQ_Check.dtEmission Between @DateFrom And @DateTo
			AND (
				(@Type = 'RIN' AND CHQ_Operation.vcRefType = 'RIN' ) OR
				(@Type = 'Bourses' AND CHQ_Operation.vcRefType in ('PAE','RGC','AVC') ) OR
				(@Type = 'RES' AND CHQ_Operation.vcRefType = 'RES' ) OR
				(@Type = 'RET' AND CHQ_Operation.vcRefType = 'RET' ) OR
				(@Type = 'OUT' AND CHQ_Operation.vcRefType = 'OUT' )
				)
		) CHQ
	GROUP BY
		CHQ.Compte

END

