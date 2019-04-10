/****************************************************************************************************

	PROCEDURE DE VÉRIFICATION DE DATE NULLE

*********************************************************************************
	17-05-2004 Dominic Létourneau
		Migration de l'ancienne procedure selon les nouveaux standards
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_PR_CRQ_IsDateNull] (@DateNull DATETIME OUTPUT) -- Date à vérifier	

AS

BEGIN

	-- Pour les insertions dans les tables nous devons vérifier si la date est '1850/01/01' ou -2
	-- ce qui va donner à la fin une date NULL
	IF @DateNull IS NOT NULL
		IF @DateNull = CONVERT (DATETIME, '1850.01.01', 102) OR @DateNull = -2
			SET @DateNull = NULL
END

