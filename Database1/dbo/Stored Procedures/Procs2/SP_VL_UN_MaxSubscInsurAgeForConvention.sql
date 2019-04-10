/****************************************************************************************************
	Il y a un age maximum pour qu'un souscripteur puisse être assuré.  Cette 
	procédure valide que l'age est correct lorsque l'on modifie une convention.
 ******************************************************************************
 	2004-06-01 Bruno Lapointe
		Création 
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MaxSubscInsurAgeForConvention] (
	@SubscriberID  INTEGER, -- ID Unique du souscripteur
	@ConventionID  INTEGER) -- ID Unique de la convention
AS 
BEGIN
	DECLARE 
		@NotOkCount INTEGER,
		@BirthDate DATETIME

	SELECT 
		@BirthDate = H.BirthDate      
	FROM dbo.Mo_Human H
	WHERE (H.HumanID = @SubscriberID)

	SELECT
		@NotOkCount = COUNT(U.UnitID)
	FROM dbo.Un_Unit U 
	JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
	JOIN (
		SELECT
			U.UnitID,
			MIN(S.MaxAgeForSubscInsur) AS MaxAgeForSubscInsur
		FROM Un_SubscriberAgeLimitCfg S
		JOIN dbo.Un_Unit U ON (U.SignatureDate >= S.EffectDate) 
		WHERE U.ConventionID = @ConventionID
		GROUP BY U.UnitID, U.SignatureDate  
		HAVING (MAX(EffectDate) <= U.SignatureDate)
		) V ON (V.UnitID = U.UnitID)
	WHERE (C.ConventionID = @ConventionID) 
	  AND (U.WantSubscriberInsurance <> 0) 
	  AND (dbo.fn_Mo_Age( @BirthDate, U.SignatureDate ) > V.MaxAgeForSubscInsur)                   
 
	IF @NotOkCount > 0 
		RETURN (-1)
	ELSE 
		RETURN (@ConventionID)  
END;


