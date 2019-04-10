/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_Template 
Description         :	Procédure qui retournera un modèle de chèque.
Valeurs de retours  :	Dataset :
									iTemplateID				INTEGER			ID du modèle.
									iCheckBookID			INTEGER 			ID du chéquier.
									vcCheckBookDesc		VARCHAR(255)	Nom du chéquier
									iTemplateType			INTEGER			Type de modèle.
									iMaxStubDtlLines		INTEGER			Nombre de ligne maximum de détail qui peut s’afficher sur le talon du chèque.
									vcTemplateName			VARCHAR(100)	Nom du modèle.
									txTemplateDocument	TEXT				Modèle.
									cTemplateLanguage		CHAR(10)			Langue du modèle.
									dtCreated				DATETIME			Date de création du modèle.
Note                :	ADX0000714	IA	2005-09-16	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_Template] (
	@iTemplateID INTEGER ) -- ID unique du modèle voulu. (0 = Tous)
AS
BEGIN

	SET NOCOUNT ON

	SELECT 
		T.iTemplateID, -- ID du modèle.
		T.iCheckBookID, -- ID du chéquier.
		CB.vcCheckBookDesc, -- Nom du chéquier
		T.iTemplateType, -- Type de modèle.
		T.iMaxStubDtlLines, -- Nombre de ligne maximum de détail qui peut s’afficher sur le talon du chèque.
		T.vcTemplateName, -- Nom du modèle.
		T.txTemplateDocument, -- Modèle.
		T.cTemplateLanguage, -- Langue du modèle.
		T.dtCreated -- Date de création du modèle.
	FROM CHQ_Template T
	JOIN CHQ_CheckBook CB ON CB.iCheckBookID = T.iCheckBookID
	WHERE @iTemplateID = T.iTemplateID
		OR @iTemplateID = 0

END
