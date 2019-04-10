
/****************************************************************************************************
Copyright (c) 2006 Gestion Universitas.Inc
Nom 				:	fn_Un_LastDepositDate
Description 		:	Fonction calculant la date du dernier dépôt
Valeurs de retour	:	Table temporaire
Note				:	
									02-09-2003	Bruno Lapointe  Création
					ADX0001374	IA	2007-05-30	Alain Quirion	Si @FPmtQty = 1 alros on retuorne la date d'entrée en vigueur de la convention	
*********************************************************************************/
CREATE FUNCTION dbo.fn_Un_LastDepositDate 
(
  @FInForceDate     DATETIME,      --Date de vigueur (Un_Unit.InForceDate)
  @FFirstPmtDate    DATETIME,      --Date de paiement (Un_Convention.FirstPmtDate)
  @FPmtQty          INTEGER,        --Nombre de paiement (Un_Modal.PmtQty)
  @FPmtByYearID     INTEGER         --Nombre de paiement par année (Un_Modal.PmtByYearID)
)  
RETURNS DATETIME -- Retourne la date du dernier dépôt.
AS  
BEGIN
	DECLARE @Y INTEGER,
			@M INTEGER, 
			@D INTEGER,
			@NbMonth INTEGER,
			@LastDepositDate DATETIME

	SET @LastDepositDate = NULL

	IF @FPmtQty = 1
	BEGIN
		SET @LastDepositDate = @FInForceDate
	END 
	
	ELSE IF @FPmtByYearID = 1 
		SET @LastDepositDate = DATEADD(YEAR, (YEAR(@FInForceDate)+@FPmtQty-1901),DATEADD(MONTH, MONTH(@FFirstPmtDate)-1, DATEADD(DAY, DAY(@FFirstPmtDate), '1899-12-31')))
	ELSE
	BEGIN		
		SET @Y = YEAR(@FInForceDate)
		SET @M = MONTH(@FInForceDate)
		SET @D = DAY(@FFirstPmtDate)

		IF @FPmtByYearID = 0
			SET @NbMonth = 0
		ELSE
			SET @NbMonth = FLOOR((@FPmtQty-1) * (12/@FPmtByYearID))	 
	   
		SET @Y = @Y + FLOOR(@NbMonth/12)
		SET @NbMonth = @NbMonth - (FLOOR(@NbMonth/12)*12)
	   
		-- Gére le cas ou le jour de paiement de la convention n'est pas un jour
		-- existant dans tous les mois.
		IF ((@NbMonth + @M) IN (2,14)) AND (@D > 28) 
			SET @D = 28
		ELSE IF ((@NbMonth + @M) IN (4,6,9,11,16,18,21,23)) AND (@D > 30) 
			SET @D = 30

		IF (@NbMonth + @M) > 12 
			SET @LastDepositDate = DATEADD(YEAR, @Y-1899,DATEADD(MONTH, (@NbMonth + @M) - 13, DATEADD(DAY, @D, '1899-12-31')))
		ELSE
			SET @LastDepositDate = DATEADD(YEAR, @Y-1900,DATEADD(MONTH, (@NbMonth + @M) - 1, DATEADD(DAY, @D, '1899-12-31')))
	END

	RETURN @LastDepositDate
END

