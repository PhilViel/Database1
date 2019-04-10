/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service        : fnConv_DateRemboursementIntegralePourConvention
Nom du service         : Retourne la date de remboursement integral pour une convention
But                    : Calculer en un appel la date de remboursement integral

Paramètres d’entrée    :    
    Paramètre                    Description
    --------------------    ------------------------------------------------------------------------------------------
	@ConventionId           Id de la convention dont on veut calculer la date de RI    

Exemple d’appel     :   fnConv_DateRemboursementIntegralePourConvention(495958)

Historique des modifications:
    Date            Programmeur                Description                                                    Référence
    ----------      --------------------    ---------------------------------------------------------   --------------
    2016-02-25      Dominique Pothier			Création
**********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnConv_DateRemboursementIntegralePourConvention]
(
	@ConventionId int
)
RETURNS DATETIME
AS
BEGIN
	declare @dateRemboursement DateTime

	;With CTE_GroupeUnite as(
		Select Conv.ConventionId, Unit.UnitId, Modal.PmtByYearID, Modal.PmtQty, Modal.BenefAgeOnBegining, Unit.InForceDate,Plans.IntReimbAge, Unit.IntReimbDateAdjust
		From Un_Convention Conv
			join Un_Unit Unit on Unit.ConventionID = Conv.ConventionID 
			join Un_Modal Modal on Modal.ModalID = Unit.ModalId
			join Un_Plan Plans on Plans.PlanID = Modal.PlanID
		where Conv.ConventionID = @ConventionId
	),
	CTE_DatesRemboursementIntegralParGroupeUnite as(
	  Select ConventionId, 
			 UnitID,
	         dateRemboursement = dbo.FN_UN_EstimatedIntReimbDate(PmtByYearID,PmtQty,BenefAgeOnBegining,
																 InForceDate,IntReimbAge,IntReimbDateAdjust)
	  from CTE_GroupeUnite
	)
	Select @dateRemboursement = Min(dateRemboursement)
	from CTE_DatesRemboursementIntegralParGroupeUnite
	group by ConventionID

	-- Return the result of the function
	RETURN @dateRemboursement

END
