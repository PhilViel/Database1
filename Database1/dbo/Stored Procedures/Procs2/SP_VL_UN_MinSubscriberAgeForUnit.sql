/****************************************************************************************************
	Il y a un age minimum qu'un souscripteur doit avoir pour qu'il est le droit
	d'avoir une convention.  Le souscripteur doit avoir atteint cet age à la 
	signature du contrat. Cet procédure valide que ce minimum est respecté lors
	de la modification d'un groupe d'unités.
 ******************************************************************************
	2004-05-27 Bruno Lapointe
		Création 
 ******************************************************************************/
CREATE PROCEDURE dbo.SP_VL_UN_MinSubscriberAgeForUnit (
	@SubscriberID  INTEGER,
	@SignatureDate DATETIME)
AS 
BEGIN

	DECLARE
		@BirthDate DATETIME,
		@MinSubscriberAge INTEGER
	
	SELECT 
		@BirthDate = H.BirthDate      
	FROM dbo.Mo_Human H
	WHERE (H.HumanID = @SubscriberID)
	
	SELECT 
		@MinSubscriberAge = MIN(MinSubscriberAge)
	FROM Un_SubscriberAgeLimitCfg
	HAVING (MAX(EffectDate) <= @SignatureDate)
	
	IF dbo.fn_Mo_Age( @BirthDate, @SignatureDate ) < @MinSubscriberAge 
		RETURN (-1)
	ELSE 
		RETURN (1)  
 
END;


