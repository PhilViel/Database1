/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_CHQSuggestionMostUse
Description         :	Procédure sauvegardant les modifications faites à la proposition de modification de chèque 
								prédéfinie.
Valeurs de retours  :	@ReturnValue :
									> 0 : La sauvegarde a réussie.
									<= 0 : La sauvegarde a échouée
Note                :	ADX0000693	IA	2005-05-17	Bruno Lapointe		Création
								ADX0000754	IA	2005-10-04	Bruno Lapointe		Modification
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_CHQSuggestionMostUse] (
	@iHumanID VARCHAR(77) ) -- ID de l’humain qui sera le destinataire du chèque.
AS
BEGIN
	DECLARE
		@iResult INTEGER

	IF NOT EXISTS (
		SELECT iCHQSuggestionMostUseID
		FROM Un_CHQSuggestionMostUse
		)
		INSERT INTO Un_CHQSuggestionMostUse (
			iHumanID ) -- ID de l’humain qui sera le destinataire du chèque
		VALUES (
			@iHumanID )
	ELSE
		UPDATE Un_CHQSuggestionMostUse
		SET 
			iHumanID = @iHumanID -- ID de l’humain qui sera le destinataire du chèque

	IF @@ERROR <> 0
		SET @iResult = -1
	ELSE
		SELECT 
			@iResult = MAX(iCHQSuggestionMostUseID)
		FROM Un_CHQSuggestionMostUse

	RETURN @iResult
END

