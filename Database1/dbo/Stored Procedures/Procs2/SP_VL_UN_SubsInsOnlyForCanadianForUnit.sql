/****************************************************************************************************
	Retourne le numéro de la convention si le groupe d'unités a de l'assurance 
	souscripteur et que le souscripteur réside à l'extérieur du Canada.  Cette 
	procédure sert à faire la validation à la modification et création d'un 
	groupe d'unités de la règle disant que seul les souscripteurs résidant au 
	Canada ont le droit d'être assuré.
 ******************************************************************************                                                                             
	2004-05-27 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_SubsInsOnlyForCanadianForUnit] (
	@ConventionID INTEGER, -- ID Unique de la convention
	@WantSubscriberInsurance INTEGER) -- 0 = pas d'assurance et <> 0 = assuré
AS
BEGIN
	SELECT DISTINCT
		C.ConventionNo
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human H ON (H.HumanID = C.SubscriberID)
	JOIN dbo.Mo_Adr A ON (A.AdrID = H.AdrID)
	WHERE (@WantSubscriberInsurance = 1)
	  AND (C.ConventionID = @ConventionID)
	  AND (A.CountryID <> 'CAN')
END;


