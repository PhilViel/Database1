/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	IU_CHQ_NewRecipientsForCheckCanceled
Description         :	Procédure qui ajoute un ou des destinataires à la liste des destinataires disponibles lors d’une « Annulation : Destinataire perdu ».
Valeurs de retours  :	@ReturnValue :
					> 0 : Réussite
					<= 0 : Échec.
				
Note                :	ADX0001179	IA	2006-10-25	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_CHQ_NewRecipientsForCheckCanceled](
@iBlobID INTEGER)	--ID du blob contenant la liste des destinataires séparé par une virgule
AS
BEGIN
	DECLARE 
		@iReturn INTEGER

	SET @iReturn = 1

	INSERT INTO CHQ_NewRecipientsForCheckCanceled
	SELECT F.iVal
	FROM dbo.FN_CRI_BlobToIntegerTable(@iBlobID) F
	LEFT JOIN CHQ_NewRecipientsForCheckCanceled C ON C.iRecipientID = F.iVal
	WHERE C.iRecipientID IS NULL	-- Destinataires qui n'existent pas déjà 

	IF @@ERROR <> 0
		SET @iReturn = -1

	RETURN @iReturn		
END
