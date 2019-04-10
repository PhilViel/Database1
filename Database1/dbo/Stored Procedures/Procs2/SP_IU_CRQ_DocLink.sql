/****************************************************************************************************

	PROCEDURE D'AJOUT DE LIENS DE DOCUMENTS À UN OBJET

*********************************************************************************
	12-05-2004 Dominic Létourneau
		Création de la procedure pour CRQ-INT-00003
*********************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_CRQ_DocLink] (
	@ConnectID INTEGER, -- Identifiant unique de la connection
	@DocLinkID INTEGER, -- Identifiant unique de l'objet
	@DocID INTEGER, -- Identifiant unique du document
	@DocLinkType INTEGER) -- Contient le type de lien entre le document et l'objet
AS

BEGIN

	-- Variables de travail
	DECLARE 
		@LogDesc VARCHAR(5000),
		@Err INTEGER

	-- Ajout du nouveau lien dans CRQ_DocLink
	INSERT CRQ_DocLink (
		DocLinkID,
		DocID,
		DocLinkType)
	SELECT 
		@DocLinkID,
		@DocID,
		@DocLinkType

	SET @Err = @@ERROR

	-- Gestion du log
	IF @Err = 0
	BEGIN
		-- Initialisation des variables pour le log
		SET @LogDesc = ''
		
		-- Header du log
		SET @LogDesc = dbo.FN_CRQ_FormatLog ('CRQ_DocLink', 'NEW', '', '')
		-- Détail du log
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocLink', 'DocLinkID', '', @DocLinkID)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocLink', 'DocID', '', @DocID)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('CRQ_DocLink', 'DocLinkType', '', @DocLinkType)
		-- Sauvegarde du log
		EXEC SP_IU_CRQ_Log @ConnectID, 'CRQ_DocLink', '', 'I', @LogDesc
	END -- Gestion du log

	-- Fin des traitements
	RETURN @Err -- Si une erreur s'est produite, elle est retournée, sinon 0 (suppression effectuée avec succès)

END

