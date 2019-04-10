/****************************************************************************************************
  Cette procédure sert à faire la validation à la modification du 
  souscripteur de la règle disant que seul les souscripteurs résidant au Canada
  ont le droit d'être assuré.
 ******************************************************************************                                                                             
	2004-05-26 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_SubsInsOnlyForCanadianForSubscriber](
	@SubscriberID INTEGER,      -- ID Unique du souscripteur
	@CountryID    VARCHAR(4)) -- Pays de résidence
AS
BEGIN
	-- Retourne la liste des conventions qui ne passe pas la validation
	SELECT DISTINCT
		C.ConventionNo
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
	WHERE (@CountryID <> 'CAN')
	  AND (C.SubscriberID = @SubscriberID)
	  AND (U.WantSubscriberInsurance = 1)
END;


