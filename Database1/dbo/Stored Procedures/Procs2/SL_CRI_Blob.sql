/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CRI_Blob
Description         :	Retourne un blob temporaire.
Valeurs de retours  :	Dataset :
									iBlobID	INTEGER	ID du blob
									dtBlob	DATETIME	Date d'insertion du blob.
									txBlob	TEXT		Blob contenant les objets
Note                :	ADX0000847	IA	2006-03-28	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CRI_Blob] (
	@iBlobID INTEGER) -- ID du blob
AS
BEGIN
	-- Retourne le blob temporaire
	SELECT 
		iBlobID,
		dtBlob,
		txBlob
	FROM CRI_Blob
	WHERE iBlobID = @iBlobID
END
