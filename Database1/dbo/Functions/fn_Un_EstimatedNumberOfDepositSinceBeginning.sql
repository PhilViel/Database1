/****************************************************************************************************
  Description : Cette fonction retourne le nombre de dépôt entre depuis le début
               d'un groupe d'unités jusqu'à une date passé en paramètre. 

  Variables :
   @FToDate      : Date de fin
   @FPaymentDay  : Jour de paiement 
   @FPmtByYearID : Nombre de dépôt par année  
   @FPmtQty      : Nombre de dépôt total pour un groupe d'unité
   @InForceDate  : Date vigueur 
                                        
 ******************************************************************************                                    
  12-11-2003 Bruno           Création (Optimisation)
 ******************************************************************************/
CREATE FUNCTION dbo.fn_Un_EstimatedNumberOfDepositSinceBeginning
(
  @FToDate          MoDate,      
  @FPaymentDay      MoID,        
  @FPmtByYearID     MoPmtByYear, 
  @FPmtQty          MoID,        
  @InForceDate      MoDate       
)  
RETURNS MoID 
AS  
BEGIN
DECLARE
  @NextDepositDate MoDate, -- Date du premier dépôt de la période 
  @iPmtQty         MoID;   -- Paramêtre de retour 
  
  IF (@FToDate = 0) 
    RETURN(0)
  
  SET @NextDepositDate = CAST(CAST(YEAR(@InForceDate) AS VARCHAR(4))+'-'+CAST(MONTH(@InForceDate) AS VARCHAR(2))+'-'+CAST(@FPaymentDay AS VARCHAR(2)) AS DATETIME)

  IF @NextDepositDate > @FToDate
    SET @iPmtQty = 0
  ELSE IF DAY(@FToDate) >= DAY(@NextDepositDate)  
    SET @iPmtQty = FLOOR(DATEDIFF(MONTH, @NextDepositDate, @FToDate) / (12/@FPmtByYearID)) +1
  ELSE
    SET @iPmtQty = FLOOR((DATEDIFF(MONTH, @NextDepositDate, @FToDate)-1) / (12/@FPmtByYearID)) +1


  IF @iPmtQty > @FPmtQty 
    SET @iPmtQty = @FPmtQty;

  RETURN(@iPmtQty);
END

