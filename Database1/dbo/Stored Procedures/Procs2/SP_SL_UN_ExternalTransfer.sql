/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_SL_UN_ExternalTransfer
Description         :	Sélection, rafraîchir d'une transfert externe
Valeurs de retours  :	Dataset de données
Note                :	ADX0001283	BR	2005-02-15	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_ExternalTransfer] (
	@CotisationID INTEGER) -- ID unique de la cotisation
AS
BEGIN
	SELECT
		E.CotisationID,	
		E.ExternalPlanID,
		P.ExternalPlanGovernmentRegNo,
		E.ExternalContractID,
		E.ExternalContractDate,
		E.FullTransfert,
		E.UnassistedCapitalAmount,
		E.AssistedCapitalAmount,
		E.GovernmentGrantOldAmount,
		E.TotalAssetAmountTransfered
	FROM Un_ExternalTransfert E 
	JOIN Un_ExternalPlan P ON P.ExternalPlanID = E.ExternalPlanID
	WHERE E.CotisationID = @CotisationID
END

