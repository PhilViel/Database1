/****************************************************************************************************
	Retourne les paramètres de configuration de compurangers
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_Def]
AS
BEGIN
	SELECT
		DocMaxSizeInMeg
	FROM CRQ_Def
END;
