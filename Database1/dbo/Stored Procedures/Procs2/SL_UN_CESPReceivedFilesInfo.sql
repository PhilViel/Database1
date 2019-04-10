/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESPReceivedFilesInfo
Description         :	Renvoit des fichiers de retour avec date
Valeurs de retours  :	@ReturnValue :
					> 0 : Réussite
					<= 0 : Erreurs.
Note                :					
					2006-12-12	IA	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESPReceivedFilesInfo]
AS
BEGIN
	SELECT
		iCESPReceiveFileID, -- ID du fichier reçu du PCEE.
		dtRead = dbo.FN_CRQ_DateNoTime(dtRead) -- Date d’importation du fichier.
	FROM Un_CESPReceiveFile
	ORDER BY dtRead DESC
END

