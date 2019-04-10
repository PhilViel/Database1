/****************************************************************************************************
Copyright (c) 2006 Gestion Universitas Inc
Nom 			:	FN_UN_EstimatedIntReimbDate
Description 		:	Fonction qui permet de caculer la date estimée du remboursement  intégral
Valeurs de retour	:	Table temporaire
Note			:	ADX0000808	IA	2006-04-20	Bruno Lapointe	Création
				ADX0000983	IA	2006-05-15	Mireya Gonthier Modification
				ADX0001114	IA	2006-11-17	Alain Quirion 	Ajout du paramètre @fIntReimbDateAdjust	
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_EstimatedIntReimbDate (
	@fPmtByYearID MoPmtByYear,
	@fPmtQty INTEGER,
	@fBenefAgeOnBegining INTEGER,
	@fInForceDate DATETIME,
	@fIntReimbAge SMALLINT,
	@fIntReimbDateAdjust DATETIME )  
RETURNS DATETIME 
AS
BEGIN
	DECLARE
		@iAge INTEGER,
		@dtEstimatedIntReimb DATETIME

	IF @fIntReimbDateAdjust IS NOT NULL
		SET @dtEstimatedIntReimb = @fIntReimbDateAdjust
	ELSE
	BEGIN
		IF (ROUND(@fPmtQty / @fPmtByYearID,0)+@fBenefAgeOnBegining) > @fIntReimbAge
		BEGIN
			IF @fPmtByYearID = 1 AND @fPmtQty > 1 -- Si c'est un annuel
				SET @iAge = @fIntReimbAge
			ELSE
				SET @iAge = ROUND(@fPmtQty / @fPmtByYearID,0)+@fBenefAgeOnBegining
		END
		ELSE
			SET @iAge = @fIntReimbAge
		-- si la date d'entrée en vigueur avant le 1er mai 2006
		IF @fInForceDate < '05-01-2006'
		BEGIN
			IF MONTH(@fInForceDate) <= 4 
				SET @dtEstimatedIntReimb = '05-01-'+CAST(YEAR(@fInForceDate)+(@iAge-@fBenefAgeOnBegining) AS CHAR(4))
			ELSE IF MONTH(@fInForceDate) > 10 
				SET @dtEstimatedIntReimb = '05-01-'+CAST(YEAR(@fInForceDate)+(@iAge-@fBenefAgeOnBegining)+1 AS CHAR(4))
			ELSE
				SET @dtEstimatedIntReimb = '11-01-'+CAST(YEAR(@fInForceDate)+(@iAge-@fBenefAgeOnBegining) AS CHAR(4))
		END
		-- Si la date d'entrée en vigueur est égale ou supérieur au 1er mai 2006			
		ELSE
		BEGIN	-- 15 janv - 14 mai
			IF @fInForceDate >= '01-15-'+CAST(YEAR(@fInForceDate) AS CHAR(4))AND @fInForceDate <= '05-14-'+CAST(YEAR(@fInForceDate) AS CHAR(4))
				SET @dtEstimatedIntReimb = '05-15-'+CAST(YEAR(@fInForceDate)+(@iAge-@fBenefAgeOnBegining) AS CHAR(4)) 
			-- 15 mai - 14 sept 
			ELSE IF @fInForceDate >= '05-15-'+CAST(YEAR(@fInForceDate) AS CHAR(4))AND @fInForceDate <= '09-14-'+CAST(YEAR(@fInForceDate) AS CHAR(4))
				SET @dtEstimatedIntReimb = '09-15-'+CAST(YEAR(@fInForceDate)+(@iAge-@fBenefAgeOnBegining) AS CHAR(4))
			--15 sept - 31 dec 
			ELSE IF @fInForceDate >= '09-15-'+CAST(YEAR(@fInForceDate) AS CHAR(4))AND @fInForceDate <= '12-31-'+CAST(YEAR(@fInForceDate) AS CHAR(4))
				SET @dtEstimatedIntReimb = '01-15-'+CAST(YEAR(@fInForceDate)+(@iAge-@fBenefAgeOnBegining)+1 AS CHAR(4))
			--01 janv - 14 janv
			ELSE
				SET @dtEstimatedIntReimb = '01-15-'+CAST(YEAR(@fInForceDate)+(@iAge-@fBenefAgeOnBegining) AS CHAR(4))
		END
	END	
	
	RETURN(@dtEstimatedIntReimb)
END


