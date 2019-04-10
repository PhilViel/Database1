/****************************************************************************************************
	Il y a un age maximum pour qu'un souscripteur puisse être assuré.  Cette 
	procédure valide que l'age est correct sur toutes les conventions lorsque 
	l'on modifie un souscripteur.
 ******************************************************************************
	2004-05-26 Bruno Lapointe
		Création 
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MaxSubscInsurAgeForSubscriber] (
	@SubscriberID MoID,
	@BirthDate MoDateOption)
AS 
BEGIN
	-- Retourne la liste des conventions qui ne passe pas la validation
	SELECT DISTINCT
		C.ConventionNo
	FROM dbo.Un_Unit U 
	JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
	JOIN(
		SELECT
			U.UnitID,
			MaxAgeForSubscInsur = MIN(S.MaxAgeForSubscInsur)
		FROM Un_SubscriberAgeLimitCfg S
		JOIN dbo.Un_Unit U ON (U.SignatureDate >= S.EffectDate) 
		JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
		WHERE (C.SubscriberID = @SubscriberID)
		GROUP BY U.UnitID, U.SignatureDate  
		HAVING (MAX(EffectDate) <= U.SignatureDate)
		) V ON (V.UnitID = U.UnitID)
	WHERE (C.SubscriberID = @SubscriberID) 
	  AND (dbo.fn_Mo_Age( @BirthDate, U.SignatureDate ) > V.MaxAgeForSubscInsur)                   
	  AND (U.WantSubscriberInsurance <> 0)
END;


