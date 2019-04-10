/****************************************************************************************************

	Fonction RETOURNANT LA DESCRIPTION DU STATUT CIVIL

*********************************************************************************
	17-05-2004 Dominic Létourneau
		Migration de l'ancienne fonction selon les nouveaux standards
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_CivilDesc (@CivilID CHAR(3)) -- Description Param1
RETURNS VARCHAR(75)
AS

BEGIN

	DECLARE @Result MoDesc

	IF ISNULL(@CivilID, '') = '' 
		SET @Result = ''
	ELSE IF @CivilID = 'U' 
		SET @Result = 'Unknow'
	ELSE IF @CivilID = 'S' 
		SET @Result = 'Single'
	ELSE IF @CivilID = 'M' 
		SET @Result = 'Maried'
	ELSE IF @CivilID = 'J' 
		SET @Result = 'Joint'
	ELSE IF @CivilID = 'D' 
		SET @Result = 'Divorced'
	ELSE IF @CivilID = 'P' 
		SET @Result = 'Separated'
	ELSE IF @CivilID = 'W' 
		SET @Result = 'Widowed'
	
	RETURN(@Result)                  

END

