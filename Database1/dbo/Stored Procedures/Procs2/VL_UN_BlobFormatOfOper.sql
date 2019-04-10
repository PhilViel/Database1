/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_BlobFormatOfOper
Description         :	Valide le format d'un blob d'opération
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :						2004-07-19	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_BlobFormatOfOper] (
	@iBlobID INTEGER) -- ID Unique du blob contenant l'information
AS
BEGIN
	-- Valeur de retour @RETURN_VALUE
	-- iBlobID : Tout a fonctionné
	-- -1 : Le blob n'existe pas
	-- -2 : Update du blob par le service par encore fait
	-- -3 : Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot

	DECLARE 
		@iResult INTEGER

	SET @iResult = @iBlobID
	
	-- -1 : Le blob n'existe pas
	IF NOT EXISTS (
			SELECT 
				iBlobID
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID)
		SET @iResult = -1

	-- -2 : Update du blob par le service par encore fait
	IF EXISTS (
			SELECT 
				iBlobID
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID
			  AND txBlob LIKE 'Chaine de caracteres temporaire') AND
			(@iResult > 0)
		SET @iResult = -2

	-- -3 : Les deux derniers caractères ne sont pas un saut de ligne et un retour de chariot
	IF NOT EXISTS (
			SELECT
				iBlobID
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID
			  AND SUBSTRING(txBlob, DATALENGTH (txBlob)-1, 2) = CHAR(13)+CHAR(10)) AND
			(@iResult > 0)
		SET @iResult = -3

	RETURN @iResult
END

