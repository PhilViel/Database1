/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc
Nom                 :	RP_ExportToGreatPlains_GetTotal
						
Description         :	Retourne le nb de chèques et le montant total selon le type de chèque et la plage de date demandée
Valeurs de retours  :	Dataset
							

Note                :	2008-12-09	Donald Huppé
						2010-08-26	Pierre-Luc Simard	Ajout du paramètre pour générer les fichiers par code de chéquier

-- exec RP_ExportToGreatPlains_GetTotal '2010-08-01','2010-08-31','OUT', 'FID-Reeeflex'
****************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_ExportToGreatPlains_GetTotal] (
	@DateFrom MoDateOption,  
	@DateTo MoDateOption,
	@Type nvarchar(20),
	@vcCode_Chequier nvarchar(50)) -- Code de chéquier dans Great Plains 
AS
BEGIN

	SELECT 
		nb_cheque = count(*),
		montant_total = sum(CHQ.fAmount)
	FROM (

		SELECT 
			distinct
			CHQ_Check.iCheckNumber, 
			CHQ_Check.fAmount
		FROM 
			CHQ_Check 
			JOIN CHQ_CheckOperationDetail ON CHQ_Check.iCheckID = CHQ_CheckOperationDetail.iCheckID
			JOIN CHQ_OperationDetail ON CHQ_CheckOperationDetail.iOperationDetailID = CHQ_OperationDetail.iOperationDetailID
			JOIN CHQ_Operation ON CHQ_OperationDetail.iOperationID = CHQ_Operation.iOperationID
			LEFT JOIN Un_Plan P ON P.PlanID = CHQ_Check.iID_Regime
			LEFT JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		WHERE 
			CHQ_Check.dtEmission between @DateFrom and @DateTo
			AND CHQ_Check.iCheckStatusID=4
			AND ISNULL(RR.vcCode_Chequier_GreatPlains,'ROYALE') = @vcCode_Chequier 	
			AND (
				(@Type = 'RIN' AND CHQ_Operation.vcRefType = 'RIN' ) OR
				(@Type = 'Bourses' AND CHQ_Operation.vcRefType in ('PAE','RGC','AVC') ) OR
				(@Type = 'RES' AND CHQ_Operation.vcRefType = 'RES' ) OR
				(@Type = 'RET' AND CHQ_Operation.vcRefType = 'RET' ) OR
				(@Type = 'OUT' AND CHQ_Operation.vcRefType = 'OUT' )
				)
		
		)CHQ

END
