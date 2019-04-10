/****************************************************************************************************

	Fonction DE CALCUL DU MONTANT DE DÉPÔT

*********************************************************************************
	10-05-2004 Dominic Létourneau
		Migration de l'ancienne fonction selon les nouveaux standards
*********************************************************************************/
CREATE FUNCTION dbo.FN_UN_Deposit (
	@FirstUnitGroup MoBitTrue, -- Indique si c'est la 1re unité du groupe  
	@UnitQty MoMoney, -- Quantité d'unité dans le groupe
	@PmtRate MoPctPos, -- Montant versé par paiement 
	@BenefInsurRate MoPctPos, -- Taux d'assurance souscripteur
	@SubsInsurRate MoPctPos, -- Taux d'assurance souscripteur
	@HalfSubsInsurRate MoPctPos, -- Taux des anciennes demi-unités
	@StateTaxPct MoPctPos) -- Taxe de vente provinciale
RETURNS MoMoney
AS

BEGIN

	DECLARE 
		@Deposit MoMoney,
		@Cotisation MoMoney,
		@SubsInsur MoMoney,
		@BenefInsur MoMoney,
		@TaxOnInsur MoMoney
	
	-- Initialisation des variables
	SELECT 
		@Deposit = 0,
		@Cotisation = 0,
		@SubsInsur  = 0,
		@BenefInsur = 0,
		@TaxOnInsur = 0
	
	SELECT 
		@Cotisation = ROUND((@UnitQty * ISNULL(@PmtRate, 0)), 2),
		@BenefInsur = ROUND(ISNULL(@BenefInsurRate, 0), 2)
	
	IF @FirstUnitGroup = 1 
		SET @SubsInsur = ROUND((1 * ISNULL(@SubsInsurRate, 0)), 2) + 
			ROUND(((@UnitQty - 1) * ISNULL(@HalfSubsInsurRate, ISNULL(@SubsInsurRate, 0))),2)
	ELSE
		SET @SubsInsur = ROUND((@UnitQty * ISNULL(@HalfSubsInsurRate, ISNULL(@SubsInsurRate, 0))), 2)
	
	SET @TaxOnInsur = ROUND((((@SubsInsur + @BenefInsur) * ISNULL(@StateTaxPct, 0))+ 0.0049), 2) 
	
	SET @Deposit = @Cotisation + @SubsInsur + @BenefInsur + @TaxOnInsur
	
	RETURN(@Deposit)   
               
END


