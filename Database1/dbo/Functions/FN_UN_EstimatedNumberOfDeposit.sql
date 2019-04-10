
/****************************************************************************************************
Copyright (c) 2006 Gestion Universitas.Inc
Nom 					:	FN_UN_EstimatedNumberOfDeposit
Description 		:	FONCTION RETOURNANT LE NOMBRE DE DÉPÔTS ENTRE 2 DATES
Valeurs de retour	:	Nombre de dépôt
Note					:	
					25-06-2003	Marc W.					Modification et documentation
 					15-07-2003	Bruno Lapointe			Optimisation
 					12-11-2003	Bruno Lapointe			Si la date de départ est plus petite ou égale à la date de vigueur, on 
 																prend la date estimée du premier dépôt comme date de départ.
 					16-04-2004	Dominic Létourneau	Migration de l'ancienne fonction selon les nouveaux standards
					2004-04-29	Bruno	Lapointe			Correction du bug dans le calcul de la date du premier dépôt estimé	
ADX0002630	BR	2007-05-30	Bruno	Lapointe			Si @PmtQty = 1 alors on utilise la date d'entrée en vigueur de la 
																convention comme date de prochain dépôt	
*******************************************************************************************************************/
CREATE FUNCTION [dbo].[FN_UN_EstimatedNumberOfDeposit] (
	@StartDate	MoDate, -- Date de début
	@EndDate	MoDate, -- Date de fin     
	@PmtDay	MoID, -- Jour du paiement       
	@PmtByYearID	MoPmtByYear, -- Nombre de paiements par année
	@PmtQty	MoID, -- Total du nombre de dépôts pour un groupe d'unités
	@InForceDate	MoDate -- Date d'entrée en vigueur
)  

RETURNS MoID
AS

BEGIN

	DECLARE
		@NextDepositDate MoDate, -- Date du premier dépôt de la période 
		@ReturnQty MoID -- Valeur de retour 
  
	IF @StartDate = 0 OR @EndDate = 0
		RETURN(0)
 
	-- Si la date de départ est plus petite ou égale à la date de vigueur, 
	-- on prend la date estimée du premier dépôt comme date de départ
	IF @StartDate <= @InForceDate
		SELECT @NextDepositDate = 
			CASE
				WHEN @PmtQty = 1 THEN @InForceDate
			   WHEN 
					CASE MONTH(@InForceDate) 
						WHEN 12 THEN CONVERT(VARCHAR(4), YEAR(@InForceDate)) + '1231' 
						ELSE CONVERT(VARCHAR(8), CONVERT(DATETIME, CONVERT(VARCHAR(4), YEAR(@InForceDate)) + '-' + RIGHT('0' + CONVERT(varchar(2), MONTH(@InForceDate) + 1),2) + '-01')-1, 112) 
					END < CAST(YEAR(CONVERT(DATETIME, @InForceDate)) AS VARCHAR(4)) + RIGHT('0' + CAST(MONTH(CONVERT(datetime, @InForceDate)) AS VARCHAR(2)),2) + RIGHT('0' + CAST(@PmtDay AS VARCHAR(2)),2)
				THEN 
					CASE MONTH(@InForceDate) 
						WHEN 12 THEN CONVERT(VARCHAR(4), YEAR(@InForceDate)) + '1231' 
						ELSE CONVERT(VARCHAR(8), CONVERT(DATETIME, CONVERT(VARCHAR(4), YEAR(@InForceDate)) + '-' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@InForceDate) + 1),2) + '-01')-1, 112) 
					END
				ELSE CAST(YEAR(CONVERT(DATETIME, @InForceDate)) AS VARCHAR(4)) + RIGHT('0' + CAST(MONTH(CONVERT(DATETIME, @InForceDate)) AS VARCHAR(2)),2) + RIGHT('0' + CAST(@PmtDay AS VARCHAR(2)),2)
			END
	ELSE
		SET @NextDepositDate = 
			CASE 
				WHEN @PmtQty = 1 THEN @InForceDate
				WHEN (MONTH(@InForceDate) % (12/@PmtByYearID)) = 0 THEN
					CASE 
						WHEN DATEADD(MONTH, ((12/@PmtByYearID)) + ((MONTH(@StartDate) - ((12/@PmtByYearID)))-((MONTH(@StartDate) - ((12/@PmtByYearID))) % (12/@PmtByYearID)))-1, DATEADD(DAY, @PmtDay-1, DATEADD(YEAR, YEAR(@StartDate)-1900, 0))) < @StartDate THEN
							DATEADD(MONTH, (12/@PmtByYearID) + ((12/@PmtByYearID)) + ((MONTH(@StartDate) - ((12/@PmtByYearID)))-((MONTH(@StartDate) - ((12/@PmtByYearID))) % (12/@PmtByYearID)))-1, DATEADD(DAY, @PmtDay-1, DATEADD(YEAR, YEAR(@StartDate)-1900, 0))) 
						ELSE DATEADD(MONTH, ((12/@PmtByYearID)) + ((MONTH(@StartDate) - ((12/@PmtByYearID)))-((MONTH(@StartDate) - ((12/@PmtByYearID))) % (12/@PmtByYearID)))-1, DATEADD(DAY, @PmtDay-1, DATEADD(YEAR, YEAR(@StartDate)-1900, 0))) 
					END
			ELSE 
				CASE 
					WHEN DATEADD(MONTH, (MONTH(@InForceDate) % (12/@PmtByYearID)) + ((MONTH(@StartDate) - (MONTH(@InForceDate) % (12/@PmtByYearID)))-((MONTH(@StartDate) - (MONTH(@InForceDate) % (12/@PmtByYearID))) % (12/@PmtByYearID)))-1, DATEADD(DAY, @PmtDay-1, DATEADD(YEAR, YEAR(@StartDate)-1900, 0))) < @StartDate THEN
						DATEADD(MONTH, (12/@PmtByYearID) + (MONTH(@InForceDate) % (12/@PmtByYearID)) + ((MONTH(@StartDate) - (MONTH(@InForceDate) % (12/@PmtByYearID)))-((MONTH(@StartDate) - (MONTH(@InForceDate) % (12/@PmtByYearID))) % (12/@PmtByYearID)))-1, DATEADD(DAY, @PmtDay-1, DATEADD(YEAR, YEAR(@StartDate)-1900, 0))) 
					ELSE DATEADD(MONTH, (MONTH(@InForceDate) % (12/@PmtByYearID)) + ((MONTH(@StartDate) - (MONTH(@InForceDate) % (12/@PmtByYearID)))-((MONTH(@StartDate) - (MONTH(@InForceDate) % (12/@PmtByYearID))) % (12/@PmtByYearID)))-1, DATEADD(DAY, @PmtDay-1, DATEADD(YEAR, YEAR(@StartDate)-1900, 0))) 
				END
			END 

	IF @NextDepositDate > @EndDate
		SET @ReturnQty = 0
	ELSE IF DAY(@EndDate) >= DAY(@NextDepositDate)  
		SET @ReturnQty = FLOOR(DATEDIFF(MONTH, @NextDepositDate, @EndDate) / (12/@PmtByYearID)) +1
	ELSE
		SET @ReturnQty = FLOOR((DATEDIFF(MONTH, @NextDepositDate, @EndDate)-1) / (12/@PmtByYearID)) +1

	IF @ReturnQty > @PmtQty 
		SET @ReturnQty = @PmtQty
	
	RETURN(@ReturnQty)
END

