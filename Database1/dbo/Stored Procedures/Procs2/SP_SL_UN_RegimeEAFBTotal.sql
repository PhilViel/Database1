/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : SP_SL_UN_RegimeEAFBTotal
Description         : Totaux unités et EAFB de cohorte pour l'historique des EAFB
Valeurs de retours  : 
Note                :	ADX0000601	IA	2004-12-17	Bruno Lapointe			Création
                                        2017-12-12  Pierre-Luc Simard       Ajout du compte RST dans le compte BRS
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_RegimeEAFBTotal] (
	@ConventionID INTEGER) -- ID unique de la convention
AS
BEGIN
	DECLARE
		@UnitQty MONEY,
		@EAFB MONEY

	SELECT
		@UnitQty = SUM(U.UnitQty)
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Convention CCoh ON CCoh.YearQualif = C.YearQualif AND CCoh.PlanID = C.PlanID
	JOIN dbo.Un_Unit U ON U.ConventionID = CCoh.ConventionID
	WHERE C.ConventionID = @ConventionID

	SELECT
		@EAFB	= SUM(CO.ConventionOperAmount)
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Convention CCoh ON CCoh.YearQualif = C.YearQualif AND CCoh.PlanID = C.PlanID
	JOIN Un_ConventionOper CO ON CO.ConventionID = CCoh.ConventionID
	WHERE C.ConventionID = @ConventionID
		AND CO.ConventionOperTypeID IN ('INC', 'EFB', 'FDI', 'BRS', 'RST', 'AVC')

	SELECT
		UnitQty = @UnitQty,
		EAFB = @EAFB,
		Average = ROUND(@EAFB/@UnitQty,2)
END