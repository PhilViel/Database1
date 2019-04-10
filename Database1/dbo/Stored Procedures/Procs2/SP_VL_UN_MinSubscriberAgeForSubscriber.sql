/****************************************************************************************************
	Il y a un age minimum qu'un souscripteur doit avoir pour qu'il est le droit
	d'avoir une convention.  Le souscripteur doit avoir atteint cet age à la 
	signature du contrat. Cet procédure valide que ce minimum est respecté lors
	de la modification d'un souscripteur.
 ******************************************************************************
	2004-05-26 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MinSubscriberAgeForSubscriber] (
	@SubscriberID  INTEGER, -- ID du souscripteur
	@BirthDate     DATETIME) -- Date de naissance du souscripteur (modifié ou non)
AS 
BEGIN
	-- Retourne la liste des conventions qui ne passe pas la validation
	SELECT DISTINCT
		C.ConventionNo
	FROM dbo.Un_Unit U 
	JOIN dbo.Un_Convention C ON (C.ConventionID = U.ConventionID)
	JOIN (
		SELECT
			U.UnitID,
			MinSubscriberAge = MIN(S.MinSubscriberAge)
		FROM Un_SubscriberAgeLimitCfg S
		JOIN dbo.Un_Unit U ON (U.SignatureDate >= S.EffectDate) 
		GROUP BY U.UnitID, U.SignatureDate  
		HAVING (MAX(S.EffectDate) <= U.SignatureDate)
		) V ON (V.UnitID = U.UnitID)
	WHERE (C.SubscriberID = @SubscriberID) 
	  AND (dbo.fn_Mo_Age( @BirthDate, U.SignatureDate ) < V.MinSubscriberAge)                   
END;


