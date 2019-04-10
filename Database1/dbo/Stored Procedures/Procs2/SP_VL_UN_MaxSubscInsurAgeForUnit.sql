/****************************************************************************************************
	Il y a un age maximum pour qu'un souscripteur puisse être assuré.  Cette 
	procédure valide que l'age est correct sur la convention lorsque 
	l'on modifie un groupe d'unités.
 ******************************************************************************
	2004-05-27 Bruno Lapointe
		Création 
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MaxSubscInsurAgeForUnit] (
	@SubscriberID  INTEGER,
	@SignatureDate DATETIME)
AS 
BEGIN
	
	DECLARE
		@BirthDate DATETIME,
		@MaxAgeForSubscInsur INTEGER
	
	SELECT 
		@BirthDate = H.BirthDate      
	FROM dbo.Mo_Human H
	WHERE (H.HumanID = @SubscriberID)
	
	SELECT 
		@MaxAgeForSubscInsur = MIN(MaxAgeForSubscInsur)
	FROM Un_SubscriberAgeLimitCfg
	HAVING (MAX(EffectDate) <= @SignatureDate)
	
	IF dbo.fn_Mo_Age( @BirthDate, @SignatureDate ) > @MaxAgeForSubscInsur 
		RETURN (-1)
	ELSE 
		RETURN (1)  
END;


