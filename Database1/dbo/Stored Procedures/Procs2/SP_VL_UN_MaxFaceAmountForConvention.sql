/****************************************************************************************************
	Cette procédure fait la validation du maximum du capital assuré pour un
	changement de souscripteur sur un groupe d'unité.
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MaxFaceAmountForConvention] (
  @SubscriberID INTEGER, -- ID Unique du souscripteur
  @ConventionID INTEGER) -- ID Unique de la convention
AS
BEGIN
	DECLARE
		@TotalCapitalInsured MONEY,
		@NewCapitalInsured MONEY,
		@MaxFaceAmount MONEY

	SET @TotalCapitalInsured = 0
	SET @NewCapitalInsured = 0
	SET @MaxFaceAmount = 0

	IF NOT EXISTS(
		SELECT ConventionID
		FROM dbo.Un_Convention 
		WHERE ConventionID = @ConventionID
		  AND SubscriberID = @SubscriberID)
	BEGIN
		SELECT @MaxFaceAmount = MaxFaceAmount
		FROM Un_Def

		-- Va chercher le montant de capital assuré du souscripteur pour les autres conventions
		SELECT @TotalCapitalInsured = ISNULL(SubscribAmount,0) - ISNULL(AmountToDate,0)
		FROM (
			SELECT 
				C.SubscriberID, 
				SubscribAmount = SUM(ROUND(M.PmtRate*U.UnitQty,2) * M.PmtQty)
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			WHERE C.SubscriberID = @SubscriberID
			  AND U.WantSubscriberInsurance = 1
			GROUP BY C.SubscriberID 
			) V1
		LEFT JOIN (
			SELECT 
				C.SubscriberID, 
				AmountToDate = SUM(Co.Cotisation + Co.Fee)
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Un_Cotisation Co ON Co.UnitID = U.UnitID
			WHERE C.SubscriberID = @SubscriberID
			GROUP BY C.SubscriberID 
			) V2 ON V1.SubscriberID = V2.SubscriberID

		IF ISNULL(@TotalCapitalInsured,0) <= 0
			SET @TotalCapitalInsured = 0

		-- Va chercher le montant de capital assuré de la convention présente
		SELECT @NewCapitalInsured = ISNULL(SubscribAmount,0) - ISNULL(AmountToDate,0)
		FROM (
			SELECT 
				C.SubscriberID, 
				SubscribAmount = SUM(ROUND(M.PmtRate * U.UnitQty,2) * M.PmtQty)
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			WHERE C.ConventionID = @ConventionID
			  AND U.WantSubscriberInsurance = 1
			GROUP BY C.SubscriberID 
			) V1
		LEFT JOIN (
			SELECT 
				C.SubscriberID, 
				AmountToDate = SUM(Co.Cotisation + Co.Fee)
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN Un_Cotisation Co ON Co.UnitID = U.UnitID
			WHERE C.ConventionID = @ConventionID
			GROUP BY C.SubscriberID
		) V2 ON V1.SubscriberID = V2.SubscriberID

		IF ISNULL(@NewCapitalInsured,0) <= 0
			SET @NewCapitalInsured = 0
	END

	-- Retourne un enregistrement si le maximum est dépassé
	SELECT 
		MaxFaceAmount = @MaxFaceAmount,
		TotalCapitalInsured = @TotalCapitalInsured
	WHERE (@TotalCapitalInsured + @NewCapitalInsured) > @MaxFaceAmount
END;


