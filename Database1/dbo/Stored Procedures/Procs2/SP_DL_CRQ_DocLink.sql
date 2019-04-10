/****************************************************************************************************

	PROCEDURE DE SUPPRESSION DE LIENS ENTRE UN OBJECT ET UN DOCUMENT

*********************************************************************************
	12-05-2004 Dominic Létourneau
		Création de la procedure pour CRQ-INT-00003
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_CRQ_DocLink] (
	@ConnectID INTEGER, -- Identifiant unique de la connection
	@DocLinkID INTEGER, -- Identifiant unique de l'objet
	@DocID INTEGER, -- Identifiant unique du document
	@DocLinkType INTEGER) -- Contient le type d'objet 

AS

BEGIN

	-- Variables de travail
	DECLARE 
		@LogDesc VARCHAR(5000),
		@Err INTEGER		

	-- Suppression du lien de documents
	DELETE CRQ_DocLink
	WHERE DocLinkID = @DocLinkID
		AND DocID = @DocID
		AND DocLinkType = @DocLinkType

	-- Gestion d'erreur
	SET @Err = @@ERROR

	IF @Err = 0 -- Si aucune erreur
	BEGIN
		-- Header du log
		SET @LogDesc = dbo.FN_CRQ_FormatLog ('CRQ_DocLink', 'DEL', '', '')
		-- Détail du log
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocLink', 'DocLinkID', '', @DocLinkID)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocLink', 'DocID', '', @DocID)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocLink', 'DocLinkType', '', @DocLinkType)
		-- Sauvegarde du log
		EXEC SP_IU_CRQ_Log @ConnectID, 'CRQ_DocLink', '', 'D', @LogDesc
	END

	-- Fin des traitements	
	RETURN @Err -- Si une erreur s'est produite, elle est retournée, sinon 0 (suppression effectuée avec succès)

END

