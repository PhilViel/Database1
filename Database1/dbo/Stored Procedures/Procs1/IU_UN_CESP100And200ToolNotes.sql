/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_CESP100And200ToolNotes
Description         :	Sauvegarde les notes de l’usager sur les erreurs
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Échec
Note                :	ADX0001422	IA	2007-06-23	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_CESP100And200ToolNotes(
	@iBlobID INT ) -- ID du blob de la table CRI_Blob contenant le blob des notes à sauvegarder. Le blob aura une ligne par note. Il y aura l’iCESP800ID et la note séparé par des « ; ». Structures d’une ligne : <iCESP800ID>;<vcNote>;
AS
BEGIN
	DECLARE @CESP100And200ToolNotes TABLE (
		iCESP800ID INT PRIMARY KEY,
		vcNote VARCHAR(75))
	
	INSERT @CESP100And200ToolNotes
		SELECT 
			iCESP800ID,
			vcNote
		FROM dbo.FN_UN_CESP100And200ToolNotes(@iBlobID)

	UPDATE Un_CESP800ToTreat 
	SET vcNote = N.vcNote
	FROM Un_CESP800ToTreat C8T
	JOIN @CESP100And200ToolNotes N ON N.iCESP800ID = C8T.iCESP800ID
	
	IF @@ERROR = 0
		RETURN(1)
	ELSE
		RETURN(-1)
END

