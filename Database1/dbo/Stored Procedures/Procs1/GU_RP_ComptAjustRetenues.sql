/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	GU_RP_ComptAjustRetenues
Description         :	Rapport historique des ajustements et retenues des représentants pour la création du fichier Excel
Valeurs de retours  :	Dataset 
Note                :	Pierre-Luc Simard	2008-01-17 	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_ComptAjustRetenues]
(
	@ReptreatmentID INTEGER) -- ID du traitement de commissions)

AS
BEGIN
	SET NOCOUNT ON
	SELECT 
		Statut = --Indique si un représentant est actif (1) ou inactif (0) pour tier les données
			CASE
				WHEN Un_Rep.BusinessEnd <= Un_RepCharge.RepChargeDate THEN 0
			ELSE 1
			END,
		Un_Rep.RepCode, -- Code du représentant
		Mo_Human.LastName, -- Nom du représentant
		Mo_Human.FirstName, -- Prénom du représentant
		Un_Rep.BusinessEnd, -- Date de fin du représentant
		Un_RepCharge.RepChargeDate, -- Date de la transaction
		Un_RepChargeType.RepChargeTypeDesc, -- Type de la transaction 
		Un_RepCharge.RepChargeDesc, -- Description de la transaction
		Un_RepCharge.RepChargeAmount -- Montant de la transaction
	FROM Un_RepCharge 
	INNER JOIN Un_RepChargeType ON Un_RepCharge.RepChargeTypeID = Un_RepChargeType.RepChargeTypeID 
	INNER JOIN Un_Rep ON Un_RepCharge.RepID = Un_Rep.RepID 
	INNER JOIN dbo.Mo_Human ON Un_Rep.RepID = Mo_Human.HumanID
	WHERE Un_RepCharge.RepTreatmentID = @ReptreatmentID 
	ORDER BY CASE	WHEN Un_Rep.BusinessEnd <= Un_RepCharge.RepChargeDate THEN 0 ELSE 1 END, Un_RepChargeType.RepChargeTypeDesc, Un_Rep.RepCode
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GU_RP_ComptAjustRetenues] TO [Rapport]
    AS [dbo];

