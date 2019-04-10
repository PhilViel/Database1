/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	DL_CHQ_NewRecipientsForCheckCanceled
Description         :	Procédure qui supprime un destinataire de la liste des destinataires disponibles lors d’une « Annulation : Destinataire perdu ».
Valeurs de retours  :	@ReturnValue :
					> 0 : Réussite
					<= 0 : Échec.
				
Note                :	ADX0001179	IA	2006-10-25	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_CHQ_NewRecipientsForCheckCanceled](
@iRecipientID INTEGER)	--ID du destinataire
AS
BEGIN
	DECLARE @iReturn INTEGER
	
	SET @iReturn = 1

	DELETE
	FROM CHQ_NewRecipientsForCheckCanceled
	WHERE iRecipientID = @iRecipientID

	IF @@ERROR <> 0
		SET @iReturn = -1

	RETURN @iReturn		
END
