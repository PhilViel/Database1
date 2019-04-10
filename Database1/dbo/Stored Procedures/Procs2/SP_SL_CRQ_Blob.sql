/****************************************************************************************************
	Retourne un blob temporaire
*********************************************************************************
	2004-11-18 Bruno Lapointe
		Création
		IA-ADX0000588
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_Blob] (
	@BlobID INTEGER) -- ID du blob
AS
BEGIN
	-- Retourne le blob temporaire
	SELECT 
		BlobID,
		Blob
	FROM CRQ_Blob
	WHERE BlobID =@BlobID
END
