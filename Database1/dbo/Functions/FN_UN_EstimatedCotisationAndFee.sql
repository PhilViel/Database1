
-- *******************************************************************************
-- 
-- 	FONCTION RETOURNANT LE MONTANT DÛ DE DÉPÔT ENTRE 2 DATES
-- 
-- *******************************************************************************
-- 	25-06-2003 Marc W.     
--			Modification et documentation
-- 	17-10-2003 Bruno Lapointe
-- 		Traitement d'une exeption pour corriger les avis de retard
-- 	12-11-2003 Bruno Lapointe
-- 		Enlever les modifications faites le 17-10-2003 puisque le cas est 
-- 		désormais géré dans la function fn_Un_EstimatedNumberOfDeposit.
-- 	20-04-2004 Dominic Létourneau
-- 		Migration de l'ancienne fonction selon les nouveaux standards
-- *******************************************************************************
CREATE FUNCTION dbo.FN_UN_EstimatedCotisationAndFee (
	@StartDate MoDate, -- Date de départ
	@EndDate MoDate, -- Date de fin
	@PaymentDay MOID, -- Jour de paiement        
	@UnitQty MoMoney, -- Nombre d'unités  
	@PmtRate MoPctPos, -- Montant de paiement par unité 
	@PmtByYearID MoPmtByYear, -- Nombre de dépôt par année
	@PmtQty MoID, -- Nombre de dépôt total pour un groupe d'unité       
	@InForceDate MoDate -- Date d'entrée en vigueur  
)  
RETURNS MoMoney
AS

BEGIN
	/* Validation des valeurs des paramètres */
	IF (@UnitQty = 0) or (@PmtRate = 0) 
		RETURN(0) -- Données incorrectes
	
	/* Calcul du montant estimé de cotisation et de frais */
	RETURN( ROUND(@UnitQty * ISNULL(@PmtRate, 0),2) * dbo.FN_UN_EstimatedNumberOfDeposit( -- fonction retournant le nombre de dépôts entre 2 dates
																			@StartDate,
																			@EndDate,
																			@PaymentDay,
																			@PmtByYearID,
																			@PmtQty, 
																			@InForceDate))                  

END

