/****************************************************************************************************
	Cette procédure fait la vaidation du maximum du capital assuré pour un
	souscripteur avant la création d'un nouveau groupe d'unité demandant de
	l'assurance.
 ******************************************************************************
	2004-05-27 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MaxFaceAmountForUnit](
	@SubscriberID INTEGER, -- ID Unique du souscripteur
	@UnitQty MONEY, -- Nombre d'unités 
 	@WantSubscriberInsurance INTEGER, -- 0 = pas d'assurance et <> 0 = assuré
	@ModalID INTEGER) -- ID de la modalité de paiement du groupe d'unités
AS
BEGIN
	DECLARE
		@TotalCapitalInsured MONEY,
		@NewCapitalInsured   MONEY,
		@MaxFaceAmount       MONEY
	
	-- Va chercher le maximum de capital assuré
	SELECT 
		@MaxFaceAmount = MaxFaceAmount
	FROM Un_Def
	
	-- Donne le montant déjà assuré
	SELECT 
		@TotalCapitalInsured = ISNULL(SubscribAmount,0) - ISNULL(AmountToDate,0)
	FROM (
		SELECT 
			C.SubscriberID, 
			SubscribAmount = SUM(ROUND(M.PmtRate*U.UnitQty,2) * M.PmtQty)
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
		JOIN Un_Modal M ON (M.ModalID = U.ModalID)
		WHERE (C.SubscriberID = @SubscriberID)
		  AND (U.WantSubscriberInsurance = 1)
		GROUP BY C.SubscriberID 
		) V1
	LEFT JOIN (
		SELECT 
			C.SubscriberID, 
			AmountToDate = SUM(Co.Cotisation + Co.Fee)
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
		JOIN Un_Cotisation Co ON (Co.UnitID = U.UnitID)
		WHERE (C.SubscriberID = @SubscriberID)
		GROUP BY C.SubscriberID 
		) V2 ON (V1.SubscriberID = V2.SubscriberID)
	
	IF ISNULL(@TotalCapitalInsured,0) <= 0
		SET @TotalCapitalInsured = 0
	
	-- Calcul le montant assuré du nouveau groupe d'unités
	SELECT 
		@NewCapitalInsured = SUM(ROUND(M.PmtRate*@UnitQty,2) * (M.PmtQty-1))
	FROM Un_Modal M
	WHERE ModalID = @ModalID
	  AND @WantSubscriberInsurance <> 0

	IF ISNULL(@NewCapitalInsured,0) <= 0
		SET @NewCapitalInsured = 0
	
	-- Retourne le montant maximum est le total déjà assuré s'il le maximum est dépassé à cause du nouveau groupe d'unités
	SELECT 
		MaxFaceAmount = @MaxFaceAmount,
		TotalCapitalInsured = @TotalCapitalInsured
	WHERE (@TotalCapitalInsured + @NewCapitalInsured) > @MaxFaceAmount
END;


