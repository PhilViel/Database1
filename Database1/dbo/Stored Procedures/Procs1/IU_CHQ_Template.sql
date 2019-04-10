/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	IU_CHQ_Template 
Description         :	Sauvegarde la modification du modèle de chèque.
Valeurs de retours  :	@ReturnValue :
									> 0 : L’opération a réussie.
									< 0 : La sauvegarde a échouée.
Note                :	ADX0000714	IA	2006-02-02	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_CHQ_Template] (
	@iTemplateID INTEGER, -- ID du modèle
	@txTemplateDocument TEXT ) -- Blob contenant le modèle
AS
BEGIN
	SET NOCOUNT ON

	UPDATE CHQ_Template
	SET txTemplateDocument = @txTemplateDocument
	WHERE iTemplateID = @iTemplateID

	IF @@ERROR = 0
		RETURN 1
	ELSE
		RETURN -1
END
