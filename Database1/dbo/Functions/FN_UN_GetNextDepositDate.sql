-- *******************************************************************************
-- 
-- 	FONCTION QUI RETOURNE LA PROCHAINE DATE DE DÉPÔT PAR RAPPORT À UNE AUTRE DATE
-- 
-- *******************************************************************************
-- 	2004-04-19 Dominic Létourneau
-- 		Migration de l'ancienne fonction selon nouveaux standards
-- *******************************************************************************
CREATE FUNCTION dbo.FN_UN_GetNextDepositDate (  
	@InputDate MoDate, -- Date à laquelle on se base pour calculer la prochaine date de paiement
	@InForceDate MoDate, -- Date d'entrée en vigueur de l'unité
	@PmtByYear MoID, -- Nombre de paiements par année
	@PmtDay MoID) -- Jour du paiement
RETURNS MoDate
AS

BEGIN

	DECLARE 
		@MonthToAdd MoID,
		@NextPmtDate MoDate

	/* Vérification des valeurs des paramètres */
	IF (@InputDate IS NOT NULL) OR (@InForceDate IS NOT NULL) OR (@PmtByYear IS NOT NULL) OR (@PmtDay BETWEEN 1 AND 28) 
	BEGIN -- Les paramètres sont valides

		IF DAY(@InputDate) > @PmtDay -- Si le jour de InputDate est plus grand que le jour de paiement
			SET @InputDate = DATEADD ( Month, 1, @InputDate ) -- Ajout d'un mois à la date de calcul
		
		SET @MonthToAdd = (MONTH(@InputDate) - MONTH(@InForceDate)) % (12/@PmtByYear) -- Calcul le nombre de mois à ajouter
		
		IF @MonthToAdd > 0 
			SET @MonthToAdd = (12/@PmtByYear) - @MonthToAdd
		ELSE    
			SET @MonthToAdd = ABS(@MonthToAdd)
		
		SET @InputDate = (@InputDate - DAY(@InputDate)) + @PmtDay -- Le jour de la date de calcul devient le jour de paiement

		SET @NextPmtDate = DATEADD ( Month, @MonthToAdd, @InputDate ) -- Ajout du nombre de mois à la nouvelle date de calcul
	END
	ELSE /* Au moins un des paramètres est invalide */
		SET @NextPmtDate = 0
	
	/* Retour de la date */
	RETURN(@NextPmtDate)

END

