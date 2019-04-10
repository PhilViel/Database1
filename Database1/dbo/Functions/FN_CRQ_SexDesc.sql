/****************************************************************************************************

	Fonction RETOURNANT LA DESCRIPTION DU SEXE

*********************************************************************************
	17-05-2004 Dominic Létourneau
		Migration de l'ancienne fonction selon les nouveaux standards
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_SexDesc (@SexID CHAR(1)) -- Identifiant unique du sexe (U, F, M)
RETURNS VARCHAR(75)
AS

BEGIN

	DECLARE @Result MoDesc
	
	IF ISNULL(@SexID, '') = '' 
		SET @Result = ''
	ELSE IF @SexID = 'U' 
		SET @Result = 'Unknow'
	ELSE IF @SexID = 'F' 
		SET @Result = 'Female'
	ELSE IF @SexID = 'M' 
		SET @Result = 'Male'
	
	RETURN(@Result)                  

END

