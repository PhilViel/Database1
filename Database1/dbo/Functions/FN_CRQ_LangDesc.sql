/****************************************************************************************************

	Fonction RETOURNANT LA DESCRIPTION DE LA LANGUE

*********************************************************************************
	17-05-2004 Dominic Létourneau
		Migration de l'ancienne fonction selon les nouveaux standards
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_LangDesc (@LangID CHAR(3)) -- Identifiant de la langue
RETURNS VARCHAR(75)
AS

BEGIN

	DECLARE @Result MoDesc
    
	IF ISNULL(@LangID, '') = '' 
		SET @Result = ''
	ELSE IF @LangID = 'UNK' 
		SET @Result = 'Unknow'
	ELSE IF @LangID = 'ENU' 
		SET @Result = 'English'
	ELSE IF @LangID = 'FRA' SET 
		@Result = 'French'

  RETURN(@Result)                  

END

