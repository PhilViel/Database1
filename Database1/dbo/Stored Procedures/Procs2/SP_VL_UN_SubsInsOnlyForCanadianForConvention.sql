/****************************************************************************************************
	Retourne le numéro de la convention si un des groupes d'unités a de 
	l'assurance souscripteur et que le souscripteur réside à l'extérieur du 
	Canada.  Cette procédure sert à faire la validation lors d'un changement de 
	souscripteur sur une convention de la règle disant que seul les 
	souscripteurs résidant au Canada ont le droit d'être assuré.
 ******************************************************************************                                                                             
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_SubsInsOnlyForCanadianForConvention] (
  @ConventionID INTEGER, -- ID Unique de la convention
  @SubscriberID INTEGER) -- ID Unique du souscripteur
AS
BEGIN
	-- Valide que la règle soit respecté entre la convention dont on fait le changement de souscripteur et le nouveau souscripteur de cette convention.
	SELECT 
		C.ConventionNo
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
	WHERE EXISTS(
		SELECT 
			H.HumanID
		FROM dbo.Mo_Human H 
		JOIN dbo.Mo_Adr A ON (A.AdrID = H.AdrID)
		WHERE (H.HumanID = @SubscriberID)
		  AND (A.CountryID <> 'CAN')) 
	  AND (C.ConventionID = @ConventionID)
	  AND (U.WantSubscriberInsurance = 1) 
	UNION  
	-- Valide que la règle soit déjà respecté entre le souscripteur et les conventions qu'il avait avant le changement
	SELECT 
		C.ConventionNo
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
	WHERE EXISTS(
		SELECT 
			H.HumanID
		FROM dbo.Mo_Human H 
		JOIN dbo.Mo_Adr A ON (A.AdrID = H.AdrID)
		WHERE (H.HumanID = @SubscriberID)
		  AND (A.CountryID <> 'CAN')) 
	  AND (C.SubscriberID = @SubscriberID)
	  AND (U.WantSubscriberInsurance = 1)    
END;


