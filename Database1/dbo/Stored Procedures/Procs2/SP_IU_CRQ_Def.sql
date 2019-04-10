/******************************************************************************
	Modification des paramètres de configuration de compurangers
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE SP_IU_CRQ_Def(
	@DocMaxSizeInMeg INTEGER) -- Maximum en meg pour fichier word généré par la gestion des documents
AS
BEGIN
	UPDATE CRQ_Def
	SET 
		DocMaxSizeInMeg = @DocMaxSizeInMeg
	FROM CRQ_Def
	
	IF @@ERROR = 0
		RETURN 1 -- Tous à bien fonctionné
	ELSE
		RETURN -1 -- Une erreur est survenue
END;
