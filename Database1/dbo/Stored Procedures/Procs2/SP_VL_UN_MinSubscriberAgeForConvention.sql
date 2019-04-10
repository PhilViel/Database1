/****************************************************************************************************
	Il y a un age minimum qu'un souscripteur doit avoir pour qu'il est le droit
	d'avoir une convention.  Le souscripteur doit avoir atteint cet age à la 
	signature du contrat. Cet procédure valide que ce minimum est respecté lors
	de la modification d'une convention.
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MinSubscriberAgeForConvention] (
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
	JOIN(
		SELECT
			U.UnitID,
			MinSubscriberAge = MIN(S.MinSubscriberAge)
		FROM Un_SubscriberAgeLimitCfg S
		JOIN dbo.Un_Unit U ON (U.SignatureDate >= S.EffectDate) 
		GROUP BY U.UnitID, U.SignatureDate  
		HAVING (MAX(S.EffectDate) <= U.SignatureDate)
		) V ON (V.UnitID = U.UnitID)
	WHERE (C.ConventionID = @ConventionID)  
	  AND (dbo.fn_Mo_Age( @BirthDate, U.SignatureDate ) < V.MinSubscriberAge)                   

	IF @NotOkCount > 0 
		RETURN (-1)
	ELSE 
		RETURN (@ConventionID)  
END;


